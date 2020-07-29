classdef Figure < Container
    % Figure Base class to handle common GUI properties and actions.
    
    properties (SetAccess = protected)
        toolbarHandle;
    end
    
    events
        % Triggered when user attempts to close the figure
        CloseRequested;
        % Triggered after figure is closed
        FigureClosed;
        % Triggered when an information message is created
        InfoMessage;
    end
    
    methods
        function this = Figure()
            % Figure Create figure window.
            
            this.createFigure();
        end
        
        function setTitle(this, title)
            % setTitle Set the title of the figure window.
            %
            %   setTitle(title)
            %       title - Title to assign.
            
            set(this.handle, 'Name', title);
        end
        
        function delete(this)
            % delete Close and delete the figure.
            %
            %   delete()
            %
            %   The 'FigureClosed' event will be triggered prior to
            %   deleting the figure handle.
            
            notify(this, 'FigureClosed');
            
            if(this.handle ~= 0)
                delete(this.handle);
            end
            
            this.handle = 0;
        end
        
        function closeRequest(this)
            % closeRequest Trigger the 'CloseRequested' event and then delete the figure.
            %
            %   closeRequest()
            %
            
            notify(this, 'CloseRequested');
            
            this.delete();
        end
        
        function figure = getParentFigure(this)
            figure = this;
        end
        
        
        function showStandardMenu(this)
            set(this.handle, 'MenuBar', 'figure');
        end
        
        function showStandardToolbar(this)
            set(this.handle, 'Toolbar', 'figure');
        end
        
        function showStandardFigure(this)
            this.showStandardMenu();
            this.showStandardToolbar();
        end
        
        function setWidthPixels(this, width)
            oldUnits = get(this.handle, 'Units');
            set(this.handle, 'Units', 'pixels');
            
            position = get(this.handle, 'Position');
            position(3) = width;
            
            set(this.handle, 'Position', position);
            set(this.handle, 'Units', oldUnits);
        end
    end
    
    methods (Access = protected)
        
        function createFigure(this)
            % createFigure Create figure.
            %
            %   createFigure()
            if(isempty(this.handle))
                if this.isUIFigure
                    this.handle = uifigure(...
                        'Name', 'Figure', ...
                        'AutoResizeChildren', 'off', ...
                        'CloseRequestFcn', @(src, evnt)this.closeRequest(), ...
                        'WindowButtonMotionFcn', @(src, evnt)this.buttonMotion(), ...
                        'WindowButtonUpFcn', @(src, evnt)this.buttonUp());
                else
                    this.handle = figure(...
                        'Name', 'Figure', ...
                        'AutoResizeChildren', 'off', ...
                        'NumberTitle','off',...
                        'Units','characters',...
                        'MenuBar','none',...
                        'Toolbar','none', ...
                        'CloseRequestFcn', @(src, evnt)this.closeRequest(), ...
                        'WindowButtonMotionFcn', @(src, evnt)this.buttonMotion(), ...
                        'WindowButtonUpFcn', @(src, evnt)this.buttonUp());
                end
                
                % Set the callback for when the window is resized
                if(isprop(this.handle, 'SizeChangedFcn'))
                    set(this.handle, 'SizeChangedFcn', @(src, evnt)this.sizeChanged());
                else
                    set(this.handle, 'ResizeFcn', @(src, evnt)this.sizeChanged());
                end
            end
            
            this.createMenu();
            this.createToolbar();
        end
        
        function createMenu(this)
            % createMenu Create and add a menu to the figure.
            %
            %    createMenu()
        end
        
        function createToolbar(this)
            % createToolbar Create and add a toolbar to the figure.
            %
            %    createToolbar()
        end
        
    end
    
    
    
end