classdef Parser < handle
    properties (Abstract, Constant)
        Name;
    end
    
    properties (SetAccess = protected)
        % Dimensions 
        width;
        height;
        depth;
        
        numSpectralChannels;
        
        %imageOrientated = 0;
        spectrumOrientated = 1;
        
        % 
        rowMajor = 1;
        
        filename;
    end
    
    events
        ParsingStarted
        ParsingComplete
        
        DataLoadProgress
    end
    
    methods (Abstract)
        parse(obj);
        
        spectrum = getSpectrum(obj, x, y);
%        [image] = getImage(obj, spectralChannel, channelWidth);
        image = getOverviewImage(obj);
        
        % Get data 
%         data = getData(obj, pixels, spectralChannels);

%        bool = isProjectedData(obj);
%        bool = isSparseData(obj);
    end
    
    methods
        function width = getWidth(obj)
            width = obj.width;
        end
        
        function height = getHeight(obj)
            height = obj.height;
        end
        
        function depth = getDepth(obj)
            depth = obj.depth;
        end
        
        function shortFilename = getShortFilename(this)
            [path, name, ext] = fileparts(this.filename);
            
            shortFilename = [name ext];
        end
        
        function numSpectralChannels = getNumberOfSpectralChannels(obj)
            numSpectralChannels = obj.numSpectralChannels;
        end
        
        % For faster access to data, determine wether the data is stored by
        % spectrum or by image
        function bool = isSpectrumOrientated(obj)
            bool = obj.spectrumOrientated;
        end
        
        function bool = isImageOrientated(obj)
            bool = ~obj.spectrumOrientated; %obj.imageOrientated;
        end
        
        function bool = isRowMajor(obj)
            bool = obj.rowMajor;
        end
        
        function image = getImage(obj, spectralChannel, channelWidth)
            image = zeros(obj.height, obj.width);
            
            for y = 1:obj.height
                for x = 1:obj.width
                    [spectralChannels, intensities] = obj.getSpectrum(x, y);
                    
                    indicies = spectralChannels >= (spectralChannel-channelWidth) & spectralChannels <= (spectralChannel + channelWidth);
                    
                    image(y, x) = sum(intensities(indicies));
                    
                end
                
                ped = ProgressEventData(y / obj.height, ['Generating ' num2str(spectralChannel) ' +/- ' num2str(channelWidth)]);
                notify(obj, 'DataLoadProgress', ped);
            end
            
            image = Image(image);
        end 
        
        function imageList = getImages(obj, spectralChannelList, channelWidthList)
            images = zeros(obj.height, obj.width, length(spectralChannelList));
            
            for y = 1:obj.height
                for x = 1:obj.width
                    [spectralChannels, intensities] = obj.getSpectrum(x, y, 1);
                    
                    for z = 1:length(spectralChannelList)
                        indicies = spectralChannels >= (spectralChannelList(z)-channelWidthList(z)) & spectralChannels <= (spectralChannelList(z) + channelWidthList(z));

                        images(y, x, z) = sum(intensities(indicies));
                    end
                end
                
                ped = ProgressEventData(y / obj.height, ['Generating ' num2str(length(spectralChannelList)) ' images']);
                notify(obj, 'DataLoadProgress', ped);
            end
            
            for i = 1:length(spectralChannelList)
                imageList(i) = Image(images(:, :, i));
            end
        end 
        
%         % Get data 
%         function data = getData(obj, pixels, spectralChannelRange, zeroFilling)
%             
%         end
        
        % This method should be overridden by any method that has projected
        % data
        function projectionMatrix = getProjectionMatrix(obj)
            projectionMatrix = [];
            
            if(obj.isProjectedData())
                exception = MException('Parser:undefinedFunction', 'getProjectionMatrix function needs to be overridden');
                throw(exception);
            else
                exception = MException('Parser:invalidFunctionCall', 'getProjectionMatrix function cannot be called on non-projected data');
                throw(exception);
            end
        end
        
        function bool = isProjectedData(obj)
            bool = 0;
        end
        
        function bool = isSparseData(obj)
            bool = 0;
        end
    end
    
    methods (Static, Abstract)
        % Get the filter spec(s) for this parser as required by uigetfile
        % They must be of the form:  {'*.imzML', 'Mass Spectrometry Imaging (*.imzML)'; ...}
        filterSpec = getFilterSpec(this);
%             % Make sure that the filterSpec has pairs of entries.
%             % They should be of the form:  {'*.imzML', 'Mass Spectrometry Imaging (*.imzML)'; ...}
%             if(mod(numel(filterSpec), 2) == 0)
%                 numFileTypes = numel(filterSpec) / 2;
%                 
%                 % Ensure that the filter list is of the correct form:
%                 % {formatA, descriptionA; formatB, descriptionB; ...}
%                 for j = 1:numFileTypes
%                     filterTypeList{end+1, 1} = filterSpec{((j-1)*2)+1};
%                     filterTypeList{end, 2} = filterSpec{j*2};
%                 end
%             else
%                 exception = MException('SpectralAnalysisInterface:openFile', ...
%                     ['Class ''' parserClassName ''' does not have a correct implementation of the getFilterSpec() method']);
%                 throw(exception);
%             end
    end
end