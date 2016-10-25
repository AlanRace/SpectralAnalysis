classdef PeakFilterListEditor < Editor
    properties (SetAccess = private)        
        spectrumDisplay;
        spectrumPanel;
        
        peakDetection;
    end
    
%     events
%         FinishedEditingPeakFilterList;
%     end
    
    properties (Access = private)
        % Store handles of each child interface element
        contextMenu;
        
        spectrumLabel;
%         spectrumAxis;
        
        peakFilterList;
        moveUpButton;
        moveDownButton;
        removeButton;
        
        peakFilterLabel;
        peakFilterSelectionPopup;
        peakFilterAddButton;
        peakFilterMethodFiles;
        
%         okButton;
        
        peakFilterEditor;
    end
    
    methods
        function obj = PeakFilterListEditor(spectrum, peakDetection)
            if(~isa(spectrum, 'SpectralData'))
                exception = MException('PeakFilterListEditor:invalidArgument', 'Must provide an instance of SpectralData');
                throw(exception);
            end
            
            if(~isa(peakDetection, 'SpectralPeakDetection'))
                exception = MException('PeakFilterListEditor:invalidArgument', 'Must provide an instance of SpectralPeakDetection');
                throw(exception);
            end
            
%             obj.createFigure();
            
            obj.setTitle('Peak Filter List Editor');

            obj.spectrumPanel = SpectrumPanel(obj, spectrum);
            obj.spectrumDisplay = obj.spectrumPanel.spectrumDisplay; %SpectrumDisplay(obj, spectrum);
            obj.peakDetection = peakDetection;
            
            obj.spectrumDisplay.disableContextMenu();
            obj.spectrumDisplay.setPeakDetection(obj.peakDetection);
            
%             set(obj.handle, 'WindowButtonMotionFcn', @(src,evnt)obj.mouseMovedCallback());
%             set(obj.handle, 'WindowButtonUpFcn', @(src, evnt)obj.mouseButtonUpCallback());

            obj.sizeChanged();

        end
        
        function mouseMovedCallback(obj)
            obj.beforeSpectrumDisplay.mouseMovedCallback();
            obj.afterSpectrumDisplay.mouseMovedCallback();
        end
        
        function mouseButtonUpCallback(obj)
            obj.beforeSpectrumDisplay.mouseButtonUpCallback();
            obj.afterSpectrumDisplay.mouseButtonUpCallback();
        end
        
        
        
        function addPeakFilterCallback(obj)
            % Check if we have already opened the
            % PeakFilterEditor and if so if it is still a valid
            % instance of the class. If so show it, otherwise recreate it
            if(isa(obj.peakFilterEditor, 'PeakFilterEditor') && isvalid(obj.peakFilterEditor))
                figure(obj.peakFilterEditor.handle);
            else
                index = get(obj.peakFilterSelectionPopup, 'Value');
                
                if(index > 1)
                    obj.peakFilterEditor = PeakFilterEditor(obj.spectrumDisplay.data, obj.peakFilterMethodFiles{index});
                    obj.peakFilterEditor
                else
                        error('Invalid Peak Filter');
                end

                if(isa(obj.peakFilterEditor, 'PeakFilterEditor'))
                    % Add a listener for updating preprocessingMethod list
                    addlistener(obj.peakFilterEditor, 'FinishedEditingPeakFilter', @(src, evnt)obj.finishedEditingPeakFilter());
                end
            end
        end
        
        function finishedEditingPeakFilter(obj)
            if(isa(obj.peakFilterEditor, 'PeakFilterEditor'))
                peakFilter = obj.peakFilterEditor.peakFilter;
                
                obj.peakDetection.addPeakFilter(peakFilter);
%                warning('TODO: update the preprocesisngMethod list and update the after spectrum');
            end
            
            obj.updatePeakFilterList();
            
            obj.peakFilterEditor = [];
        end
        
        function updatePeakFilterList(obj)
            listItems = {};
            
            for i = 1:obj.peakDetection.numberOfFilters()
                peakFilter = obj.peakDetection.getPeakFilter(i);
                
                listItems{i} = peakFilter.toString();
            end
            
            if(isempty(listItems))
                listItems = {''};
            end
            
            set(obj.peakFilterList, 'String', listItems);
            
            obj.spectrumDisplay.updatePeakDetection();
        end
        
        function moveUpButtonCallback(obj)
           selectedIndex = get(obj.peakFilterList, 'Value');
           
           if(selectedIndex > 1)
               obj.peakDetection.swap(selectedIndex, selectedIndex - 1);
               obj.updatePeakFilterList();
               
               if(selectedIndex - 1  >= 1)
                   set(obj.peakFilterList, 'Value', selectedIndex - 1);
               end
           end
        end
        
        function moveDownButtonCallback(obj)
            selectedIndex = get(obj.peakFilterList, 'Value');
           
           if(selectedIndex < obj.peakDetection.numberOfFilters())
               obj.peakDetection.swap(selectedIndex, selectedIndex + 1);
               obj.updatePeakFilterList();
               
               if(selectedIndex + 1  <= obj.peakDetection.numberOfFilters())
                   set(obj.peakFilterList, 'Value', selectedIndex + 1);
               end
           end
        end
        
        function removeButtonCallback(obj)
            selectedIndex = get(obj.peakFilterList, 'Value');
           
            if(selectedIndex > 1 && selectedIndex == obj.peakDetection.numberOfFilters())
                set(obj.peakFilterList, 'Value', selectedIndex - 1);
            end
            
           obj.peakDetection.removePeakFilter(selectedIndex);
           
           obj.updatePeakFilterList();
        end
        
        function updatePeakFilterPopup(obj)
            % Find all classes to populate the selection drop-down
            % boxes
            currentPath = mfilename('fullpath');
            [pathstr, name, ext] = fileparts(currentPath);
            
            %warning('TODO: Update this with the correct structure');
            spectralAnalysisPath = pathstr;
            
            fileList = dir([spectralAnalysisPath filesep '*.m']);
            
%             peakFilterClasses = {'None'};
%             obj.peakFilterMethodFiles = {'None'};
            [obj.peakFilterMethodFiles, peakFilterClasses] = getSubclasses('PeakFilter', 1);
            
%             for i = 1:length(fileList)
%                 filename = fileList(i).name(1:end-2); % Strip off the .m
%                 
%                 if(exist(filename, 'class'))
%                     if(ismember('PeakFilter', superclasses(filename)))
%                         peakFilterClasses{end+1} = eval([filename '.Name']);
%                         obj.peakFilterMethodFiles{end+1} = filename;
%                     end
%                 end
%             end
            
            set(obj.peakFilterSelectionPopup, 'String', peakFilterClasses);
        end
        
%         function okButtonCallback(obj)
%             notify(obj, 'FinishedEditingPeakFilterList'); %, obj.preprocessingMethod);
%             
%             obj.delete();
%         end
    end
    
    methods (Access = protected)
        function createFigure(obj)
            if(isempty(obj.handle) || ~obj.handle)
                createFigure@Editor(obj);
%                 obj.handle = figure(...
%                     'Name', 'Peak Filter List Editor', 'NumberTitle','off',...
%                     'Units','characters',...
%                     'MenuBar','none',...
%                     'Toolbar','none', ...
%                     'CloseRequestFcn', @(src, evnt)obj.closeRequest());
                
%                 if(isprop(obj.handle, 'SizeChangedFcn'))
%                     set(obj.handle, 'SizeChangedFcn', @(src, evnt)obj.sizeChanged());
%                 else
%                     set(obj.handle, 'ResizeFcn', @(src, evnt)obj.sizeChanged());
%                 end                   
                
                obj.createContextMenu();
                set(obj.handle, 'uicontextmenu', obj.contextMenu);
                
                obj.spectrumLabel = uicontrol(obj.handle, 'Style', 'text', 'Units', 'normalized', ...
                    'Position', [0.4 0.90 0.15 0.05], 'String', '');
%                 obj.spectrumAxis = axes('Parent', obj.handle, 'Position', [.1 .55 .8 .35]);
                
                obj.peakFilterList = uicontrol(obj.handle, 'Style', 'listbox', ...
                    'Units', 'normalized', 'Position', [0.1 0.1 0.25 0.35]);

                obj.moveUpButton = uicontrol(obj.handle, 'String', '^', ...
                    'Units', 'normalized', 'Position', [0.36 0.35 0.05 0.05], 'Callback', @(src, evnt)obj.moveUpButtonCallback());
                obj.moveDownButton = uicontrol(obj.handle, 'String', 'v', ...
                    'Units', 'normalized', 'Position', [0.36 0.2 0.05 0.05], 'Callback', @(src, evnt)obj.moveDownButtonCallback());
                obj.removeButton = uicontrol(obj.handle, 'String', '-', ...
                    'Units', 'normalized', 'Position', [0.36 0.275 0.05 0.05], 'Callback', @(src, evnt)obj.removeButtonCallback());
                
                obj.peakFilterLabel = uicontrol(obj.handle, 'Style', 'text', 'Units', 'normalized', ...
                    'Position', [0.48 0.4 0.22 0.04], 'String', 'Peak Filter', 'HorizontalAlignment', 'left');
                obj.peakFilterSelectionPopup = uicontrol(obj.handle, 'Style', 'popup', 'Units', 'normalized', ...
                    'Position', [0.7 0.4 0.2 0.04], 'String', 'None');
                obj.peakFilterAddButton = uicontrol(obj.handle, 'Units', 'normalized', ...
                    'Position', [0.9 0.4 0.04 0.04], 'String', '+', ...
                    'Callback', @(src, evnt)obj.addPeakFilterCallback());
                
%                 obj.okButton = uicontrol(obj.handle, 'String', 'OK', ...
%                     'Units', 'normalized', 'Position', [0.8 0.05 0.15 0.05], 'Callback', @(src, evnt)obj.okButtonCallback());
                
                obj.updatePeakFilterPopup();
            end
        end
        
        function createContextMenu(obj)
            % Set up the context menu
            obj.contextMenu = uicontextmenu();
            %exportDataMenu = uimenu(obj.contextMenu, 'Label', 'Export Data', 'Callback', []);
            %uimenu(exportDataMenu, 'Label', 'To workspace', 'Callback', @(src,evnt)obj.b.exportToWorkspace());
            
            exportWorkflowMenu = uimenu(obj.contextMenu, 'Label', 'Export Workflow', 'Callback', []);
            uimenu(exportWorkflowMenu, 'Label', 'To workspace', 'Callback', @(src,evnt)obj.preprocessingWorkflow.exportToWorkspace());
        end
        
        function sizeChanged(obj, src, evnt)
            if(obj.handle ~= 0)
                oldUnits = get(obj.handle, 'Units');
                set(obj.handle, 'Units', 'pixels');
            
                newPosition = get(obj.handle, 'Position');

                Figure.setObjectPositionInPixels(obj.spectrumPanel.handle, [30 newPosition(4)/2 newPosition(3)-80 newPosition(4)/2-30]);
                
%                 axisOldUnits = get(obj.spectrumAxis, 'Units');
%                 set(obj.spectrumAxis, 'Units', 'pixels');
%                 set(obj.spectrumAxis, 'Position', [50 newPosition(4)/2 newPosition(3)-80 newPosition(4)/2-30]);
%                 set(obj.spectrumAxis, 'Units', axisOldUnits);

                % Sort out the 'Before' label
                labelOldUnits = get(obj.spectrumLabel, 'Units');
                set(obj.spectrumLabel, 'Units', 'pixels');
                labelOldPosition = get(obj.spectrumLabel, 'Position');
                set(obj.spectrumLabel, 'Position', [labelOldPosition(1) newPosition(4)-28 labelOldPosition(3) 20]);
                set(obj.spectrumLabel, 'Units', labelOldUnits);

                set(obj.handle, 'Units', oldUnits);
            end
            
            sizeChanged@Editor(obj);
        end
    end
end