macro "CombineScanR" {
	/* This macro combines tiled images from the ScanR microscope.
	 * The result is an image stack, which is reduced substantionally in size. 
	 * 
	 * 
	 * Maria Smedh 130913-130919
	 */

	run("Close All");
	print("\\Clear");
	setBatchMode(true);
	
	Folder = getDirectory("Choose the folder where your images are located");
	OutputFolderName = "OutputTest";
	//Output_Folder = Folder + "/" + OutputFolderName;
	Output_Folder = Folder +File.separator+ OutputFolderName;
	print(Output_Folder);
	File.makeDirectory(Output_Folder); //Seems only to be done if folder does not exist, no overwriting
	File.makeDirectory(Output_Folder + File.separator+"Temp");
	ChType = getString("Which channel was used (DAPI, FITC, TxRed, Cy5 or Trans)? ","DAPI");
	
	/* The file names have this type of syntax:
	 *  A1--W00001--P00001--Z00000--T00000--ChType.tif
	 *  Find out about how many images there are in the folder, and if it is a multi well scan,
	* a Z stack, and/or a time series. 
	 */

	Files = getFileList(Folder);
	NrOfFiles = Files.length;
	print("There are "+NrOfFiles+" files in the folder");
	NrOfImages = 0;
	MaxPos = 0;
	MaxZ = 0;
	MaxT = 0;
	//If normalization to the full dynamic range of the ScanR 12 bit images (saved as 16 bit):
	//Uncomment row 110, and comment rows 100-109!
	minInt = 32768;
	maxInt = 36864;
	FirstFileName = "";

	//-------------------------
	// Find the indexes for time, position and z-layer in the file names
	for (i=0; i<NrOfFiles; i++) {
		//print("Loopindex i = "+i);
		if (endsWith(Files[i], ""+ChType+".tif")){
			if (lengthOf(FirstFileName)==0){
				FirstFileName = Files[i];
				print(FirstFileName);
			}
			NrOfImages = NrOfImages + 1;
			PosInd = indexOf(Files[i], "P000");
			//print("Index is "+PosInd);
			//CompStr = substring(Files[i], PosInd, PosInd+6);
			//print("Comp string is "+CompStr);			
			Position = parseInt(substring(Files[i], PosInd+3, PosInd+6));
			if (Position > MaxPos){
				MaxPos = Position;
			}
			//print("Position is "+Position);			
			ZInd = indexOf(Files[i], "Z000");
			Zlayer = parseInt(substring(Files[i], ZInd+3, ZInd+6));
			if (Zlayer > MaxZ){
				MaxZ = Zlayer;
			}
			//CompStr2 = substring(Files[i], ZInd, ZInd+6);
			//print("Z layer is "+Zlayer);
			/*TInd = indexOf(Files[i], "T000");
			Tpoint = parseInt(substring(Files[i], TInd+3, TInd+6));
			File.makeDirectory(Output_Folder+File.separator+"Temp"+File.separator+"TimePoint"+MaxT);
			if (Tpoint > MaxT){
				MaxT = Tpoint;
			}

			open(Folder+Files[i]);
   			if (ChType == "Trans"){
   				setMinAndMax(minInt,maxInt);
   			}else{
	   			run("Subtract Background...", "rolling=200");
	   			getMinAndMax(min, max);
	   			setMinAndMax(min,max);
   			}*/
   			
   			//setMinAndMax(minInt,maxInt);
   			/*run("8-bit");
			run("Size...", "width=672 height=512 constrain average interpolation=Bilinear");
			saveAs("Tiff", Output_Folder + File.separator+"Temp"+File.separator+"TimePoint"+Tpoint+File.separator+Files[i]);
			close();*/
			//CompStr3 = substring(Files[i], TInd, TInd+6);
			//print("Time point is "+Tpoint);
		//if (matches(Files[i],"P00001")){
			//print(Files[i]);
		//}
		}
   	}
   	print("There are "+NrOfImages+" "+ChType+" images in the folder");
   	print("Position index nr is "+PosInd);
   	print("Max position nr is "+MaxPos);
   	print("Z index nr is "+ZInd);
   	print("Max Z layer is "+MaxZ);
   	print("T index nr is "+TInd);
   	print("Max time point is "+MaxT); 
	//------------------------- 
	
	/*for (k=0; k<MaxT+1; k++) {
		File.makeDirectory(Output_Folder + File.separator+"Temp"+File.separator+"TimePoint" +k);
	}

	//-------------------------------------------------
   	// Resize images:*/
   	//
   	for (i=0; i<NrOfFiles; i++) {   		
   		if (endsWith(Files[i], ""+ChType+".tif")){   			
   			//TInd = indexOf(Files[i], "T000");
			Tpoint = parseInt(substring(Files[i], TInd+3, TInd+6));
   			open(Folder+Files[i]);
   			if (ChType == "Trans"){
   				setMinAndMax(minInt,maxInt);
   			}else{
	   			run("Subtract Background...", "rolling=200");
	   			getMinAndMax(min, max);
	   			setMinAndMax(min,max);
   			}
   			
   			//setMinAndMax(minInt,maxInt);
   			run("8-bit");
			run("Size...", "width=672 height=512 constrain average interpolation=Bilinear");
			saveAs("Tiff", Output_Folder + File.separator+"Temp"+File.separator+"TimePoint"+Tpoint+File.separator+Files[i]);
			close();
		}   		
   	}
   	//-------------------------------------------------
   	// Call the "Grid/Collection stitching" plugin:
   	//
   	TileType = getString("Which type of tile order was used? Center = c, Meander = m or unidirectional = u","m");
		if (TileType == "c") {
			exit("The Grid/Collection stitching plugin does not support centered tile order");		
		} else {
		if (TileType == "m") {
			TileType = "[Grid: snake by columns] order=[Down & Right                ]";
		} else {
		if (TileType == "u") {
			TileType = "[Grid: column-by-column] order=[Down & Right                ]";
		} else {
		if (TileType!="c") && (TileType!="m") && (TileType!="u"){
			error("The tile order was not recognized");
			//print("The tile order was not recognized");
			//RunStitchingPlugin(MaxT, Folder, Output_Folder);				
			}}}			
		}
	//MaxPos = 16;	
	num = round(sqrt(MaxPos));
	Xnr = getNumber("Number of image columns?", num);	
	Ynr = getNumber("Number of image rows?", num);
	
	//RunStitchingPlugin(MaxT, Folder, Output_Folder);
	//function RunStitchingPlugin(MaxT, Folder, Output_Folder) {	
	for (i=0; i<MaxT+1; i++) { 
		TempFolder = Output_Folder + File.separator+"Temp"+File.separator+"TimePoint"+i+File.separator;	
		if (i<10){
			Tpoint ="0"+i;		
		}else{
			Tpoint =i;
		}
		print("Prepare for Stitching: TimePoint = "+Tpoint);
		FileName = FirstFileName; 
		//FileName = "A1--W00001--P00006--Z00000--T00001--DAPI.tif";
		//TInd = 28;
		//Tpoint = "00";
		ChangeString = substring(FileName, TInd+4, TInd+6);
		//print("ChangeString = "+ChangeString);
		ChangeString = "T000"+ChangeString;
		//print("ChangeString = "+ChangeString);
		NewString = "T000"+Tpoint;
		FileName = replace(FileName, ChangeString, NewString);
		print("FileName = "+FileName);
		FileName2 = substring(FileName, 0, PosInd)+"P000{ii}"+substring(FileName, PosInd+6);
		print("Filenames for Stitching ="+FileName2);	
			
		run("Grid/Collection stitching", "type="+TileType+" grid_size_x="+Xnr+" grid_size_y="+Ynr+" tile_overlap=0 first_file_index_i=1 directory="+TempFolder+" file_names="+FileName2+" output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save memory (but be slower)] image_output=[Write to disk] output_directory="+TempFolder+" use");
		//TempFolder="/Users/maria_smedh/Documents/Work/Images/ScanR/EvaBom_MCF7_dish1_5000cells_010_time1and2and3/Output/Temp/TimePoint2/";
		File.rename(TempFolder +"img_t1_z1_c1", TempFolder +"TiledImage_T"+i+"_"+ChType+".tif");
		//File.delete(TempFolder +"img_t1_z1_c1");
		//Output_Folder = "/Volumes/maria/FluoTiles_131021/BPAEcells_003/data/Output";
		TempFolder = Output_Folder +File.separator+ "Temp"+File.separator+"TimePoint"+i+File.separator;
		//print(TempFolder);
		open(TempFolder +"TiledImage_T"+i+"_"+ChType+".tif");
	}
		
	//-------------------------------------------------
   	// Make a stack from the tiled images:
   	//
   	/*for (i=0; i<MaxT+1; i++) { 
   		//Output_Folder = "/Volumes/maria/FluoTiles_131021/BPAEcells_003/data/Output";
		TempFolder = Output_Folder +File.separator+ "Temp"+File.separator+"TimePoint"+i+File.separator;
		//print(TempFolder);
		open(TempFolder +"TiledImage_T"+i+"_"+ChType+".tif");
	}*/
   	run("Images to Stack", "name=TimeSeries title=[] use");
   	run("8-bit");
   	getMinAndMax(min, max);
   	//print(min,max);
   	setMinAndMax(min, max);
   	saveAs("Tiff", Output_Folder +"/TimeSeries_"+ChType+".tif");
   	//File.delete(Output_Folder + "/Temp/"); //Only works if directory is empty :-(, need to delete manually...
   	setBatchMode("exit and display" );			
}