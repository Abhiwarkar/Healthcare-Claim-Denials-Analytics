-- =========================================================================
-- PROJECT: Hospital Revenue Cycle & Claim Denials Analytics
-- DESCRIPTION: Phase 3 - Advanced Business Analytics (CFO View)
-- =========================================================================

-- Q1: HIGH LEVEL KPI (Total Billed Revenue, Denied Revenue & Denial Rate)
PROMPT Running KPI Query 1 (Revenue Overview)...
SELECT 
    SUM(ClaimAmount) as Total_Billed_Revenue,
    SUM(CASE WHEN ClaimStatus = 'DENIED' THEN ClaimAmount ELSE 0 END) as Total_Denied_Revenue,
    ROUND((SUM(CASE WHEN ClaimStatus = 'DENIED' THEN ClaimAmount ELSE 0 END) / SUM(ClaimAmount)) * 100, 2) as Denial_Rate_Percentage
FROM Billing;


-- Q2: TOP DENIAL REASONS (Financial Loss Contribution Rank)
PROMPT Running KPI Query 2 (Top Denial Reasons)...
SELECT 
    d.Meaning as Denial_Reason,
    COUNT(b.ClaimID) as Total_Cases,
    SUM(b.ClaimAmount) as Leaked_Revenue,
    ROUND((SUM(b.ClaimAmount) / (SELECT SUM(ClaimAmount) FROM Billing WHERE ClaimStatus = 'DENIED')) * 100, 2) as Contribution_Percentage
FROM Billing b
JOIN Denial_Reason_Lookup d ON b.DenialCode = d.DenialCode
WHERE b.ClaimStatus = 'DENIED'
GROUP BY d.Meaning
ORDER BY Leaked_Revenue DESC;


-- Q3: RUNNING TOTALS (Department-wise Cumulative Loss Trend over Months)
PROMPT Running Analytics Query 3 (Running Totals using CTEs & Window Functions)...
WITH Monthly_Denials AS (
    SELECT 
        c.Department,
        TO_CHAR(c.AdmissionDate, 'YYYY-MM') as Admission_Month,
        SUM(b.ClaimAmount) as Monthly_Denied_Amount
    FROM Billing b
    JOIN Clinical c ON b.ClaimID = c.ClaimID
    WHERE b.ClaimStatus = 'DENIED'
    GROUP BY c.Department, TO_CHAR(c.AdmissionDate, 'YYYY-MM')
)
SELECT 
    Department,
    Admission_Month,
    Monthly_Denied_Amount,
    SUM(Monthly_Denied_Amount) OVER (
        PARTITION BY Department 
        ORDER BY Admission_Month
    ) as Cumulative_Denied_Amount
FROM Monthly_Denials
ORDER BY Department, Admission_Month;


-- Q4: PATIENT RISK PROFILING (Demographic Segmentations & Loss Correlation)
PROMPT Running Analytics Query 4 (Demographic Risk Profiles)...
SELECT 
    Age_Group,
    Gender,
    COUNT(PatientID) as Total_Patients,
    SUM(Total_Billed) as Total_Billed,
    SUM(Total_Denied) as Total_Denied,
    ROUND((SUM(Total_Denied) / SUM(Total_Billed)) * 100, 2) as Segment_Denial_Rate
FROM (
    SELECT 
        p.PatientID,
        p.Gender,
        CASE 
            WHEN p.Age < 18 THEN 'Under 18'
            WHEN p.Age BETWEEN 18 AND 40 THEN '18-40'
            WHEN p.Age BETWEEN 41 AND 60 THEN '41-60'
            ELSE 'Senior Citizen (60+)'
        END as Age_Group,
        SUM(b.ClaimAmount) as Total_Billed,
        SUM(CASE WHEN b.ClaimStatus = 'DENIED' THEN b.ClaimAmount ELSE 0 END) as Total_Denied
    FROM Patients p
    JOIN Clinical c ON p.PatientID = c.PatientID
    JOIN Billing b ON c.ClaimID = b.ClaimID
    GROUP BY p.PatientID, p.Gender, p.Age
)
GROUP BY Age_Group, Gender
ORDER BY Segment_Denial_Rate DESC;


-- Q5: INSURANCE PERFORMANCE BENCHMARKING (Dense Ranking of Insurance Portfolios)
PROMPT Running Analytics Query 5 (Insurance Benchmarking using DENSE_RANK)...
WITH Ins_Stats AS (
    SELECT 
        InsuranceCompany,
        COUNT(ClaimID) as Total_Claims,
        SUM(ClaimAmount) as Total_Billed,
        SUM(CASE WHEN ClaimStatus = 'DENIED' THEN ClaimAmount ELSE 0 END) as Denied_Amount,
        ROUND((SUM(CASE WHEN ClaimStatus = 'DENIED' THEN ClaimAmount ELSE 0 END) / SUM(ClaimAmount)) * 100, 2) as Denial_Rate
    FROM Billing
    GROUP BY InsuranceCompany
)
SELECT 
    InsuranceCompany,
    Total_Claims,
    Total_Billed,
    Denied_Amount,
    Denial_Rate,
    DENSE_RANK() OVER (ORDER BY Denied_Amount DESC) as Financial_Leakage_Rank
FROM Ins_Stats;