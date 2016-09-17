classdef PostProcessing < Processing
    properties (SetAccess = protected)
        preprocessingWorkflow;
        
        preprocessEverySpectrum = 1;
        processEntireDataset = 1;
        
        regionOfInterestList;
    end
    
    methods (Abstract)
        dataRepresentation = process(obj, dataRepresentation);
    end
    
    methods
        function this = PostProcessing()
            this.regionOfInterestList = RegionOfInterestList();
        end
        
        function setPreprocessingWorkflow(obj, preprocessingWorkflow)
            if(~isempty(preprocessingWorkflow) && ~isa(preprocessingWorkflow, 'PreprocessingWorkflow'))
                exception = MException('PostProcessing:invalidArgument', 'Must provide an instance of a class that extends PreprocessingWorkflow');
                throw(exception);
            end
            
            obj.preprocessingWorkflow = preprocessingWorkflow;            
        end
        
        function applyPreprocessingToEverySpectrum(this, preprocessEverySpectrum)
            this.preprocessEverySpectrum = preprocessEverySpectrum;
        end
        
        function postProcessEntireDataset(this, processEntireDataset)
            this.processEntireDataset = processEntireDataset;
        end
        
        function addRegionOfInterest(this, regionOfInterest)
            if(~isa(regionOfInterest, 'RegionOfInterest'))
                exception = MException([class(this) ':InvalidArgument'], 'regionOfInterest must be an instance of RegionOfInterest');
                throw(exception);
            end
            
            this.regionOfInterestList.add(regionOfInterest);
        end
        
        function setRegionOfInterestList(this, regionOfInterestList)
            if(~isa(regionOfInterestList, 'RegionOfInterestList'))
                exception = MException([class(this) ':InvalidArgument'], ...
                    'setRegionOfInterestList: regionOfInterestList must be an instance of RegionOfInterestList');
                throw(exception);
            end
            
            this.regionOfInterestList = regionOfInterestList;
        end
        
        function pixels = getPixelListToProcess(this, dataRepresentation)
            rois = this.regionOfInterestList.getObjects();    
            
            pixels = [];
            
            if(this.processEntireDataset)
                pixels = dataRepresentation.pixels;
            else
                if(numel(rois) > 0)
                    pixels = rois{1}.getPixelList();
                
                    for i = 2:numel(rois)
                        pixels = union(pixels, rois{i}.getPixelList(), 'rows');
                    end                    
                end
            end
        end
        
        function spectrum = getProcessedSpectrum(this, dataRepresentation, x, y)
            spectrum = dataRepresentation.getSpectrum(x, y);
                
            % If we aren't dealing with a square image then no point
            % pre-processing
            if(isempty(spectrum.intensities))
                return;
            end
            
            if(~isempty(this.preprocessingWorkflow) && this.preprocessEverySpectrum)
                spectrum = this.preprocessingWorkflow.performWorkflow(spectrum);
            end
        end
    end
end