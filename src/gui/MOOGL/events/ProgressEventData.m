classdef ProgressEventData < event.EventData
    properties (SetAccess = protected)
        progress;
        event;
    end
    
    methods
        function data = ProgressEventData(progress, event)
            data.progress = progress;
            
            if(nargin > 1)
                data.event = event;
            else
                data.event = [];
            end
        end
    end
end