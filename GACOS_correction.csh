#!/bin/csh -f
#	$Id$
#GACOS Correction
#Erik Rivas, Oct 18 2021
#

if ($#argv != 5) then
    echo ""
    echo "Usage: GACOS_correction.csh list_interferograms full_path_to_GACOS_data full_path_topo reference_point incidence_angle"
    echo "Script needs to be run inside the intf_all folder" 
    echo "Performs gacos correction"
    echo ""
    echo "list_interferograms: list of folders inside the intf_all folder containing the unwrap.grd files and coherence grids"
    echo ""
    echo "full_path_to_GACOS_data"
    echo "Example: /home/erikr/gacos/"
    echo ""
    echo "full_path_topo"
    echo "Example: /home/erikr/project/topo/"
    echo ""
    echo "the topo folder needs to have: dem.grd, master.PRM, and the correspondant .LED file"
    echo ""
    echo "Reference point in lon lat coordinates (text file)"
    echo ""
    echo "Indicence angle in degrees obtained with SAT_look (float/integer)"
    echo ""
    echo "Outputs: unwrap.grd files corrected and added as additional products in each interferogram folder." 
    echo "These outputs should be used for the SBAS time series analysis"
    exit 1
endif

set list = $1
set GACOS_dir = $2
set topo_dir = $3
set reference_point = $4
set incidence = $5

#Checking inputs
if !(-e $list) then
    echo "$list seems not to exist"
    exit 1
endif
if !(-d $GACOS_dir) then
    echo "$GACOS_dir seems not to exist"
    exit 1
endif
if !(-d $topo_dir) then
    echo "$topo_dir seems not to exist"
    exit 1
endif
if !(-f $reference_point) then
    echo "Reference point file: $reference_point seems not to exist. Provide a text file with lon lat values"
    exit 1
endif


#PROJECT POINT FROM LON-LAT TO RADAR COORDINATES
set ref_llh = $topo_dir"ref.llh"
set out_ratll = $topo_dir"out.ratll"
set reference_point_ra = $topo_dir"ref_point.ra"
if (-f $ref_llh) then
    echo "Removing old $ref_llh"
    rm $ref_llh
endif
if (-f $out_ratll) then
    echo "Removing old $out_ratll"
    rm $out_ratll
endif
if (-f $reference_point_ra) then
    echo "Removing old $reference_point_ra"
    rm $reference_point_ra
endif

gmt grdtrack $reference_point -G$topo_dir"dem.grd" >> $ref_llh
ln -s $topo_dir*.LED .
SAT_llt2rat $topo_dir"master.PRM" 0 < $topo_dir"ref.llh" > $out_ratll
rm *.LED
cat $out_ratll |awk '{print $1, $2}' > $reference_point_ra
set dem_grd = $topo_dir"dem.grd"
#----------------------------------------------#

#FOR LOOP OVER LIST OF INTERFEROGRAMS
foreach dir (`awk '{print $1}' $list`)
        if !(-d $dir) then
            echo "$dir directory seems not to exist"
            exit 1
        endif
 
	cd $dir
	
	#Check if there are only two SLC files (not sure if this step is neccessary)
	if (`ls *.SLC|wc -l` != "2") then
	echo "the number of SLC files is inconsistent"
	endif
 
	#ls sorts content alphanumeric, therefore it is assume the first as the master on the list	
	set fst_date = `ls *.SLC|sed -n '1p'|awk '{print substr($1,4,8)}'`
	set scd_date = `ls *.SLC|sed -n '2p'|awk '{print substr($1,4,8)}'`

	#Save directory of current intf
	set intf_dir = `pwd`
	
	cd $GACOS_dir

	
	#Check if the GACOS files are in the folder
	if (-f $fst_date".ztd"  && -f $fst_date".ztd.rsc" && -f $scd_date".ztd" && -f $scd_date".ztd.rsc") then
		set first_ztd = $GACOS_dir$fst_date".ztd"
		set first_rsc = $GACOS_dir$fst_date".ztd.rsc"
		set second_ztd = $GACOS_dir$scd_date".ztd"
		set second_rsc = $GACOS_dir$scd_date".ztd.rsc"	
	
		#GACOS Correction
		cd $intf_dir
       	 	#Link trans.dat to each folder. Neccesary to project ztd grids to radar coordinates
        	ln -s $topo_dir"trans.dat"
            if !(-e unwrap.grd) then
                echo "unwrap.grd seems not to exists. Do unwrapping first"
                exit 1
            endif
        	operation.csh $first_ztd $first_rsc $second_ztd $second_rsc $reference_point_ra $incidence $dem_grd
        	rm trans.dat

	else

		echo "GACOS files do not exist / Wrong directory"
                exit 1

	endif
	
	cd ..
end

echo "GACOS correction done"
