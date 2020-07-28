classdef PeakThresholdFilterMedian < PeakFilter
    properties (Constant)
        Name = 'Median noise threshold';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Absolute', ParameterType.Boolean, 1), ...
            ParameterDescription('Threshold at n * nonzero median', ParameterType.Double, 3)];
    end
    
    properties
        absolute;
        multiplier;
    end
    
    methods
        function this = PeakThresholdFilterMedian(absolute, multiplier)
            if(nargin == 2)
                this.Parameters = Parameter(PeakThresholdFilterMedian.ParameterDefinitions(1), absolute);
                this.Parameters(2) = Parameter(PeakThresholdFilterMedian.ParameterDefinitions(2), multiplier);

                this.absolute = absolute;
                this.multiplier = multiplier;
            end
        end
        
        function peaks = applyFilter(this, spectralData, peaks)
            intensities = spectralData.intensities;
            
            peakIntensities = [peaks.intensity];
            
            if(this.absolute)
                nzm = median(nonzeros(intensities));
                threshold = this.multiplier * nzm;
                
                peaks(peakIntensities < threshold) = [];
            else
                relIntensities = intensities ./ max(intensities);
                nzm = median(nonzeros(relIntensities));
                relThreshold = this.multiplier * nzm;
                
                peaks(relIntensities < relThreshold) = [];
            end
        end
    end
end
