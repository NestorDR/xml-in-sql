/*
    T-SQL script to create database
*/

USE master
GO

-- Input params
DECLARE @DropPreviousDBSameName bit,
        @DBName varchar(10),
        @DBFolder varchar(200),
        @SQLScript varchar(MAX),
        @VerbosityLevel int

SET @DropPreviousDBSameName = 1                         -- Flag to drop previous database with same name. Set to 0 not to delete.
SET @DBName   = 'health'                                -- Database name
SET @DBFolder = 'D:\Development\repos\xml-in-sql\'      -- Database folder
SET @VerbosityLevel = 0                                 -- It controls verbosity level, the higher, the more messages.

IF @VerbosityLevel  < 2
    -- Stops the message that shows the count of the number of rows affected by a Transact-SQL statement. Increase performance.
    SET NOCOUNT ON
ELSE
    -- Allows the message that shows the count of the number of rows affected by a Transact-SQL statement. 
    SET NOCOUNT OFF

IF @DropPreviousDBSameName = 1 
    -- Drop required. Check if database with same name exists on SQL Server
    IF EXISTS(SELECT * FROM sys.databases WHERE name = @dbName)
      BEGIN 
        -- Drop required AND database with same name exists on SQL Server
        
        -- Show database with same name to be dropped
        SELECT 'To be dropped' AS obs, name, database_id, create_date FROM sys.databases WHERE name = @dbName

        -- Drop dababase
        SET @SQLScript = '
        DROP DATABASE {DBName}'
        SET @SQLScript = REPLACE(@SQLScript, '{DBName}', @DBName)
        EXECUTE (@SQLScript)
        IF @VerbosityLevel > 0 PRINT CHAR(13) + 'Drop' + @SQLScript
        PRINT UPPER(@DBName) + ' database dropped.'
      END

BEGIN TRY 

    -- Creata database

    -- CONTAINMENT = NONE: A contained database is a database that is isolated from other databases and from the instance of SQL Server that hosts the database.
    -- Visit: https://docs.microsoft.com/en-us/sql/relational-databases/databases/contained-databases?view=sql-server-ver15
    SET @SQLScript = '
        CREATE DATABASE {DBName} CONTAINMENT = NONE
            ON PRIMARY ( NAME = ''{DBName}'', FILENAME = ''{DBFolder}{DBName}.mdf'' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
           LOG 
            ON ( NAME = ''{DBName}_log'', FILENAME = ''{DBFolder}{DBName}_log.ldf'' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
           WITH CATALOG_COLLATION = DATABASE_DEFAULT'
    SET @SQLScript = REPLACE(@SQLScript, '{DBName}', @DBName)
    SET @SQLScript = REPLACE(@SQLScript, '{DBFolder}', @DBFolder)
    EXECUTE (@SQLScript)
    IF @VerbosityLevel > 0 PRINT  CHAR(13) + 'Create' + @SQLScript
    PRINT UPPER(@DBName) + ' database created.'

    -- Show database just created
    SELECT 'Just created' AS obs, name, database_id, create_date FROM sys.databases WHERE name = @dbName

    -- Sets
    SET @SQLScript = '
        EXEC {DBName}.[dbo].[sp_fulltext_database] @action = ''enable'';
        ALTER DATABASE {DBName} SET ANSI_NULL_DEFAULT OFF;
        ALTER DATABASE {DBName} SET ANSI_NULLS OFF;
        ALTER DATABASE {DBName} SET ANSI_PADDING OFF;
        ALTER DATABASE {DBName} SET ANSI_WARNINGS OFF; 
        ALTER DATABASE {DBName} SET ARITHABORT OFF;
        ALTER DATABASE {DBName} SET AUTO_CLOSE OFF;
        ALTER DATABASE {DBName} SET AUTO_SHRINK OFF;
        ALTER DATABASE {DBName} SET AUTO_UPDATE_STATISTICS ON;
        ALTER DATABASE {DBName} SET CURSOR_CLOSE_ON_COMMIT OFF;
        ALTER DATABASE {DBName} SET CURSOR_DEFAULT  GLOBAL;
        ALTER DATABASE {DBName} SET CONCAT_NULL_YIELDS_NULL OFF;
        ALTER DATABASE {DBName} SET NUMERIC_ROUNDABORT OFF;
        ALTER DATABASE {DBName} SET QUOTED_IDENTIFIER OFF;
        ALTER DATABASE {DBName} SET RECURSIVE_TRIGGERS OFF;
        ALTER DATABASE {DBName} SET  DISABLE_BROKER;
        ALTER DATABASE {DBName} SET AUTO_UPDATE_STATISTICS_ASYNC OFF;
        ALTER DATABASE {DBName} SET DATE_CORRELATION_OPTIMIZATION OFF;
        ALTER DATABASE {DBName} SET TRUSTWORTHY OFF;
        ALTER DATABASE {DBName} SET ALLOW_SNAPSHOT_ISOLATION OFF;
        ALTER DATABASE {DBName} SET PARAMETERIZATION SIMPLE;
        ALTER DATABASE {DBName} SET READ_COMMITTED_SNAPSHOT OFF;
        ALTER DATABASE {DBName} SET HONOR_BROKER_PRIORITY OFF;
        ALTER DATABASE {DBName} SET RECOVERY FULL;
        ALTER DATABASE {DBName} SET  MULTI_USER;
        ALTER DATABASE {DBName} SET PAGE_VERIFY CHECKSUM;
        ALTER DATABASE {DBName} SET DB_CHAINING OFF;
        ALTER DATABASE {DBName} SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF );
        ALTER DATABASE {DBName} SET TARGET_RECOVERY_TIME = 60 SECONDS;
        ALTER DATABASE {DBName} SET DELAYED_DURABILITY = DISABLED;
        ALTER DATABASE {DBName} SET QUERY_STORE = OFF;
        ALTER DATABASE {DBName} SET  READ_WRITE;'
    SET @SQLScript = REPLACE(@SQLScript, '{DBName}', @DBName)
    EXECUTE (@SQLScript)
    IF @VerbosityLevel > 0 PRINT CHAR(13) + 'Configure' + @SQLScript
    PRINT UPPER(@DBName) + ' database configured.'

END TRY  
BEGIN CATCH

    DECLARE @ErrorMessage varchar(max)
    DECLARE @ErrorSeverity int
    DECLARE @ErrorState int

    SELECT  @ErrorMessage = ERROR_MESSAGE(),  
            @ErrorSeverity = ERROR_SEVERITY(),  
            @ErrorState = ERROR_STATE()  

    -- Use RAISERROR inside the CATCH block to return error information about the original error that caused execution to jump to the CATCH block.  
    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
END CATCH 

