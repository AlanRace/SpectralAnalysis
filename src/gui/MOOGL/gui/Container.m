classdef Container < handle
    
    properties (SetAccess = protected)
        % MATLAB figure handle
        handle = [];
        
        buttonColour = [36 160 237]./255;%[0.8 0.8 0.8]; % get(obj.spectrumPreprocessingLabel, 'BackgroundColor')
        iconColour = [1 1 1];
        
        defaultMargin = 5;
        
        defaultLabelSize = 28;
        defaultButtonSize = 28;
        defaultEditBoxSize = 24;
        defaultSelectBoxSize = 24;
        
        defaultColourBarSize = 80;
        
        parent;
    end
    
    events
        ButtonDown;
        ButtonUp;
        ButtonMotion;
        
        SizeChanged;
    end
    
    methods
        function figure = getParentFigure(this)
            if(isa(this, 'Figure'))
                figure = this;
            else
                figure = this.parent.getParentFigure();
            end
        end
        
        function setWidth(this, width)
            % setWidth Set the width of the container in pixels.
            %
            %   setWidth(width)
            %       width - Width in pixels.
            
            units = get(this.handle, 'Units');
            set(this.handle, 'Units', 'pixels');
            currentPosition = get(this.handle, 'Position');
            currentPosition(3) = width;
            
            set(this.handle, 'Position', currentPosition, 'Units', units);
        end
        
        function setHeight(this, height)
            % setHeight Set the height of the container in pixels.
            %
            %   setHeight(height)
            %       height - Height in pixels.
            
            units = get(this.handle, 'Units');
            set(this.handle, 'Units', 'pixels');
            currentPosition = get(this.handle, 'Position');
            currentPosition(4) = height;
            
            set(this.handle, 'Position', currentPosition, 'Units', units);
        end
        
        function setSize(this, width, height)
            % setSize Set the size of the container in pixels.
            %
            %   setSize(width, height)
            %       width - Width in pixels.
            %       height - Height in pixels.
            
            units = get(this.handle, 'Units');
            set(this.handle, 'Units', 'pixels');
            currentPosition = get(this.handle, 'Position');
            currentPosition(3) = width;
            currentPosition(4) = height;
            
            set(this.handle, 'Position', currentPosition, 'Units', units);
        end
    end
    
    methods (Access = protected)
        function buttonDown(this)
            notify(this, 'ButtonDown');
        end
        
        function buttonMotion(this)
            notify(this, 'ButtonMotion');
        end
        
        function buttonUp(this)
            notify(this, 'ButtonUp');
        end
        
        function sizeChanged(this)
            % sizeChanged Callback function for when figure size is changed.
            %
            %   sizeChanged()
            
            notify(this, 'SizeChanged');
        end
    end
    
    methods (Static)
        function position = getPositionInPixels(object) 
            % getPositionInPixels  Get the position of the object within 
            % the figure in pixels.
            %
            %    position = getPositionInPixels(object) 
            
            
            oldUnits = get(object, 'Units');
            set(object, 'Units', 'pixels');
            
            position = get(object, 'Position');
            set(object, 'Units', oldUnits);
        end
        
        function setObjectPositionInPixels(object, newPosition)
            % setObjectPositionInPixels Set the position of object in 
            % pixels.
            %
            %   setObjectPositionInPixels(object, newPosition) 
            
            % Ensure that we're setting the size to a valid one
            if(newPosition(3) > 0 && newPosition(4) > 0)
                oldUnits = get(object, 'Units');
                set(object, 'Units', 'pixels');
                set(object, 'Position', newPosition);
                set(object, 'Units', oldUnits);
            end
        end
    end
end