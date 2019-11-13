classdef SpectralRepresentation < PostProcessing
    
    properties (SetAccess = protected)
        spectrumList
        javaROIList
        javaDataRepresentation
    end
    
    methods (Abstract)
        spectrum = process(obj, dataRepresention);
    end
    
    methods
        function resultsViewer = displayResults(this, dataViewer)
            dataViewer.addSpectra(this.spectrumList)
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
        end
    end
    
end