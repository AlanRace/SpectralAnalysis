classdef SpectralPreprocessing < Processing
    
    methods (Abstract)
        [spectralChannels, intensities] = process(obj, spectralChannels, intensities);
    end
    
    methods (Static)
        function bool = defaultsRequireGenerating()
            bool = 0;
        end                
        
        function Parameters = generateDefaultsFromSpectrum(spectrum)
        end
    end
end