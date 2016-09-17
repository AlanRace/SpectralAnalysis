classdef SNREstimator < Processing
    
    properties(Access = protected)
        snr;
    end
    
    methods (Abstract)
        estimate(this, spectralData);
    end
    
    methods
        function snr = getSNR(this)
            snr = this.snr;
        end
    end
    
    methods (Static)
        function bool = defaultsRequireGenerating()
            bool = 0;
        end                
        
        function Parameters = generateDefaultsFromSpectrum(spectrum)
        end
    end
end