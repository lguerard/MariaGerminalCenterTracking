macro "Track_Cells" {
	/* 
	 *  Tracks cells in a time series of cells labeled by a nuclear stain.
	 *  The time series has to be opened and the active frame before running the script
	 */

	print("\\Clear");
	run("Colors...", "foreground=white background=black selection=yellow");
	run("Set Measurements...", "area centroid redirect=None decimal=4");
	setBatchMode(true);

	//-------------------------------------------------
   	// Get information from current image and prepare for segmentation
   	//-------------------------------------------------
	Folder = getInfo("image.directory");
	ImageTitle = getTitle();
	OutputFolderName = "TrackingOutput";
	//Output_Folder = Folder + "/" + OutputFolderName;
	Output_Folder = Folder + OutputFolderName;
	//print(Output_Folder);
	File.makeDirectory(Output_Folder); //Seems only to be done if folder does not exist, no overwriting
	
	selectImage(ImageTitle);
	getDimensions(width, height, channels, slices, frames);
	//run("Subtract Background...", "rolling=200");
   	//run("Median...", "radius=10");
   	//run("Median...", "radius=2 stack");
	if (slices > frames){
		frames = slices; 
	}
	//print(width, height, channels, slices, frames);
	//newImage("MaskStack", "8-bit Black", width, height, frames);
	newImage("OutlineStack", "8-bit Black", width, height, frames);
	newImage("Centroids", "8-bit Black", width, height, frames);
	newImage("temp", "8-bit Black", width, height, 1);

	//-------------------------------------------------
   	// Segment images, create one stack of nuclear masks 
   	// and one stack of "centroid particles" for tracking
   	//-------------------------------------------------
   	for (FrameNr=1;FrameNr <=frames;FrameNr++){
   		//FrameNr=1;
   		selectImage(ImageTitle);
   		setSlice(FrameNr);
   		run("Duplicate...", "title=Mask");
   		selectImage("Mask");
   		/* getStatistics(area, mean, min, max, std, histogram);
		//print(mean, min, max);
		lower = mean*std*2;
		upper = 255;
		setThreshold(lower, upper);
		*/
		NucSmooth = 10;//12;
		run("FeatureJ Laplacian", "compute smoothing="+d2s(NucSmooth,1));
		//LaplacianID = getImageID();
		getMinAndMax(min,max);
		//print(min,max);
		NucSensitivity = -0.05;
		setThreshold(min,NucSensitivity);	
		run("Convert to Mask");
		run("Fill Holes");
		//for(i=0;i<NucDilIter;i++)run("Dilate");
		 //Split Particles
		run("Watershed");
				
	
		//Estimate Median Area
		run("Analyze Particles...", "size=0-Infinity circularity=0.5-1.00 show=Nothing display exclude clear include"); 
		Area = newArray(nResults); //nResults is the number of particles found
		for(i=0;i<nResults;i++)
			Area[i] = getResult("Area", i);
		Area = Array.sort(Area);
		MedianArea = Area[nResults/2];
		/*print("");
		print("The median area is "+ d2s(MedianArea,0) + " pixels");
		print("Objects smaller than "+MedianArea*0.5+" and larger than "+MedianArea*2+" will be removed");
		*/
		
		//Analyze Particles
		run("Analyze Particles...", "size="+MedianArea*0.5+"-"+MedianArea*2+" circularity=0.5-1.00 show=Nothing display clear include add");
		LaplacianMaskID = getImageID();
		//NbNuclei = roiManager("count");

		/*
		//Put images with the overlaid objects into a stack
		selectImage("Mask");
   		roiManager("Draw");
		run("Select All");
		run("Copy");
		run("Select None");
		selectImage("MaskStack");
		setSlice(FrameNr);
		run("Paste");
		run("Select None");
		*/

		//Put the outlines into a stack
		selectImage("OutlineStack");
		setSlice(FrameNr);
		//setSlice(2);
		roiManager("Draw");
				
		selectImage("temp");
		run("Select All");
		run("Clear");
		for(j=0;j<nResults;j++){
			makeOval(round(getResult("X",j)), round(getResult("Y",j)), 10, 10); // Make "particles" at the centroid positions of nuclei
			run("Fill");
		}
		run("Select All");
		run("Copy");
		run("Select None");
		selectImage("Centroids");
		setSlice(FrameNr);
		run("Paste");
		run("Select None");	

		selectImage("Mask");
		close();
		selectImage(LaplacianMaskID);
		close();
   	}
   	selectImage("temp");
   	close();
   	selectImage("Centroids");
   	OutputPath = ""+Output_Folder+"/Centroids.tif";
   	saveAs("tiff", OutputPath);
   	/*
   	selectImage("MaskStack");
   	OutputPath = ""+Output_Folder+"/TrackedCells.tif";
   	saveAs("tiff", OutputPath);
   	close();
   	*/
   	selectImage("OutlineStack");
   	OutputPath = ""+Output_Folder+"/Outlines.tif";
   	saveAs("tiff", OutputPath);   	
   	
   	run("Merge Channels...", "c1="+ImageTitle+" c3=Outlines.tif keep"); //outlines in blue
   	rename("Outlines_Cells_RGB");
   	//run("Merge Channels...", "c1=TimeSeries_TxRed.tif c4=Outlines.tif keep"); //outlines in white
   	//run("Merge Channels...", "c1=TimeSeries_TxRed.tif c3=Outlines.tif keep"); //outlines in green
   	OutputPath = ""+Output_Folder+"/Outlines_Cells_RGB.tif";
   	saveAs("tiff", OutputPath);
	selectImage("Outlines.tif");
   	close();

	selectWindow("Results");
	run("Close");
   	
/* --------------------------------
 *  An attempt to track the segmented cells within the macro. However,
 *  two result files are saved but I do not know how to use them. 
 *  It is better to stop here and manually run the Mosaic - Particle Tracker 2D/3D Plugin
 *  and then start the macro "Track_Cells_AnalyzeTracks" afterwards to calculate the mean displacements.
 *    	
//selectImage("Centroids"); 	
//run("Select None");
//run("Particle Tracker 2D/3D", "radius=5 cutoff=0 per/abs=0.50000 link=2 displacement=50");
*/

print("-------------------------------");
print("The segmentation is finished");
print("Please choose the image Centroids.tif and run the Plugin Mosaic - Particle Tracker 2D/3D");
print("Radius = 5, Cutoff = 0, Per/Abs = 0.5000, Link Range = 1, Displacement = 50.00");
print("");
print("Mandatory: Click the button 'All Trajectories to Table'.");
print("Optionally: Inspect the results by visualizing the trajectories.");
print("");
print("Finally, run the macro Track_Cells_AnalyzeTracks");
print("-------------------------------");
	
setBatchMode("exit and display" );			
}

