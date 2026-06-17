# National CCET PAPs Database Pipeline

This project automates the extraction, transformation, and loading (ETL) of the National Climate Change Expenditure Tagging (CCET) data into a fully normalized MySQL database. 

It utilizes a **Star Schema** dimensional model to efficiently store over 146,000+ records, reducing data redundancy and optimizing analytical query performance. The infrastructure is containerized using Docker, and the ETL process is handled via a robust Python/Pandas pipeline.

## 📋 Prerequisites

Before running the setup, ensure you have the following installed on your machine:
* **Docker & Docker Compose** *(Docker Desktop is recommended)*
* **Python 3.8+**
* Required Python Libraries:
  ```bash
  pip install pandas sqlalchemy pymysql openpyxl


## 📂 Project Structure

Ensure your project directory contains the following files before execution:
Plaintext

```
/ccet-database-project
 ├── datasets                 # Datasets folder
 │   ├── data-original.csv
 │   └── data-tagged.csv
 ├── docker-compose.yml       # Docker configuration for the MySQL container
 ├── schema.sql               # DDL script defining tables and foreign key constraints
 ├── migration.py             # Python ETL script (Handles deduplication and ID generation)
 ├── setup.sh                 # Initialization script for macOS/Linux
 └──  setup.ps1               # Initialization script for Windows
 ```

## 🏗️ Database Architecture (Star Schema)

The database (ccet_db) is modeled to separate repetitive text data from numerical financial data:

    fact_ccet_expenditure: The central repository storing discrete budgetary rows, mapped via Foreign Keys to Agencies, PAPs, and Typologies. Includes amounts for adaptation, mitigation, and total expenditures.

    dim_department: Distinct governmental departments.
    dim_agency: Sub-agencies and their associated grit_tagging classifications.
    dim_pap: Programs, Activities, and Projects (PAPs) with their full text descriptions.
    dim_typology: CCET initiative classifications and descriptions.

Note: To ensure 100% data integrity and avoid database-level string collation conflicts (e.g., invisible trailing spaces or byte-decoding traps), all deduplication and primary key ID generation is handled strictly within the Python application layer before insertion.

## Entity Relationship Diagram
![Entity Relationship Diagram](/images/erd-bg.png "Entity Relationship Diagram")

## 🚀 Installation and Setup
**Step 1:** Start the Database Environment

Spin up the local MySQL instance using Docker. Run this command in your terminal from the project folder:
Bash

```docker compose up -d```

(Wait 10-15 seconds for the database container to fully initialize).
**Step 2:** Initialize the Database Schema

Apply the schema to create the empty tables and enforce relationships.

For macOS/Linux:
Bash

```docker exec -i ccet_mysql mysql -uroot -prootpassword ccet_db < schema.sql```

For Windows (PowerShell/CMD):
DOS

```cmd.exe /c "type schema.sql | docker exec -i ccet_mysql mysql -uroot -prootpassword ccet_db"```

**Step 3:** Run the ETL Pipeline

Execute the Python script to clean the CSVs, map the relational IDs, and batch-insert the data into MySQL.
Bash

```python migrate_data.py```

(Alternatively, you can just run ./setup.sh on Mac/Linux or .\setup.ps1 on Windows to execute all three steps automatically).

## 🔌 Connecting to the Database

Once the migration is complete, you can connect to the database using any SQL client (e.g., DBeaver, MySQL Workbench, DataGrip) with the following credentials:

*THIS ARE SAMPLE CREDENTIALS*
```
    Host: localhost
    Port: 3306
    Database: ccet_db
    Username: root
    Password: rootpassword
```

## 🛠️ Data Cleaning Rules Applied

The `migration.py` script automatically performs the following data sanitization steps:

    - NaN Handling: Fills missing textual values with "Unknown" or "N/A" and missing numerical values with 0.
    - String Stripping: Removes accidental leading/trailing whitespaces from the Excel exports.
    - Truncation: Limits dimension names (Departments, Agencies, Codes) to 255 characters to comply with MySQL indexing limits, while leaving large description fields unbounded (TEXT).
    - Referential Integrity: Generates localized IDs simultaneously for dimension tables and fact tables, ensuring zero orphaned rows during the final insertion block.

## ⚠️ Troubleshooting

    "Database already contains data" Error: The Python script includes a safety lock to prevent data duplication. If you need to re-run the script, you must wipe the database by repeating Step 2 (Initialize the Database Schema) first.

    Port 3306 is taken: If Docker fails to start, ensure you do not have another local instance of MySQL or MariaDB running on your machine.