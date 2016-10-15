classdef DataRepresentation < handle 
    properties (SetAccess = protected)
        width;
        height;
        
        name;
        
        parser;
        
        isContinuous = true;
        
        regionOfInterest;
        pixels;
        pixelIndicies;
        
        isRowMajor = 1;
    end
    
    properties (Access = protected)
        minX;
        maxX;
        minY;
        maxY;
    end
    
    events
        DataLoadProgress
    end
    
    methods (Abstract)
        spectrum = getSpectrum(obj, x, y, z, relative);
        image = generateImages(obj, spectralChannelList, channelWidthList, preprocessingWorkflow);
        
        image = getOverviewImage(obj);
        
        sizeInBytes = getEstimatedSizeInBytes(obj);
    end
    
    methods
        function setParser(this, parser)
            this.parser = parser;
        end
        
        function setRegionOfInterest(this, regionOfInterest)
            this.regionOfInterest = regionOfInterest;
            
            this.createPixelList();
        end
        
        function setIsContinuous(this, isContinuous)
            this.isContinuous = isContinuous;
        end
        
        function createPixelList(obj)
            obj.pixels = obj.regionOfInterest.getPixelList();
            
            obj.minX = min(obj.pixels(:, 1));
            obj.maxX = max(obj.pixels(:, 1));
            obj.minY = min(obj.pixels(:, 2));
            obj.maxY = max(obj.pixels(:, 2));
            
            obj.width = (obj.maxX - obj.minX) + 1;
            obj.height = (obj.maxY - obj.minY) + 1;
            
            if(obj.isRowMajor)
                % Sort by y column, then by x column
                [obj.pixels, obj.pixelIndicies] = sortrows(obj.pixels, [2 1]);                    
            else
                % Sort by x column, then by y column
                [obj.pixels, obj.pixelIndicies] = sortrows(obj.pixels, [1 2]);
            end
        end
        
        function exportToWorkspace(obj)
            variableName = inputdlg('Please specifiy a variable name:', 'Variable name', 1, {'dataRepresentation'});
            
            while(~isempty(variableName))
                if(isvarname(variableName{1}))
                    assignin('base', variableName{1}, obj);
                    break;
                else
                    variableName = inputdlg('Invalid variable name. Please specifiy a variable name:', 'Variable name', 1, variableName);
                end
            end
        end
    end
end