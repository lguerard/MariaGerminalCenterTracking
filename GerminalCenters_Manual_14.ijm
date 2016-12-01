macro "GerminalCenters_Manual" {
/* Segmentation of Tcell regions, which should be in channel 1,
 * Bcell regions, which should be in channel 2, and germinal centers, which should be in channel 3.
 * The Tcell and Bcell regions are combined into follicle regions. The segmentation is only done in
 * a user-defined tissue area.
 * Threshold levels are set automatically.
 * 
 * Instructions:
 * Run the macro!
 * The resulting images and analysis results are found in the folder ../GC_Results
 * 
 * Macro created by Maria Smedh, Centre for Cellular Imaging 
 * 141217 Version 1.0
 * 150115 Version 1.1: Bug fix for creating RGB images with the objects (the merge function gave errors for unknown reason)
 * 150122 Version 1.2: Added the function that germinal centers are only allowed to be inside/touching follicles  
 * 150226 Version 1.3: Segmenting enhanced images instead of raw data, bug fixes
 * 150315 Version 1.4: Handling of only one GC object
 */
 
setBatchMode(true);
run("Close All");
print("\\Clear");
roiManager("Reset");
run("Clear Results");
print("-----------------------------------");
print("GerminalCenters macro started");

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
month = 11; dayOfMonth = 24;
if ((month>=10) && (dayOfMonth<10)) {print("Date: "+year+"-"+month+1+"-0"+dayOfMonth);}
else if ((month<10) && (dayOfMonth<10)) {print("Date: "+year+"-0"+month+1+"-0"+dayOfMonth);}
else if ((month<10) && (dayOfMonth>010)) {print("Date: "+year+"-0"+month+1+"-"+dayOfMonth);}
else {print("Date: "+year+"-"+month+1+"-"+dayOfMonth);}
//Start time:
StartTime = (hour*60+minute)*60+second;

run("Colors...", "foreground=white background=black selection=yellow");
//run("Set Measurements...", "area mean min centroid display redirect=None decimal=4");
run("Set Measurements...", "area centroid shape display redirect=None decimal=4");
run("Options...", "iterations=1 count=1 black edm=Overwrite"); //Black background in binary images

//--------------------------------------------------------
// Set parameters:
//--------------------------------------------------------
ChNames = newArray("Tcells", "Bcells", "GerminalCenters");
NrObjects = newArray(3);
AccumObjects = newArray(3);
TotalAreas = newArray(5);
//Thresholds for object sizes (µm^):
MinFollicleSize = 20000;
MinBCSize = 10000;
MinTCSize = 2000;
MinGermCentSize = 1000;
MinSizeArray = newArray(MinTCSize, MinBCSize, MinGermCentSize, MinFollicleSize);
//Initial threshold values:
Tcells_threshold = 400;
Bcells_threshold = 400; 
GerminalCenters_threshold = 100; 


//--------------------------------------------------------
//Get file/folder information from image to analyze:
path = File.openDialog("Please, open the image to be analyzed");
open(path);
FileName = getTitle();
print(" ");
print("File currently analyzed: "+FileName);

Folder = getInfo("image.directory");
StrInd1 = indexOf(FileName, ".lsm");
ShortFileName=substring(FileName,0, StrInd1);
OutputFolderName = "GC_Results/";
Output_Folder = Folder + "/" + OutputFolderName;
File.makeDirectory(Output_Folder);
OutputFolderName = "GC_Results/"+ShortFileName+"/";
Output_Folder = Folder + "/" + OutputFolderName;
File.makeDirectory(Output_Folder);

//--------------------------------------------------------
//Resample image to fewer pixels:
getDimensions(width, height, channels, slices, frames);
if ((channels >= slices) && (channels >= frames)){
	depth = channels;
}else if ((slices >= channels) && (slices >= frames)){
	depth = slices;
}else{
	depth = frames;
}

if ((width >= height) && (width > 1024)){
	scale = width/1024;
	NewHeight = round(height/scale);
	print("Old width and height is: "+width+","+height);
	print("New width and height is: 1024,"+NewHeight);
	run("Size...", "width=1024 height=1024 depth="+depth+" constrain average interpolation=Bilinear");
}else if ((height > width) && (height > 1024)){
	scale = height/1024;
	NewWidth = round(width/scale);
	print("Old width and height is: "+width+","+height);
	print("New width and height is: "+NewWidth+",1024");
	run("Size...", "width="+NewWidth+" height=1024 depth="+depth+" constrain average interpolation=Bilinear");   			
}
print("-----------------------------------");
getDimensions(width, height, channels, slices, frames);
//New pixel size:
getPixelSize(unit, pixelWidth, pixelHeight);
setVoxelSize(pixelWidth, pixelHeight, 1, unit);


//--------------------------------------------------------
//Create enhanced individual channels and merged RGB image:
//--------------------------------------------------------
run("Duplicate...", "title=["+ShortFileName+"_new] duplicate channels=1-"+channels);
run("Select None");
run("Remove Overlay");
run("Split Channels"); //Split removes the original image stack
for (ChNr=1;ChNr<=channels;ChNr++){
	selectWindow("C"+ChNr+"-"+ShortFileName+"_new");
	run("Select None");
	rename(ChNames[ChNr-1]+"_Enhanced");
	run("Grays");
	run("Subtract Background...", "rolling=100");
	if (ChNr < 3){ 
		run("Remove Outliers...", "radius=2 threshold=500 which=Bright");
	}else if (ChNr == 3){ 	 
		run("Remove Outliers...", "radius=5 threshold=500 which=Bright");
		run("Subtract Background...", "rolling=10");	   				
	}
	run("Enhance Contrast", "saturated=0.001");
	run("Despeckle");
}
run("Merge Channels...", "c1=Bcells_Enhanced c2=Tcells_Enhanced c4=GerminalCenters_Enhanced create keep ignore");
run("RGB Color");		
rename(ShortFileName+"_RGB");


//--------------------------------------------------------
//Let the user draw the tissue ROI and measure it's area:
//--------------------------------------------------------
selectWindow(ShortFileName+"_RGB");
setBatchMode("show");
setTool("polygon");
run("Select None");
run("Remove Overlay");
beep();
waitForUser("Please, draw a region in the tissue where you want to measure the germinal centers and then press 'OK'");
setTool("hand");
roiManager("Add");
roiManager("Select", 0);
roiManager("Rename", "TissueROI");
roiManager("Deselect");
run("Select All");
roiManager("Add");
roiManager("Select", newArray(0,1));
/*			
roiManager("XOR");
roiManager("Add");
roiManager("Deselect");
roiManager("Select", 1);
roiManager("Delete");
roiManager("Select", 1);
roiManager("Rename", "NonTissueROI");
roiManager("Deselect");
setBatchMode("hide");

run("Clear Results");
roiManager("Select", 0);
run("Measure");
TotalAreas[0] = getResult("Area", 0);

print(" ");
print("Start segmentation");

//--------------------------------------------------------
//First segmentation of images:
//--------------------------------------------------------
run("Clear Results");
selectWindow(ShortFileName+"_RGB");
run("Select None");
run("Remove Overlay");
setBatchMode("show");

showStatus(" Start segmentation");
TotObjects = 0;
for (ChNr=1;ChNr<=channels;ChNr++){   
	selectWindow(ChNames[ChNr-1]+"_Enhanced");	   			
	run("Select None");
	run("Remove Overlay");	
	run("Grays");
	run("Duplicate...", "title="+ChNames[ChNr-1]+"Objects"); 

	selectWindow(ChNames[ChNr-1]+"_Enhanced");
	setBatchMode("show");
	selectWindow(ChNames[ChNr-1]+"Objects");
	//Remove the area outside TissueROI:	   			
	roiManager("Deselect");
	roiManager("Select", 0);
	setBackgroundColor(0, 0, 0);
	run("Clear Outside");
	run("Select None");
	setBatchMode("show");
	
	if (ChNames[ChNr-1]=="Tcells"){ 
		//Tcells_threshold = 400;
		Ans="n";
		run("Gaussian Blur...", "sigma=2");  
		getMinAndMax(min, max);
		run("Threshold...");
		setAutoThreshold("Default dark");
		while (Ans=="n") {
			selectWindow(ChNames[ChNr-1]+"Objects");
			setThreshold(Tcells_threshold, max);
			Tcells_threshold_new = getNumber("If not happy with the segmentation, enter a new threshold", Tcells_threshold);
			if (Tcells_threshold_new != Tcells_threshold){
				Ans="n";
				Tcells_threshold = Tcells_threshold_new;
			}else {
				Ans="y";
			}
		}
		setOption("BlackBackground", true);
		run("Convert to Mask");	
		run("Analyze Particles...", "size="+ MinTCSize +"-Infinity circularity=0.00-1.00 show=Nothing display add");
		run("Remove Overlay");
		
	}else if (ChNames[ChNr-1]=="Bcells"){ 
		//Bcells_threshold = 400;
		Ans="n";
		run("Gaussian Blur...", "sigma=2");  
		getMinAndMax(min, max);
		run("Threshold...");
		setAutoThreshold("Default dark");
		while (Ans=="n") {
			selectWindow(ChNames[ChNr-1]+"Objects");
			setThreshold(Bcells_threshold, max);
			Bcells_threshold_new = getNumber("If not happy with the segmentation, enter a new threshold", Bcells_threshold);
			if (Bcells_threshold_new != Bcells_threshold){
				Ans="n";
				Bcells_threshold = Bcells_threshold_new;
			}else {
				Ans="y";
			}
		}
		setOption("BlackBackground", true);
		run("Convert to Mask");	
		run("Analyze Particles...", "size="+ MinBCSize +"-Infinity circularity=0.00-1.00 show=Nothing display add");
		run("Remove Overlay");						
	}else if (ChNames[ChNr-1]=="GerminalCenters"){ 
		//GerminalCenters_threshold = 350;
		Ans="n";
		run("Gaussian Blur...", "sigma=1");   				   				
		getMinAndMax(min, max);
		run("Threshold...");
		setAutoThreshold("Default dark");
		while (Ans=="n") {
			selectWindow(ChNames[ChNr-1]+"Objects");
			setThreshold(GerminalCenters_threshold, max);
			GerminalCenters_threshold_new = getNumber("If not happy with the segmentation, enter a new threshold", GerminalCenters_threshold);
			if (GerminalCenters_threshold_new != GerminalCenters_threshold){
				Ans="n";
				GerminalCenters_threshold = GerminalCenters_threshold_new;
			}else {
				Ans="y";
			}
		}
		setOption("BlackBackground", true);
		run("Convert to Mask");	
		run("Analyze Particles...", "size="+ MinGermCentSize +"-Infinity circularity=0.00-1.00 show=Nothing display add");
		run("Remove Overlay");
	}
	selectWindow(ChNames[ChNr-1]+"Objects");
	setBatchMode("hide");
	selectWindow(ChNames[ChNr-1]+"_Enhanced");
	setBatchMode("hide");
	if (ChNr==1){ 
		NrObjects[ChNr-1]=nResults;	   				
		AccumObjects[ChNr-1] = nResults;
		TotObjects = nResults;
	}else{	   				
		NrObjects[ChNr-1] = nResults-TotObjects;
		AccumObjects[ChNr-1] = nResults;
	TotObjects = TotObjects + NrObjects[ChNr-1];				
	}	   			
	print("");
	showStatus(" Segmentation of "+ChNames[ChNr-1]+" is done.");
	print("Segmentation of "+ChNames[ChNr-1]+" is done.");
	//print("NrObjects= "+NrObjects[ChNr-1]);
	//print("AccumObjects= "+AccumObjects[ChNr-1]);
		
}
//print("TotObjects= "+TotObjects);
//Rename the objects:
for (ObjectNr=1;ObjectNr<=TotObjects;ObjectNr++){
	roiManager("Deselect");
	roiManager("Select", ObjectNr+1);
	roiManager("Rename", getResultLabel(ObjectNr-1)+"_"+ObjectNr);
}


//--------------------------------------------------------
//Create the follicle regions:
//--------------------------------------------------------
//TotObjects = 81;
//NrObjects = newArray(43, 37, 1);
//AccumObjects = newArray(43, 80, 81);

//Start by finding green objects that are touching red objects			
DiscardObjects = newArray(0); //Tcell object numbers without Bcell overlap
//DiscardObjectNames = newArray(0);
KeepTcellObjects = newArray(0); //Tcell object numbers with Bcell overlap
KeepTcellNrs  = newArray(0); //ROI manager numbers
for (ObjectNr=1;ObjectNr<=AccumObjects[0];ObjectNr++){ //loop over all Tcell objects
	ObjectName = getResultLabel(ObjectNr-1)+"_"+ObjectNr;
	SizeArray = newArray(0); 
	for (k=AccumObjects[0]+2;k<=AccumObjects[1]+1;k++){ //loop over all Bcell objects
		array1 = newArray(0);
		array1 = Array.concat(ObjectNr+1,k);		
		roiManager("Deselect");
		roiManager("Select", array1);
		roiManager("AND");
		getSelectionBounds(x, y, width, height);
		if (x > 0 || y > 0){
			SizeArray = Array.concat(SizeArray,k);
		}
	}
	if (lengthOf(SizeArray) == 0){
		DiscardObjects = Array.concat(DiscardObjects,ObjectNr);
		//DiscardObjectNames = Array.concat(DiscardObjectNames,ObjectName);
	}else{	
		KeepTcellObjects = Array.concat(KeepTcellObjects,ObjectNr);
		KeepTcellNrs = Array.concat(KeepTcellNrs,ObjectNr+1);
	}	
}
NrObjects[0]=(lengthOf(KeepTcellObjects)); //New number of Tcell objects
FinalTotObjects=TotObjects-lengthOf(DiscardObjects);
showStatus(" Non-follicle Tcells removed.");
print("");
print("Non-follicle Tcells removed.");
//print("NrObjects0= "+NrObjects[0]);
//print("FinalTotObjects= "+FinalTotObjects);

//--------------------------------------------------------
//Create ROIs for combined objects:
//--------------------------------------------------------

//Create an object for all germinal center objects:
if (NrObjects[2]==0){ 
	showStatus("There are no germinal centers in this image!");
}else if (NrObjects[2]==1){ 
	roiManager("select", roiManager("count")-1); 
	roiManager("Add");
	roiManager("Rename", "AllGCObjects");	
}else{ 
	array1 = newArray(0);
	run("Select None");
	run("Remove Overlay");
	for (i=AccumObjects[1]+2;i<=AccumObjects[2]+1;i++){ 
		roiManager("Deselect");
		roiManager("Select", i);
		array1 = Array.concat(array1,i);				
	}			
	roiManager("Deselect");
	roiManager("select", array1);
	roiManager("Combine");
	roiManager("Add");
	roiManager("select", roiManager("count")-1); 
	roiManager("Rename", "AllGCObjects");	
}

//Create an object for all Bcell objects:
if (NrObjects[1]==0){ 
	exit(("There are no Bcell areas found in this image!");
}else if (NrObjects[1]==1){ 
	roiManager("select", roiManager("count")-1); 
	roiManager("Add");
	roiManager("Rename", "AllBcellObjects");
}else{ 
	array1 = newArray(0);
	run("Select None");
	run("Remove Overlay");
	for (i=AccumObjects[0]+2;i<=AccumObjects[1]+1;i++){ 
		roiManager("Deselect");
		roiManager("Select", i);
		array1 = Array.concat(array1,i);				
	}
	
	roiManager("Deselect");
	roiManager("select", array1);
	roiManager("Combine");
	roiManager("Add");
	roiManager("select", roiManager("count")-1); 
	roiManager("Rename", "AllBcellObjects");
}

//Create an object for follicle Tcell objects:
run("Select None");
run("Remove Overlay");
roiManager("Deselect");
roiManager("select", KeepTcellNrs);
roiManager("Combine");
roiManager("Add");
roiManager("select", roiManager("count")-1); 
roiManager("Rename", "FollicleTcellObjects");		

//Combine all Tcell and Bcell objects into one follicle object:
run("Select None");
run("Remove Overlay");
roiManager("Deselect");
roiManager("select", roiManager("count")-2);
roiManager("Add");
roiManager("Deselect");
roiManager("select", roiManager("count")-2);
roiManager("Add");
nr1 = roiManager("count")-2;
nr2 = roiManager("count")-1;
array1 = newArray(nr1, nr2);
//array1 = newArray(60, 61);
run("Select None");
run("Remove Overlay");
roiManager("Deselect");
roiManager("select", array1);
roiManager("Combine");
roiManager("Add");
roiManager("select", roiManager("count")-1); 
roiManager("Rename", "FollicleObjects");
nr1 = roiManager("count")-3;
nr2 = roiManager("count")-2;
array1 = newArray(nr1, nr2);
run("Select None");
run("Remove Overlay");
roiManager("Deselect");
roiManager("select", array1);
roiManager("Delete");

//--------------------------------------------------------
//Segmantation and removal of too small "follicles":
//--------------------------------------------------------

selectWindow(ShortFileName+"_RGB");
//getPixelSize(unit, pixelWidth, pixelHeight);
run("Select None");
run("Remove Overlay");
run("Duplicate...", "title=temp");

selectWindow("temp");
run("Select All");
setBackgroundColor(0, 0, 0);
run("Clear", "slice");
run("Select None");
roiManager("select", roiManager("count")-1); 
run("Overlay Options...", "stroke=white width=0 fill=white set");
run("Add Selection...");
run("Flatten");
setOption("BlackBackground", true);
run("Make Binary");
setVoxelSize(pixelWidth, pixelHeight, 1, unit);
rename("FinalFollicleObjects");

selectWindow("FinalFollicleObjects");
//MinFollicleSize = 20000;
run("Clear Results");
run("Set Measurements...", "area display redirect=None decimal=4");
run("Analyze Particles...", "size="+ MinFollicleSize +"-Infinity circularity=0.00-1.00 show=Nothing display add");
run("Remove Overlay");
print(" ");
print("Small follicles removed");
NrFollicles = nResults;


//Combine follicle objects to one and remove individual follicle objects	
array1 = newArray(0);
run("Select None");
run("Remove Overlay");
for (i=1;i<=NrFollicles;i++){ 
	roiManager("Deselect");
	//roiManager("Select", roiManager("count")-i);
	array1 = Array.concat(array1,roiManager("count")-i);				
}			
roiManager("Deselect");
roiManager("select", array1);
roiManager("Combine");
roiManager("Add");
roiManager("select", roiManager("count")-1); 
roiManager("Rename", "FinalFollicleObjects");	

for (i=1;i<=NrFollicles+1;i++){ 
	roiManager("Deselect");
	roiManager("Select", roiManager("count")-2);			
	roiManager("Delete");	
}


//--------------------------------------------------------
//Remove all objects outside follicle regions:
//--------------------------------------------------------
//channels = 3;
//ChNames = newArray("Tcells", "Bcells", "GerminalCenters");
//NrObjects=newArray(3);
//NrObjects[2]=0;

showStatus(" Remove objects outside follicles");
run("Select None");
run("Remove Overlay");

for (ChNr=1;ChNr<=channels;ChNr++){
	if ((ChNr==3) && (NrObjects[2]==0)){ 
			showStatus("There are no germinal centers in this image!");
	}else if ((ChNr<3) && (NrObjects[2]==0)){ 
		roiManager("Deselect");	
		array1 = Array.concat(roiManager("count")-ChNr,roiManager("count")-3);
		roiManager("select", array1);
		roiManager("And");
		roiManager("Add");
		roiManager("select", roiManager("count")-1); 
		roiManager("Rename", "Final"+ChNames[2-ChNr]+"Objects");
	}else{ 
		roiManager("Deselect");	
		array1 = Array.concat(roiManager("count")-ChNr,roiManager("count")-4);
		roiManager("select", array1);
		roiManager("And");
		roiManager("Add");
		roiManager("select", roiManager("count")-1); 
		roiManager("Rename", "Final"+ChNames[3-ChNr]+"Objects");
	}				
}

if (NrObjects[2]==0){ 
	roiManager("select", roiManager("count")-3); 
	roiManager("Add");
	roiManager("select", roiManager("count")-4); 
	roiManager("Delete");
}else{ 
	roiManager("select", roiManager("count")-4); 
	roiManager("Add");
	roiManager("select", roiManager("count")-5); 
	roiManager("Delete");
}
roiManager("select", roiManager("count")-1); 
roiManager("Rename", "FinalFollicleObjects"); //These last 6 lines are only to have same order as before...

//channels = 3;
//ChNames = newArray("Tcells", "Bcells", "GerminalCenters");
for (ChNr=1;ChNr<=channels;ChNr++){
	if ((ChNr==3) && (NrObjects[2]==0)){ 
		showStatus("There are no germinal centers in this image!");
		selectWindow(ChNames[ChNr-1]+"Objects");
		run("Select None");
		run("Remove Overlay");	
		run("Duplicate...", "title=Final"+ChNames[ChNr-1]+"Objects");
		selectWindow("Final"+ChNames[ChNr-1]+"Objects");
		run("Select All");
		setBackgroundColor(0, 0, 0);
		run("Clear", "slice");
		run("Select None");
	}else{ 
		selectWindow(ChNames[ChNr-1]+"Objects");
		run("Select None");
		run("Remove Overlay");	
		run("Duplicate...", "title=Final"+ChNames[ChNr-1]+"Objects");
		selectWindow("Final"+ChNames[ChNr-1]+"Objects");
		roiManager("Deselect");
		roiManager("select", roiManager("count")-ChNr-1); 
		setBackgroundColor(0, 0, 0);
		run("Clear Outside");
		run("Select None");
	}		
}

selectWindow("FinalFollicleObjects");
close();
selectWindow("FinalBcellsObjects");
run("Select None");
run("Remove Overlay");
selectWindow("FinalTcellsObjects");
run("Select None");
run("Remove Overlay");
imageCalculator("Add create", "FinalBcellsObjects","FinalTcellsObjects");
rename("FinalFollicleObjects");

print("");
print("Final follicle regions created.");

selectWindow("FinalFollicleObjects");
run("Select None");
run("Remove Overlay");
//MinFollicleSize = 20000;
run("Clear Results");
run("Set Measurements...", "area display redirect=None decimal=4");
run("Analyze Particles...", "size="+ MinFollicleSize +"-Infinity circularity=0.00-1.00 show=Nothing display add");
run("Remove Overlay");

//TotalAreas = newArray(5);
NrFollicles = nResults;
for (i=1;i<=NrFollicles;i++){
	TotalAreas[4] = TotalAreas[4]+getResult("Area", i-1);
}

for (i=1;i<=NrFollicles;i++){ 
	roiManager("Deselect");
	roiManager("Select", roiManager("count")-1);			
	roiManager("Delete");	
}

selectWindow("Results");
OutputPath = ""+Output_Folder+ShortFileName+"_ResultsFinalFollicleObjects.txt";
saveAs("Results", OutputPath);
run("Close");

//--------------------------------------------------------
//Number and areas of final objects:
//--------------------------------------------------------

roiManagerCount = roiManager("count"); //FinalFollicleObjects
FinalTotObjects = 0;
showStatus(" Measure areas of final objects");
for (ChNr=1;ChNr<=channels;ChNr++){
	if ((ChNr==3) && (NrObjects[2]==0)){ 
		showStatus("There are no germinal centers in this image!");
		TotalAreas[ChNr]= 0;
	}else{
		run("Clear Results");
		run("Set Measurements...", "area display redirect=None decimal=4");
		selectWindow("Final"+ChNames[ChNr-1]+"Objects");
		run("Select None");
		run("Remove Overlay");
		//MinSizeArray = newArray(MinTCSize, MinBCSize, MinGermCentSize, MinFollicleSize);
		run("Analyze Particles...", "size="+MinSizeArray[ChNr-1]+"-Infinity circularity=0.00-1.00 show=Nothing display add");
		run("Remove Overlay");
	
		NrObjects[ChNr-1]=nResults;
		FinalTotObjects = FinalTotObjects + NrObjects[ChNr-1];	
	
		for (i=1;i<=NrObjects[ChNr-1];i++){
			TotalAreas[ChNr] = TotalAreas[ChNr]+getResult("Area", i-1);
		}
		
		selectWindow("Results");
		OutputPath = ""+Output_Folder+ShortFileName+"_ResultsFinal"+ChNames[ChNr-1]+"Objects.txt";
		saveAs("Results", OutputPath);	
	
		for (i=1;i<=NrObjects[ChNr-1];i++){
			roiManager("select", roiManager("count")-1); 
			roiManager("Delete");
		}
	}
}


//--------------------------------------------------------
// Save summed results:
//--------------------------------------------------------
showStatus(" Saving results");
LabelNames = newArray("TissueROI", "FinalTcellsObjects", "FinalBcellsObjects","FinalGerminalCentersObjects", "FinalFollicleObjects");
ThresArray = newArray(Tcells_threshold, Bcells_threshold, GerminalCenters_threshold);
run("Clear Results");
for  (i=1;i<=5;i++){
	setResult("Label", i-1, LabelNames[i-1]);
	setResult("TotalArea", i-1, TotalAreas[i-1]);
}

setResult("NrObjects", 0, 1);
setResult("Threshold", 0, "-");
setResult("NrObjects", 4, NrFollicles);
setResult("Threshold", 4, "-");

for  (i=1;i<=3;i++){
	setResult("NrObjects", i, NrObjects[i-1]);
	setResult("Threshold", i, ThresArray[i-1]);
}

selectWindow("Results");
OutputPath = ""+Output_Folder+ShortFileName+"_SummedResults.txt";
saveAs("Results", OutputPath);

print("");
print("Areas measured.");


//--------------------------------------------------------
//Draw objects in images and save images:
//--------------------------------------------------------
//
//C1(red), C2(green), C3(blue), C4(gray), C5(cyan), C6(magenta), C7(yellow)
showStatus(" Drawing objects and saving images");
selectWindow("temp");
run("Select None");
run("Remove Overlay");
run("Duplicate...", "title=OutlinesFollicleObjects"); 
run("8-bit");
run("Select All");
run("Clear", "slice");
roiManager("Deselect");
roiManager("Select", roiManager("count")-1); 
roiManager("Draw");
run("Yellow");
run("RGB Color");

selectWindow("temp");
run("Select None");
run("Remove Overlay");
run("Duplicate...", "title=OutlinesTissueArea"); 
run("8-bit");
run("Select All");
run("Clear", "slice");
roiManager("Deselect");
roiManager("Select", 0); 
roiManager("Draw");
run("Yellow");
run("RGB Color");
// roiManager("count")-2 => Tcells, roiManager("count")-3 => Bcells, roiManager("count")-4 => CG

// Create overlays of each channel with their corresponding objects. 
// Channels in green, red and cyan and objects in white
ChColorArray = newArray("Green", "Red", "Cyan");
for (ChNr=1;ChNr<=channels;ChNr++){
	if ((ChNr==3) && (NrObjects[2]==0)){ 
		print("No germinal centers image to save...");
	}else{
		selectWindow(ChNames[ChNr-1]+"Objects");
		run("Select None");
		run("Remove Overlay");
		run("8-bit");
		run("Select All");
		run("Clear", "slice");
		roiManager("Deselect");
		roiManager("Select", roiManager("count")-ChNr-1); 
		roiManager("Draw");
		run("Duplicate...", "title="+ChNames[ChNr-1]+"Objects_white");
		run("RGB Color");
		selectWindow(ChNames[ChNr-1]+"_Enhanced"); 
		run("8-bit");
		run(ChColorArray[ChNr-1]);
		run("RGB Color");
		imageCalculator("Add create", ChNames[ChNr-1]+"_Enhanced",ChNames[ChNr-1]+"Objects_white");
		OutputPath = ""+Output_Folder+ShortFileName+"_"+ChNames[ChNr-1]+".tif";
		saveAs("tiff", OutputPath);
	}
}

// Create overlays of germinal centers in white and follicle objects in yellow. 
if (NrObjects[2]>0){ 
	selectWindow("GerminalCentersObjects");
	run("RGB Color");
	imageCalculator("Add create", "GerminalCentersObjects","OutlinesFollicleObjects");
	rename("GCinFolliclesObjects");
	imageCalculator("Add create", ShortFileName+"_RGB","GCinFolliclesObjects");
	OutputPath = ""+Output_Folder+ShortFileName+"_Outlines_GCandFolliclesObjects_RGB.tif";
	saveAs("tiff", OutputPath);
	
	// Create overlays of Bcell objects in red, Tcell objects in green and germinal centers in white. 
	for (ChNr=1;ChNr<=2;ChNr++){
		selectWindow(ChNames[ChNr-1]+"Objects");
		run(ChColorArray[ChNr-1]);
		run("RGB Color");
	}
	imageCalculator("Add create", "GerminalCentersObjects","BcellsObjects");
	rename("AllObjects");
	imageCalculator("Add", "AllObjects","TcellsObjects");
	imageCalculator("Add", "AllObjects","OutlinesTissueArea");
	imageCalculator("Add create", ShortFileName+"_RGB","AllObjects");
	OutputPath = ""+Output_Folder+ShortFileName+"_AllObjects_RGB.tif";
	saveAs("tiff", OutputPath);

}else if (NrObjects[2]==0){ 
		for (ChNr=1;ChNr<=2;ChNr++){
			selectWindow(ChNames[ChNr-1]+"Objects");
			run(ChColorArray[ChNr-1]);
			run("RGB Color");
		}
		imageCalculator("Add create", "TcellsObjects","BcellsObjects");
		rename("AllObjects");
		imageCalculator("Add", "AllObjects","OutlinesTissueArea");
		imageCalculator("Add create", ShortFileName+"_RGB","AllObjects");
		OutputPath = ""+Output_Folder+ShortFileName+"_AllObjects_RGB.tif";
		saveAs("tiff", OutputPath);

	}


//--------------------------------------------------------

selectWindow(ShortFileName+"_RGB");
run("Select None");
run("Remove Overlay");
OutputPath = ""+Output_Folder+ShortFileName+"_RGB.tif";
saveAs("tiff", OutputPath);

for (ChNr=1;ChNr<=channels;ChNr++){
	selectWindow("Final"+ChNames[ChNr-1]+"Objects");
	run("Select None");
	run("Remove Overlay");	
	OutputPath = ""+Output_Folder+ShortFileName+"_Final"+ChNames[ChNr-1]+"Objects.tif";
	saveAs("tiff", OutputPath);	
}
selectWindow("FinalFollicleObjects");
run("Select None");
run("Remove Overlay");
OutputPath = ""+Output_Folder+ShortFileName+"_FinalFollicleObjects.tif";
saveAs("tiff", OutputPath);
		   	
OutputPath = ""+Output_Folder+ShortFileName+"_RoiSet.zip";		   	
roiManager("Save", OutputPath);
run("Close");


getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
EndTime = (hour*60+minute)*60+second;
MacroTime = (EndTime - StartTime)/60;
MacroTimeMin =  floor(MacroTime);
MacroTimeSec =  (MacroTime-MacroTimeMin)*60;

beep();
showMessage("<html>"+"<font size=+2>"+"The analysis is finished!"+"<font size=+1>"+"<p>Total time: "+MacroTimeMin+" min and "+MacroTimeSec+" sec</p>");

}			