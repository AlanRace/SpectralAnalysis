classdef PeakTopXFilter < PeakFilter
    properties (Constant)
        Name = 'Top X Peaks';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('X', ParameterType.Integer, 5)];
    end
    
    properties
        x;
    end
    
    methods
        function this = PeakTopXFilter(x)
            this.Parameters = Parameter(PeakTopXFilter.ParameterDefinitions(1), x);

            this.x = x;
        end
        
        function [spectralChannels, intensities, peakDetails] = applyFilter(this, spectralChannels, intensities, peakDetails)
            [soredInts, sortedInds] = sort(intensities, 'descend');
            
            if(length(sortedInds) > this.x)
                sortedInds = sortedInds(1:this.x);
            end
            
            spectralChannels = spectralChannels(sortedInds);
            intensities = intensities(sortedInds);
            peakDetails = peakDetails(sortedInds, :);
            
            % Make sure that the output peaks are in ascending order
            % according to m/z
            [spectralChannels, sortedInds] = sort(spectralChannels, 'ascend');
            intensities = intensities(sortedInds);
            peakDetails = peakDetails(sortedInds, :);
        end
    end
end