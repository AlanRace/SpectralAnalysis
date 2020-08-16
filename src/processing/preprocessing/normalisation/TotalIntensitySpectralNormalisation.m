classdef TotalIntensitySpectralNormalisation < SpectralNormalisation
    properties (Constant)
        Name = 'Total Intensity Normalisation';
        Description = '';
        
        ParameterDefinitions = [];
    end
    
    methods
        function obj = TotalIntensitySpectralNormalisation()
        end
        
        function [spectralChannels, intensities] = normalise(obj, spectralChannels, intensities)
%             zeroVals = intensities == 0;
%             sum(intensities)
            intensities(isnan(intensities)) = 0;
            intensities = intensities ./ sum(intensities);
            
%             intensities(zeroVals) = 0;

        end
    end
end