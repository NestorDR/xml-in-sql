## Description

README.md under construction

This example shows how to import into a MS SQL table from an XML document, and then query and process the imported data.

Before importing, I exported a small piece of data from SQL tables to an XML format, 

This example was created using as data platform **Microsfot SQL Server 2019**.

In each filed, find y replace my working path *D:\\Development\\repos\\xml-in-sql\\*, with the folder's path where you download the files of this example.

### Create database
Open, edit input params to adjust to file system context and execute T-SQL script: create_database.sql

### Create destination table
Open and execute T-SQL script: sp_ImportedXml_prepare_table.sql. 

### Import XML data
Open, edit input params to adjust to file system context and execute batch file: import_xml.cmd

### Tranform XML data
Open and execute T-SQL script: process_imported_xml.sql.