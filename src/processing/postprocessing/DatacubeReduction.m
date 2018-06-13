classdef DatacubeReduction < DataReduction
    properties (Constant)
        Name = 'Datacube';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Image Generation', ParameterType.Selection, {'Extract at location', 'Integrate over peak'}), ...
            ParameterDescription('Output', ParameterType.Selection, {'New Window', 'ImzML'}), ...
            ParameterDescription('Intensity Data Type', ParameterType.Selection, {'Double', 'Single', '64-Bit Integer', ...
            '32-Bit Integer', '16-Bit Integer', '8-Bit Integer'}), ...
            ParameterDescription('Storage Type (To ImzML Only)', ParameterType.Selection, {'Processed', 'Continuous'})];
    end
    
    properties
        imageGeneration;
        output;
        intensityDataType;
        storageType;
    end
    
    methods
        function obj = DatacubeReduction(imageGeneration, output, intensityDataType, storageType)
            obj.imageGeneration = imageGeneration;
            obj.output = output;
            obj.intensityDataType = intensityDataType;
            
            switch(obj.imageGeneration)
                case 'Extract at location'
                    obj.setExtractAtLocation()
                case 'Integrate over peak'
                    obj.setIntegrateOverPeak()
            end
            
            obj.storageType = storageType;
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
        end
    end
    
    methods (Access = private)
        function dataRepresentationList = processSIMSParser(this, dataRepresentation)
            if(~strcmp(this.output, 'New Window'))
                exception = MException('DatacubeReduction:InvalidArgument', 'Data must originally be imzML to export to imzML');
                throw(exception);
            end
            
            if(this.preprocessEverySpectrum)
                msgbox('Warning: No preprocessing is applied when reducing a SIMS dataset to a datacube');
            end
            
            rois = this.regionOfInterestList.getObjects();
            
            peakWidths = this.peakDetails(:, 3) - this.peakDetails(:, 1);
            centroids = this.peakDetails(:, 1) + peakWidths ./ 2;
            
            images = dataRepresentation.parser.simsParser.generateImages(centroids, peakWidths);
            
            assignin('base', 'imagesGeneratedFromJSIMS', images);
            
%             images = dataRepresentation.parser.getImages(centroids, peakWidths);
            
            imageData = zeros(numel(images(1).getImage()), length(images));
            
            for i = 1:length(images)
                image = images(i).getImage()';
                
                imageData(:, i) = image(:);
            end
            
            peakList = this.peakDetails(:, 2);
            data{1} = imageData;
            pixelLists{1} = this.getPixelListToProcess(dataRepresentation);
            
            dataRepresentationList = generateDataRepresentationList(this, dataRepresentation, peakList, data, rois);
        end
        
        function dataRepresentationList = generateDataRepresentationList(this, dataRepresentation, peakList, data, rois)
            dataRepresentationList = DataRepresentationList();
            
            for i = 1:numel(data)
                dataInMemory = DataInMemory();
                
                if(~dataRepresentation.isContinuous || (~isempty(this.preprocessingWorkflow) && this.preprocessingWorkflow.containsPeakPicking()) ...
                        || ~isempty(this.peakDetails))
                    dataInMemory.setIsContinuous(false);
                end
                
                if(this.processEntireDataset && i == 1)
                    dataInMemory.setData(data{i}, dataRepresentation.regionOfInterest, ...
                        dataRepresentation.isRowMajor, peakList, [dataRepresentation.name ' (Processed)']);
                elseif(this.processEntireDataset)
                    dataInMemory.setData(data{i}, rois{i-1}, dataRepresentation.isRowMajor, peakList, rois{i-1}.getName());
                else
                    dataInMemory.setData(data{i}, rois{i}, dataRepresentation.isRowMajor, peakList, rois{i}.getName());
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
            
            size(pixels)
            
            channelSize = length(this.peakList);
            peakList = this.peakList;
            
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
            
            if(canUseFastMethods && strcmp(this.output, 'New Window') && isa(dataRepresentation, 'DataOnDisk'))
                
                ped = ProgressEventData(0, ['Using fast methods. Generating ' num2str(length(this.peakList)) ' image(s)']);
                notify(this, 'ProcessingProgress', ped);
                
                try
                    peakList = this.peakList;
                    
                    % Generate the peak list using the JSpectralAnalysis methods,
                    % otherwise small numerical errors cause different
                    % results and prevent the zero filling from working
                    % correctly
                    if(isempty(peakList))
                        s = dataRepresentation.getSpectrum(pixels(1, 1), pixels(1, 2));
                        spectrum = com.alanmrace.JSpectralAnalysis.Spectrum(s.spectralChannels, s.intensities);
                        
                        if(this.preprocessEverySpectrum)
                            spectrum = workflow.process(spectrum);
                        end
                        
                        peakList = spectrum.getSpectralChannels();
                        this.peakList = peakList;
                    end
                    
                    if(this.imageGenerationMethod == 0)
                        imageGeneration = com.alanmrace.JSpectralAnalysis.MultithreadedDatacubeGeneration();
                        imageGeneration.generateDatacube(dataRepresentation.parser.imzML, workflow, peakList, pixels);
                    elseif(this.imageGenerationMethod == 1)
                        peakWidths = this.peakDetails(:, 3) - this.peakDetails(:, 1);
                        centroids = this.peakDetails(:, 1) + peakWidths ./ 2;
                        
%                         imageGeneration = com.alanmrace.JSpectralAnalysis.MultithreadedImageGeneration();
                        imageGeneration = com.alanmrace.JSpectralAnalysis.MultithreadedDatacubeGeneration();
                        
                        imageGeneration.generateDatacube(dataRepresentation.parser.imzML, workflow, centroids, peakWidths, pixels);
                    end
                    
                    while(~imageGeneration.isDone())
                        ped = ProgressEventData(imageGeneration.getProgress(), ['Using fast methods. Generating ' num2str(length(peakList)) ' image(s)']);
                        notify(this, 'ProcessingProgress', ped);
                        
                        pause(0.05);
                    end
                    
                    if(this.imageGenerationMethod == 0)
                        images = imageGeneration.getDatacube();
                    elseif(this.imageGenerationMethod == 1)
                        images = imageGeneration.getDatacube();
%                         images = imageGeneration.getImageList();
%                         images = permute(images, [2 1 3]);
%                         images = reshape(images, size(images, 1)*size(images, 2), []);
                    end
                    %
                    data{1} = images;
                    %                         peakList = this.peakList;
                catch err
                    errBox = errordlg(err.message, err.identifier);
                    
                    rethrow(err);
                end
                
                ped = ProgressEventData(1, ['Generated ' num2str(length(this.peakList)) ' image(s)']);
                notify(this, 'ProcessingProgress', ped);
                
            else
                if(strcmp(this.output, 'New Window'))
                    pixels = this.getPixelListToProcess(dataRepresentation);
                    
                    if(isempty(this.peakList))

                        firstPixel = pixels(1, :);
                        preprocessedSpectrum = this.getProcessedSpectrum(dataRepresentation, firstPixel(1), firstPixel(2));

                        
                        this.peakList = preprocessedSpectrum.spectralChannels;
                        channelSize = length(this.peakList);
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
                                data{end+1} = zeros(size(pixels, 1), channelSize);
                                pixelLists{end+1} = pixels;
                            end
                            
                            for roiIndex = 1:numel(rois)
                                pixelLists{end+1} = rois{roiIndex}.getPixelList();
                                data{end+1} = zeros(size(pixelLists{end}, 1), channelSize);
                            end
                        end
                        
                        for pixelListIndex = 1:numel(pixelLists)
                            [pixel, row, col] = intersect(pixelLists{pixelListIndex}, pixels(i, :), 'rows');
                            
                            if(~isempty(row))
%                                 size(data{1})
%                                 size(spectrum.intensities)
                                data{pixelListIndex}(row, :) = spectrum.intensities;
                            end
                        end
                        
                        progressEvent = ProgressEventData(i / size(pixels, 1), processDescription);
                        notify(this, 'ProcessingProgress', progressEvent);
                    end

                end
                
            end
            
            dataRepresentationList = generateDataRepresentationList(this, dataRepresentation, this.peakList, data, rois);
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
%                         newImzML.getRun().setSpectrumList(com.alanmrace.jimzmlparser.mzml.SpectrumList(0, newImzML.getRun().getSpectrumList().getDefaultDataProcessingRef()));
%                         newImzML.getRun().setChromatogramList(com.alanmrace.jimzmlparser.mzml.ChromatogramList(0, newImzML.getRun().getSpectrumList().getDefaultDataProcessingRef()));
%                         
%                         rpgmzArray = newImzML.getReferenceableParamGroupList().getReferenceableParamGroup('mzArray');
%                         rpgintensityArray = newImzML.getReferenceableParamGroupList().getReferenceableParamGroup('intensityArray');
%                         
%                         if(isempty(rpgintensityArray))
%                             rpgintensityArray = newImzML.getReferenceableParamGroupList().getReferenceableParamGroup('intensities');
%                         end
%                         
%                         % Ensure that everything is set to be stored as
%                         % double precision
%                         rpgmzArray.removeChildOfCVParam(com.alanmrace.jimzmlparser.mzml.BinaryDataArray.dataTypeID);
%                         rpgmzArray.addCVParam(com.alanmrace.jimzmlparser.mzml.EmptyCVParam(oldImzML.getOBO().getTerm(com.alanmrace.jimzmlparser.mzml.BinaryDataArray.doublePrecisionID)));
%                         
%                         rpgintensityArray.removeChildOfCVParam(com.alanmrace.jimzmlparser.mzml.BinaryDataArray.dataTypeID);
%                         
%                         % 'Double', 'Single', '64-Bit Integer', '32-Bit Integer', 
%                         % '16-Bit Integer', '8-Bit Integer'
%                         cvParam = [];
%                         
%                         switch(this.intensityDataType)
%                             case 'Double'
%                                 cvParam = com.alanmrace.jimzmlparser.mzml.BinaryDataArray.doublePrecisionID;
%                             case 'Single'
%                                 cvParam = com.alanmrace.jimzmlparser.mzml.BinaryDataArray.singlePrecisionID;
%                             case '64-Bit Integer'
%                                 cvParam = com.alanmrace.jimzmlparser.mzml.BinaryDataArray.signed64bitIntegerID;
%                             case '32-Bit Integer'
%                                 cvParam = com.alanmrace.jimzmlparser.mzml.BinaryDataArray.signed32bitIntegerID;
%                             case '16-Bit Integer'
%                                 cvParam = com.alanmrace.jimzmlparser.mzml.BinaryDataArray.signed16bitIntegerID;
%                             case '8-Bit Integer'
%                                 cvParam = com.alanmrace.jimzmlparser.mzml.BinaryDataArray.signed8bitIntegerID;
%                             otherwise
%                                 exception = MException('DatacubeReduction:InvalidArgument', ['Invalid intensity data type provided: ' this.intensityDataType]);
%                                 throw(exception);
%                         end
%                         
%                         rpgintensityArray.addCVParam(com.alanmrace.jimzmlparser.mzml.EmptyCVParam(oldImzML.getOBO().getTerm(cvParam)));
%                         
%                         % Remove any compression
%                         rpgmzArray.removeChildOfCVParam(com.alanmrace.jimzmlparser.mzml.BinaryDataArray.compressionTypeID);
%                         rpgintensityArray.removeChildOfCVParam(com.alanmrace.jimzmlparser.mzml.BinaryDataArray.compressionTypeID);
%                         
%                         % Ensure that it is stored as no compression
%                         rpgmzArray.addCVParam(com.alanmrace.jimzmlparser.mzml.EmptyCVParam(oldImzML.getOBO().getTerm(com.alanmrace.jimzmlparser.mzml.BinaryDataArray.noCompressionID)));
%                         rpgintensityArray.addCVParam(com.alanmrace.jimzmlparser.mzml.EmptyCVParam(oldImzML.getOBO().getTerm(com.alanmrace.jimzmlparser.mzml.BinaryDataArray.noCompressionID)));
%                         
%                         % TODO: Add in SpectralAnalysis software and
%                         % any preprocessing performed
%                         
                        % TODO: Add in UUID
                        
                        imzMLList{fileIndex} = newImzML;
%                         [ibdPath ibdFilename ext] = fileparts(filenameList{fileIndex});
%                         
%                         ibdFileNames{fileIndex} = [ibdPath filesep ibdFilename '.ibd'];
%                         ibdFileIDs(fileIndex) = fopen(ibdFileNames{fileIndex}, 'w');
%                         
%                         % Create UUID and write it out
%                         uuid = java.util.UUID.randomUUID();
%                         bytesToWrite = com.alanmrace.jimzmlparser.util.UUIDHelper.uuidToByteArray(uuid);
%                         fwrite(ibdFileIDs(fileIndex), bytesToWrite, 'int8', 'ieee-be');
%                         
%                         uuid = strrep(char(uuid), '-', '')
%                         
%                         % Add UUID to the imzML
%                         newImzML.getFileDescription().getFileContent().removeChildOfCVParam('IMS:1000080');
%                         newImzML.getFileDescription().getFileContent().addCVParam(com.alanmrace.jimzmlparser.mzml.StringCVParam(oldImzML.getOBO().getTerm('IMS:1000080'), uuid));
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
                        newSpectrum.setPixelLocation(pixel(1) - minX + 1, pixel(2) - minY + 1);
                        curImzML.getRun().getSpectrumList().addSpectrum(newSpectrum);
%                         
%                         % Check if we are exporting to continuous
%                         if(strcmp(this.storageType, 'Continuous') && ~writtenOutmzList(pixelListIndex))
%                             mzListOffset(pixelListIndex) = ftell(ibdFileIDs(pixelListIndex));
%                             mzListArrayLength(pixelListIndex) = length(spectrum.spectralChannels);
%                             mzListEncodedLength(pixelListIndex) = 8 * mzListArrayLength;
% 
%                             curImzML.getFileDescription().getFileContent().removeChildOfCVParam('IMS:1000003');
%                             curImzML.getFileDescription().getFileContent().addCVParam(com.alanmrace.jimzmlparser.mzml.EmptyCVParam(oldImzML.getOBO().getTerm('IMS:1000030')));
% 
%                             % Write out the data
%                             fwrite(ibdFileIDs(pixelListIndex), spectrum.spectralChannels, 'double');
%                             
%                             writtenOutmzList(pixelListIndex) = true;
%                         else
%                             % Otherwise change the binary type to specify
%                             % processed
%                             curImzML.getFileDescription().getFileContent().removeChildOfCVParam('IMS:1000003');
%                             curImzML.getFileDescription().getFileContent().addCVParam(com.alanmrace.jimzmlparser.mzml.EmptyCVParam(oldImzML.getOBO().getTerm('IMS:1000031')));
%                         end
%                         
%                         mzMLSpectrum = com.alanmrace.jimzmlparser.mzml.Spectrum(mzMLSpectrum, oldImzML.getReferenceableParamGroupList(), curImzML.getDataProcessingList(), ...
%                             curImzML.getFileDescription().getSourceFileList(), curImzML.getInstrumentConfigurationList());
%                         
%                         bdaList = mzMLSpectrum.getBinaryDataArrayList();
%                         
%                         for listIndex = 0:bdaList.size()-1
%                             bda = bdaList.getBinaryDataArray(listIndex);
%                             dataArrayType = bda.getCVParamOrChild(com.alanmrace.jimzmlparser.mzml.BinaryDataArray.binaryDataArrayID);
%                             
%                             if(dataArrayType.getTerm().getID().equals(com.alanmrace.jimzmlparser.mzml.BinaryDataArray.mzArrayID))
%                                 
%                                 if(strcmp(this.storageType, 'Continuous'))
%                                     % Set offset
%                                     bda.getCVParam('IMS:1000102').setValue(mzListOffset);
%                                     % Set array length
%                                     arrayLengthParam = bda.getCVParam('IMS:1000103');
%                                     if(~isempty(arrayLengthParam))
%                                         arrayLengthParam.setValue(mzListArrayLength);
%                                     end
%                                     % Set encoded length
%                                     bda.getCVParam('IMS:1000104').setValue(mzListEncodedLength);
%                                 else
%                                     arrayLength = length(spectrum.spectralChannels);
% 
%                                     % Set offset
%                                     bda.getCVParam('IMS:1000102').setValue((ftell(ibdFileIDs(pixelListIndex))));
%                                     % Set array length
%                                     arrayLengthParam = bda.getCVParam('IMS:1000103');
%                                     if(~isempty(arrayLengthParam))
%                                         arrayLengthParam.setValue((arrayLength));
%                                     end
%                                     % Set encoded length
%                                     bda.getCVParam('IMS:1000104').setValue((8*arrayLength));
% 
%                                     % Write out the data
%                                     fwrite(ibdFileIDs(pixelListIndex), spectrum.spectralChannels, 'double');
%                                 end
%                             elseif(dataArrayType.getTerm().getID().equals(com.alanmrace.jimzmlparser.mzml.BinaryDataArray.intensityArrayID))
%                                 arrayLength = length(spectrum.intensities);
%                                 
%                                 % Set offset
%                                 bda.getCVParam('IMS:1000102').setValue((ftell(ibdFileIDs(pixelListIndex))));
%                                 % Set array length
%                                 arrayLengthParam = bda.getCVParam('IMS:1000103');
%                                 if(~isempty(arrayLengthParam))
%                                     arrayLengthParam.setValue((arrayLength));
%                                 end;
%                                 
%                                 % 'Double', 'Single', '64-Bit Integer', '32-Bit Integer', 
%                                 % '16-Bit Integer', '8-Bit Integer'
%                                 switch(this.intensityDataType)
%                                     case 'Double'
%                                         % Set encoded length
%                                         bda.getCVParam('IMS:1000104').setValue((8*arrayLength));
%                                         % Write out the data
%                                         fwrite(ibdFileIDs(pixelListIndex), spectrum.intensities, 'double');
%                                     case 'Single'
%                                         % Set encoded length
%                                         bda.getCVParam('IMS:1000104').setValue((4*arrayLength));
%                                         % Write out the data
%                                         fwrite(ibdFileIDs(pixelListIndex), single(spectrum.intensities), 'single');
%                                     case '64-Bit Integer'
%                                         % Set encoded length
%                                         bda.getCVParam('IMS:1000104').setValue((8*arrayLength));
%                                         % Write out the data
%                                         fwrite(ibdFileIDs(pixelListIndex), int64(spectrum.intensities), 'int64');
%                                     case '32-Bit Integer'
%                                         % Set encoded length
%                                         bda.getCVParam('IMS:1000104').setValue((4*arrayLength));
%                                         % Write out the data
%                                         fwrite(ibdFileIDs(pixelListIndex), int32(spectrum.intensities), 'int32');
%                                     case '16-Bit Integer'
%                                         % Set encoded length
%                                         bda.getCVParam('IMS:1000104').setValue((2*arrayLength));
%                                         % Write out the data
%                                         fwrite(ibdFileIDs(pixelListIndex), int16(spectrum.intensities), 'int16');
%                                     case '8-Bit Integer'
%                                         % Set encoded length
%                                         bda.getCVParam('IMS:1000104').setValue((arrayLength));
%                                         % Write out the data
%                                         fwrite(ibdFileIDs(pixelListIndex), int8(spectrum.intensities), 'int8');
%                                     otherwise
%                                         exception = MException('DatacubeReduction:InvalidArgument', ['Invalid intensity data type provided: ' this.intensityDataType]);
%                                         throw(exception);
%                                 end
%                             end
%                         end
%                         
%                         imzMLList{pixelListIndex}.getRun().getSpectrumList().addSpectrum(mzMLSpectrum);
                    end
                end
%                 progressEvent = ProgressEventData(i / size(pixels, 1), processDescription);
%                 notify(this, 'ProcessingProgress', progressEvent);
            end
            
            if(~isempty(imzMLList))
                for i = 1:numel(imzMLList)
%                     fclose(ibdFileIDs(i));
                    
                    curImzML = imzMLList{i};
                    
                    % Calculate the SHA-1 Hash using jimzMLParser 
%                     sha1Hash = com.alanmrace.jimzmlparser.imzml.ImzML.calculateSHA1(ibdFileNames{i});
% 
%                     % Replace any old CVParam with the new SHA-1 Hash
%                     curImzML.getFileDescription().getFileContent().removeChildOfCVParam(com.alanmrace.jimzmlparser.mzml.FileContent.ibdChecksumID);
%                     curImzML.getFileDescription().getFileContent().addCVParam(com.alanmrace.jimzmlparser.mzml.StringCVParam(oldImzML.getOBO().getTerm('IMS:1000091'), sha1Hash));

                    writer = com.alanmrace.jimzmlparser.writer.ImzMLWriter();
                    
                    writer.write(curImzML, filenameList{i});
                end
            end
        end
    end
end