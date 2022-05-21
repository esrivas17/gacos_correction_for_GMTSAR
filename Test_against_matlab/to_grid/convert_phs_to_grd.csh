#!/bin/csh -f

if ($#argv != 2) then
    echo ""
    echo "Usage: read_phs_file.csh phase_file header.rsc"
    echo ""
    echo "Convert binary files to .grd file"
    echo ""
    echo "binary file and header in .rsc is needed"
    exit 1
 endif

#######File to grid#########
set x_first_d1 = `cat $2|grep X_FIRST|awk '{print $2}'`
set y_first_d1 = `cat $2|grep Y_FIRST|awk '{print $2}'`
set width_d1   = `cat $2|grep WIDTH|awk '{print $2}'`
set length_d1  = `cat $2|grep FILE_LENGTH|awk '{print $2}'`
set x_step_d1  = `cat $2|grep X_STEP|awk '{print $2}'`
set y_step_d1  = `cat $2|grep X_STEP|awk '{print $2}'`
set name = `echo $1| awk -F/ '{print $NF}'`
gmt xyz2grd $1 -G"$name.grd" -RLT$x_first_d1/$y_first_d1/$width_d1/$length_d1 -I$x_step_d1/$y_step_d1 -ZTLf -di0 -r

echo "From $1, $name.grd has been produced"
