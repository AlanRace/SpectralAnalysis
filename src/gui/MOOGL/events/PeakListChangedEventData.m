classdef PeakListChangedEventData < event.EventData
    
    properties (SetAccess = protected)
        peakList;
    end
    
    methods
        function data = PeakListChangedEventData(peakList)
            % TODO: Check event inputs
            
            data.peakList = peakList;
        end
    end
end