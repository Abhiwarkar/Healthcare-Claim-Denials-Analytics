-- =========================================================================
-- PROJECT: Hospital Revenue Cycle & Claim Denials Analytics
-- AUTHOR: [Your Name]
-- DESCRIPTION: Phase 1 - Schema Creation and Staging Area Setup
-- DATABASE ENGINE: Oracle SQL (23ai Free / Enterprise)
-- =========================================================================

-- 1. DROP EXISTING TABLES (If any to avoid conflicts during deployment)
PROMPT Dropping existing tables...
DROP TABLE Billing CASCADE CONSTRAINTS;
DROP TABLE Clinical CASCADE CONSTRAINTS;
DROP TABLE Patients CASCADE CONSTRAINTS;
DROP TABLE Insurance CASCADE CONSTRAINTS;
DROP TABLE Denial_Reason_Lookup CASCADE CONSTRAINTS;

DROP TABLE STG_PATIENTS CASCADE CONSTRAINTS;
DROP TABLE STG_CLINICAL CASCADE CONSTRAINTS;
DROP TABLE STG_BILLING CASCADE CONSTRAINTS;
DROP TABLE STG_INSURANCE CASCADE CONSTRAINTS;
DROP TABLE STG_DENIAL_REASON_LOOKUP CASCADE CONSTRAINTS;

-- 2. CREATE STAGING TABLES (ELT Landing Layer - No constraints)
PROMPT Creating Staging Tables...
CREATE TABLE STG_PATIENTS (
    PatientID VARCHAR2(50),
    Name VARCHAR2(100),
    Age VARCHAR2(50),
    Gender VARCHAR2(50),
    City VARCHAR2(100)
);

CREATE TABLE STG_CLINICAL (
    ClaimID VARCHAR2(50),
    PatientID VARCHAR2(50),
    Department VARCHAR2(100),
    ICDCode VARCHAR2(50),
    AdmissionDate VARCHAR2(50)
);

CREATE TABLE STG_BILLING (
    ClaimID VARCHAR2(50),
    InsuranceCompany VARCHAR2(100),
    ClaimAmount VARCHAR2(50),
    ClaimStatus VARCHAR2(50),
    DenialReason VARCHAR2(100)
);

CREATE TABLE STG_INSURANCE (
    InsuranceCompany VARCHAR2(100),
    PlanType VARCHAR2(50),
    CoverageLimit VARCHAR2(50)
);

CREATE TABLE STG_DENIAL_REASON_LOOKUP (
    DenialCode VARCHAR2(50),
    Meaning VARCHAR2(200)
);

-- 3. CREATE PRODUCTION TABLES (Clean, Optimized, Relational Layer)
PROMPT Creating Core Production Tables...
CREATE TABLE Patients (
    PatientID VARCHAR2(10) PRIMARY KEY,
    Name VARCHAR2(50) NOT NULL,
    Age NUMBER,
    Gender VARCHAR2(10),
    City VARCHAR2(50)
);

CREATE TABLE Insurance (
    InsuranceCompany VARCHAR2(100) PRIMARY KEY,
    PlanType VARCHAR2(20),
    CoverageLimit NUMBER
);

CREATE TABLE Denial_Reason_Lookup (
    DenialCode VARCHAR2(10) PRIMARY KEY,
    Meaning VARCHAR2(100) NOT NULL
);

CREATE TABLE Clinical (
    ClaimID VARCHAR2(10) PRIMARY KEY,
    PatientID VARCHAR2(10) NOT NULL,
    Department VARCHAR2(50),
    ICDCode VARCHAR2(10),
    AdmissionDate DATE,
    CONSTRAINT fk_clin_patient FOREIGN KEY (PatientID) REFERENCES Patients(PatientID)
);

CREATE TABLE Billing (
    ClaimID VARCHAR2(10),
    InsuranceCompany VARCHAR2(100) NOT NULL,
    ClaimAmount NUMBER NOT NULL,
    ClaimStatus VARCHAR2(20) NOT NULL,
    DenialCode VARCHAR2(10),
    CONSTRAINT fk_bill_claim FOREIGN KEY (ClaimID) REFERENCES Clinical(ClaimID),
    CONSTRAINT fk_bill_ins FOREIGN KEY (InsuranceCompany) REFERENCES Insurance(InsuranceCompany),
    CONSTRAINT fk_bill_denial FOREIGN KEY (DenialCode) REFERENCES Denial_Reason_Lookup(DenialCode)
);

