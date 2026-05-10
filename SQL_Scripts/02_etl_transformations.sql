-- =========================================================================
-- PROJECT: Hospital Revenue Cycle & Claim Denials Analytics
-- DESCRIPTION: Phase 2 - ETL Data Pipelines & Advanced Transformations
-- DESCRIPTION: Migrates raw staging data to production with cleanups.
-- =========================================================================

PROMPT Starting ETL Transformations...

-- 1. TRANSFORM PATIENTS: Remove duplicates, trim whitespace, standardize text casing
INSERT INTO Patients (PatientID, Name, Age, Gender, City)
SELECT PatientID, Name, TO_NUMBER(Age), Gender, City
FROM (
    SELECT 
        TRIM(PatientID) as PatientID,
        TRIM(INITCAP(Name)) as Name,
        TRIM(Age) as Age,
        TRIM(INITCAP(Gender)) as Gender,
        TRIM(UPPER(City)) as City,
        ROW_NUMBER() OVER (PARTITION BY TRIM(PatientID) ORDER BY TRIM(PatientID)) as row_num
    FROM STG_PATIENTS
)
WHERE row_num = 1 AND PatientID IS NOT NULL;

-- 2. TRANSFORM INSURANCE: Upper casing parent keys to prevent case conflicts
INSERT INTO Insurance (InsuranceCompany, PlanType, CoverageLimit)
SELECT DISTINCT
    UPPER(TRIM(InsuranceCompany)),
    TRIM(INITCAP(PlanType)),
    TO_NUMBER(TRIM(CoverageLimit))
FROM STG_INSURANCE
WHERE InsuranceCompany IS NOT NULL;

-- 3. TRANSFORM DENIAL LOOKUP
INSERT INTO Denial_Reason_Lookup (DenialCode, Meaning)
SELECT DISTINCT
    TRIM(UPPER(DenialCode)),
    TRIM(Meaning)
FROM STG_DENIAL_REASON_LOOKUP
WHERE DenialCode IS NOT NULL;

-- 4. TRANSFORM CLINICAL: Regular Expressions to handle dynamic mixed date formats
INSERT INTO Clinical (ClaimID, PatientID, Department, ICDCode, AdmissionDate)
SELECT DISTINCT
    TRIM(UPPER(ClaimID)),
    TRIM(UPPER(PatientID)),
    TRIM(INITCAP(Department)),
    TRIM(UPPER(ICDCode)),
    CASE 
        -- Format: DD-MM-YYYY
        WHEN REGEXP_LIKE(TRIM(AdmissionDate), '^[0-9]{2}-[0-9]{2}-[0-9]{4}$') THEN 
            TO_DATE(TRIM(AdmissionDate), 'DD-MM-YYYY')
        -- Format: YYYY/MM/DD
        WHEN REGEXP_LIKE(TRIM(AdmissionDate), '^[0-9]{4}/[0-9]{2}/[0-9]{2}$') THEN 
            TO_DATE(TRIM(AdmissionDate), 'YYYY/MM/DD')
        -- Format: Mon DD YYYY (e.g. Apr 22 2026)
        WHEN REGEXP_LIKE(TRIM(AdmissionDate), '^[A-Za-z]{3} [0-9]{2} [0-9]{4}$') THEN 
            TO_DATE(TRIM(AdmissionDate), 'MON DD YYYY', 'NLS_DATE_LANGUAGE = AMERICAN')
        ELSE NULL 
    END as AdmissionDate
FROM STG_CLINICAL
WHERE ClaimID IS NOT NULL;

-- 5. TRANSFORM BILLING: Map descriptive text to relational codes (D01, D02...)
INSERT INTO Billing (ClaimID, InsuranceCompany, ClaimAmount, ClaimStatus, DenialCode)
SELECT DISTINCT
    TRIM(UPPER(b.ClaimID)),
    UPPER(TRIM(b.InsuranceCompany)),
    TO_NUMBER(TRIM(b.ClaimAmount)),
    TRIM(UPPER(b.ClaimStatus)),
    l.DenialCode
FROM STG_BILLING b
LEFT JOIN Denial_Reason_Lookup l 
  ON TRIM(UPPER(b.DenialReason)) = TRIM(UPPER(l.Meaning))
WHERE b.ClaimID IS NOT NULL;

-- 6. COMMIT ALL DATA IN A SINGLE TRANSACTION
COMMIT;

PROMPT ETL Transformations and load complete.