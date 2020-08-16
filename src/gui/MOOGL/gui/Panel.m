classdef Panel < Container
        
    methods
        function this = Panel(parent)
            if(~isa(parent, 'Figure') && ~isa(parent, 'Panel'))
                exception = MException('Panel:invalidArgument', '''parent'' must be a valid instance of Figure or Panel');
                throw(exception);
            end
            
            this.parent = parent;
            
            addlistener(parent, 'ButtonMotion', @(src, evnt) this.buttonMotion());
            addlistener(parent, 'ButtonUp', @(src, evnt) this.buttonUp());
%             addlistener(parent, 'SizeChanged', @(src, evnt) this.sizeChanged());
            
            this.createPanel();
        end
    end
    
    methods(Access = protected)
        function createPanel(this)
            this.handle = uipanel(this.parent.handle, 'AutoResizeChildren', 'off');
            
            if this.isUIFigure
                this.handle.BorderType = 'none';
                this.handle.AutoResizeChildren = 'off';
                this.handle.SizeChangedFcn = @(src, evnt) this.sizeChanged;
            else
                set(this.handle, 'BorderWidth', 0);
                set(this.handle, 'ButtonDownFcn', @(src, evnt) this.buttonDown());
                
                addlistener(this.parent, 'SizeChanged', @(src, evnt) this.sizeChanged());
            end
        end
    end
end