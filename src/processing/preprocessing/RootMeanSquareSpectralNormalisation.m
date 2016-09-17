classdef RootMeanSquareSpectralNormalisation < SpectralNormalisation
    properties (Constant)
        Name = 'Root Mean Square Normalisation';
        Description = '';
        
        ParameterDefinitions = [];
    end
    
    methods
        function obj = RootMeanSquareSpectralNormalisation()
        end
        
        function [spectralChannels, intensities] = normalise(obj, spectralChannels, intensities)
            intensities = intensities ./ sqrt(mean(intensities.^2));
        end
    end
end