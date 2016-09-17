classdef SpectralBaselineCorrection < SpectralPreprocessing
    methods (Abstract)
        [spectralChannels, intensities] = baselineCorrect(spectralChannels, intensities);     
    end
    
    methods
        function [spectralChannels, intensities] = process(obj, spectralChannels, intensities)
            [spectralChannels, intensities] = obj.baselineCorrect(spectralChannels, intensities);
        end
    end
end