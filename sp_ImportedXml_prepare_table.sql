/*
    T-SQL script to create a stored procedure that create the destination table from the XML data
*/

USE health
GO

SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('dbo.sp_ImportedXml_prepare_table') AND type in ('P', 'PC'))
    -- Stored procedure already exists, delete it
    DROP PROCEDURE dbo.sp_ImportedXml_prepare_table
GO

CREATE PROCEDURE dbo.sp_ImportedXml_prepare_table
    @VerbosityLevel int = 0
AS
    IF OBJECT_ID('dbo.ImportedXml') IS NULL
      BEGIN
        -- There is no table to import XML data, then create it.
        CREATE TABLE [dbo].[ImportedXml]
        (
	        Id          int  IDENTITY(1,1)  NOT NULL,
	        VarcharData varchar(max)        NOT NULL,
	        CreatedAd   datetime            NOT NULL,
	        UpdatedAt   datetime            NULL,
            CONSTRAINT 
                [PK_ImportedXml] PRIMARY KEY CLUSTERED ( [Id] ASC ) 
                WITH (PAD_INDEX=OFF, STATISTICS_NORECOMPUTE=OFF, IGNORE_DUP_KEY=OFF, ALLOW_ROW_LOCKS=ON, ALLOW_PAGE_LOCKS=ON, OPTIMIZE_FOR_SEQUENTIAL_KEY=OFF) ON [PRIMARY]
        ) ON [PRIMARY]
        ALTER TABLE [dbo].[ImportedXml] ADD  CONSTRAINT [DF_ImportedXml_CreatedAd]  DEFAULT (getdate()) FOR [CreatedAd]
        
        IF @VerbosityLevel > 0 PRINT 'ImportedXml table: created'
      END
    ELSE
	  BEGIN
        -- There is a table to import XML data, only clean it.
        TRUNCATE TABLE ImportedXml

        IF @VerbosityLevel > 0 PRINT 'ImportedXml table: truncated'
      END
GO

-- Execution testing
EXECUTE health.dbo.sp_ImportedXml_prepare_table @VerbosityLevel = 1
