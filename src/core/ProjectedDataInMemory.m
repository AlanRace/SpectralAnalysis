classdef ProjectedDataInMemory < DataInMemory & ProjectedDataRepresentation
    
    properties (SetAccess = protected)
        projectionMatrix;
%         projectionChannels;
    end
    
    methods
        function obj = ProjectedDataInMemory()
        end
        
        function setData(obj, data, projectionMatrix, pixelSelection, isRowMajor, spectralChannels, name)
            setData@DataInMemory(obj, data, pixelSelection, isRowMajor, spectralChannels, name);
            
            obj.projectionMatrix = projectionMatrix;
%             obj.projectionChannels = projectionChannels;
        end
        
        function numChannels = getNumberOfDimensions(this) 
            numChannels = size(this.projectionMatrix, 2);
        end
        
        function spectrum = getSpectrum(obj, x, y, z, relative)
            if(nargin < 4)
                z = 1;
            end
            if(nargin < 5)
                relative = 0;
            end
            spectrum = getSpectrum@DataInMemory(obj, x, y, z, relative);

            intensities =  obj.projectionMatrix * spectrum.intensities';
            
            spectrum = SpectralData(spectrum.spectralChannels, intensities);
        end
        
        function spectrum = getProjectedSpectrum(obj, index)
            spectrum = SpectralData(obj.spectralChannels, obj.projectionMatrix(:, index));
            spectrum.setIsContinuous(false);
        end
        
        function [image] = getProjectedImage(obj, index)
            image = zeros(obj.height, obj.width);
            
            pixelMask = obj.regionOfInterest.getPixelMask();
            selectionData = pixelMask(obj.minY:obj.maxY, obj.minX:obj.maxX);
            
%             image(selectionData == 1) = obj.data(:, index);
            size(obj.data)
            d = obj.data(:, index);
            
            for i = 1:length(obj.pixels)
                image(obj.pixels(i, 2), obj.pixels(i, 1)) = d(i);
            end
        end
    end
end