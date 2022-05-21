#!/bin/csh -f

if ($#argv != 7) then
    echo ""
    echo "Usage: single_GACOS_correction.csh master_ztd master_ztd.rsc slave_ztd slave_ztd.rsc intf_phase.grd reference point incidence angle" 
    echo	""
    echo "Performs gacos correction for Sentinel 1 for a single interferogram in grd format"
    echo ""
    echo "Output: wrapped phase"
    echo ""
    echo "Reference point file in lon/lat"
    echo ""
    echo ""
    echo "Indicence angle in degrees, in this case 0 "
    echo ""
    exit 1
 endif

#reference point/stable point in radar coordinates
set reference_point = $6

#incidence angle obtained with the "SAT_look" script in degrees
set incidence = $7

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

#######RESAMPLE DIFFERENCE WITH THE INTERFEROGRAM PARAMETERS####
set xmin = `gmt grdinfo -C $5|awk '{print $2}'`
set xmax = `gmt grdinfo -C $5|awk '{print $3}'`
set ymin = `gmt grdinfo -C $5|awk '{print $4}'`
set ymax = `gmt grdinfo -C $5|awk '{print $5}'`
set xinc = `gmt grdinfo -C $5|awk '{print $8}'`
set yinc = `gmt grdinfo -C $5|awk '{print $9}'`
#Resample
gmt grdsample zpddm.grd -Gresample_zpddm.grd -R$xmin/$xmax/$ymin/$ymax -I$xinc/$yinc -r

#FROM METERS TO PHASE
gmt grdmath resample_zpddm.grd $wavelength DIV 4 MUL $pi MUL = resample_zpddm_phs.grd

#REFERENCE POINT
set ref_value_zpddm = `gmt grdtrack $reference_point -Gresample_zpddm_phs.grd -Z`
set ref_value_phase = `gmt grdtrack $reference_point -G$5 -Z`
gmt grdmath resample_zpddm_phs.grd $ref_value_zpddm SUB = szpddm.grd
gmt grdmath $5 $ref_value_phase SUB = phase_ref.grd

#FROM METER TO PHASE
#gmt grdmath szpddm.grd 4 MUL $pi MUL $wavelength DIV = szpddm_phase.grd

#PROJECTION FROM ZENITH VIEW TO LOS
#gmt grdmath szpddm_phase.grd $incidence COSD DIV = szpddm_phase_LOS.grd
gmt grdmath szpddm.grd $incidence COSD DIV = szpddm_LOS.grd

#CORRECTION WITH GACOS DATA
#UNITS: Phase
gmt grdmath phase_ref.grd szpddm_LOS.grd SUB = phase_GACOS_corrected_phs.grd

#DETRENDING
#UNITS: phase
gmt grdtrend phase_GACOS_corrected_phs.grd -N3r -Dphase_GACOS_corrected_phs_detrended.grd

#clean up
#
rm date1_ztd.grd date2_ztd.grd
rm zpddm.grd
rm resample_zpddm.grd resample_zpddm_phs.grd
rm phase_ref.grd
rm szpddm.grd
rm szpddm_LOS.grd
echo "corrections done with GACOS files $1 and $3 over interferogram: $5" 
