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
        
        function peaks = applyFilter(this, spectralData, peaks)
            peakIntensities = [peaks.intensity];
            
            [~, sortedInds] = sort(peakIntensities, 'descend');
            
            if(length(sortedInds) > this.x)
                sortedInds = sortedInds(1:this.x);
            end
            
            peaks = peaks(sortedInds);
            
            % Make sure that the output peaks are in ascending order
            % according to m/z
%             [spectralChannels, sortedInds] = sort(spectralChannels, 'ascend');
%             intensities = intensities(sortedInds);
%             peakDetails = peakDetails(sortedInds, :);
        end
    end
end