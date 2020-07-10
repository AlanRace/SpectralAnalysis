classdef MedianIntensitySpectralNormalisation < SpectralNormalisation
    properties (Constant)
        Name = 'Median Intensity Normalisation';
        Description = '';
        
        ParameterDefinitions = [];
    end
    
    methods
        function obj = MedianIntensitySpectralNormalisation()
        end
        
        function [spectralChannels, intensities] = normalise(obj, spectralChannels, intensities)
%            med = median(intensities);
% median(intensities)
			med = median(intensities(intensities > 0));
            
            if(med ~= 0)
                intensities = intensities ./ med;

                % Fix NaN and Inf errors
                intensities(isnan(intensities)) = 0;
                intensities(isinf(intensities)) = 0;
            end
        end
    end
end