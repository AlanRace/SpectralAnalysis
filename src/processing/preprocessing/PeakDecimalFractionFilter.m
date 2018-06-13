classdef PeakDecimalFractionFilter < PeakFilter
    properties (Constant)
        Name = 'Peak Decimal Fraction';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Minimum', ParameterType.Double, 0.2), ...
            ParameterDescription('Maximum', ParameterType.Double, 0.9)];
    end
    
    properties
        minimum;
        maximum;
    end
    
    methods
        function this = PeakDecimalFractionFilter(minimum, maximum)
            if(nargin == 2)
                this.Parameters = Parameter(PeakDecimalFractionFilter.ParameterDefinitions(1), minimum);
                this.Parameters(2) = Parameter(PeakDecimalFractionFilter.ParameterDefinitions(2), maximum);

                this.minimum = minimum;
                this.maximum = maximum;
            end
        end
        
        function [spectralChannels, intensities, peakDetails] = applyFilter(this, spectralChannels, intensities, peakDetails)
            decimalPart = spectralChannels - floor(spectralChannels);

            toKeep = decimalPart >= this.minimum & decimalPart <= this.maximum;
            
            spectralChannels = spectralChannels(toKeep);
            intensities = intensities(toKeep);
            peakDetails = peakDetails(toKeep, :);
        end
    end
end