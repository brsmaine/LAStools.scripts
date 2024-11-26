:: 
:: command lines for blog article:
::
:: http://rapidlasso.com/
::
:: Rev.1 7-6-22 nwp

::Echo off

SET /P INFILE=INPUT filename:
::IF NOT DEFINED %INFILE% SET INFILE=*.las

SET /P JOB_NO=Enter BRS job number:

set STARTTIME=%Time%

set PATH=%PATH%;C:\lastools\bin;C:\Legacy\OSGeo4W64\bin
set INFILEEXT=.las
set NUM_CORES=7

::lasindex -i %INFILE%%INFILEEXT% -cores %NUM_CORES%

lasinfo -i %INFILE%%INFILEEXT% -merged -cd -histo z 1 ^
	-histo user_data 1 -histo point_source 1 -v ^
	-o %JOB_NO%_info.txt -cores %NUM_CORES%