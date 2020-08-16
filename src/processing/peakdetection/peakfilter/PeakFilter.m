classdef PeakFilter < Processing
    methods (Abstract)
        [spectralChannels, intensities, peakDetails] = applyFilter(spectralChannels, intensities, peakDetails);     
    end
        
end