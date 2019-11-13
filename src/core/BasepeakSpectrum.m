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
            this.spectrumList = SpectrumList();
            
            pixels = this.getPixelListToProcess(dataRepresentation);
            rois = this.regionOfInterestList.getObjects();
            
            % Set up the memory required
            data = {};
            pixelLists = {};
            descriptions = {};
            
            % Check whether we can use fast methods for processing
            [canUseFastMethods, workflow] = this.setUpFastMethods(dataRepresentation);
                        
            if(canUseFastMethods)
                ped = ProgressEventData(0, ['Using fast methods. Generating Total Spectrum']);
                notify(this, 'ProcessingProgress', ped);
                
                try
                    spectrumGeneration = com.alanmrace.JSpectralAnalysis.spectralrepresentation.MultithreadedSpectralRepresentationGeneration(this.javaDataRepresentation, workflow, this.javaROIList);
                    spectrumGeneration.generateBasepeakSpectrum();
                    
                    while(~spectrumGeneration.isDone())
                        ped = ProgressEventData(spectrumGeneration.getProgress(), ['Using fast methods. Generating Basepeak Spectrum']);
                        notify(this, 'ProcessingProgress', ped);
                        
                        pause(0.05);
                    end
                    
                    sList = spectrumGeneration.getSpectrumList();
                    
                    this.addJavaSpectrumList(sList);
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
                    
                    progressEvent = ProgressEventData(i / length(pixels), processDescription);
                    notify(this, 'ProcessingProgress', progressEvent);
                end
                
                for i = 1:numel(data)
                    s = SpectralData(peakList', data{i});
                    
                    s.setDescription([eval([class(this) '.Name']) ' ' descriptions{i}]);
                    
                    this.spectrumList.add(s);
                end
            end
            
            spectrumList = this.spectrumList;
        end
    end
end