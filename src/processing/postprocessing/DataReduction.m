classdef DataReduction < PostProcessing
    properties (SetAccess = protected)
        peakList;
        peakDetails;
        
%         % 0 - extract at location
%         % 1 - integrate over peak
% %         imageGenerationMethod = 0;
        
        dataRepresentationList;
    end
    
    methods
        function setPeakList(obj, peakList)
            obj.peakList = peakList;
        end
        
        function setPeakDetails(obj, peakDetails)
            obj.peakDetails = peakDetails;
        end
        
%         function setExtractAtLocation(this)
%             this.imageGenerationMethod = 0;
%         end
%         
%         function setIntegrateOverPeak(this)
%             this.imageGenerationMethod = 1;
%         end
        
        function spectrum = getProcessedSpectrum(this, dataRepresentation, x, y)
            spectrum = getProcessedSpectrum@PostProcessing(this, dataRepresentation, x, y);
            
            if(~isempty(this.peakList) || ~isempty(this.peakDetails))
                intensities = zeros(1, length(this.peakList));
                
                switch(this.imageGenerationMethod)
                    case 0
                        [indicesList, pList] = ismember(this.peakList, spectrum.spectralChannels);

                        pList(pList == 0) = [];
                        intensities(indicesList) = spectrum.intensities(pList);
                    case 1
                        for i = 1:size(this.peakDetails, 1)
                            intensities(i) = sum(spectrum.intensities(spectrum.spectralChannels >= this.peakDetails(i, 1) & spectrum.spectralChannels <= this.peakDetails(i, 3)));
                        end
%                         this.peakDetails
%                         size(this.peakDetails, 1)
%                         size(this.peakDetails)
%                         intensities(i)
                end
                
                spectrum = SpectralData(this.peakList, intensities);
            end
        end
        
        function viewer = displayResults(this, dataViewer)
            for i = 1:this.dataRepresentationList.getSize()
                this.dataRepresentationList.get(i)
                viewer = DimRedDataViewer(this.dataRepresentationList.get(i));
            end
        end
    end
end