classdef PostProcessing < Processing
    properties (SetAccess = protected)
        preprocessingWorkflow;
        
        preprocessEverySpectrum = 1;
        processEntireDataset = 1;
        
        regionOfInterestList;
        
        javaROIList
        javaDataRepresentation
    end
    
    events
        % Event triggered when it is determined whether fast methods can be
        % used or not
        FastMethods
    end
    
    methods (Abstract)
        dataRepresentation = process(obj, dataRepresentation);
        resultsViewer = displayResults(this, dataViewer);
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
    
    methods (Access = protected, Static)
        function javaPixelList = getJavaPixelList(pixelList)
            javaPixelList = com.alanmrace.jimzmlparser.imzml.PixelLocation(pixelList(1, 1), pixelList(1, 2), 1);
            
            for i = 2:size(pixelList, 1)
                javaPixelList(i) = com.alanmrace.jimzmlparser.imzml.PixelLocation(pixelList(i, 1), pixelList(i, 2), 1);
            end
        end
    end
    
    methods (Access = protected)
        function addJavaSpectrumList(this, sList)
            for i = 0:sList.size()-1
                s = SpectralData(sList.get(i).getSpectralChannels(), sList.get(i).getIntensities());
                
                name = char(this.javaROIList.get(i).getName());
                
                s.setDescription([eval([class(this) '.Name']) ' ' name]);
                
                this.spectrumList.add(s);
            end
        end
                
        function [canUseFastMethods, workflow] = setUpFastMethods(this, dataRepresentation)
            canUseFastMethods = 0;
            
            % Currently only the ImzMLParser can be used with the fast
            % methods as it is the only one implemented in Java so far
            if(isa(dataRepresentation.parser, 'ImzMLParser'))
                rois = this.regionOfInterestList.getObjects();
                
                this.javaROIList = com.alanmrace.JSpectralAnalysis.RegionOfInterest.createROIList();
                
                if(this.processEntireDataset)
                    roi = com.alanmrace.JSpectralAnalysis.RegionOfInterest('Entire Dataset', dataRepresentation.regionOfInterest.width, dataRepresentation.regionOfInterest.height);
                    roi.addPixels(dataRepresentation.regionOfInterest.pixelSelection');
                    this.javaROIList.add(roi);
                end
                
                for i = 1:numel(rois)
                    roi = com.alanmrace.JSpectralAnalysis.RegionOfInterest(rois{i}.getName(), dataRepresentation.regionOfInterest.width, dataRepresentation.regionOfInterest.height);
                    roi.addPixels(rois{i}.pixelSelection');
                    this.javaROIList.add(roi);
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
                this.javaDataRepresentation = com.alanmrace.JSpectralAnalysis.datarepresentation.DataOnDisk(javaParser);
            end
            
            % Notify listeners whether we are using FastMethods or not
            notify(this, 'FastMethods', BooleanEventData(canUseFastMethods));
        end
    end
end