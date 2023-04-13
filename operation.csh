#!/bin/csh -f

if ($#argv != 7) then
    echo ""
    echo "Usage: operation.csh master_ztd master_ztd.rsc slave_ztd slave_ztd.rsc reference_point incidence_angle dem_grid"
    echo "  Performs gacos correction over the phasefilt.grd files for Sentinel 1"
    echo ""
    echo "It works in each directory where the phase grids are located. This script works jointly with GACOS_correction.csh"
    echo ""
    echo "Reference point in radar coordinates (text file)"
    echo ""
    echo "Indicence angle in degrees from SAT_look (float/integer)"
    echo ""
    exit 1
 endif

#reference point/stable point in radar coordinates
set reference_point = $5

#incidence angle obtained with the "SAT_look" script in degrees
set incidence = $6

#wavelength for Sentinel 1 (m)
set wavelength = 0.0554658 
set pi = 3.141592653589793238462

#######FIRST ZTD to grid#########
set x_first_d1 = `cat $2|grep X_FIRST|awk '{print $2}'`
set y_first_d1 = `cat $2|grep Y_FIRST|awk '{print $2}'`
set width_d1   = `cat $2|grep WIDTH|awk '{print $2}'`
set length_d1  = `cat $2|grep FILE_LENGTH|awk '{print $2}'`
set x_step_d1  = `cat $2|grep X_STEP|awk '{print $2}'`
set y_step_d1  = `cat $2|grep X_STEP|awk '{print $2}'`
set date_ztd_d1 = `echo $1|awk -F/ '{print $NF}'|cut -c1-8`
gmt xyz2grd $1 -G"date1_ztd.grd" -RLT$x_first_d1/$y_first_d1/$width_d1/$length_d1 -I$x_step_d1/$y_step_d1 -ZTLf -di0 -r

#######SECOND ZTD to grid#########
set x_first_d2 = `cat $4|grep X_FIRST|awk '{print $2}'`
set y_first_d2 = `cat $4|grep Y_FIRST|awk '{print $2}'`
set width_d2   = `cat $4|grep WIDTH|awk '{print $2}'`
set length_d2  = `cat $4|grep FILE_LENGTH|awk '{print $2}'`
set x_step_d2  = `cat $4|grep X_STEP|awk '{print $2}'`
set y_step_d2  = `cat $4|grep X_STEP|awk '{print $2}'`
set date_ztd_d2 = `echo $3|awk -F/ '{print $NF}'|cut -c1-8`
gmt xyz2grd $3 -G"date2_ztd.grd" -RLT$x_first_d2/$y_first_d2/$width_d2/$length_d2 -I$x_step_d2/$y_step_d2 -ZTLf -di0 -r

#TIME DIFFERENCE
gmt grdmath date2_ztd.grd date1_ztd.grd SUB = zpddm.grd 

#Checking GACOS grids within the DEM boundaries
set xmin_dem = `gmt grdinfo -C $7|awk '{print $2}'`
set xmax_dem = `gmt grdinfo -C $7|awk '{print $3}'`
set ymin_dem = `gmt grdinfo -C $7|awk '{print $4}'`
set ymax_dem = `gmt grdinfo -C $7|awk '{print $5}'`

set xmin_gacos = `gmt grdinfo -C zpddm.grd|awk '{print $2}'`
set xmax_gacos = `gmt grdinfo -C zpddm.grd|awk '{print $3}'`
set ymin_gacos = `gmt grdinfo -C zpddm.grd|awk '{print $4}'`
set ymax_gacos = `gmt grdinfo -C zpddm.grd|awk '{print $5}'`

set check = `echo "$xmin_dem < $xmin_gacos && $ymin_dem < $ymin_gacos && $xmax_dem > $xmax_gacos && $ymax_dem > $ymax_gacos"| bc`

if ($check == 0) then
    echo "Seems like your DEM is not large enough. GACOS grids dimensions must be within the DEM."
    echo "DEM dimensions: xmin: $xmin_dem xmax: $xmax_dem ymin: $ymin_dem ymax: $ymax_dem"
    echo "GACOS dimensions: xmin: $xmin_gacos xmax: $xmax_gacos ymin: $ymin_gacos ymax: $ymax_gacos"
    exit 1
else
    echo "GACOS grid dimensions within DEM boundaries... continue..."
endif

#PROJECT TO RADAR COORDINATES
proj_ll2ra.csh trans.dat zpddm.grd zpddm_ra.grd

#RESAMPLE ZTD FILES WITH WRAPPED GRID PARAMETERS
#set xmin = `gmt grdinfo -C phasefilt.grd|awk '{print $2}'`
#set xmax = `gmt grdinfo -C phasefilt.grd|awk '{print $3}'`
#set ymin = `gmt grdinfo -C phasefilt.grd|awk '{print $4}'`
#set ymax = `gmt grdinfo -C phasefilt.grd|awk '{print $5}'`
#set xinc = `gmt grdinfo -C phasefilt.grd|awk '{print $8}'`
#set yinc = `gmt grdinfo -C phasefilt.grd|awk '{print $9}'`
#gmt grdsample zpddm_ra.grd -Gresample_zpddm.grd -R$xmin/$xmax/$ymin/$ymax -I$xinc/$yinc -r


#RESAMPLE ZTD FILES WITH UNWRAPPED GRID PARAMETERS (edition 13/4/2023)
set xmin = `gmt grdinfo -C unwrap.grd|awk '{print $2}'`
set xmax = `gmt grdinfo -C unwrap.grd|awk '{print $3}'`
set ymin = `gmt grdinfo -C unwrap.grd|awk '{print $4}'`
set ymax = `gmt grdinfo -C unwrap.grd|awk '{print $5}'`
set xinc = `gmt grdinfo -C unwrap.grd|awk '{print $8}'`
set yinc = `gmt grdinfo -C unwrap.grd|awk '{print $9}'`
gmt grdsample zpddm_ra.grd -Gresample_zpddm.grd -R$xmin/$xmax/$ymin/$ymax -I$xinc/$yinc -r


#REFERENCE POINT
set ref_value = `gmt grdtrack $reference_point -Gresample_zpddm.grd -Z`
#set ref_value_phase = `gmt grdtrack $reference_point -Gphasefilt.grd -Z`
#Taking reference value from unwrap.grd (Edition: 13/4/2023)
set ref_value_phase = `gmt grdtrack $reference_point -Gunwrap.grd -Z`
gmt grdmath resample_zpddm.grd $ref_value SUB = szpddm.grd 
#gmt grdmath phasefilt.grd $ref_value_phase SUB = phasefilt_ref.grd
#Referencing unwrap.grd (Edition: 13/4/2023)
gmt grdmath unwrap.grd $ref_value_phase SUB = unwrap_ref.grd
#Checking reference point values
if ($ref_value == "" || $ref_value_phase == "") then
    echo "Problems with the reference point. Is the reference point within the AOI?"
    exit 1
endif

#FROM METER TO PHASE
#gmt grdmath szpddm.grd 4 MUL $pi MUL $wavelength DIV = szpddm_phase.grd
#multiplying by -4 instead of 4 (edition: 13/4/2023)
gmt grdmath szpddm.grd -4 MUL $pi MUL $wavelength DIV = szpddm_phase.grd

#PROJECTION FROM ZENITH VIEW TO LOS
gmt grdmath szpddm_phase.grd $incidence COSD DIV = szpddm_phase_LOS.grd

#CORRECTION WITH GACOS DATA
#gmt grdmath phasefilt_ref.grd szpddm_phase_LOS.grd SUB = phasefilt_GACOS_corrected.grd
#Applying correction using unwrap_ref.grd instead. Edition 13/4/2023
gmt grdmath unwrap_ref.grd szpddm_phase_LOS.grd SUB = unwrapped_GACOS_corrected.grd

#DETRENDING
gmt grdtrend unwrapped_GACOS_corrected.grd -N3r -Dunwrapped_GACOS_corrected_detrended.grd

#checking existence of final outputs
if !(-f unwrapped_GACOS_corrected.grd || -f unwrapped_GACOS_corrected_detrended.grd) then
    echo "Seems like there was an issue correcting with GACOS $1 and $3"
    exit 1
endif

#clean up
#
rm date1_ztd.grd date2_ztd.grd
rm zpddm.grd zpddm_ra.grd resample_zpddm.grd
rm szpddm_phase.grd
rm unwrap_ref.grd
rm szpddm_phase_LOS.grd
echo "corrections done with $date_ztd_d1 and $date_ztd_d2 over unwrap.grd" 
