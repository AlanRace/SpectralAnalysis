classdef MouseEventData < event.EventData
    properties (Constant)
        ButtonDown = 1;
        ButtonUp = 2;
        MouseMoved = 3;
        DoubleClick = 4;
        
        LeftButton = 1;
        RightButton = 2;
    end
    
    properties (SetAccess = protected)
        mouseEvent;
        button;
        
        x;
        y;
    end
    
    methods
        function data = MouseEventData(mouseEvent, x, y)
            % Check mouse event inputs
            if(~isnumeric(mouseEvent))
                exception = MException('MouseEventData:invalidArgument', ['Invalid mouseEvent specified: ' mouseEvent]);
                throw(exception);
            else
                switch mouseEvent
                    case MouseEventData.ButtonDown
                    case MouseEventData.ButtonUp
                    case MouseEventData.MouseMoved
                    case MouseEventData.DoubleClick
                    otherwise
                        % Not a recognised mouse event
                        exception = MException('MouseEventData:invalidArgument', ['Invalid mouseEvent specified: ' num2str(mouseEvent)]);
                        throw(exception);
                end
            end
            
            if(~isnumeric(x) || ~isnumeric(y))
                exception = MException('MouseEventData:invalidArgument', ['Invalid coordinates specified x: ' x ', y: ' y]);
                throw(exception);
            end
            
            data.mouseEvent = mouseEvent;
            data.x = x;
            data.y = y;
        end

        function setButton(obj, button)
            if(~isnumeric(button))
                exception = MException('MouseEventData:invalidArgument', ['Invalid button specified: ' button]);
                throw(exception);
            end
            
            switch button
                case MouseEventData.LeftButton
                case MouseEventData.RightButton
                otherwise
                    % Not a recognised mouse event
                    exception = MException('MouseEventData:invalidArgument', ['Invalid button specified: ' num2str(button)]);
                    throw(exception);
            end
            
            obj.button = button;
        end
    end
end