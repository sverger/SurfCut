/////////////////////////////////////////////////////////////////////////
////////====Cell segmentation for FibrilTool Batch====///////////////////
/////////////////////////////////////////////////////////////////////////
////////File author(s): Stéphane Verger /////////////////////////////////
/////////////////////////////////////////////////////////////////////////

//This macro allows a semi-automated segmentation and creation of ROI sets 
//for fibrilToolBatch (Creates input for FibrilTool_BatchSeg.ijm).
//As input you need 2D images of cell contours (..._cells.tif) and a 
//matching 2D image of the mircotubule arrays (..._MTs.tif). These can be 
//created using SurfCut macro (https://github.com/sverger/SurfCut).

///====================================================///
///=======Cell segmentation for FibrilTool Batch=======///
///====================================================///

dir = getDirectory("Choose a directory")

list = getFileList(dir);

for (j=0; j<list.length; j++){
	//print("entering loop 1");
	if(endsWith (list[j], "_cells.tif")){
	print("file_path",dir+list[j]);
	open( dir+File.separator+list[j] );
	file_name1=substring(list[j],0,indexOf(list[j],".tif"));
	file_name2=substring(list[j],0,indexOf(list[j],"_cells.tif"));
    //print (file_name);
    run("8-bit");
    run("Gaussian Blur...", "sigma=3");
    //waitForUser("If needed...", "Blur more? Close cell?...");
    run("Morphological Segmentation");
    wait(1000);
    call("inra.ijpb.plugins.MorphologicalSegmentation.setInputImageType", "border");
    call("inra.ijpb.plugins.MorphologicalSegmentation.segment", "tolerance=10", "calculateDams=true", "connectivity=6");
    waitForUser("Watershed segmentation", "Rerun the watershed segmentation with appropriate parameters if necessary.\nWhen you are satisfied, click OK here!");
    call("inra.ijpb.plugins.MorphologicalSegmentation.setDisplayFormat", "Watershed lines");
    call("inra.ijpb.plugins.MorphologicalSegmentation.createResultImage");
    selectWindow("Morphological Segmentation");
    close();
    selectWindow(list[j]);
    close();
    selectWindow(file_name1+"-watershed-lines.tif");
    run("Erode");
    run("Erode");
    run("Erode");
    run("Erode");
    //run("Invert");
    run("Analyze Particles...", "size=1000-100000 clear add");

    Dialog.create("Satisfied with ROI sizes");
    Dialog.addCheckbox("Satisfied?", true);
    Dialog.show();
    Satisfied = Dialog.getCheckbox();
    while (Satisfied==false){ 
    	run("Analyze Particles...");
    	Dialog.create("Satisfied with ROI sizes");
        Dialog.addCheckbox("Satisfied?", false);
        Dialog.show();
        Dialog.addCheckbox("Satisfied?", false);
        Satisfied = Dialog.getCheckbox();
    }

    open(dir+File.separator+file_name2+"_MTs.tif" );
    roiManager("Show All");
    waitForUser("Manage ROIs", "If needed, move or remove some ROIs to fit your needs\nSome ROIs may not be well aligned with the cells on the MTs images\nWhen you are satisfied, click OK here.");
	roiManager("Save", dir+File.separator+file_name2+"_cells_RoiSet.zip");
	selectWindow(file_name2+"_MTs.tif");
	close();
	selectWindow(file_name1+"-watershed-lines.tif");
	close();
	roiManager("Delete");
	}
}
selectWindow("ROI Manager");
run("Close");
print ("End of the Seg_forFTBatch macro"); 
