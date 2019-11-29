classdef DataInMemory < DataRepresentation
    
    properties (SetAccess = protected)
        spectralChannels;
        data;
        
        spectralChannelRange;
        zeroFilling;
    end
    
    methods
        function obj = DataInMemory()
        end        
        
        function numChannels = getNumberOfChannels(this) 
            numChannels = length(this.spectralChannels);
        end
        
        function numChannels = getNumberOfDimensions(this) 
            numChannels = length(this.spectralChannels);
        end
        
        function sizeInBytes = getEstimatedSizeInBytes(obj)
            sizeInBytes = 0;
            
            sizeInBytes = sizeInBytes + sizeof(obj.spectralChannels);
            sizeInBytes = sizeInBytes + sizeof(obj.data);
            
            sizeInBytes = sizeInBytes + sizeof(obj.pixels);
        end
        
        function setData(obj, data, regionOfInterest, isRowMajor, spectralChannels, name)
            obj.data = data;
            obj.spectralChannels = spectralChannels;
            obj.spectralChannelRange = [min(spectralChannels) max(spectralChannels)];
            obj.name = name;
            
            obj.isRowMajor = isRowMajor;
            
            % Ensure that no NaN exist in the data to avoid issues with
            % display and subsequent processing
            obj.data(isnan(obj.data)) = 0;
                        
            obj.setRegionOfInterest(regionOfInterest);
        end
        
        function loadData(obj, parser, regionOfInterest, spectralChannelRange, zeroFilling)
            if(~isa(parser, 'Parser'))
                exception = MException('DataInMemory:InvalidArgument', ...
                    'loadData: Must supply an instance of a subclass of Parser');
                throw(exception);
            end
            if(~isa(regionOfInterest, 'RegionOfInterest'))
                exception = MException('DataInMemory:InvalidArgument', ...
                    'loadData: Must supply an instance of RegionOfInterest');
                throw(exception);
            end
            
            obj.data = [];
            obj.regionOfInterest = regionOfInterest;
            obj.spectralChannelRange = spectralChannelRange;
            obj.zeroFilling = zeroFilling;
            obj.parser = parser;
            obj.name = parser.getShortFilename();
            
%             if(ischar(pixels) && strcmp(pixels, 'all'))
%                 [X Y] = meshgrid(1:parser.getWidth(), 1:parser.getHeight());
%                 
%                 pixels = [X(:) Y(:)];
%             end

            obj.isRowMajor = parser.isRowMajor();
            obj.createPixelList();
            
            [pathstr, filename, ext] = fileparts(parser.filename);
            
            if(parser.isSpectrumOrientated())
                for i = 1:size(obj.pixels, 1)
                    x = obj.pixels(i, 1);
                    y = obj.pixels(i, 2);
                    
                    spectrum = parser.getSpectrum(x, y);
                    spectralChannels = spectrum.spectralChannels;
                    intensities = spectrum.intensities;
                    
                    if(~isempty(zeroFilling))
                        [spectralChannels, intensities] = zeroFilling.process(spectralChannels, intensities);
                    end
                    
                    if(isempty(obj.data))
                        if(isinf(spectralChannelRange(1)) && ~isempty(spectralChannels))
                            spectralChannelRange(1) = min(spectralChannels);
                        end
                        if(isinf(spectralChannelRange(2)) && ~isempty(spectralChannels))
                            spectralChannelRange(2) = max(spectralChannels);
                        end
                        
                        range = (spectralChannels >= spectralChannelRange(1)) & (spectralChannels <= spectralChannelRange(2));
                            
                        obj.data = zeros(size(obj.pixels, 1), sum(range));
                    end
                    
                    obj.data(obj.pixelIndicies(i), :) = intensities(range);
                    
                    ped = ProgressEventData(i / size(obj.pixels, 1), ['Loading data from ' filename '.' ext]);
                    notify(obj, 'DataLoadProgress', ped);
                end
                
                obj.spectralChannels = spectralChannels((spectralChannels >= spectralChannelRange(1)) & (spectralChannels <= spectralChannelRange(2)));
            else%if(obj.isImageOrientated())
            end
        end
        
        % Coordinate system:
        %   - relative = 0 is the default meaning that the coordinate
        %                  system is based on the underlying data and not
        %                  the loaded data
        function spectrum = getSpectrum(obj, x, y, z, relative)
            if(nargin < 4)
                z = 1;
            end
            if(nargin < 5)
                relative = 0;
            end
            
            % Find in [x y] in obj.pixels and then get
            % obj.pixelIndicies(location) from obj.data
%             if(relative)
%                 x = x + obj.minX - 1;
%                 y = y + obj.minY - 1;
%             end
            
            [a b] = find(obj.pixels(:, 1) == x);
            [c d] = find(obj.pixels(:, 2) == y);
            index = intersect(a, c);
            
            if(isempty(index))
                intensities = zeros(size(obj.spectralChannels));
                warning(['Couldn''t find pixel: (' num2str(x) ', ' num2str(y) ')']);
            else
                intensities = obj.data(obj.pixelIndicies(index), :);
            end
            
            spectrum = SpectralData(obj.spectralChannels, intensities);
            spectrum.setIsContinuous(obj.isContinuous);
            spectrum.setDescription(['Spectrum at (' num2str(x) ', ' num2str(y) ')']);
        end
        
        function imageList = generateImages(obj, spectralChannelList, spectralWidthList, preprocessingWorkflow)
            images = zeros(obj.height, obj.width, length(spectralChannelList));
            
            pixelMask = obj.regionOfInterest.getPixelMask();
            selectionData = pixelMask(obj.minY:obj.maxY, obj.minX:obj.maxX);
            
            if(isempty(preprocessingWorkflow) || preprocessingWorkflow.numberOfMethods == 0)
                
                for imageIndex = 1:length(spectralChannelList)
                    indicies = obj.spectralChannels >= (spectralChannelList(imageIndex)-spectralWidthList(imageIndex)) ...
                        & obj.spectralChannels <= (spectralChannelList(imageIndex) + spectralWidthList(imageIndex));

                    d = sum(obj.data(:, indicies), 2);

                    for i = 1:length(obj.pixels)
                        images(obj.pixels(i, 2), obj.pixels(i, 1), imageIndex) = d(i);
                    end
                end
                
%                 image(selectionData == 1) = sum(obj.data(:, indicies), 2);
                
                
            else
%                 tic;
                numPix = size(obj.pixels, 1);
                
                for i = 1:numPix
                    x = obj.pixels(i, 1) - obj.minX + 1;
                    y = obj.pixels(i, 2) - obj.minY + 1;
                    
%                     [spectralChannels, intensities] = preprocessingWorkflow.performWorkflow(obj.spectralChannels, obj.data(obj.pixelIndicies(i), :));

                    spectrum = SpectralData(obj.spectralChannels, obj.data(obj.pixelIndicies(i), :));
                    spectrum = preprocessingWorkflow.performWorkflow(spectrum);
                    
                    imageIndex = 1;
                    
                    for imageIndex = 1:length(spectralChannelList)
                        indicies = spectrum.spectralChannels >= (spectralChannelList(imageIndex)-spectralWidthList(imageIndex))...
                            & spectrum.spectralChannels <= (spectralChannelList(imageIndex) + spectralWidthList(imageIndex));
                        images(y, x, imageIndex) = sum(spectrum.intensities(indicies), 2);
                    end
                    
                    if(mod(i, 20) == 0)
                        ped = ProgressEventData(i / size(obj.pixels, 1), ['Generating  ' num2str(length(spectralChannelList)) ' images']);
                        notify(obj, 'DataLoadProgress', ped);
                    end
                end
            end
            
            ped = ProgressEventData(1, ['Generating ' num2str(length(spectralChannelList)) ' images']);
            notify(obj, 'DataLoadProgress', ped);
            
            for i = 1:length(spectralChannelList)
                imageList(i) = Image(images(:, :, i));
            end
        end
        
        function image = getOverviewImage(obj)
            image = zeros(obj.height, obj.width);
            
            pixelMask = obj.regionOfInterest.getPixelMask();
            selectionData = pixelMask(obj.minY:obj.maxY, obj.minX:obj.maxX);
            
%             image(selectionData == 1) = sum(obj.data, 2);
            
            d = sum(obj.data, 2);
            
            for i = 1:length(obj.pixels)
                image(obj.pixels(i, 2), obj.pixels(i, 1)) = d(i);
            end
            
            image = Image(image);
            image.setDescription('Overview Image');
        end
        
        % Handle export of object
        function s = saveobj(obj)
            s = saveobj@DataRepresentation(obj);
            
            s.spectralChannels = obj.spectralChannels;
            s.data = obj.data;
        
            s.spectralChannelRange = obj.spectralChannelRange;
%             s.zeroFilling;
        end
    end
    
    methods (Access = protected)
        function loadObjectParameters(this, obj)
            loadObjectParameters@DataRepresentation(this, obj);
            
            this.width = obj.width;
            this.height = obj.height;
            
            this.name = obj.name;
            
            this.isContinuous = obj.isContinuous;
            
%             regionOfInterest;
            this.pixels = obj.pixels;
            this.pixelIndicies = obj.pixelIndicies;
            
            this.isRowMajor = obj.isRowMajor;
        end
    end
    
    
    methods (Static)
        function obj = loadobj(s)
          if isstruct(s)
              % TODO: Check that the class name matches 
              % TODO: Write a helper function which generates the class
              % automatically from the name and then calls loadObjectParameters
             newObj = DataInMemory(); 
             
             newObj.loadObjectParameters(s);
            obj = newObj;
          else
             obj = s;
          end
       end
    end
end