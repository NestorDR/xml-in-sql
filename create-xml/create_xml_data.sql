USE Unimed
GO

SET NOCOUNT ON

DECLARE @personId bigint,
        @patientId int

DECLARE patientCursor CURSOR FAST_FORWARD FOR 
 SELECT Person.Id_afiliado      AS personId,
        Patient.Id_afiliacion   AS patientId
   FROM Afiliados Person
        INNER JOIN Afiliaciones Patient ON Patient.Id_afiliado = Person.Id_afiliado
 WHERE  LEN(Patient.Id_tarjeta) > 4
        AND YEAR(Person.Nacimiento) < 2000
        AND EXISTS( SELECT  * 
                      FROM  Procedimientos 
                            INNER JOIN Procedimiento_Roles ON Procedimiento_Roles.Id_procedimiento = Procedimientos.Id_procedimiento
                     WHERE  Procedimientos.Fecha BETWEEN '2018-01-02' AND '2018-01-03' 
                            AND Procedimientos.Id_afiliacion = Patient.Id_afiliacion
                            AND Procedimientos.Id_afiliado = Person.Id_afiliado 
                            AND Procedimientos.Id_nom = 1               -- 1 is Medical services
                            AND Procedimientos.Id_estado = 4            -- 4 is Finished
                            AND Procedimiento_Roles.Id_estado = 7       -- 7 is Billed
                            AND Procedimiento_Roles.Id_rol IN (1,2,3,4,5,6,14)
                            AND Procedimiento_Roles.Id_prestador IS NOT NULL)

OPEN patientCursor
FETCH NEXT FROM patientCursor INTO @personId, @patientId

WHILE @@FETCH_STATUS = 0
  BEGIN
    SELECT  TOP 10
            Patient.Id_afiliacion                                       AS Id,
            CASE Person.Sexo
                WHEN 'M' THEN 'Male '  
                ELSE          'Female '
            END + CONVERT(VARCHAR, 2020 - YEAR(Person.Nacimiento)) 
                + ' years old'                                          AS Type,
            LEFT(Person.Sexo, 1)                                        AS Gender,
            (
                SELECT  HealthService.Id_procedimiento                  AS Id,
                        CONVERT(VARCHAR(20), HealthService.Fecha, 120)  AS DateTime,
                        HealthService.Id_codigo                         AS ServiceTypeId,
                        LEFT(Nomenclador.Nombre, 50)                    AS ServiceTypeName,
                        (
                            SELECT  Role.Id_rol                         AS Id,
                                    CASE Role.Id_rol
                                        WHEN  1 THEN 'Requester'
                                        WHEN  2 THEN 'Effector'
                                        WHEN  3 THEN 'Effector'
                                        WHEN  4 THEN 'Assistant'
                                        WHEN  3 THEN 'Anesthetist'
                                        WHEN  6 THEN 'Expenses'
                                        WHEN 14 THEN 'Expenses'
                                    END                                 AS Name,
                                    Role.Id_prestador                   AS ProviderId,
                                    Role.Facturado                      AS Amount
                              FROM  Procedimiento_Roles Role 
                             WHERE  Role.Id_procedimiento = HealthService.Id_procedimiento
                                    AND Role.Id_estado = 7              -- 7 is Billed
                                    AND Role.Id_rol IN (1,2,3,4,5,6,14)
                                    AND Role.Id_prestador IS NOT NULL
                               FOR  XML AUTO, TYPE
                        ) AS RoleList
                  FROM  Procedimientos HealthService
                        INNER JOIN Nomenclador ON Nomenclador.Id_nom = HealthService.Id_nom
                                              AND Nomenclador.Id_codigo = HealthService.Id_codigo
                 WHERE  HealthService.Fecha BETWEEN '2018-01-02' AND '2018-01-03'
                        AND HealthService.Id_afiliacion = Patient.Id_afiliacion
                        AND HealthService.Id_afiliado   = Person.Id_afiliado
                        AND HealthService.Id_nom = 1                    -- 1 is Medical services
                        AND HealthService.Id_estado = 4                 -- 4 is Finished
                 ORDER  BY HealthService.Id_procedimiento
                   FOR  XML AUTO, TYPE
            ) AS HealthServiceList
      FROM  Afiliados Person
            INNER JOIN Afiliaciones Patient ON Patient.Id_afiliado = Person.Id_afiliado
     WHERE  Person.Id_afiliado = @personId
            AND Patient.Id_afiliacion = @patientId
            AND EXISTS( SELECT  * FROM Procedimientos 
                         WHERE  Fecha BETWEEN '2018-01-02' AND '2018-01-03' 
                                AND Procedimientos.Id_afiliacion = Patient.Id_afiliacion
                                AND Procedimientos.Id_afiliado = Person.Id_afiliado 
                                AND Procedimientos.Id_nom = 1)
     ORDER  BY Patient.Id_tarjeta
       FOR  XML AUTO, TYPE

    FETCH NEXT FROM patientCursor INTO @personId, @patientId
  END

CLOSE patientCursor
DEALLOCATE patientCursor
GO