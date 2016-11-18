classdef SpectralRepresentation < PostProcessing
    
    methods (Abstract)
        spectrum = process(obj, dataRepresention);
    end
end