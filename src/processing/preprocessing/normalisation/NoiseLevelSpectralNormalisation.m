classdef NoiseLevelSpectralNormalisation < SpectralNormalisation
    properties (Constant)
        Name = 'Noise Level Normalisation';
        Description = '';
        
        ParameterDefinitions = [];
    end
    
    methods
        function this = NoiseLevelSpectralNormalisation()
        end
        
        function [spectralChannels, intensities] = normalise(this, spectralChannels, intensities)
%			intesitiesToUse = intensities;
			intesitiesToUse = intensities(intensities > 0);
		
            d = intesitiesToUse(2:end) - intesitiesToUse(1:end-1);
            f = median(abs(d - median(d)));
            
            intensities = intensities ./ f;
            
            % Fix NaN and Inf errors
            intensities(isnan(intensities)) = 0;
            intensities(isinf(intensities)) = 0;
        end
    end
end