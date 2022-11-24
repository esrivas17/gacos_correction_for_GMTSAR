#!/bin/csh -f

if ($#argv != 6) then
    echo ""
    echo "Usage: operation.csh master_ztd master_ztd.rsc slave_ztd slave_ztd.rsc reference_point incidence_angle"
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

#PROJECT TO RADAR COORDINATES
proj_ll2ra.csh trans.dat zpddm.grd zpddm_ra.grd

#RESAMPLE ZTD FILES WITH UNWRAP GRID PARAMETERS
set xmin = `gmt grdinfo -C phasefilt.grd|awk '{print $2}'`
set xmax = `gmt grdinfo -C phasefilt.grd|awk '{print $3}'`
set ymin = `gmt grdinfo -C phasefilt.grd|awk '{print $4}'`
set ymax = `gmt grdinfo -C phasefilt.grd|awk '{print $5}'`
set xinc = `gmt grdinfo -C phasefilt.grd|awk '{print $8}'`
set yinc = `gmt grdinfo -C phasefilt.grd|awk '{print $9}'`
gmt grdsample zpddm_ra.grd -Gresample_zpddm.grd -R$xmin/$xmax/$ymin/$ymax -I$xinc/$yinc -r


#REFERENCE POINT
set ref_value = `gmt grdtrack $reference_point -Gresample_zpddm.grd -Z`
set ref_value_phase = `gmt grdtrack $reference_point -Gphasefilt.grd -Z`
gmt grdmath resample_zpddm.grd $ref_value SUB = szpddm.grd
gmt grdmath phasefilt.grd $ref_value_phase SUB = phasefilt_ref.grd

#FROM METER TO PHASE
gmt grdmath szpddm.grd 4 MUL $pi MUL $wavelength DIV = szpddm_phase.grd

#PROJECTION FROM ZENITH VIEW TO LOS
gmt grdmath szpddm_phase.grd $incidence COSD DIV = szpddm_phase_LOS.grd

#CORRECTION WITH GACOS DATA
#attention: Here the phasefilt.grd is corrected, therefore for the unwrap process this output or the detrended output
#should be used.
gmt grdmath phasefilt_ref.grd szpddm_phase_LOS.grd SUB = phasefilt_GACOS_corrected.grd

#DETRENDING
gmt grdtrend phasefilt_GACOS_corrected.grd -N3r -Dphasefilt_GACOS_corrected_detrended.grd

#clean up
#
rm date1_ztd.grd date2_ztd.grd
rm zpddm.grd zpddm_ra.grd resample_zpddm.grd
rm szpddm_phase.grd
rm phasefilt_ref.grd
rm szpddm_phase_LOS.grd
echo "corrections done with $date_ztd_d1 and $date_ztd_d2 over phasefilt.grd" 
