/*
    T-SQL script to process imported XML data
*/

USE health
GO

-- Stops the message that shows the count of the number of rows affected by a Transact-SQL statement. Increase performance.
SET NOCOUNT ON

-- Transform XML data, extracting rows in a common temporary table
SELECT  -- HealthService.XmlData
        
        -- Patient data
        HealthService.XmlData.value('(/Patient/@Id)[1]'              , 'int')         AS PatientId,
        HealthService.XmlData.value('(/Patient/@Type)[1]'            , 'varchar(50)') AS PatientType,
        HealthService.XmlData.value('(/Patient/@Gender)[1]'          , 'varchar(1)')  AS PatientGender,

        -- Health service data
        HealthServiceList.HealthService.value('(@Id)[1]'             , 'int')         AS ServiceId,
        HealthServiceList.HealthService.value('(@DateTime)[1]'       , 'datetime')    AS ServiceDateTimne,
        HealthServiceList.HealthService.value('(@ServiceTypeId)[1]'  , 'int')         AS ServiceTypeId,
        HealthServiceList.HealthService.value('(@ServiceTypeName)[1]', 'varchar(50)') AS ServiceTypeName,

        -- Providers data
        RoleList.Role.value('(@Id)[1]'                               , 'int')         AS RoleId,
        RoleList.Role.value('(@Name)[1]'                             , 'varchar(10)') AS RoleName,
        RoleList.Role.value('(@ProviderId)[1]'                       , 'int')         AS ProviderId,
        RoleList.Role.value('(@Amount)[1]'                           , 'money')       AS Cost

  INTO  #tmpHealthService       -- Extract rows to a temporary table
  
  FROM  (
            SELECT  CAST(REPLACE(CAST(VarcharData AS NVARCHAR(MAX)),'utf-8','utf-16') AS XML) AS XmlData
            FROM ImportedXml
        ) HealthService
          OUTER APPLY HealthService.XmlData.nodes('Patient/HealthServiceList/HealthService')                AS HealthServiceList(HealthService)
          OUTER APPLY HealthService.XmlData.nodes('Patient/HealthServiceList/HealthService/RoleList/Role')  AS RoleList(Role)

-- Show health services imported
-- SELECT TOP 10 * FROM #tmpHealthService ORDER BY ServiceId


-- Get indicators per patient
DECLARE @PatientsQuantity               int,
        @ServicesQuantity               int,
        @TotalCostWithPatient           money,
        @AverageServicesPerPatient      decimal(5,2),
        @AverageCostPerPatient          money

SELECT  @PatientsQuantity             = COUNT(ServicesByPatient.PatientId),
        @ServicesQuantity             = SUM(ServicesByPatient.ServicesQuantity),
        @TotalCostWithPatient         = SUM(ServicesByPatient.TotalCost),
        @AverageServicesPerPatient    = AVG(ServicesByPatient.ServicesQuantity),
        @AverageCostPerPatient        = AVG(ServicesByPatient.TotalCost)
  FROM  (
            SELECT  PatientId,
                    CONVERT(decimal(5,2), COUNT(DISTINCT ServiceId))    AS ServicesQuantity,
                    SUM(Cost)                                           AS TotalCost
              FROM  #tmpHealthService
             GROUP  BY  PatientId
        ) ServicesByPatient

-- Get indicators per Provider
DECLARE @ProvidersQuantity              int,
        @TotalCostWithProvider          money,
        @AverageBillingPerProvider         money

SELECT  @ProvidersQuantity            = COUNT(ServicesByProvider.ProviderId),
        @TotalCostWithProvider        = SUM(ServicesByProvider.TotalCost),
        @AverageBillingPerProvider    = AVG(ServicesByProvider.TotalCost)
  FROM  (
            SELECT  ProviderId,
                    SUM(Cost)                                           AS TotalCost
              FROM  #tmpHealthService
             GROUP  BY  ProviderId
        ) ServicesByProvider

-- Show indicators
SELECT  CONVERT(VARCHAR(50), 'A. Rows processed')   AS key_indicator,
        COUNT(*)                                    AS Count,
        CONVERT(money, NULL)                        AS Amount
  FROM  #tmpHealthService
UNION    
SELECT  CONVERT(VARCHAR(50), 'B. Patients'),
        @PatientsQuantity,
        NULL
UNION    
SELECT  'C. Health service totals',
        @ServicesQuantity,
        @TotalCostWithPatient
UNION    
SELECT  'D. Average health services per patient',
        @AverageServicesPerPatient,
        @AverageCostPerPatient
UNION
SELECT  'E. Providers',
        @ProvidersQuantity,
        NULL
UNION    
SELECT  'F. Total billed for health services',
        NULL,
        @TotalCostWithProvider
UNION    
SELECT  'G. Average billing per Provider',
        NULL,
        @AverageBillingPerProvider

-- Rank patients with a total cost greater than 20 times the average cost per patient
DECLARE @CostThreshold money
SET @CostThreshold = @AverageCostPerPatient * 20
SELECT  PatientId,
        PatientType,
        SUM(Cost) AS TotalCost
  FROM  #tmpHealthService
 GROUP  BY  PatientId,
            PatientType
HAVING  SUM(Cost) > @CostThreshold
 ORDER  BY  TotalCost DESC


-- Rank providers with billing greater than 10 times the average billing per provider
DECLARE @BilledThreshold money
SET @BilledThreshold = @AverageBillingPerProvider * 10
SELECT  ProviderId,
        SUM(Cost) AS TotalBilled
  FROM  #tmpHealthService
 GROUP  BY  ProviderId
HAVING  SUM(Cost) > @BilledThreshold
 ORDER  BY  TotalBilled DESC

-- Drop temporary table
DROP TABLE #tmpHealthService