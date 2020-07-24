classdef Display < handle
    properties (SetAccess = private)
        data; % Data to be displayed
        
        parent; % Parent of the display, either Figure or Panel
        axisHandle; % Axis handle used to display the data
    end
    
    properties (Access = protected)
        % dataListener is listener that is added to the data and is
        % triggered each time the data is updated. This is deleted and renewed
        % each time the data is changed.
        dataListener; 
        
        contextMenu; % Context menu stored on <b>parent</b>
        exportMenu; % Context sub-menu storing details about exporting data
        
        lastSavedPath = ''; % The last used path for saving data to the harddisk
    end

    events
        % DisplayChanged is triggered when the display is updated (i.e. the
        % view is changed somehow)
        DisplayChanged;
    end
    
    methods
        function obj = Display(parent, data)
            % Display creates a display for the <i>data</i> in the
            % <i>parent</i> Figure or Panel. If the supplied parent is
            % anything other than Figure or Panel then en exception is
            % thrown.
            %
            % Axis and context menu are created and the data is displayed.
            
            if(isempty(parent) || (~isa(parent, 'Figure') && ~isa(parent, 'Panel')))
                exception = MException('Display:invalidArgument', '''parent'' must be a valid instance of Figure or Panel');
                throw(exception);
            end
            
            obj.parent = parent;
            parentHandle = parent.handle;
            
            obj.axisHandle = axes('Parent', parentHandle);
            
            obj.setData(data);
            
            obj.createContextMenu();
            
            % Set up callbacks
            set(obj.axisHandle, 'UIContextMenu', obj.contextMenu);
        end
        
        function data = getData(this)
            % getData returns the raw data being displayed
            
            data = this.data;
        end
        
        function setData(obj, data)
            % setData sets the specified data to be displayed and updates
            % the display.
            
            if(~isa(data, 'Data'))
                exception = MException('Display:invalidArgument', 'Must provide an instance of a class that extends Data');
                throw(exception);
            end
            
            if(~isempty(obj.dataListener))
                delete(obj.dataListener);
            end
            
            obj.dataListener = addlistener(data, 'DataChanged', @(src, evnt)obj.updateDisplay());
            
            obj.data = data;
            obj.updateDisplay();
        end
        
        function createContextMenu(obj)
            % createContextMenu creates a context menu on the <b>parent</b>
            % of the Display. This overrides any existing context menu.
            
            parentHandle = obj.parent.getParentFigure().handle;
            
            % Set up the context menu
            obj.contextMenu = uicontextmenu('Parent', parentHandle);
            uimenu(obj.contextMenu, 'Label', 'Open in new window', 'Callback', @(src,evnt)obj.openInNewWindow());
            uimenu(obj.contextMenu, 'Label', 'Open copy in new window', 'Callback', @(src,evnt)obj.openCopyInNewWindow());
            
            % Set up export menu
            obj.exportMenu = uimenu(obj.contextMenu, 'Label', 'Export Data', 'Callback', []);
            
            if(~isdeployed())
                uimenu(obj.exportMenu, 'Label', 'To workspace', 'Callback', @(src,evnt)obj.data.exportToWorkspace());
            end
            
            uimenu(obj.exportMenu, 'Label', 'To MATLAB .mat file', 'Callback', @(src, evnt)obj.exportToMAT()); 
            uimenu(obj.exportMenu, 'Label', 'To PDF', 'Callback', @(src, evnt)obj.exportToImage());
%             uimenu(obj.exportMenu, 'Label', 'To LaTeX', 'Callback', @(src, evnt)obj.exportToLaTeX());
        end
        
        function exportToMAT(this)
            % exportToMAT exports the data to a .mat file
            
            [fileName, pathName, filterIndex] = uiputfile([this.lastSavedPath 'data.mat'], 'Export data');
            
            if(filterIndex > 0)
                this.lastSavedPath = [pathName filesep];
                
                save([pathName filesep fileName], 'this.data');
            end
        end
        
        function disableContextMenu(this)
            % disableContextMenu deletes and removes the context menu
            
            delete(this.contextMenu);
            
            this.contextMenu = [];
        end
        
        function updateDisplay(this)
            % updateDisplay should be overriden by subclasses to update the
            % display. Display.updateDisplay simply notifies listeners of
            % the DisplayChanged event
            
            notify(this, 'DisplayChanged');
        end
    end
    
    methods (Abstract)
        % openInNewWindow opens the data in a new window, copying any 
        % display settings.
        openInNewWindow(obj);
        % openCopyInNewWindow makes a copy of the data and opents this in 
        % a new window, copying any display settings.
        openCopyInNewWindow(obj);
        
        % exportToImage exports the visualised data to a PDF image
        exportToImage(obj);
        % exportToLaTeX exports the visualised data to LaTeX
        exportToLaTeX(obj);
    end
end