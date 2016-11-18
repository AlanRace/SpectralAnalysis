classdef BasepeakSpectrum < SpectralRepresentation
    properties (Constant)
        Name = 'Basepeak Spectrum';
        Description = '';
        
        ParameterDefinitions = [];
    end
    
    properties (SetAccess = protected)
        numSpectra = 0;
    end
    
    methods
        function spectrumList = process(this, dataRepresentation)
            spectrumList = SpectrumList();
            
            pixels = this.getPixelListToProcess(dataRepresentation);
            rois = this.regionOfInterestList.getObjects();
            
            % Set up the memory required
            data = {};
            pixelLists = {};
            descriptions = {};
            
%             if(isa(dataRepresentation, 'DataInMemory') && isempty(this.preprocessingWorkflow))
%                 
%             else
                % Check if the multithreaded methods implemented in Java
                % can be used
                canUseFastMethods = 0;
                tic;
                
                % Currently only the ImzMLParser can be used with the fast
                % methods as it is the only one implemented in Java so far
                if(isa(dataRepresentation.parser, 'ImzMLParser'))
                    roiList = com.alanmrace.JSpectralAnalysis.RegionOfInterest.createROIList();

                    if(this.processEntireDataset)
                        roi = com.alanmrace.JSpectralAnalysis.RegionOfInterest('Entire Dataset', dataRepresentation.regionOfInterest.width, dataRepresentation.regionOfInterest.height);
                        roi.addPixels(dataRepresentation.regionOfInterest.pixelSelection');
                        roiList.add(roi);
                    end

                    for i = 1:numel(rois)
                        roi = com.alanmrace.JSpectralAnalysis.RegionOfInterest(rois{i}.getName(), dataRepresentation.regionOfInterest.width, dataRepresentation.regionOfInterest.height);
                        roi.addPixels(rois{i}.pixelSelection');
                        roiList.add(roi);
                    end

                    if(this.preprocessEverySpectrum)
                        workflow = generateFastPreprocessingWorkflow(this.preprocessingWorkflow);
                    else
                        workflow = com.alanmrace.JSpectralAnalysis.PreprocessingWorkflow();
                    end

                    if(isempty(this.preprocessingWorkflow) || ~this.preprocessEverySpectrum || ~isempty(workflow))
                        canUseFastMethods = 1;
                    end

                    javaParser = com.alanmrace.JSpectralAnalysis.io.ImzMLParser(dataRepresentation.parser.imzML);
                    javaDataRepresentation = com.alanmrace.JSpectralAnalysis.datarepresentation.DataOnDisk(javaParser);
                end

                if(canUseFastMethods)
                    ped = ProgressEventData(0, ['Using fast methods. Generating Total Spectrum']);
                    notify(this, 'ProcessingProgress', ped);

                    try 
                        spectrumGeneration = com.alanmrace.JSpectralAnalysis.spectralrepresentation.MultithreadedSpectralRepresentationGeneration(javaDataRepresentation, workflow, roiList);
                        spectrumGeneration.generateBasepeakSpectrum();

                        while(~spectrumGeneration.isDone())
                            ped = ProgressEventData(spectrumGeneration.getProgress(), ['Using fast methods. Generating Basepeak Spectrum']);
                            notify(this, 'ProcessingProgress', ped);

                            pause(0.05);
                        end

    %                     if(spectrumGeneration.hasError())
    %                         'error'
    %                     end
                        assignin('base', 'spectrumGeneration', spectrumGeneration);
                        sList = spectrumGeneration.getSpectrumList();
                        roiList
                        for i = 0:sList.size()-1
                            s = SpectralData(sList.get(i).getSpectralChannels(), sList.get(i).getIntensities());

                            name = char(roiList.get(i).getName());

                            s.setDescription([eval([class(this) '.Name']) ' ' name]);

                            spectrumList.add(s);
                        end
                    catch err

                        errBox = errordlg(err.message, err.identifier);

                        rethrow(err);
                    end

                    ped = ProgressEventData(1, ['Generated Basepeak Spectrum']);
                    notify(this, 'ProcessingProgress', ped);
                else
                    for i = 1:size(pixels, 1)
                        spectrum = this.getProcessedSpectrum(dataRepresentation, pixels(i, 1), pixels(i, 2));

                        if(isempty(spectrum.intensities))
                            continue;
                        end

                        processDescription = ['Generating ' eval([class(this) '.Name'])];

                        % Create the data based on the first spectrum acquired
                        if(isempty(data))
                            channelSize = length(spectrum.spectralChannels);
                            peakList = spectrum.spectralChannels;

                            if(this.processEntireDataset)
                                data{end+1} = zeros(1, channelSize);
                                pixelLists{end+1} = pixels;
                                descriptions{end+1} = '(Entire Dataset)';
                            end

                            for roiIndex = 1:numel(rois)
                                pixelLists{end+1} = rois{roiIndex}.getPixelList();
                                data{end+1} = zeros(1, channelSize);
                                descriptions{end+1} = ['(' rois{roiIndex}.getName() ')'];
                            end
                        end

                        for pixelListIndex = 1:numel(pixelLists)
                            [pixel, row, col] = intersect(pixelLists{pixelListIndex}, pixels(i, :), 'rows');

                            if(~isempty(row))
                                data{pixelListIndex}(1, :) = max(data{pixelListIndex}(1, :), spectrum.intensities);
                            end
                        end

                        progressEvent = ProgressEventData(i / length(pixels), 'Calculating spectral representation');
                        notify(this, 'ProcessingProgress', progressEvent);
                    end

                    for i = 1:numel(data)
                        s = SpectralData(peakList', data{i});

                        s.setDescription([eval([class(this) '.Name']) ' ' descriptions{i}]);

                        spectrumList.add(s);
                    end
                end
%             end
            
            toc;
            
%             % This could be optimised for each data representation
%             
%             if(~obj.preprocessEverySpectrum && isa(dataRepresentation, 'DataInMemory'))
%                 maxIntensities = sum(dataRepresentation.data, 1);
%                 spectralChannels = dataRepresentation.spectralChannels;
% 
%                 obj.numSpectra = sum(sum(dataRepresentation.data, 2) ~= 0);
%             else
%                 for y = 1:dataRepresentation.height
%                     for x = 1:dataRepresentation.width
%                         spectrum = dataRepresentation.getSpectrum(x, y);
%                         
%                         spectralChannels = spectrum.spectralChannels;
%                         
%                         if(isempty(spectrum.intensities))
%                             continue;
%                         end
% 
%                         if(~isempty(obj.preprocessingWorkflow) && obj.preprocessEverySpectrum)
%                             spectrum = obj.preprocessingWorkflow.performWorkflow(spectrum);
%                         end
%                         
%                         if(~isempty(spectrum.intensities))
%                             obj.numSpectra = obj.numSpectra + 1;
%                             maxIntensities = maxIntensities + spectrum.intensities;
%                         end
%                     end
%                 end
%             end
%             
%             spectrum = SpectralData(spectralChannels, maxIntensities);
        end
    end
end