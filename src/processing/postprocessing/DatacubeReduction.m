classdef DatacubeReduction < DataReduction
    properties (Constant)
        Name = 'Datacube';
        Description = '';
        
        ParameterDefinitions = [...
            ParameterDescription('Peak Tolerance (if < 0, detected peak width used)', ParameterType.Double, 0), ...
            ParameterDescription('Tolerance Unit', ParameterType.Selection, {'PPM', 'Spectrum Unit'}), ...
            ParameterDescription('Keep original pixel coordinates', ParameterType.Boolean, 1), ...
            ParameterDescription('Output', ParameterType.Selection, {'New Window', 'ImzML'}), ...
            ParameterDescription('Intensity Data Type', ParameterType.Selection, {'Double', 'Single', '64-Bit Integer', ...
            '32-Bit Integer', '16-Bit Integer', '8-Bit Integer'}), ...
            ParameterDescription('Storage Type (To ImzML Only)', ParameterType.Selection, {'Processed', 'Continuous'})];
    end
    
    properties
        peakTolerance;
        toleranceUnit;
        keepOriginalPixels;
        output;
        intensityDataType;
        storageType;
    end
    
    methods
        function obj = DatacubeReduction(peakTolerance, toleranceUnit, keepOriginalPixels, output, intensityDataType, storageType)
            obj.peakTolerance = peakTolerance;
            
            if nargin > 1
                obj.toleranceUnit = toleranceUnit;
            end
            
            if nargin > 2
                obj.keepOriginalPixels = keepOriginalPixels;
            else
                obj.keepOriginalPixels = 1;
            end
            
            if nargin > 3
                obj.output = output;
            else
                obj.output = 'New Window';
            end
            
            if nargin > 4
                obj.intensityDataType = intensityDataType;
                obj.storageType = storageType;
            end
        end
        
        function dataRepresentationList = process(this, dataRepresentation)
            if(strcmp(this.output, 'ImzML'))
                this.writeOutimzML(dataRepresentation);
                dataRepresentationList = DataRepresentationList();
            else
                if(isa(dataRepresentation.parser, 'SIMSParser') && isa(dataRepresentation, 'DataOnDisk'))
                    dataRepresentationList = this.processSIMSParser(dataRepresentation);
                else
                    dataRepresentationList = this.processOtherParser(dataRepresentation);
                end
            end
            
            this.dataRepresentationList = dataRepresentationList;
        end
        
        
        function resultsViewerList = displayResults(this, dataViewer)
            % displayResults is the callback function, called once
            % DatacubeReduction is complete. This creates a DataViewerList and
            % adds all newly created DataRepresentation to a DataViewer and
            % returns the DataViewerList.
        
            resultsViewerList = DataViewerList();
            
            for i = 1:this.dataRepresentationList.getSize()
                this.dataRepresentationList.get(i)
                resultsViewerList.add(DataViewer(this.dataRepresentationList.get(i)));
            end
        end
        
        function spectrum = getProcessedSpectrum(this, dataRepresentation, x, y)
            spectrum = getProcessedSpectrum@PostProcessing(this, dataRepresentation, x, y);
            
            if(~isempty(this.peakList))
                [centroids, peakWidths] = this.getPeakWidths();
                minValues = centroids - peakWidths./2;
                maxValues = centroids + peakWidths./2;
                
                intensities = zeros(1, length(this.peakList));
                
                for i = 1:length(this.peakList)
                    intensities(i) = sum(spectrum.intensities(spectrum.spectralChannels >= minValues(i) & spectrum.spectralChannels <= maxValues(i)));
                end
                
                spectrum = SpectralData(centroids, intensities);
            end
        end
    end
    
    methods (Access = private)
        function [centroids, peakWidths] = getPeakWidths(this)
            peakWidths = [this.peakList.maxSpectralChannel] - [this.peakList.minSpectralChannel];
            centroids = [this.peakList.minSpectralChannel] + peakWidths./2;
            
            if(this.peakTolerance > 0)
                if(strcmpi(this.toleranceUnit, 'PPM'))
                    peakWidths = (centroids .* this.peakTolerance) / 1e6;
                else
                    peakWidths = ones(size(centroids)) .* this.peakTolerance;
                end
            end
        end
        
        
        
        function dataRepresentationList = processSIMSParser(this, dataRepresentation)
            if(~strcmp(this.output, 'New Window'))
                exception = MException('DatacubeReduction:InvalidArgument', 'Data must originally be imzML to export to imzML');
                throw(exception);
            end
            
            if(this.preprocessEverySpectrum)
                msgbox('Warning: No preprocessing is applied when reducing a SIMS dataset to a datacube');
            end
            
            rois = this.regionOfInterestList.getObjects();
            
            [centroids, peakWidths] = this.getPeakWidths();
            
            images = dataRepresentation.parser.simsParser.generateImages(centroids, peakWidths);
            
            assignin('base', 'imagesGeneratedFromJSIMS', images);
            s
            %             images = dataRepresentation.parser.getImages(centroids, peakWidths);
            
            imageData = zeros(numel(images(1).getImage()), length(images));
            
            for i = 1:length(images)
                image = images(i).getImage()';
                
                imageData(:, i) = image(:);
            end
            
            this.peakList = this.peakDetails(:, 2);
            data{1} = imageData;
            pixelLists{1} = this.getPixelListToProcess(dataRepresentation);
            
            dataRepresentationList = generateDataRepresentationList(this, dataRepresentation, this.peakList, data, rois);
        end
        
        function dataRepresentationList = generateDataRepresentationList(this, dataRepresentation, centroids, data, rois)
            % TODO: Pass peak list to DataRepresentation to keep track of
            % the limits used to generate the data
            %centroids = [peakList.centroid];
            
            dataRepresentationList = DataRepresentationList();
            
            for i = 1:numel(data)
                dataInMemory = DataInMemory();
                
                if(~dataRepresentation.isContinuous || (~isempty(this.preprocessingWorkflow) && this.preprocessingWorkflow.containsPeakPicking()) ...
                        || ~isempty(centroids))
                    dataInMemory.setIsContinuous(false);
                end
                
                if(this.processEntireDataset && i == 1)
                    dataInMemory.setData(data{i}, dataRepresentation.regionOfInterest, ...
                        dataRepresentation.isRowMajor, centroids, [dataRepresentation.name ' (Processed)']);
                else
                    if(this.processEntireDataset)
                        roi = rois{i-1};
                    else
                        roi = rois{i};
                    end
                    
                    if ~this.keepOriginalPixels
                        newROIPixels = roi.pixelSelection;
                        newROIPixels(sum(newROIPixels, 2) == 0, :) = [];
                        newROIPixels(:, sum(newROIPixels, 1) == 0) = [];
                        
                        newROI = RegionOfInterest(size(newROIPixels, 2), size(newROIPixels, 1));
                        newROI.addPixels(newROIPixels);
                        newROI.setName(roi.getName());
                        roi = newROI;
                    end
                    
                    dataInMemory.setData(data{i}, roi, dataRepresentation.isRowMajor, centroids, roi.getName());
                end
                
                dataInMemory.setParser(dataRepresentation.parser);
                
                dataRepresentationList.add(dataInMemory);
            end
        end
        
        
        function dataRepresentationList = processOtherParser(this, dataRepresentation)
            pixels = this.getPixelListToProcess(dataRepresentation);
            rois = this.regionOfInterestList.getObjects();
            
            % Set up the memory required
            data = {};
            pixelLists = {};
            
            canUseFastMethods = 0;
            preprocessingWorkflow = this.preprocessingWorkflow;
            
            if(isa(dataRepresentation.parser, 'ImzMLParser'))
                if(this.preprocessEverySpectrum)
                    workflow = generateFastPreprocessingWorkflow(preprocessingWorkflow);
                else
                    workflow = generateFastPreprocessingWorkflow([]);
                end
                
                if(isempty(preprocessingWorkflow) || ~isempty(workflow))
                    canUseFastMethods = 1;
                end
            end
            
            % Notify listeners whether we are using FastMethods or not
            notify(this, 'FastMethods', BooleanEventData(canUseFastMethods));
            
            % If no peak list has been selected, and no preprocessing is...
            %             if(isempty(this.peakList) && (isempty(preprocessingWorkflow) || ~isempty(workflow)))
            %                 pixels = this.getPixelListToProcess(dataRepresentation);
            %
            %                 firstPixel = pixels(1, :);
            %                 preprocessedSpectrum = this.getProcessedSpectrum(dataRepresentation, firstPixel(1), firstPixel(2));
            %
            %                 %                 channelSize = length(spectrum.spectralChannels);
            %                 this.peakList = preprocessedSpectrum.spectralChannels;
            %             end
            
            %             canUseFastMethods = 0;
            
            % TODO: this.peakList vs this.peakDetails - which is used and
            % why?
            
            if(canUseFastMethods && strcmp(this.output, 'New Window') && isa(dataRepresentation, 'DataOnDisk') && ~isempty(this.peakList))
                ped = ProgressEventData(0, ['Using fast methods. Generating ' num2str(length(this.peakList)) ' image(s)']);
                notify(this, 'ProcessingProgress', ped);
                
                try
                    % Generate the peak list using the JSpectralAnalysis methods,
                    % otherwise small numerical errors cause different
                    % results and prevent the zero filling from working
                    % correctly
                    if(isempty(this.peakList))
                        s = dataRepresentation.getSpectrum(pixels(1, 1), pixels(1, 2));
                        spectrum = com.alanmrace.JSpectralAnalysis.Spectrum(s.spectralChannels, s.intensities);
                        
                        if(this.preprocessEverySpectrum)
                            spectrum = workflow.process(spectrum);
                        end
                        
                        this.peakList = spectrum.getSpectralChannels();
                    end
                    
                    % Determine peak limits based on supplied options
                    [centroids, peakWidths] = this.getPeakWidths();
                    
                    imageGeneration = com.alanmrace.JSpectralAnalysis.MultithreadedDatacubeGeneration(dataRepresentation.parser.imzML);
                    
                    % Generate the datacube
                    imageGeneration.generateDatacube(dataRepresentation.parser.imzML, workflow, centroids, peakWidths, pixels);
                    
                    while(~imageGeneration.isDone())
                        ped = ProgressEventData(imageGeneration.getProgress(), ['Using fast methods. Generating ' num2str(length(this.peakList)) ' image(s)']);
                        notify(this, 'ProcessingProgress', ped);
                        
                        pause(0.05);
                    end
                    
                    % Get the images from the ImageGeneration Java class 
                    images = imageGeneration.getDatacube();
                    
                    if(isempty(data))
                        if(this.processEntireDataset)
                            data{end+1} = zeros(size(pixels, 1), length(this.peakList));
                            pixelLists{end+1} = pixels;
                        end
                        
                        for roiIndex = 1:numel(rois)
                            pixelLists{end+1} = rois{roiIndex}.getPixelList();
                            data{end+1} = zeros(size(pixelLists{end}, 1), length(this.peakList));
                        end
                    end
                    
                    for pixelListIndex = 1:numel(pixelLists)
                        [pixel, row, col] = intersect(pixelLists{pixelListIndex}, pixels, 'rows');
                        
                        if(~isempty(row))
                            data{pixelListIndex}(row, :) = images(col, :);
                        end
                    end
                catch err
                    errBox = errordlg(err.message, err.identifier);
                    
                    rethrow(err);
                end
                
                ped = ProgressEventData(1, ['Generated ' num2str(length(this.peakList)) ' image(s)']);
                notify(this, 'ProcessingProgress', ped);
                
                centroids = preprocessedSpectrum.spectralChannels;
            else
                if(strcmp(this.output, 'New Window'))
                    pixels = this.getPixelListToProcess(dataRepresentation);
                    
                    dataSize = length(this.peakList);
                    
                    if(isempty(this.peakList))
                        
                        firstPixel = pixels(1, :);
                        preprocessedSpectrum = this.getProcessedSpectrum(dataRepresentation, firstPixel(1), firstPixel(2));
                        
                        
                        dataSize = length(preprocessedSpectrum.spectralChannels);
                    end
                    
                    for i = 1:size(pixels, 1)
                        spectrum = this.getProcessedSpectrum(dataRepresentation, pixels(i, 1), pixels(i, 2));
                        
                        if(isempty(spectrum.intensities))
                            continue;
                        end
                        
                        processDescription = 'Generating data';
                        
                        % Create the data based on the first spectrum acquired
                        if(isempty(data))
                            if(this.processEntireDataset)
                                data{end+1} = zeros(size(pixels, 1), dataSize);
                                pixelLists{end+1} = pixels;
                            end
                            
                            for roiIndex = 1:numel(rois)
                                pixelLists{end+1} = rois{roiIndex}.getPixelList();
                                data{end+1} = zeros(size(pixelLists{end}, 1), dataSize);
                            end
                        end
                        
                        for pixelListIndex = 1:numel(pixelLists)
                            [pixel, row, col] = intersect(pixelLists{pixelListIndex}, pixels(i, :), 'rows');
                            
                            if(~isempty(row))
                                data{pixelListIndex}(row, :) = spectrum.intensities;
                            end
                        end
                        
                        progressEvent = ProgressEventData(i / size(pixels, 1), processDescription);
                        notify(this, 'ProcessingProgress', progressEvent);
                    end
                    
                    if(isempty(this.peakList))                        
                        centroids = preprocessedSpectrum.spectralChannels;
                    else
                        centroids = [peakList.centroid];
                    end
                    
                end
                
            end
            
            dataRepresentationList = generateDataRepresentationList(this, dataRepresentation, centroids, data, rois);
        end
        
        function writeOutimzML(this, dataRepresentation)
            processDescription = 'Writing imzML';
            
            % Variables used to store details of any imzML files written
            % out so that resources can be tidied up
            imzMLList = {};
            ibdFileIDs = [];
            ibdFileNames = {};
            
            pixelLists = {};
            
            pixels = this.getPixelListToProcess(dataRepresentation);
            rois = this.regionOfInterestList.getObjects();
            
            writtenOutmzList = false;
            
            oldImzML = dataRepresentation.parser.imzML;
            
            for i = 1:size(pixels, 1)
                % Prompt user for file names
                if(isempty(imzMLList))
                    prompt = {};
                    defaults = {};
                    
                    imzMLParser = dataRepresentation.parser;
                    
                    if(~isa(imzMLParser, 'ImzMLParser'))
                        exception = MException('DatacubeReduction:InvalidArgument', 'Data must originally be imzML to export to imzML');
                        throw(exception);
                    end
                    
                    [filePath fileName ext] = fileparts(dataRepresentation.parser.filename);
                    
                    if(this.processEntireDataset)
                        prompt{end+1} = 'Entire dataset';
                        defaults{end+1} = [filePath filesep fileName '_Processed.imzML'];
                        pixelLists{end+1} = pixels;
                    end
                    for roiIndex = 1:numel(rois)
                        prompt{end+1} = rois{roiIndex}.getName();
                        defaults{end+1} = [filePath filesep fileName '_' rois{roiIndex}.getName() '.imzML'];
                        pixelLists{end+1} = rois{roiIndex}.getPixelList();
                    end
                    
                    filenameList = inputdlg(prompt, 'Please supply filenames for imzML output', 1, defaults);
                    
                    for fileIndex = 1:numel(filenameList)
                        newImzML = com.alanmrace.jimzmlparser.imzml.ImzML(oldImzML);
                        newImzML.getSpectrumList().clear();
                        
                        imzMLList{fileIndex} = newImzML;
                    end
                end
                
                spectrum = this.getProcessedSpectrum(dataRepresentation, pixels(i, 1), pixels(i, 2));
                
                if(isempty(spectrum.intensities))
                    continue;
                end
                
                % TODO: When outputting imzML add in a userParam with
                % the peak list/spectral channels for the entire data
                % set so that when loading into memory can use this
                % information without it needing to be processed
                
                
                mzMLSpectrum = oldImzML.getSpectrum(pixels(i, 1), pixels(i, 2));
                
                if(isempty(mzMLSpectrum))
                    continue;
                end
                
                
                for pixelListIndex = 1:numel(pixelLists)
                    [pixel, row, col] = intersect(pixelLists{pixelListIndex}, pixels(i, :), 'rows');
                    
                    % TODO move this outside of the loop
                    minX = min(pixels(:, 1));
                    minY = min(pixels(:, 2));
                    
                    if(~isempty(row))
                        curImzML = imzMLList{pixelListIndex};
                        
                        newSpectrum = com.alanmrace.jimzmlparser.mzml.Spectrum(oldImzML.getSpectrum(pixel(1), pixel(2)), curImzML);
                        
                        if ~this.keepOriginalPixels
                            newSpectrum.setPixelLocation(pixel(1) - minX + 1, pixel(2) - minY + 1);
                        else
                            newSpectrum.setPixelLocation(pixel(1), pixel(2));
                        end
                        
                        newSpectrum.updateSpectralData(spectrum.spectralChannels, spectrum.intensities, com.alanmrace.jimzmlparser.mzml.DataProcessing.create());
                        
                        curImzML.getRun().getSpectrumList().addSpectrum(newSpectrum);
                        
                    end
                end
                
                ped = ProgressEventData(i/size(pixels, 1), ['Processing imzML spectra']);
                notify(this, 'ProcessingProgress', ped);
            end
            
            if(~isempty(imzMLList))
                for i = 1:numel(imzMLList)
                    curImzML = imzMLList{i};
                    
                    writer = com.alanmrace.jimzmlparser.writer.ImzMLWriter();
                    
                    writer.write(curImzML, filenameList{i});
                end
            end
        end
    end
end