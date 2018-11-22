// Stack has to start with the top image
// signle channel

///Open a stack for calibration
open();
imgDir = File.directory;
print(imgDir);
imgName = getTitle();
print(imgName);
imgPath = imgDir+imgName;
print(imgPath);


Satisfied = false;
while (Satisfied==false){ 
	///Ask the user about cut depth parameters
	Dialog.create("SurfCut Parameters");
	Dialog.addMessage("1) Choose Gaussian blur radius");
	Dialog.addNumber("Radius\t", 3);
	Dialog.addMessage("2) Choose the intensity threshold\nfor surface detection\n(Between 0 and 255)");
	Dialog.addNumber("Threshold\t", 20);
	Dialog.show();
	  
	Rad = Dialog.getNumber();
	Thld = Dialog.getNumber();
	
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
	
	run("3D Viewer");
	call("ij3d.ImageJ3DViewer.setCoordinateSystem", "false");
	call("ij3d.ImageJ3DViewer.add", "Stack-invert", "None", "Stack-invert", "0", "true", "true", "true", "2", "0");

	///Satisfied?
	waitForUser("Check Edge Detect", "Check the quality of Edge Detection\nThen click OK.");
	Dialog.create("Satisfied with Gaussian blur and threshold?");
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
	Dialog.addNumber("Top\t", 6);
	Dialog.addNumber("Bottom\t", 8);
	Dialog.addMessage("4) Enter the actual voxel properties\nin micrometers");
	Dialog.addNumber("Width\t", 0.3632815);
	Dialog.addNumber("height\t", 0.3632815);
	Dialog.addNumber("Depth\t", 0.5);
	Dialog.show();
	
	Top = Dialog.getNumber();
	Bot = Dialog.getNumber();
	Wth = Dialog.getNumber();
	Hgt = Dialog.getNumber();
	Dpt = Dialog.getNumber();

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
	Dialog.create("Satisfied with SurfCut depth");
	Dialog.addCheckbox("Satisfied?", false);
	Dialog.show();
	Satisfied = Dialog.getCheckbox();
	wait(1000);
	close("Reslice of Composite");
	close("Original projection");
	close("SurfCut projection");
	wait(1000);
	if (Satisfied){
		wait(1000);
		Dialog.create("Save SurfCut Calibration Parameters");
		Dialog.addMessage("5) Suffix added to saved file");
        Dialog.addString("Suffix", "_for_L1_cells");
        Dialog.show();

        Suf = Dialog.getString();
        
		f = File.open(imgDir+"SurfCutCalibration"+Suf+".txt");
		print(f, "Calibration parameters:"+"\n");
		print(f, "Radius " + Rad);
		print(f, "Thld " + Thld);
		print(f, "Top " + Top);
		print(f, "Bottom " + Bot);
		print(f, "Width " + Wth);
		print(f, "Height " + Hgt);
		print(f, "Depth " + Dpt);
	}
}
run("Close All");