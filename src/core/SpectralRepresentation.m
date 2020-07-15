classdef SpectralRepresentation < PostProcessing
    
    properties (SetAccess = protected)
        spectrumList
    end
    
    methods (Abstract)
        spectrum = process(obj, dataRepresention);
    end
    
    methods
        function resultsViewer = displayResults(this, dataViewer)
            dataViewer.addSpectra(this.spectrumList)
        end
    end
    
    
    
end