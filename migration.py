import pandas as pd
from sqlalchemy import create_engine
import sys
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Build the connection string securely from environment variables
db_user = os.getenv("MYSQL_DB_USER")
db_password = os.getenv("MYSQL_DB_PASSWORD")
db_host = os.getenv("MYSQL_DB_HOST")
db_port = os.getenv("MYSQL_DB_PORT")
db_name = os.getenv("MYSQL_DB_NAME")

connection_string = f"mysql+pymysql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"

# 1. Connect to Database
engine = create_engine(connection_string)

print("Reading CSVs...")
df1 = pd.read_csv("./datasets/data-original.csv", dtype={'PAP ID': str, 'TYPOLOGY ID': str})
df2 = pd.read_csv("./datasets/data-tagged.csv", dtype={'PAP ID': str, 'TYPOLOGY ID': str})

if 'GRIT TAGGING' not in df1.columns:
    df1['GRIT TAGGING'] = None

df = pd.concat([df1, df2], ignore_index=True)

# 2. Rename Columns
df.rename(columns={
    'DEPARTMENT': 'department_name',
    'AGENCY': 'agency_name',
    'GRIT TAGGING': 'grit_tagging',
    'PAP ID': 'pap_code',
    'PAP Description': 'pap_description',
    'TYPOLOGY ID': 'typology_code',
    'TYPOLOGY Description': 'typology_description',
    'Fiscal_Year': 'fiscal_year',
    'Type': 'budget_type',
    'ADAPTION': 'adaptation_amount',
    'MITIGATION': 'mitigation_amount',
    'TOTAL': 'total_amount'
}, inplace=True)

# 3. Clean Data 
df['department_name'] = df['department_name'].fillna('Unknown Department').astype(str).str.strip().str[:255]
df['agency_name'] = df['agency_name'].fillna('Unknown Agency').astype(str).str.strip().str[:255]
df['grit_tagging'] = df['grit_tagging'].fillna('None').astype(str).str.strip().str[:255]

df['pap_code'] = df['pap_code'].fillna('Unknown').astype(str).str.strip().str[:255]
df['pap_description'] = df['pap_description'].fillna('N/A').astype(str).str.strip()

df['typology_code'] = df['typology_code'].fillna('Unknown').astype(str).str.strip().str[:255]
df['typology_description'] = df['typology_description'].fillna('N/A').astype(str).str.strip()

df['budget_type'] = df['budget_type'].fillna('Unknown').astype(str).str.strip().str[:100]
df.fillna({'adaptation_amount': 0, 'mitigation_amount': 0, 'total_amount': 0, 'fiscal_year': 2000}, inplace=True)

print("Starting database insertion...")

with engine.connect() as conn:
    row_count = pd.read_sql("SELECT COUNT(*) as cnt FROM dim_department", con=conn).iloc[0]['cnt']
    if row_count > 0:
        print("❌ ERROR: The database already contains data!")
        print("Please run schema.sql to drop and recreate the tables before migrating.")
        sys.exit(1)

    # ======================================================================
    # LOCAL ID GENERATION: Guarantees 100% match success rate
    # ======================================================================
    
    # --- 1. Department ---
    print("Mapping Departments...")
    depts = df[['department_name']].drop_duplicates().reset_index(drop=True)
    depts['department_id'] = depts.index + 1 # Generate IDs in Python
    df = df.merge(depts, on='department_name', how='left')
    depts.to_sql('dim_department', con=engine, if_exists='append', index=False)

    # --- 2. Agency ---
    print("Mapping Agencies...")
    agencies = df[['agency_name', 'grit_tagging', 'department_id']].drop_duplicates().reset_index(drop=True)
    agencies['agency_id'] = agencies.index + 1 # Generate IDs in Python
    df = df.merge(agencies, on=['agency_name', 'department_id', 'grit_tagging'], how='left')
    agencies.to_sql('dim_agency', con=engine, if_exists='append', index=False)

    # --- 3. PAP ---
    print("Mapping PAPs...")
    paps = df[['pap_code', 'pap_description']].drop_duplicates().reset_index(drop=True)
    paps['pap_id'] = paps.index + 1 # Generate IDs in Python
    df = df.merge(paps, on=['pap_code', 'pap_description'], how='left')
    paps.to_sql('dim_pap', con=engine, if_exists='append', index=False)

    # --- 4. Typology ---
    print("Mapping Typologies...")
    typos = df[['typology_code', 'typology_description']].drop_duplicates().reset_index(drop=True)
    typos['typology_id'] = typos.index + 1 # Generate IDs in Python
    df = df.merge(typos, on=['typology_code', 'typology_description'], how='left')
    typos.to_sql('dim_typology', con=engine, if_exists='append', index=False)

    # --- 5. Fact Table ---
    missing_ids = df['agency_id'].isna().sum()
    if missing_ids > 0:
        print(f"⚠️ Warning: {missing_ids} rows failed to map and will be dropped.")
    
    df.dropna(subset=['agency_id', 'pap_id', 'typology_id'], inplace=True)
    
    print(f"Inserting {len(df)} rows into fact table...")
    fact_table = df[['fiscal_year', 'budget_type', 'agency_id', 'pap_id', 'typology_id', 
                     'adaptation_amount', 'mitigation_amount', 'total_amount']]
    
    # We use chunksize to avoid maxing out MySQL's packet limit
    fact_table.to_sql('fact_ccet_expenditure', con=engine, if_exists='append', index=False, chunksize=10000)

print("✅ Data migration to MySQL complete!")