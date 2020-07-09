classdef SpectralZeroFilling < SpectralPreprocessing
    methods (Abstract)
        [spectralChannels, intensities] = zeroFill(obj, spectralChannels, intensities);     
    end
    
    methods
        function [spectralChannels, intensities] = process(obj, spectralChannels, intensities)
            [spectralChannels, intensities] = obj.zeroFill(spectralChannels, intensities);
        end
    end
end