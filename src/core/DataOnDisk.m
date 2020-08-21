classdef DataOnDisk < DataRepresentation
    
    
    
    methods
        function obj = DataOnDisk(parser)
            if(~isa(parser, 'Parser'))
                exception = MException('DataOnDisk:InvalidArgument', 'Must supply an instance of the Parser class.');
                throw(exception);
            end
            
            obj.parser = parser;
            
            obj.setSpectrumLabels(parser.getSpectrumXAxisLabel(), parser.getSpectrumYAxisLabel());
            
            obj.width = obj.parser.getWidth();
            obj.height = obj.parser.getHeight();
            obj.name = parser.getShortFilename();
            
            obj.regionOfInterest = RegionOfInterest(obj.width, obj.height);
            
            obj.isRowMajor = parser.isRowMajor();
            obj.isContinuous = parser.isSpectrumContinuous();
            
            obj.createPixelList();
        end
        
        function spectrum = getSpectrum(obj, x, y, z, relative)
            if(nargin < 4)
                z = 1;
            end
            
            spectrum = obj.parser.getSpectrum(x, y, z);
            spectrum.setDescription(['Spectrum at (' num2str(x) ', ' num2str(y) ')']);
        end
        
        function imageList = generateImages(obj, spectralChannelList, channelWidthList, preprocessingWorkflow)
            listener = addlistener(obj.parser, 'DataLoadProgress', @obj.dataLoadProgress);
            
            canUseFastMethods = canUseJSpectralAnalysis();
            
            tic;
            if(isa(obj.parser, 'ImzMLParser'))
                workflow = generateFastPreprocessingWorkflow(preprocessingWorkflow);
                
                if(isempty(preprocessingWorkflow) || ~isempty(workflow))
                    canUseFastMethods = canUseJSpectralAnalysis();
                else
                    canUseFastMethods = 0;
                end
            else
                canUseFastMethods = 0;
            end
            
            if(canUseFastMethods)
%                 mBox = msgbox('Using fast methods, no progress bar available', 'Using fast methods');
                
                ped = ProgressEventData(0, ['Using fast methods. Generating ' num2str(length(spectralChannelList)) ' image(s)']);
                notify(obj, 'DataLoadProgress', ped);
                
                try 
                    imageGeneration = com.alanmrace.JSpectralAnalysis.MultithreadedImageGeneration();
                    imageGeneration.generateIonImages(obj.parser.imzML, workflow, spectralChannelList, channelWidthList);
                    
                    while(~imageGeneration.isDone())
                        ped = ProgressEventData(imageGeneration.getProgress(), ['Using fast methods. Generating ' num2str(length(spectralChannelList)) ' image(s)']);
                        notify(obj, 'DataLoadProgress', ped);
                        
                        pause(0.05);
                    end
                    
                    images = imageGeneration.getImageList();
                    
                    for i = 1:length(spectralChannelList)
                        imageList(i) = Image(images(:, :, i));
                    end
                catch err
%                     if(~isempty(mBox))
%                         delete(mBox);
%                     end
                    
                    errBox = errordlg(err.message, err.identifier);
                    
                    rethrow(err);
                end
                
                ped = ProgressEventData(1, ['Generated ' num2str(length(spectralChannelList)) ' image(s)']);
                notify(obj, 'DataLoadProgress', ped);
                
%                 if(~isempty(mBox))
%                     delete(mBox);
%                 end
            else
                if(isempty(preprocessingWorkflow) || preprocessingWorkflow.numberOfMethods == 0 || isa(obj.parser, 'SIMSParser'))
                    if(isa(obj.parser, 'SIMSParser'))
                        channelWidthList = channelWidthList*2;
                    end
                    
                    imageList = obj.parser.getImages(spectralChannelList, channelWidthList);
                else
                    images = zeros(obj.parser.getHeight(), obj.parser.getWidth(), length(spectralChannelList));

                    for y = 1:obj.parser.getHeight()
                        for x = 1:obj.parser.getWidth()
                            spectrum = obj.getSpectrum(x, y);

                            if(isempty(spectrum) || isempty(spectrum.intensities))
                                continue;
                            end

                            spectrum = preprocessingWorkflow.performWorkflow(spectrum);

                            for imageIndex = 1:length(spectralChannelList)
                                indicies = spectrum.spectralChannels >= (spectralChannelList(imageIndex)-channelWidthList(imageIndex)) ...
                                    & spectrum.spectralChannels <= (spectralChannelList(imageIndex) + channelWidthList(imageIndex));

                                images(y, x, imageIndex) = sum(spectrum.intensities(indicies));
                            end
                        end

                        ped = ProgressEventData(y / obj.height, ['Generating ' num2str(length(spectralChannelList)) ' image(s)']);
                        notify(obj, 'DataLoadProgress', ped);
                    end
                    
                    for i = 1:length(spectralChannelList)
                        imageList(i) = Image(images(:, :, i));
                    end
                end
            end
            
            toc;
            delete(listener);
        end
        
        function image = getOverviewImage(obj)
            image = obj.parser.getOverviewImage();
        end
        
        function sizeInBytes = getEstimatedSizeInBytes(this)
            sizeInBytes = 10000;
        end
    end
    
    methods (Access = private)
        function dataLoadProgress(obj, src, evnt)
            notify(obj, 'DataLoadProgress', evnt);
        end
    end
end