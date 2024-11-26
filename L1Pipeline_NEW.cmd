@echo off

::variables
setlocal EnableDelayedExpansion
SET PATH=%PATH%;C:\lastools\bin;C:\Legacy\OSGeo4W64\bin
SET INFILE=cloud_merged
SET INFILEEXT=.las
SET STARTTIME=%time%
SET TILESIZ=40
SET NUM_CORES=36
SET Min_Elev=-5
SET Max_Elev=500
SET Rugged_Val=0.45
SET Ground_Offset_Val=2.0
SET Planar_Val=0.1
SET Classif_Step_Size=1.25
SET VertUnits=-elevation_feet
SET GROUNDStepBelow=-archeology
SET GROUNDSubStepBelow=-hyper_fine

SET ELEVCUTOFF=10
SET VERTBUFFER=2.5

CALL vbs %ELEVCUTOFF%+%VERTBUFFER%
SET dropZabove=%val%
CALL vbs %ELEVCUTOFF%-%VERTBUFFER%
SET dropZbelow=%val%

:: dropZbetween is NOT CURRENTLY USED
::SET dropZbetween=7.5 12.5

::prompts
echo.
SET /P JOB_NO=Enter BRS job number:
echo.
SET /P INFILE2=Enter lowercase filename (no extension) or leave blank for cloud_merged: 
echo.
if "%INFILE2%"=="" (goto noFileUpdate) else ( goto fileUpdate ) 

:fileUpdate
SET INFILE=!%INFILE2!
goto noFileUpdate

:noFileUpdate

echo %INFILE%%INFILEEXT% will be processed.  Choose options: 
echo.
echo GROUND Step Options: -archeology, -wilderness, -nature, -town, -city, -metro
SET /P GROUNDStep=Enter GroundStep (Above): 
echo.
echo GROUND SubStep Options: -extra_coarse ,-coarse, -fine, -extra_fine, -ultra_fine, -hyper_fine
SET /P GROUNDSubStep=Enter GroundSubStep (Above): 
echo.

::initial setup
del *.vrt, *.lax, *.kml, *.tfw, *.laz, *above*.las, *below*.las, *above*.tif, *below*.tif, %JOB_NO%_vegetation.tif, %JOB_NO%_buildings.tif, veg.tif, bldg.tif, DTM*.tif
for /d %%G in (".\1_*", ".\2_*", ".\3_*", ".\4_*", ".\5_*", ".\6_*") do rd /s/q "%%~G"

mkdir 1_quality, 2_tiles_raw, 2_tiles_sorted, 3_tiles_thinned_p05_step01, ^
    3_tiles_thinned_p05_step02, 3_tiles_thinned_p05_step04, ^
    3_tiles_thinned_p05_step08, 3_tiles_thinned_p05_step16, ^
    4_tiles_ground_low_above, 4_tiles_ground_low_below, ^
    4_tiles_ground_thick_above, 4_tiles_ground_thick_below, 5_merged, ^
    5_tiles_gridded_mean_ground_above, 5_tiles_gridded_mean_ground_below, ^
    6_tiles_ground_thick_classified_above, 6_tiles_ground_thick_classified_below

lasindex -i %INFILE%%INFILEEXT%
lasinfo -i %INFILE%%INFILEEXT% -merged -cd -histo z 1 -histo user_data 1 -histo point_source 1 -v -o 1_quality\%JOB_NO%_info.txt

lastile -i %INFILE%%INFILEEXT% -set_classification 0 -drop_z_below %Min_Elev% -drop_z_above %Max_Elev% -tile_size %TILESIZ% -cores %NUM_CORES% -buffer 20 -flag_as_withheld -odir 2_tiles_raw -o BRS.laz
lassort -i 2_tiles_raw\*.laz -odir 2_tiles_sorted -olaz -cores %NUM_CORES%

lasthin -i 2_tiles_sorted\*.laz -step 1 -percentile 5 20 -classify_as 8 -odir 3_tiles_thinned_p05_step01 -olaz -cores %NUM_CORES%
lasthin -i 3_tiles_thinned_p05_step01\*.laz -step  2 -percentile 5 20 -classify_as 8 -odir 3_tiles_thinned_p05_step02 -olaz -cores %NUM_CORES%
lasthin -i 3_tiles_thinned_p05_step02\*.laz -step  4 -percentile 5 20 -classify_as 8 -odir 3_tiles_thinned_p05_step04 -olaz -cores %NUM_CORES%
lasthin -i 3_tiles_thinned_p05_step04\*.laz -step  8 -percentile 5 20 -classify_as 8 -odir 3_tiles_thinned_p05_step08 -olaz -cores %NUM_CORES%
lasthin -i 3_tiles_thinned_p05_step08\*.laz -step 16 -percentile 5 20 -classify_as 8 -odir 3_tiles_thinned_p05_step16 -olaz -cores %NUM_CORES%

::split begins
lasground_new -i 3_tiles_thinned_p05_step16\*.laz -ignore_class 0 %GROUNDStep% %GROUNDSubStep% -drop_z_below %dropZbelow% -compute_height -odir 4_tiles_ground_low_above -olaz -target_elevation_feet -cores %NUM_CORES% 
lasground_new -i 3_tiles_thinned_p05_step16\*.laz -ignore_class 0 %GROUNDStepBelow% %GROUNDSubStepBelow% -drop_z_above %dropZabove% -compute_height -odir 4_tiles_ground_low_below -olaz -target_elevation_feet -cores %NUM_CORES%

lasheight -i 4_tiles_ground_low_above\*.laz -classify_between -0.05 0.5 2 -classify_between 1.5 2.0 8 -do_not_store_in_user_data -odir 4_tiles_ground_thick_above -olaz -cores %NUM_CORES%
lasheight -i 4_tiles_ground_low_below\*.laz -classify_between -0.05 0.5 2 -classify_between 1.5 2.0 8 -do_not_store_in_user_data -odir 4_tiles_ground_thick_below -olaz -cores %NUM_CORES%
    
lasclassify -i 4_tiles_ground_thick_above\*.laz %VertUnits% -step %Classif_Step_Size% -rugged %Rugged_Val% -ground_offset %Ground_Offset_Val% -planar %Planar_val% -keep_overhang -wide_gutters -small_buildings -odir 6_tiles_ground_thick_classified_above -olaz -cores %NUM_CORES%
lasclassify -i 4_tiles_ground_thick_below\*.laz %VertUnits% -step %Classif_Step_Size% -rugged %Rugged_Val% -ground_offset %Ground_Offset_Val% -planar %Planar_val% -keep_overhang -wide_gutters -small_buildings -odir 6_tiles_ground_thick_classified_below -olaz -cores %NUM_CORES%    

lastile -i 6_tiles_ground_thick_classified_above\*.laz -remove_buffer -o %JOB_NO%_Classified_SPC_UsFT_NAVD88_above%GROUNDStep%%GROUNDSubStep%.las -cores %NUM_CORES%
lastile -i 6_tiles_ground_thick_classified_below\*.laz -remove_buffer -o %JOB_NO%_Classified_SPC_UsFT_NAVD88_below%GROUNDStepBelow%%GROUNDSubStepBelow%.las -cores %NUM_CORES%

lasmerge -i 6_tiles_ground_thick_classified_above\*.laz -drop_z_below %ELEVCUTOFF% -o %JOB_NO%_Classified_SPC_UsFT_NAVD88_above%GROUNDStep%%GROUNDSubStep%.las
lasmerge -i 6_tiles_ground_thick_classified_below\*.laz -drop_z_above %ELEVCUTOFF% -o %JOB_NO%_Classified_SPC_UsFT_NAVD88_below%GROUNDStepBelow%%GROUNDSubStepBelow%.las
lasmerge -i %JOB_NO%_Classified_SPC_UsFT_NAVD88_above%GROUNDStep%%GROUNDSubStep%.las %JOB_NO%_Classified_SPC_UsFT_NAVD88_below%GROUNDStepBelow%%GROUNDSubStepBelow%.las -o %JOB_NO%_Classified_SPC_UsFT_NAVD88.las

::merged .las now used
lasgrid -i %JOB_NO%_Classified_SPC_UsFT_NAVD88.las -keep_class 2 -step 0.5 -average -use_bb -odir 5_merged -olaz
lasmerge64 -i 5_merged\*.laz -o %JOB_NO%_merged -olaz
blast2dem -i %JOB_NO%_merged.laz -step 0.5 -kill 7 -light 1 1 1 -hillshade -o %JOB_NO%_BRS_DTM_Hillshade_Classified.tif
blast2dem -i %JOB_NO%_merged.laz -step 0.5 -kill 50 -light 1 1 1 -o %JOB_NO%_BRS_DTM_Classified.tif  

lasgrid64 -i %JOB_NO%_Classified_SPC_UsFT_NAVD88.las -merged -keep_class 5 -step 1.0 -subcircle 0.5 -occupancy -fill 1 -false -use_bb -o %JOB_NO%_vegetation.tif
lasgrid64 -i %JOB_NO%_Classified_SPC_UsFT_NAVD88.las -merged -keep_class 6 -step 1.0 -subcircle 0.5 -occupancy -fill 1 -gray -use_bb -o %JOB_NO%_buildings.tif

gdalbuildvrt -srcnodata "255 255 255" virtualimage_veg.vrt %JOB_NO%_vegetation.tif
gdalbuildvrt -srcnodata "255 255 255" virtualimage_bldg.vrt %JOB_NO%_buildings.tif

gdal_translate virtualimage_veg.vrt veg.tif
gdal_translate virtualimage_bldg.vrt bldg.tif

gdalwarp -dstalpha veg.tif bldg.tif %JOB_NO%_Classified_Vegetation_Buildings.tif

::endMain

::final cleanup - result should be a single merged .las and individual merged .tifs
goto eof

:eof
CALL "CompTime.bat" %STARTTIME%
pause
del *.vrt, *.lax, *.kml, *.tfw, *.laz, *above*.las, *below*.las, *above*.tif, *below*.tif, %JOB_NO%_vegetation.tif, %JOB_NO%_buildings.tif, veg.tif, bldg.tif, DTM*.tif
for /d %%G in (".\1_*", ".\2_*", ".\3_*", ".\4_*", ".\5_*", ".\6_*") do rd /s/q "%%~G"
@echo.
@echo FINISHED.
@echo.
pause
