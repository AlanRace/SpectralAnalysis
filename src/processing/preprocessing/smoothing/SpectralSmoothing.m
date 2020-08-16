classdef SpectralSmoothing < SpectralPreprocessing
    methods (Abstract)
        [spectralChannels, intensities] = smooth(spectralChannels, intensities);     
    end
    
    methods
        function [spectralChannels, intensities] = process(obj, spectralChannels, intensities)
            [spectralChannels, intensities] = obj.smooth(spectralChannels, intensities);
        end
    end
end