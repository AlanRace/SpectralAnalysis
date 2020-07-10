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
        
        function [spectralChannels, intensities, peakDetails] = applyFilter(this, spectralChannels, intensities, peakDetails)
            if(this.absolute)
                spectralChannels(intensities < this.threshold) = [];
                peakDetails(intensities < this.threshold, :) = [];
                intensities(intensities < this.threshold) = [];
            else
                relIntensities = intensities ./ max(intensities);
                relThreshold = this.threshold / 100;
                
                spectralChannels(relIntensities < relThreshold) = [];
                intensities(relIntensities < relThreshold) = [];
                peakDetails(relIntensities < relThreshold, :) = [];
            end
        end
    end
end