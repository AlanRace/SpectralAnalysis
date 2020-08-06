classdef DataReduction < PostProcessing
    properties (SetAccess = protected)
        peakList;
        
%         % 0 - extract at location
%         % 1 - integrate over peak
% %         imageGenerationMethod = 0;
        
        dataRepresentationList;
    end
    
    methods
        function setPeakList(obj, peakList)
            obj.peakList = peakList;
        end
                
%         function setExtractAtLocation(this)
%             this.imageGenerationMethod = 0;
%         end
%         
%         function setIntegrateOverPeak(this)
%             this.imageGenerationMethod = 1;
%         end
        
        
        
        function viewer = displayResults(this, dataViewer)
            for i = 1:this.dataRepresentationList.getSize()
                this.dataRepresentationList.get(i)
                viewer = DimRedDataViewer(this.dataRepresentationList.get(i));
            end
        end
    end
end