/////////////////////////////////////////////////////////////////////////
////////=======SurfCut=======////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
////////Copyright 2019 INRA - CNRS///////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
////////File author(s): Stéphane Verger <stephane.verger@slu.se>/////////
/////////////////////////////////////////////////////////////////////////
////////Distributed under the Cecill-C License///////////////////////////
////////See accompanying file LICENSE.txt or copy at/////////////////////
////////http://www.cecill.info/licences/Licence_CeCILL-C_V1-en.html//////
/////////////////////////////////////////////////////////////////////////

///=================================///
///==========SurfCut Macro==========///
///=================================///

do{
///Ask the user to choose between Calibration and Batch mode
Dialog.create("SurfCut");
Dialog.addMessage("Choose between Calibrate and Batch mode");
Dialog.addChoice("Mode", newArray("Calibrate", "Batch"));
Dialog.show();
Mode = Dialog.getChoice();

if (Mode=="Calibrate"){
	print("=== SurfCut Calibrate mode ===");

///==========Calibrate Mode==========///


///Open a stack for calibration
open();
imgDir = File.directory;
print(imgDir);
imgName = getTitle();
print(imgName);
imgPath = imgDir+imgName;
print(imgPath);

File.makeDirectory(imgDir+File.separator+"SurfCutCalibrate");

TRad = 3;
TThld = 20;
TTop = 6;
TBot = 8;
//TWth = 0;
//THgt = 0;
//TDpt = 0;

Satisfied = false;
while (Satisfied==false){ 
	///Ask the user about Gaussian Blur and Threshold values to test
	Dialog.create("SurfCut Parameters");
	Dialog.addMessage("1) Choose Gaussian blur radius");
	Dialog.addNumber("Radius\t", TRad);
	Dialog.addMessage("2) Choose the intensity threshold\nfor surface detection\n(Between 0 and 255)");
	Dialog.addNumber("Threshold\t", TThld);
	Dialog.show();
	  
	Rad = Dialog.getNumber();
	Thld = Dialog.getNumber();

	TRad = Rad;
	TThld = Thld;
	
	///Image pre-processing
	setBatchMode(true);
	run("8-bit");
	run("Gaussian Blur...", "sigma=&Rad stack");
	
	///Threshold
	setThreshold(0, Thld);
	run("Convert to Mask", "method=Default background=Light");
	run("Invert", "stack");
	
	//Edge detect
	getDimensions(w, h, channels, slices, frames);
	print (slices);
	for (img=0; img<slices; img++){
		print("Edge detect projection" + img + "/" + slices);
		slice = img+1;
		selectWindow(imgName);
		run("Z Project...", "stop=&slice projection=[Max Intensity]");
	}
	print("Concatenate images");
	run("Images to Stack", "name=Stack-0 title=[]");
	run("Duplicate...", "title=Stack-invert duplicate");
	run("Invert", "stack");
	wait(1000);
	selectWindow(imgName);
	close();
	open(imgPath);

	setBatchMode("exit and display");

	getVoxelSize(width, height, depth, unit);
	print("Detected voxel size:\nWidth --> " + width + "\nHeight --> " + height + "\nDepth --> " + depth + "\nUnit --> " + unit);

	IndWth1 = width*1000;
	IndWth2 = round(IndWth1);
	RdWth = IndWth2/1000;
	IndHgt1 = height*1000;
	IndHgt2 = round(IndHgt1);
	RdHgt = IndHgt2/1000;
	IndDpt1 = depth*1000;
	IndDpt2 = round(IndDpt1);
	RdDpt = IndDpt2/1000;

	run("3D Viewer");
	call("ij3d.ImageJ3DViewer.setCoordinateSystem", "false");
	call("ij3d.ImageJ3DViewer.add", "Stack-invert", "None", "Stack-invert", "0", "true", "true", "true", "2", "0");

	///Satisfied?
	waitForUser("Check Edge Detect", "Check the quality of Edge Detection\nThen click OK.");
	Dialog.create("Satisfied with Edge Detection?");
	Dialog.addMessage("If you are not satisfied, do not tick the box and just click Ok.\nThis will take you back to the previous step for the selection of the\nGaussian Blur and Threshold values.\nOtherwise tick the box and click OK to proceed to the next step.");
	Dialog.addCheckbox("Satisfied?", false);
	Dialog.show();
	Satisfied = Dialog.getCheckbox();
	wait(1000);
	call("ij3d.ImageJ3DViewer.close");
	close("Stack-invert");
	if (Satisfied){
		close(imgName);
	} else {
		close("Stack-0");
}
}

Satisfied = false;
while (Satisfied==false){ 
	///Ask the user about cut depth parameters
	Dialog.create("SurfCut Parameters");
	Dialog.addMessage("3) Choose the depths between which\nthe stack will be cut relative to the\ndetected surface in micrometers");
	Dialog.addNumber("Top\t", TTop);
	Dialog.addNumber("Bottom\t", TBot);
	Dialog.addMessage("4) Voxel properties in micrometers\nare automatically retrieved from the\nimage metadata.\n!!!\nIf no value was available they are all\nset to 1.\nUse rounded values (for example\n0.500 instead of 0.501...) and with\na maximum 3 decimals");
	Dialog.addNumber("Width\t", RdWth);
	Dialog.addNumber("height\t", RdHgt);
	Dialog.addNumber("Depth\t", RdDpt);
	Dialog.show();
	
	Top = Dialog.getNumber();
	Bot = Dialog.getNumber();
	Wth = Dialog.getNumber();
	Hgt = Dialog.getNumber();
	Dpt = Dialog.getNumber();
	
	TTop = Top;
	TBot = Bot;
	//TWth = Wth;
	//THgt = Hgt;
	//TDpt = Dpt;

	///Parameters
	Cut1= Top/Dpt;
	Cut2= Bot/Dpt;

	///Add slices at begining
	setBatchMode(true);
	open(imgPath);
	selectWindow(imgName);
	getDimensions(w, h, channels, slices, frames);
	newImage("Untitled", "8-bit white", w, h, Cut2);

	//Concatenate stacks
	print("Concatenate images");
	selectWindow("Stack-0");
	run("Duplicate...", "title=Stack-0-1 duplicate range=1-&slices");
	run("Invert", "stack");
	run("Concatenate...", "  title=[Stack] image1=[Untitled] image2=[Stack-0-1] image3=[-- None --]");
	wait(1000);

	//Substraction2
	print("Substraction2");
	selectWindow(imgName);
	getDimensions(w, h, channels, slices, frames);
	selectWindow("Stack");
	run("Duplicate...", "title=Stack-1 duplicate range=1-&slices");
	selectWindow(imgName);
	wait(1000);
	run("8-bit");
	run("Invert", "stack");
	imageCalculator("Subtract create stack", "Stack-1", imgName);
	close(imgName);

	//Substraction1
	print("Substraction1");
	selectWindow("Stack");
	run("Invert", "stack");
	getDimensions(w, h, channels, slices, frames);
	Slice1 = Cut2 + 1 - Cut1;
	Slice2 = slices - Cut1;
	run("Duplicate...", "title=Stack-2 duplicate range=&Slice1-&Slice2");
	selectWindow("Result of Stack-1");
	run("Invert", "stack");
	imageCalculator("Subtract create stack", "Stack-2","Result of Stack-1");
	//run("Duplicate...", "title=ResultofStack-2-2 duplicate range=range=1-&slices");
	run("Z Project...", "projection=[Max Intensity]");
	rename("SurfCut projection");

	close("Stack-2");
	close("Result of Stack-1");
	close("Stack-1");
	close("Stack");
	
	open(imgPath);

	run("Merge Channels...", "c1=[Result of Stack-2] c4=&imgName keep");
	//setTool("line");
	makeLine(512, 1, 512, 1024);
	run("Reslice [/]...", "output=0.500 slice_count=1");
	selectWindow("Composite");
	makeLine(1, 512, 1024, 512);
	run("Reslice [/]...", "output=0.500 slice_count=1");

	close("Result of Stack-2");
	close("Composite");
	selectWindow(imgName);
	run("Z Project...", "projection=[Max Intensity]");
	run("Grays");
	rename("Original projection");
	close(imgName);
	
	setBatchMode("exit and display");

	///Satisfied?
	waitForUser("Check SurfCut Result", "Check the quality of output\nThen click OK.");
	Dialog.create("Satisfied with SurfCut output");
	Dialog.addMessage("If you are not satisfied, do not tick the box and just click Ok.\nThis will take you back to the previous step.");
	Dialog.addCheckbox("Satisfied?", false);
	Dialog.show();
	Satisfied = Dialog.getCheckbox();
	if (Satisfied){
		wait(1000);
		Dialog.create("Save SurfCut Calibration Parameters");
		Dialog.addMessage("5) Suffix added to saved file");
        Dialog.addString("Suffix", "_for_L1_cells");
        Dialog.addCheckbox("Save SurfCut Parameters file?\t", false);
        Dialog.addCheckbox("Save SurfCut output projection?\t", false);
		Dialog.addCheckbox("Save Original projection?\t", false);
        Dialog.show();

        Suf = Dialog.getString();
        SaveParam = Dialog.getCheckbox();
        SaveSCP = Dialog.getCheckbox();
		SaveOP = Dialog.getCheckbox();

		//Save SurfCut Parameter File
        if (SaveParam){
			print("Save Calibration Parameters");
			f = File.open(imgDir+File.separator+"SurfCutCalibrate"+ File.separator+"SurfCutCalibration"+Suf+".txt");
			print(f, "Calibration parameters:"+"\n");
			print(f, "Radius " + Rad);
			print(f, "Thld " + Thld);
			print(f, "Top " + Top);
			print(f, "Bottom " + Bot);
			print(f, "Width " + Wth);
			print(f, "Height " + Hgt);
			print(f, "Depth " + Dpt);
        }

		//Save SurfCut Projection
		if (SaveSCP){
			print("Save SurfCutProj"); 
			selectWindow("SurfCut projection");
			saveAs("Tiff", imgDir+File.separator+"SurfCutCalibrate"+ File.separator+"SurfCutCalibration_Proj"+Suf+".tif");
		}
		//Save original projection
		if (SaveOP){
			print("Save OriginalProj");
			selectWindow("Original projection");
			saveAs("Tiff", imgDir+File.separator+"SurfCutCalibrate"+ File.separator+"OriginalProj.tif");
		}
	} else {
	wait(1000);
	close("Reslice of Composite");
	close("Original projection");
	close("SurfCut projection");
	wait(1000);
	}

}
run("Close All");
File.close(f);
print("=== Calibration Done ===");




} else {
print("=== SurfCut Batch mode ===");

///========== Batch Mode ==========///
///Directory
dir = getDirectory("Choose a directory");
File.makeDirectory(dir+File.separator+"SurfCutResult");

///Load param file?
Dialog.create("Load Parameter file?");
Dialog.addMessage("Choose between loading a parameter file\nform a calibration previously done,\nor manually enter the parameters.");
Dialog.addChoice("Mode", newArray("Parameter file", "Manual"));
Dialog.show();
Mode = Dialog.getChoice();

if (Mode=="Parameter file"){
	print("-> Loading parameter file");
	///Retrieve parameter text file values
	pathfile=File.openDialog("Choose the Parameter file to use"); 
	filestring=File.openAsString(pathfile); 
	print(filestring);
	rows=split(filestring, "\n"); 
	x=newArray(rows.length); 
	y=newArray(rows.length); 
	for(i=0; i<rows.length; i++){ 
		columns=split(rows[i]," "); 
		y[i]=parseFloat(columns[1]); 
	} 
	PRad = y[1];
	PThld = y[2];
	PTop = y[3];
	PBot = y[4];
	PWth = y[5];
	PHgt = y[6];
	PDpt = y[7];

} else {
	print("-> Manual parameters");

	PRad = 0;
	PThld = 0;
	PTop = 0;
	PBot = 0;
	PWth = 0;
	PHgt = 0;
	PDpt = 0;
}

///Ask the user about cut depth parameters
Dialog.create("SurfCut Parameters");
Dialog.addMessage("1) Choose Gaussian blur radius");
Dialog.addNumber("Radius\t", PRad);
Dialog.addMessage("2) Choose the intensity threshold\nfor surface detection\n(Between 0 and 255)");
Dialog.addNumber("Threshold\t", PThld);
Dialog.addMessage("3) Choose the depths between which\nthe stack will be cut relative to the\ndetected surface in micrometers");
Dialog.addNumber("Top\t", PTop);
Dialog.addNumber("Bottom\t", PBot);
Dialog.addMessage("4) Enter the actual voxel properties\nin micrometers");
Dialog.addNumber("Width\t", PWth);
Dialog.addNumber("height\t", PHgt);
Dialog.addNumber("Depth\t", PDpt);
Dialog.addMessage("5) Suffix added to saved files");
Dialog.addString("Suffix", "_L1_cells");
Dialog.addMessage("6) Saving\n(The SurfCut Projection will always be saved)");
Dialog.addCheckbox("Save SurfCutStack?\t", false);
Dialog.addCheckbox("Save Original Projection?\t", false);
Dialog.show();
  
Rad = Dialog.getNumber();
Thld = Dialog.getNumber();
Top = Dialog.getNumber();
Bot = Dialog.getNumber();
Wth = Dialog.getNumber();
Hgt = Dialog.getNumber();
Dpt = Dialog.getNumber();
Suf = Dialog.getString();
SaveSCS = Dialog.getCheckbox();
SaveOP = Dialog.getCheckbox();

f = File.open(dir+File.separator+"SurfCutResult"+ File.separator+"SurfCutParameters"+Suf+".txt");
print(f, "Parameters:"+"\n");
print(f, "Radius " + Rad);
print(f, "Thld " + Thld);
print(f, "Top " + Top);
print(f, "Bottom " + Bot);
print(f, "Width " + Wth);
print(f, "Height " + Hgt);
print(f, "Depth " + Dpt);
print(f, "Suffix " + Suf);
print(f, "\n"+"List of files processed:");

///BatchMode
setBatchMode(true);

///Parameters
Cut1= Top/Dpt;
Cut2= Bot/Dpt;
  //print ("Cut1 " + Cut1);
  //print ("Cut2 " + Cut2);

///Loop on all images in folder
list = getFileList(dir);
for (j=0; j<list.length; j++){
	if(endsWith (list[j], ".tif")){
	print("file_path ",dir+list[j]);
	print(f, "file_path"+dir+list[j]);
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	print(f, hour+":"+minute+":"+second+" "+dayOfMonth+"/"+month+"/"+year);
	open(dir+File.separator+list[j]);
	file_name1=substring(list[j],0,indexOf(list[j],".tif"));

	///Image pre-processing
	run("8-bit");
	run("Gaussian Blur...", "sigma=&Rad stack");
	
	///Threshold
	setThreshold(0, Thld);
	run("Convert to Mask", "method=Default background=Light");
	run("Invert", "stack");

	///Add slices at begining
	getDimensions(w, h, channels, slices, frames);
	for (empty=0; empty<Cut2; empty++){
		newImage("Untitled", "8-bit white", w, h, 1);
	}

	//Edge detect
	print (slices);
	for (img=0; img<slices; img++){
		print("Edge detect projection" + img + "/" + slices);
		slice = img+1;
		selectWindow(list[j]);
		run("Z Project...", "stop=&slice projection=[Max Intensity]");
	}

	//Concatenate all images into one stack
	print("Concatenate images");
	run("Images to Stack", "name=Stack title=[]");
	wait(1000);
	selectWindow(list[j]);
	close();

	//Substraction2
	print("Substraction2");
	selectWindow("Stack");
	run("Duplicate...", "title=Stack-1 duplicate range=1-&slices");
	open(dir+File.separator+list[j]);
	wait(1000);
	run("8-bit");
	run("Invert", "stack");
	imageCalculator("Subtract create stack", "Stack-1",list[j]);

	//Substraction1
	print("Substraction1");
	selectWindow("Stack");
	run("Invert", "stack");
	getDimensions(w, h, channels, slices, frames);
	Slice1 = Cut2 +1 - Cut1;
	Slice2 = slices - Cut1;
	run("Duplicate...", "title=Stack-2 duplicate range=&Slice1-&Slice2");
	selectWindow("Result of Stack-1");
	run("Invert", "stack");
	imageCalculator("Subtract create stack", "Stack-2","Result of Stack-1");

	//Add voxel size and save SurfCutStack
	run("Properties...", "unit=micron pixel_width=&Wth pixel_height=&Hgt voxel_depth=&Dpt");
	if (SaveSCS){
		print("Save SurfCutStack");
		saveAs("Tiff", dir+File.separator+"SurfCutResult"+ File.separator+file_name1+"_SurfCutStack"+Suf+".tif");
	}
	//Z Max intensity projection and save SurfCutProj
	print("Project and save SurfCutProj"); 
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Tiff", dir+File.separator+"SurfCutResult"+ File.separator+file_name1+"_SurfCutProj"+Suf+".tif");

	//Z Max intensity projection of original stack and save
	if (SaveOP){
		print("Project and save OriginalProj");
		open(dir+File.separator+list[j]);
		wait(1000);
		run("8-bit");
		run("Z Project...", "projection=[Max Intensity]");
		saveAs("Tiff", dir+File.separator+"SurfCutResult"+ File.separator+file_name1+"_OriginalProj.tif");
	}

	print("Done with "+list[j]);
	run("Close All");
	}
}
print("===== Done =====");

}
// Do you wish to process other images with SurfCut?
Dialog.create("More?");
Dialog.addMessage("Do you want to process other images with SurfCut?");
Dialog.addChoice("More", newArray("Yes", "No, I'm done"));
Dialog.show();
More = Dialog.getChoice();
} while (More=="Yes");
