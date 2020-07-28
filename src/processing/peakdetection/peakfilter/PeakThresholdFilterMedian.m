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
        
        function [spectralChannels, intensities, peakDetails] = applyFilter(this, spectralChannels, intensities, peakDetails)
            if(this.absolute)
                nzm = median(nonzeros(intensities));
                threshold = this.multiplier * nzm;
                spectralChannels(intensities < threshold) = [];
                peakDetails(intensities < threshold, :) = [];
                intensities(intensities < threshold) = [];
            else
                relIntensities = intensities ./ max(intensities);
                nzm = median(nonzeros(relIntensities));
                relThreshold = this.multiplier * nzm;
                spectralChannels(relIntensities < relThreshold) = [];
                intensities(relIntensities < relThreshold) = [];
                peakDetails(relIntensities < relThreshold, :) = [];
            end
        end
    end
end
