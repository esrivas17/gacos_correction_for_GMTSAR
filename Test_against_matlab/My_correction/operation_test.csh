#!/bin/csh -f

if ($#argv != 8) then
    echo ""
    echo "Usage: operation_test.csh master_ztd master_ztd.rsc slave_ztd slave_ztd.rsc intf_phase intf_phase.rsc reference point incidence angle" 
    echo	""
    echo "Performs gacos correction for Sentinel 1 for one interferogram using binary files and headers in rsc"
    echo ""
    echo ""
    echo ""
    echo "Reference point file in lon/lat"
    echo ""
    echo "Indicence angle in degrees, in this case 0 "
    echo ""
    exit 1
 endif

#reference point/stable point in radar coordinates
set reference_point = $7

#incidence angle obtained with the "SAT_look" script in degrees
set incidence = $8

#wavelength for Sentinel 1 (m)
set wavelength = 0.055165 
set pi = 3.141592653589793238462

#######FIRST ZTD to grid#########
set x_first_d1 = `cat $2|grep X_FIRST|awk '{print $2}'`
set y_first_d1 = `cat $2|grep Y_FIRST|awk '{print $2}'`
set width_d1   = `cat $2|grep WIDTH|awk '{print $2}'`
set length_d1  = `cat $2|grep FILE_LENGTH|awk '{print $2}'`
set x_step_d1  = `cat $2|grep X_STEP|awk '{print $2}'`
set y_step_d1  = `cat $2|grep X_STEP|awk '{print $2}'`
gmt xyz2grd $1 -G"date1_ztd.grd" -RLT$x_first_d1/$y_first_d1/$width_d1/$length_d1 -I$x_step_d1/$y_step_d1 -ZTLf -di0 -r


#######SECOND ZTD to grid#########
set x_first_d2 = `cat $4|grep X_FIRST|awk '{print $2}'`
set y_first_d2 = `cat $4|grep Y_FIRST|awk '{print $2}'`
set width_d2   = `cat $4|grep WIDTH|awk '{print $2}'`
set length_d2  = `cat $4|grep FILE_LENGTH|awk '{print $2}'`
set x_step_d2  = `cat $4|grep X_STEP|awk '{print $2}'`
set y_step_d2  = `cat $4|grep X_STEP|awk '{print $2}'`
gmt xyz2grd $3 -G"date2_ztd.grd" -RLT$x_first_d2/$y_first_d2/$width_d2/$length_d2 -I$x_step_d2/$y_step_d2 -ZTLf -di0 -r

#TIME DIFFERENCE
gmt grdmath date2_ztd.grd date1_ztd.grd SUB = zpddm.grd 

#PROJECT TO RADAR COORDINATES
#proj_ll2ra.csh trans.dat zpddm.grd zpddm_ra.grd

#PHASE TO GRID AND TAKING ITS PARAMETERS TO RESAMPLE THE "TIME DIFFERENCE" GRID
set xfirst_phs = `cat $6|grep X_FIRST|awk '{print $2}'`
set yfirst_phs = `cat $6|grep Y_FIRST|awk '{print $2}'`
set width_phs   = `cat $6|grep WIDTH|awk '{print $2}'`
set length_phs  = `cat $6|grep FILE_LENGTH|awk '{print $2}'`
set x_step_phs  = `cat $6|grep X_STEP|awk '{print $2}'`
set y_step_phs  = `cat $6|grep X_STEP|awk '{print $2}'`
gmt xyz2grd $5 -G"phase_orig.grd" -RLT$xfirst_phs/$yfirst_phs/$width_phs/$length_phs -I$x_step_phs/$y_step_phs -ZTLf -di0 -r

#RESAMPLE DIFFERENCE
gmt grdsample zpddm.grd -Gresample_zpddm.grd -RLT$xfirst_phs/$yfirst_phs/$width_phs/$length_phs -I$x_step_phs/$y_step_phs -r

#FROM INTERFEROMETRIC PHASE TO METERS
gmt grdmath phase_orig.grd $wavelength MUL 4 DIV $pi DIV = phase_meters.grd 

#REFERENCE POINT
set ref_value_zpddm = `gmt grdtrack $reference_point -Gresample_zpddm.grd -Z`
set ref_value_phase = `gmt grdtrack $reference_point -Gphase_meters.grd -Z`
gmt grdmath resample_zpddm.grd $ref_value_zpddm SUB = szpddm.grd
gmt grdmath phase_meters.grd $ref_value_phase SUB = phase_meters_ref.grd

#FROM METER TO PHASE
#gmt grdmath szpddm.grd 4 MUL $pi MUL $wavelength DIV = szpddm_phase.grd

#PROJECTION FROM ZENITH VIEW TO LOS
#gmt grdmath szpddm_phase.grd $incidence COSD DIV = szpddm_phase_LOS.grd
gmt grdmath szpddm.grd $incidence COSD DIV = szpddm_LOS.grd

#FROM METERS TO CENTIMETERS
gmt grdmath szpddm_LOS.grd 100 MUL = szpddm_LOS_cm.grd
gmt grdmath phase_meters_ref.grd 100 MUL = phase_cm_ref.grd

#CORRECTION WITH GACOS DATA
#UNITS: Meters
#gmt grdmath phase_meters_ref.grd szpddm_LOS.grd SUB = phase_GACOS_corrected_m.grd
#UNITS: Centimeters // Differences in the order of 1e-2 cm with respect to matlab outputs 
gmt grdmath phase_cm_ref.grd szpddm_LOS_cm.grd SUB = phase_GACOS_corrected_cm.grd

#DETRENDING
#UNITS: m
#gmt grdtrend phase_GACOS_corrected_m.grd -N3r -Dphase_GACOS_corrected_m_detrended.grd
#UNITS: cm // Differences in the order of 2e-1 cm with respect to matlab outputs
gmt grdtrend phase_GACOS_corrected_cm.grd -N3r -Dphase_GACOS_corrected_cm_detrended.grd


#clean up
#
rm date1_ztd.grd date2_ztd.grd
rm zpddm.grd phase_orig.grd
rm phase_meters.grd resample_zpddm.grd
rm phase_meters_ref.grd szpddm.grd
rm szpddm_LOS.grd
rm szpddm_LOS_cm.grd phase_cm_ref.grd
echo "corrections done with GACOS files $1 and $3 over interferogram: $5" 
