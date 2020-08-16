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
        
        spectrumXAxisLabel;
        spectrumYAxisLabel;
        
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
            
            this.spectrumXAxisLabel = parser.getSpectrumXAxisLabel();
            this.spectrumYAxisLabel = parser.getSpectrumYAxisLabel();
        end
        
        function setRegionOfInterest(this, regionOfInterest)
            this.regionOfInterest = regionOfInterest;
            
            this.createPixelList();
        end
        
        function setIsContinuous(this, isContinuous)
            this.isContinuous = isContinuous;
        end
        
        function setSpectrumLabels(this, xLabel, yLabel)
            this.spectrumXAxisLabel = xLabel;
            this.spectrumYAxisLabel = yLabel;
        end
        
        function createPixelList(obj)
            obj.pixels = obj.regionOfInterest.getPixelList();
            
            obj.minX = min(obj.pixels(:, 1));
            obj.maxX = max(obj.pixels(:, 1));
            obj.minY = min(obj.pixels(:, 2));
            obj.maxY = max(obj.pixels(:, 2));
            
            obj.width = obj.regionOfInterest.width; %(obj.maxX - obj.minX) + 1;
            obj.height = obj.regionOfInterest.height; %(obj.maxY - obj.minY) + 1;
            
            if(obj.isRowMajor)
                % Sort by rows and then columns
                [obj.pixels, obj.pixelIndicies] = sortrows(obj.pixels, [2 1]);                    
            else
                % Sort by columns and then rows
                [obj.pixels, obj.pixelIndicies] = sortrows(obj.pixels, [1 2]);
            end
        end
        
        % Returns a list of the pixel coordinates in the order that the
        % data is stored in. I.e. if the data is row major, then the
        % returned pixel list will also be row major.
        %
        % If no regionOfInterest is supplied then the base pixel list is
        % returned
        function pixelList = getDataOrderedPixelList(this, regionOfInterest)
            if(~exist('regionOfInterest', 'var'))
                pixelList = this.pixels;
            else            
                pixelList = regionOfInterest.getPixelList();

                if(this.isRowMajor)
                    pixelList = sortrows(pixelList, [2 1]);                    
                else
                    pixelList = sortrows(pixelList, [1 2]);
                end
            end
        end
        
        function roiIndexList = getDataIndiciesForROI(this, regionOfInterest)
            roiPixelList = this.getDataOrderedPixelList(regionOfInterest);
            
            [c, index_A, index_B] = intersect(this.pixels, roiPixelList, 'stable', 'rows');
            
            roiIndexList = this.pixelIndicies(index_A);
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
        
        % Handle export of object
        function s = saveobj(obj)
            s.class = class(obj);
            s.width = obj.width;
            s.height = obj.height;
            
            s.name = obj.name;
            
            s.isContinuous = obj.isContinuous;
            
%             regionOfInterest;
            s.pixels = obj.pixels;
            s.pixelIndicies = obj.pixelIndicies;
            
            s.isRowMajor = obj.isRowMajor;
        end
    end
    
    methods (Access = protected)
        function loadObjectParameters(this, obj)
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
end