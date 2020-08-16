classdef BooleanEventData < event.EventData
    properties (SetAccess = protected)
        bool;
        event;
    end
    
    methods
        function data = BooleanEventData(bool, event)
            data.bool = bool;
            
            if(nargin > 1)
                data.event = event;
            else
                data.event = [];
            end
        end
    end
end