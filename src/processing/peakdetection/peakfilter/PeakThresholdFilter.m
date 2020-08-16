classdef PeakThresholdFilter < PeakFilter
    properties (Constant)
        Name = 'Peak Intensity Threshold';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Absolute', ParameterType.Boolean, 1), ...
            ParameterDescription('Threshold', ParameterType.Double, 5)];
    end
    
    properties
        absolute;
        threshold;
    end
    
    methods
        function this = PeakThresholdFilter(absolute, threshold)
            if(nargin == 2)
                this.Parameters = Parameter(PeakThresholdFilter.ParameterDefinitions(1), absolute);
                this.Parameters(2) = Parameter(PeakThresholdFilter.ParameterDefinitions(2), threshold);

                this.absolute = absolute;
                this.threshold = threshold;
            end
        end
        
        function peaks = applyFilter(this, spectralData, peaks)
            peakIntensities = [peaks.intensity];
            
            if(this.absolute)
                peaks(peakIntensities < this.threshold) = [];
            else
                relIntensities = peakIntensities ./ max(peakIntensities);
                relThreshold = this.threshold / 100;
                
                peaks(relIntensities < relThreshold) = [];
            end
        end
    end
end