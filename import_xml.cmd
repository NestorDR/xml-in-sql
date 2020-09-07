@echo off  

rem Set input params
set DBName=health
set DBFolder=D:\Development\repos\xml-in-sql\
set VerbosityLevel=1

echo Cleaning XML destination table...
sqlcmd.exe -S localhost -Q "EXECUTE %DBName%.dbo.sp_ImportedXml_prepare_table @VerbosityLevel=%VerbosityLevel%"
if not %errorlevel%==0 goto error
echo.

echo Importing XML data...
set Output=2
if %VerbosityLevel%==0 set Output=
dtexec.exe /file "%DBFolder%import_xml.dtsx" %Output%> nul
if not %errorlevel%==0 goto error
echo.

goto end

:error
echo.
echo Process interrupted. An error occurred (errorlevel %errorlevel%)

:end
timeout /t 30
