@echo off
set STARTTIME=%1 
set ENDTIME=%TIME%

ECHO STARTTIME=%STARTTIME%
ECHO ENDTIME=%ENDTIME%

set STARTHOUR=%STARTTIME:~0,2%
set STARTMINUTE=%STARTTIME:~3,2%
set STARTSECOND=%STARTTIME:~6,2%

set ENDHOUR=%ENDTIME:~0,2%
set ENDMINUTE=%ENDTIME:~3,2%
set ENDSECOND=%ENDTIME:~6,2%

if %STARTHOUR:~-1%==: SET STARTHOUR=%STARTTIME:~0,1%
if %STARTMINUTE:~-1%==: SET STARTMINUTE=%STARTTIME:~2,2%
if %STARTSECOND:~-1%==. SET STARTSECOND=%STARTTIME:~5,2%

if %ENDHOUR:~-1%==: SET ENDHOUR=%ENDTIME:~0,1%
if %ENDMINUTE:~-1%==: SET ENDMINUTE=%ENDTIME:~2,2%
if %ENDSECOND:~-1%==. SET ENDSECOND=%ENDTIME:~5,2%

set /A STARTTIME=(%STARTHOUR%-100)*-360000 + (%STARTMINUTE%-100)*-6000 + (%STARTSECOND%-100)*-100 + (%STARTTIME:~9,2%-100)*-1

set /A ENDTIME=(%ENDHOUR%-100)*-360000 + (%ENDMINUTE%-100)*-6000 + (%ENDSECOND%-100)*-100 + (%ENDTIME:~9,2%-100)*-1

ECHO STARTTIME=%STARTTIME%
ECHO ENDTIME=%ENDTIME%

if %ENDTIME% LSS %STARTTIME% set /A DURATION=%STARTTIME% - %ENDTIME%

set /A DURATIONH=%DURATION% / 360000
set /A DURATIONM=(%DURATION% - %DURATIONH%*360000) / 6000
set /A DURATIONS=(%DURATION% - %DURATIONH%*360000 - %DURATIONM%*6000) / 100
set /A DURATIONHS=(%DURATION% - %DURATIONH%*360000 - %DURATIONM%*6000 - %DURATIONS%*100)

set /A DURATION=%ENDTIME% - %STARTTIME%

if %DURATIONH% LSS 10 set DURATIONH=0%DURATIONH%
if %DURATIONM% LSS 10 set DURATIONM=0%DURATIONM%
if %DURATIONS% LSS 10 set DURATIONS=0%DURATIONS%
if %DURATIONHS% LSS 10 set DURATIONHS=0%DURATIONHS%

echo[
echo Runtime: %DURATIONH%:%DURATIONM%:%DURATIONS%.%DURATIONHS%
echo[
