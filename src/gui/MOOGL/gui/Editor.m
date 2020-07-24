classdef Editor < Figure
    properties (Access = protected)
        okButton;
    end
    
    events
        FinishedEditing;
    end
    
    methods (Access = protected)
        function createFigure(obj)
            % Call superclass method
            createFigure@Figure(obj);
           
%             obj.addParameterControls();
            
            obj.okButton = uicontrol(obj.handle, 'String', 'OK', ...
                'BackgroundColor', obj.buttonColour, 'ForegroundColor', obj.iconColour, ...
                'Units', 'normalized', 'Position', [0.8 0.05 0.15 0.05], 'Callback', @(src, evnt)obj.okButtonCallback());
        end
        
        function addParameterControls(this)
        end
        
        function okButtonCallback(obj)
            notify(obj, 'FinishedEditing');
            
            obj.closeRequest();
        end
    end
end