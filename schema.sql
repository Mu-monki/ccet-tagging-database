-- ==============================================================================
-- MYSQL SCHEMA CREATION (DDL) - APPLICATION-CONTROLLED INTEGRITY
-- ==============================================================================

DROP TABLE IF EXISTS fact_ccet_expenditure;
DROP TABLE IF EXISTS dim_agency;
DROP TABLE IF EXISTS dim_department;
DROP TABLE IF EXISTS dim_pap;
DROP TABLE IF EXISTS dim_typology;

-- 2. Create Dimension: Department (No unique constraints, Pandas handles deduplication)
CREATE TABLE dim_department (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(255) NOT NULL
);

-- 3. Create Dimension: Agency
CREATE TABLE dim_agency (
    agency_id INT AUTO_INCREMENT PRIMARY KEY,
    agency_name VARCHAR(255) NOT NULL,
    grit_tagging VARCHAR(255),
    department_id INT, 
    FOREIGN KEY (department_id) REFERENCES dim_department (department_id) ON DELETE CASCADE
);

-- 4. Create Dimension: PAP (Program, Activity, Project)
CREATE TABLE dim_pap (
    pap_id INT AUTO_INCREMENT PRIMARY KEY,
    pap_code VARCHAR(255) NOT NULL,
    pap_description TEXT NOT NULL
);
CREATE INDEX idx_pap_code ON dim_pap(pap_code);

-- 5. Create Dimension: Typology
CREATE TABLE dim_typology (
    typology_id INT AUTO_INCREMENT PRIMARY KEY,
    typology_code VARCHAR(255) NOT NULL,
    typology_description TEXT
);
CREATE INDEX idx_typology_code ON dim_typology(typology_code);

-- 6. Create Fact: CCET Expenditure
CREATE TABLE fact_ccet_expenditure (
    expenditure_id INT AUTO_INCREMENT PRIMARY KEY,
    fiscal_year INT NOT NULL,
    budget_type VARCHAR(100) NOT NULL, 
    agency_id INT NOT NULL,
    pap_id INT NOT NULL,
    typology_id INT NOT NULL,
    adaptation_amount DECIMAL(18, 2) DEFAULT 0,
    mitigation_amount DECIMAL(18, 2) DEFAULT 0,
    total_amount DECIMAL(18, 2) DEFAULT 0,
    FOREIGN KEY (agency_id) REFERENCES dim_agency (agency_id) ON DELETE CASCADE,
    FOREIGN KEY (pap_id) REFERENCES dim_pap (pap_id) ON DELETE CASCADE,
    FOREIGN KEY (typology_id) REFERENCES dim_typology (typology_id) ON DELETE CASCADE
);

CREATE INDEX idx_fact_fiscal_year ON fact_ccet_expenditure(fiscal_year);
CREATE INDEX idx_fact_agency ON fact_ccet_expenditure(agency_id);
CREATE INDEX idx_fact_pap ON fact_ccet_expenditure(pap_id);
CREATE INDEX idx_fact_typology ON fact_ccet_expenditure(typology_id);