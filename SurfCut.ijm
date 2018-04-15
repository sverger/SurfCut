// Stack as to start with the top image
// signle channel
// Create SurfCutResult folder
// Works better on relatively flat samples
// No image names with "C1-", "C2-"... because of problems with making composite image


///Directory
dir = getDirectory("Choose a directory")
File.makeDirectory(dir+File.separator+"SurfCutResult");

///Ask the user about cut depth parameters
Dialog.create("SurfCut Parameters");
Dialog.addMessage("1) Choose Gaussian blur radius");
Dialog.addNumber("Radius\t", 3);
Dialog.addMessage("2) Choose the intensity threshold\nfor surface detection\n(Between 0 and 255)");
Dialog.addNumber("Threshold\t", 20);
Dialog.addMessage("3) Choose the depths between which\nthe stack will be cut relative to the\ndetected surface in micrometers");
Dialog.addNumber("Top\t", 6);
Dialog.addNumber("Bottom\t", 8);
Dialog.addMessage("4) Enter the actual voxel properties\nin micrometers");
Dialog.addNumber("Width\t", 0.3632815);
Dialog.addNumber("height\t", 0.3632815);
Dialog.addNumber("Depth\t", 0.5);
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

f = File.open(dir+File.separator+"SurfCutResult"+ File.separator+"SurfCutParameters"+Suf+".txt")
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
print("done");

