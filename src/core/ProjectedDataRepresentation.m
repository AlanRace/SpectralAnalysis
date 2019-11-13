classdef ProjectedDataRepresentation < handle
    %PROJECTEDDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods (Abstract)
        spectrum = getProjectedSpectrum(obj, index);
    end
end

