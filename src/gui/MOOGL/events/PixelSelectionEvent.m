classdef PixelSelectionEvent < event.EventData
    
    properties (SetAccess = protected)
        x;
        y;
    end
    
    methods
        function data = PixelSelectionEvent(x, y)
            
            data.x = x;
            data.y = y;
        end
    end
end