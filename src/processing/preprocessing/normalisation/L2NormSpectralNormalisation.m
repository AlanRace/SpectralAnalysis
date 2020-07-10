classdef L2NormSpectralNormalisation < SpectralNormalisation
    properties (Constant)
        Name = 'L^2 Norm Normalisation';
        Description = '';
        
        ParameterDefinitions = [];
    end
    
    methods
        function obj = L2NormSpectralNormalisation()
        end
        
        function [spectralChannels, intensities] = normalise(obj, spectralChannels, intensities)
            intensities = intensities ./ sqrt(sum(intensities.^2));
        end
    end
end