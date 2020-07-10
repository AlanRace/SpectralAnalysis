classdef SpectralNormalisation < SpectralPreprocessing
    methods (Abstract)
        [spectralChannels, intensities] = normalise(obj, spectralChannels, intensities);     
    end
    
    methods
        function [spectralChannels, intensities] = process(obj, spectralChannels, intensities)
            [spectralChannels, intensities] = obj.normalise(spectralChannels, intensities);
        end
    end
end