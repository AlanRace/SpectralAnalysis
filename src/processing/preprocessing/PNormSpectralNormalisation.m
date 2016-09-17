classdef PNormSpectralNormalisation < SpectralNormalisation
    properties (Constant)
        Name = 'p-norm Normalisation';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('p', ParameterType.Integer, 2)];
    end
    
    properties (Access = private)
        p;
    end
    
    methods
        function this = PNormSpectralNormalisation(p)
            this.p = p;
        end
        
        function [spectralChannels, intensities] = normalise(this, spectralChannels, intensities)
            intensities = intensities ./ nthroot(sum(intensities.^this.p), this.p);
        end
    end
end