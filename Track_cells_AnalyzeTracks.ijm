macro "Track_Cells_AnalyzeTracks" {
	/* 
	 *  This macro should be run after the Mosaic - Particle Tracker 2D/3D 
	 *  has been run. The results table with the centroids from the tracks
	 *  and the image "Outlines_Cells_RGB.tif" should be open.
	 *  Then the mean displacements for each track is calculated and added to the results. 
	 */
	 
		
	print("\\Clear");
	selectImage("Outlines_Cells_RGB.tif");
	run("RGB Color");
	getDimensions(width, height, channels, slices, frames);
	if (slices > frames){
		frames = slices; 
	} 
	Folder = getInfo("image.directory");
	
	MinFramesToFollow = getNumber("Minimum number of frames to follow cells? (default = total number of frames)", frames);
	NrCellsToFollow = getNumber("Number of fastest cells to display?", 20);
	for(j=0;j<nResults;j++){
		if (getResult("Frame",j)>0){
			//j=1;
			xdiff = getResult("x",j)-getResult("x",j-1); 
			ydiff = getResult("y",j)-getResult("y",j-1);
			squaredxdiff = pow(xdiff, 2);
			squaredydiff = pow(ydiff, 2);	
			disp = sqrt(squaredxdiff+squaredydiff);
			setResult("Disp", j, disp);
		}
	}

	TotalTrajNr = getResult("Trajectory",nResults-1);
	print("Number of total trajectories = " +TotalTrajNr);
	NrTrackFrames = newArray(TotalTrajNr); 
	MeanDisp = newArray(TotalTrajNr);
	//print(MeanDisp[6]);
	for(j=0;j<nResults;j++){
			TrajNr = getResult("Trajectory",j);
			MeanDisp[TrajNr-1] = MeanDisp[TrajNr-1] + getResult("Disp",j);
			NrTrackFrames[TrajNr-1] = NrTrackFrames[TrajNr-1] + 1;
			//if (NrTrackFrames == TotalTrajNr)
	}
	
	for (j=0;j<TotalTrajNr;j++){
		MeanDisp[j] = MeanDisp[j]/(NrTrackFrames[j]-1); //If the cell is followed during n tracks, it has moved n-1 times
		//TrajNr = j+1;
		//print("Track "+d2s(TrajNr,0)+":Followed through "+d2s(NrTrackFrames[j],0)+" frames. Mean displacement = "+ d2s(MeanDisp[j],2));
	}
	Array.getStatistics(NrTrackFrames, min, max, mean, stdDev);
	MaxTrackFrames = max;
	print("Total number of frames = "+frames+". Longest trajectory = "+MaxTrackFrames+" frames.");
	//Array.getStatistics(MeanDisp, min, max, mean, stdDev); 	
	//print(min, max, mean, stdDev); 
	
	/* Look for tracks that can be followed for almost all frames
	 * and put the track numbers in an array
	 */
	LongTracks = newArray(0);
	LongTracksMeanDisp = newArray(0);
	LongTracksNrFrames = newArray(0);
	count = 0;
	for(j=0;j<nResults;j++){ 
		track = getResult("Trajectory",j);
		//if (NrTrackFrames[track-1] == MaxTrackFrames){
		if (NrTrackFrames[track-1] >= MinFramesToFollow){
			ans = 1;
			for (i=0;i<lengthOf(LongTracks);i++){
				if (LongTracks[i] == track){
					ans = 0;
				}
			}
			if (ans){ 
				LongTracks = Array.concat(LongTracks,track);
				LongTracksMeanDisp = Array.concat(LongTracksMeanDisp, MeanDisp[track-1]);
				LongTracksNrFrames = Array.concat(LongTracksNrFrames, NrTrackFrames[track-1]);
				//print(" LongTracks["+count+"] = "+LongTracks[count]+"and LongTracksMeanDisp["+count+"] = "+LongTracksMeanDisp[count]);
				//count = count+1;
			}
		}
	}


	Array.getStatistics(LongTracksMeanDisp, min, max, mean, stdDev);
	MaxLongTracksMeanDisp = max;
	
	for (i=0;i<lengthOf(LongTracks);i++){
		if (LongTracksMeanDisp[i] == MaxLongTracksMeanDisp){
			LongestTrack = LongTracks[i];
		}
	}
	

	tempArray = Array.copy(LongTracksMeanDisp);
	Array.sort(tempArray);
	TrackCutOff = tempArray[lengthOf(tempArray)-NrCellsToFollow]; 
	//print("10th longest cell displacement = " +TrackCutOff);

	
	LongestTracks = newArray(0);
	LongestMeanDisp = newArray(0);
	LongestMeanDisp = newArray(0);
	NrFrames = newArray(0);
	for (j=1;j<=NrCellsToFollow;j++){
		for (i=0;i<lengthOf(LongTracksMeanDisp);i++){
			if (LongTracksMeanDisp[i] == tempArray[lengthOf(tempArray)-j]){
				LongestTracks = Array.concat(LongestTracks,LongTracks[i]);
				LongestMeanDisp = Array.concat(LongestMeanDisp, LongTracksMeanDisp[i]);
				NrFrames = Array.concat(NrFrames, LongTracksNrFrames[i]);
			}			
		}		
	}
	/*
	print("LongestTracks:");
	for (i=1;i<=NrCellsToFollow;i++){
		print(LongestTracks[lengthOf(LongestTracks)-i]);
	}
	print("LongestMeanDisp:");
	for (i=1;i<=NrCellsToFollow;i++){
		print(LongestMeanDisp[lengthOf(LongestMeanDisp)-i]);
	}
	*/
	
	print("Number of cells followed through all frames = " +lengthOf(LongTracks));
	//print("Length of LongTracksMeanDisp array = " +lengthOf(LongTracksMeanDisp));	
	print("Fastest cell (track nr " +LongestTrack+ ") has a mean displacement of " +max+ " pixels");

	/*for (j=0;j<5;j++){ 
		print("Track "+LongTracks[j]+" has mean displacement "+LongTracksMeanDisp[j]);
	}
	*/

	//Array.show("title", array1, array2, ...); To display arrays in a Results table which then can be saved
			
	
	setFont("Arial", 14, "bold");
	run("Colors...", "foreground=green background=black selection=yellow");
	for(j=0;j<nResults;j++){ 
		frame = getResult("Frame",j)+1;		
		track = getResult("Trajectory",j);
		setSlice(frame);
		y=round(getResult("x",j)); x=round(getResult("y",j));
		
		setColor(255, 255, 255);
		drawString(d2s(track,0), x, y); 
		if ((frame>1) && (NrTrackFrames[track-1] == MinFramesToFollow)){
			y2=round(getResult("x",j-1)); x2=round(getResult("y",j-1));			
			//run("Colors...", "foreground=green background=black selection=yellow");
			run("Line Width...", "line=2");
			makeLine(x, y, x2, y2, 2);
			run("Fill", "stack");
		}
		ans = 0;
		for (i=0;i<NrCellsToFollow;i++){
			if (track == LongestTracks[i]){
				ans = 1;
				Nr = i+1;		
			}
		}
		if (ans){
			setColor(255, 255, 255);
			string = d2s(track,0)+"("+Nr+"): MD = "+d2s(MeanDisp[track-1],2);
			if ((x<width-140) && (y<height-50)) drawString(string, x, y+20);
			if ((x<width-140) && (y>=height-50)) drawString(string, x, y-20);
			if ((x>=width-140) && (y<height-50)) drawString(string, x-130, y+20);
			if ((x>=width-140) && (y>=height-50)) drawString(string, x-130, y-20);
		}	
	}

	
	//IJ.renameResults("Results", "TrackingResults");
	selectImage("Outlines_Cells_RGB.tif");
	OutputPath = ""+Folder+"/TrackedCells.tif";
   	saveAs("tiff", OutputPath);

	saveAs("Results", Folder+"FullTrackingResults.csv");
	Array.show(LongestTracks, LongestMeanDisp, NrFrames); //saveAs med .csv funkar ej om man har gett ett namn till tabellen!!!
	selectWindow("Arrays"); //Needed on ScanR PC? 
	saveAs("Results",Folder+"TrackingResults_fastest.csv");

	//Folder = "/Users/maria_smedh/Documents/131022_EvaBom/MCF7_5000_003/data/Output/TrackingOutput_full/";
	Ind = indexOf(Folder, "TrackingOutput");
	path = substring(Folder, 0, Ind)+"TimeSeries_Trans.tif";
	print(path);
	if (File.exists(path)) {
		open(path);
		run("RGB Color");
		imageCalculator("Add stack", "TimeSeries_Trans.tif","TrackedCells.tif");
		saveAs("Tiff", Folder+ "TrackedCells_TransOverlay.tif");
	}
}
