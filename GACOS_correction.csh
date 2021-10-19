#!/bin/csh -f
#	$Id$
#GACOS Correction
#Erik Rivas, Oct 18 2021
#

if ($#argv != 5) then
    echo ""
    echo "Usage: GACOS.csh list_interferograms full_path_to_GACOS_data full_path_topo reference_point incidence_angle"
    echo "Script needs to be run inside the intf_all folder" 
    echo "Performs gacos correction"
    echo ""
    echo "list_interferograms: list of folders inside the intf_all folder containing the unwrap phase grids"
    echo ""
    echo "full_path_to_GACOS_data"
    echo "Example: /home/erikr/gacos/"
    echo ""
    echo "full_path_topo"
    echo "Example: /home/erikr/project/topo/"
    echo ""
    echo "the topo folder needs to have: dem.grd, master.PRM, and the correspondant .LED file"
    echo ""
    echo "list_interferograms: list of folders with interferograms created"
    echo ""
    echo "Reference point in lon lat coordinates"
    echo ""
    echo "Indicence angle in degrees from SAT_look "
    echo ""
    echo "Outputs: unwrap phases corrected and added as additional products in each interferogram folder"
    exit 1
endif

set list = $1
set GACOS_dir = $2
set topo_dir = $3
set reference_point = $4
set incidence = $5

#PROJECT POINT FROM LON-LAT TO RADAR COORDINATES
rm $topo_dir"ref.llh" $topo_dir"out.ratll" $topo_dir"ref_point.ra"
gmt grdtrack $reference_point -G$topo_dir"dem.grd" >> $topo_dir"ref.llh"
ln -s $topo_dir*.LED .
SAT_llt2rat $topo_dir"master.PRM" 0 < $topo_dir"ref.llh" > $topo_dir"out.ratll"
rm *.LED
cat $topo_dir"out.ratll" |awk '{print $1, $2}' > $topo_dir"ref_point.ra"
set reference_point_ra = $topo_dir"ref_point.ra"
#----------------------------------------------#

#FOR LOOP OVER LIST OF INTERFEROGRAMS
foreach dir (`awk '{print $1}' $list`)
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
        	gacos_operation.csh $first_ztd $first_rsc $second_ztd $second_rsc $reference_point_ra $incidence
        	rm trans.dat

	else

		echo "GACOS files do not exist / Wrong directory"

	endif
	
	cd ..
end

echo "GACOS correction done"
