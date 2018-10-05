classdef PreprocessingWorkflowEditor < Editor
    properties (SetAccess = private)
%         handle = 0;
        
        beforeSpectrumDisplay;
        beforeSpectrumPanel;
        
        afterSpectrumDisplay;
        afterSpectrumPanel;
        
        preprocessingWorkflow;
    end
    
%     events
%         FinishedEditingPreprocessingWorkflow;
%     end
    
    properties (Access = private)
        % Store handles of each child interface element
        contextMenu;
        
        beforeLabel;
        beforeAxis;
        afterLabel;
        afterAxis;
        
        preprocessingWorkflowList;
        moveUpButton;
        moveDownButton;
        removeButton;
        
        saveWorkflowButton;
        loadWorkflowButton;
        
        previousPath;
        
        zeroFillingLabel;
        zeroFillingSelectionPopup;
        zeroFillingAddButton;
        zeroFillingMethodFiles;
        
        smoothingLabel;
        smoothingSelectionPopup;
        smoothingAddButton;
        smoothingMethodFiles;
        
        baselineCorrectionLabel;
        baselineCorrectionSelectionPopup;
        baselineCorrectionAddButton;
        baselineCorrectionMethodFiles;
        
        peakDetectionLabel;
        peakDetectionSelectionPopup;
        peakDetectionAddButton;
        peakDetectionMethodFiles;
        
        normalisationLabel;
        normalisationSelectionPopup;
        normalisationAddButton;
        normalisationMethodFiles;
        
%         okButton;
        
        preprocessingMethodEditor;
    end
    
    methods
        function obj = PreprocessingWorkflowEditor(spectrum, preprocessingWorkflow)
            if(~isa(spectrum, 'SpectralData'))
                exception = MException('PreprocessingWorkflowEditor:invalidArgument', 'Must provide an instance of SpectralData');
                
                % Clean up the partly generated interface
                obj.delete();
                
                throw(exception);
            end
            
            obj.createFigure();
            
            obj.setTitle('Preprocessing Workflow Editor');
            
            obj.beforeSpectrumPanel = SpectrumPanel(obj, spectrum);
            obj.beforeSpectrumDisplay = obj.beforeSpectrumPanel.spectrumDisplay; %SpectrumDisplay(obj, spectrum);
            
            afterSpectrum = SpectralData(obj.beforeSpectrumDisplay.data.spectralChannels,obj.beforeSpectrumDisplay.data.intensities);
            
            obj.afterSpectrumPanel = SpectrumPanel(obj, afterSpectrum);
            obj.afterSpectrumDisplay = obj.afterSpectrumPanel.spectrumDisplay;%SpectrumDisplay(obj, afterSpectrum);
            
            set(obj.handle, 'WindowButtonMotionFcn', @(src,evnt)obj.mouseMovedCallback());
            set(obj.handle, 'WindowButtonUpFcn', @(src, evnt)obj.mouseButtonUpCallback());

            if(nargin > 1 && isa(preprocessingWorkflow, 'PreprocessingWorkflow'))
                obj.preprocessingWorkflow = preprocessingWorkflow.copy();
                obj.updatePreprocessingWorkflowList();
            else
                obj.preprocessingWorkflow = PreprocessingWorkflow();
            end
            
            
            %warning('TODO: add listener to PreprocessingWorkflowChanged');
            
            % Ensure that all proportions are correct
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
        
        function saveWorkflowCallback(this)
            % Request location to save workflow
            [filename, path, filter] = uiputfile({'*.sap', 'SpectralAnalysis Preprocessing'}, 'Save Preprocessing Workflow', [this.previousPath filesep 'preprocessingWorkflow.sap']);
            
            if(filter > 0)
                this.previousPath = path;
                location = [path filesep filename];
                
                this.preprocessingWorkflow.saveWorkflow(location);
            end
        end
        
        function loadWorkflowCallback(this)
            [filename, path, filter] = uigetfile({'*.sap', 'SpectralAnalysis Preprocessing'}, 'Load Preprocessing Workflow', this.previousPath);
            
            if(filter > 0)
                this.previousPath = path;
                location = [path filesep filename];
                
                this.preprocessingWorkflow.loadWorkflow(location);
                
                this.updatePreprocessingWorkflowList();
            end
        end
        
        function addPreprocessingMethodCallback(obj, preprocessingType)
            % Check if we have already opened the
            % PreprocessingWorkflowEditor and if so if it is still a valid
            % instance of the class. If so show it, otherwise recreate it
            if(isa(obj.preprocessingMethodEditor, 'PreprocessingMethodEditor') && isvalid(obj.preprocessingMethodEditor))
                figure(obj.preprocessingMethodEditor.handle);
            else
                if(strcmp(preprocessingType, 'zeroFilling'))
                    index = get(obj.zeroFillingSelectionPopup, 'Value');
                elseif(strcmp(preprocessingType, 'smoothing'))
                    index = get(obj.smoothingSelectionPopup, 'Value');
                elseif(strcmp(preprocessingType, 'baselineCorrection'))
                    index = get(obj.baselineCorrectionSelectionPopup, 'Value');
%                 elseif(strcmp(preprocessingType, 'peakDetection'))
%                     index = get(obj.peakDetectionSelectionPopup, 'Value');
                elseif(strcmp(preprocessingType, 'normalisation'))
                    index = get(obj.normalisationSelectionPopup, 'Value');
                else
                    error('Invalid preprocessingType');
                end

                if(index > 1)
                    if(strcmp(preprocessingType, 'zeroFilling'))
                        obj.preprocessingMethodEditor = PreprocessingMethodEditor(obj.afterSpectrumDisplay.data, obj.zeroFillingMethodFiles{index});
                    elseif(strcmp(preprocessingType, 'smoothing'))
                        obj.preprocessingMethodEditor = PreprocessingMethodEditor(obj.afterSpectrumDisplay.data, obj.smoothingMethodFiles{index});
                    elseif(strcmp(preprocessingType, 'baselineCorrection'))
                        obj.preprocessingMethodEditor = PreprocessingMethodEditor(obj.afterSpectrumDisplay.data, obj.baselineCorrectionMethodFiles{index});
%                     elseif(strcmp(preprocessingType, 'peakDetection'))
%                         obj.preprocessingMethodEditor = PreprocessingMethodEditor(obj.afterSpectrumDisplay.data, obj.peakDetectionMethodFiles{index});
                    elseif(strcmp(preprocessingType, 'normalisation'))
                        obj.preprocessingMethodEditor = PreprocessingMethodEditor(obj.afterSpectrumDisplay.data, obj.normalisationMethodFiles{index});
                    else
                        error('Invalid preprocessingType');
                    end
                end

                if(isa(obj.preprocessingMethodEditor, 'PreprocessingMethodEditor'))
                    % Add a listener for updating preprocessingMethod list
                    addlistener(obj.preprocessingMethodEditor, 'FinishedEditing', @(src, evnt)obj.finishedEditingPreprocessingMethod());
                end
            end
        end
        
        function finishedEditingPreprocessingMethod(obj)
            if(isa(obj.preprocessingMethodEditor, 'PreprocessingMethodEditor'))
                preprocessingMethod = obj.preprocessingMethodEditor.preprocessingMethod;
%                warning('TODO: update the preprocesisngMethod list and update the after spectrum');
            end
            
            if(~isa(obj.preprocessingWorkflow, 'PreprocessingWorkflow'))
                obj.preprocessingWorkflow = PreprocessingWorkflow(preprocessingMethod);
            else
                obj.preprocessingWorkflow = obj.preprocessingWorkflow.addPreprocessingMethod(preprocessingMethod);
            end
            
            obj.updatePreprocessingWorkflowList();
            
            obj.preprocessingMethodEditor = [];
        end
        
        function updatePreprocessingWorkflowList(obj)
            listItems = {};
            
            for i = 1:obj.preprocessingWorkflow.numberOfMethods()
                preprocessingMethod = obj.preprocessingWorkflow.getPreprocessingMethod(i);
                
                listItems{i} = preprocessingMethod.toString();
            end
            
            if(isempty(listItems))
                listItems = {''};
            end
            
            set(obj.preprocessingWorkflowList, 'String', listItems);
            
            beforeSpectrum = obj.beforeSpectrumDisplay.data;
%            afterSpecturm = SpectralData(beforeSpectrum.spectralChannels, beforeSpectrum.intensities);

            try
            	afterSpecturm = obj.preprocessingWorkflow.performWorkflow(beforeSpectrum);

            	obj.afterSpectrumDisplay.setData(afterSpecturm);
            catch err 
                err
            end
        end
        
        function moveUpButtonCallback(obj)
           selectedIndex = get(obj.preprocessingWorkflowList, 'Value');
           
           if(selectedIndex > 1)
               obj.preprocessingWorkflow.swap(selectedIndex, selectedIndex - 1);
               obj.updatePreprocessingWorkflowList();
               
               if(selectedIndex - 1  >= 1)
                   set(obj.preprocessingWorkflowList, 'Value', selectedIndex - 1);
               end
           end
        end
        
        function moveDownButtonCallback(obj)
            selectedIndex = get(obj.preprocessingWorkflowList, 'Value');
           
           if(selectedIndex < obj.preprocessingWorkflow.numberOfMethods())
               obj.preprocessingWorkflow.swap(selectedIndex, selectedIndex + 1);
               obj.updatePreprocessingWorkflowList();
               
               if(selectedIndex + 1  <= obj.preprocessingWorkflow.numberOfMethods())
                   set(obj.preprocessingWorkflowList, 'Value', selectedIndex + 1);
               end
           end
        end
        
        function removeButtonCallback(obj)
            selectedIndex = get(obj.preprocessingWorkflowList, 'Value');
           
            if(selectedIndex > 1 && selectedIndex == obj.preprocessingWorkflow.numberOfMethods())
                set(obj.preprocessingWorkflowList, 'Value', selectedIndex - 1);
            end
            
           obj.preprocessingWorkflow.removePreprocessingMethod(selectedIndex);
           
           obj.updatePreprocessingWorkflowList();
        end
        
        function updatePreprocessingPopups(obj)
            % Find all classes to populate the selection drop-down
            % boxes
            currentPath = mfilename('fullpath');
            [pathstr, name, ext] = fileparts(currentPath);
            
            %warning('TODO: Update this with the correct structure');
            spectralAnalysisPath = pathstr;
            
            fileList = dir([spectralAnalysisPath filesep '*.m']);
            
%             zeroFillingClasses = {'None'};
%             obj.zeroFillingMethodFiles = {'None'};
            [obj.zeroFillingMethodFiles zeroFillingClasses] = getSubclasses('SpectralZeroFilling', 1);
            
%             smoothingClasses = {'None'};
%             obj.smoothingMethodFiles = {'None'};
            [obj.smoothingMethodFiles smoothingClasses] = getSubclasses('SpectralSmoothing', 1);
            
%             baselineCorrectionClasses = {'None'};
%             obj.baselineCorrectionMethodFiles = {'None'};
            [obj.baselineCorrectionMethodFiles baselineCorrectionClasses] = getSubclasses('SpectralBaselineCorrection', 1);
            
%             peakDetectionClasses = {'None'};
%             obj.peakDetectionMethodFiles = {'None'};
%             normalisationClasses = {'None'};
%             obj.normalisationMethodFiles = {'None'};
            [obj.normalisationMethodFiles normalisationClasses] = getSubclasses('SpectralNormalisation', 1);
            
%             for i = 1:length(fileList)
%                 filename = fileList(i).name(1:end-2); % Strip off the .m
%                 
%                 if(exist(filename, 'class'))
%                     if(ismember('SpectralZeroFilling', superclasses(filename)))
%                         zeroFillingClasses{end+1} = eval([filename '.Name']);
%                         obj.zeroFillingMethodFiles{end+1} = filename;
%                     elseif(ismember('SpectralSmoothing', superclasses(filename)))
%                         smoothingClasses{end+1} = eval([filename '.Name']);
%                         obj.smoothingMethodFiles{end+1} = filename;
%                     elseif(ismember('SpectralBaselineCorrection', superclasses(filename)))
%                         baselineCorrectionClasses{end+1} = eval([filename '.Name']);
%                         obj.baselineCorrectionMethodFiles{end+1} = filename;
% %                     elseif(ismember('SpectralPeakDetection', superclasses(filename)))
% %                         peakDetectionClasses{end+1} = eval([filename '.Name']);
% %                         obj.peakDetectionMethodFiles{end+1} = filename;
%                     elseif(ismember('SpectralNormalisation', superclasses(filename)))
%                         normalisationClasses{end+1} = eval([filename '.Name']);
%                         obj.normalisationMethodFiles{end+1} = filename;
%                     end
%                 end
%             end
            
            set(obj.zeroFillingSelectionPopup, 'String', zeroFillingClasses);
            set(obj.smoothingSelectionPopup, 'String', smoothingClasses);
            set(obj.baselineCorrectionSelectionPopup, 'String', baselineCorrectionClasses);
%             set(obj.peakDetectionSelectionPopup, 'String', peakDetectionClasses);
            set(obj.normalisationSelectionPopup, 'String', normalisationClasses);
        end
        
%         function okButtonCallback(obj)
%             notify(obj, 'FinishedEditingPreprocessingWorkflow'); %, obj.preprocessingMethod);
%             
%             obj.delete();
%         end
        
        function delete(obj)
            delete(obj.handle);
            obj.handle = 0;
        end
    end
    
    methods (Access = protected)
        function createFigure(obj)
%             if(~obj.handle)
%                 obj.handle = figure(...
%                     'Name', 'Preprocessing Workflow Editor', 'NumberTitle','off',...
%                     'Units','characters',...
%                     'MenuBar','none',...
%                     'Toolbar','none', ...
%                     'CloseRequestFcn', @(src, evnt)obj.closeRequest());
%                 
%                 if(isprop(obj.handle, 'SizeChangedFcn'))
%                     set(obj.handle, 'SizeChangedFcn', @(src, evnt)obj.sizeChanged());
%                 else
%                     set(obj.handle, 'ResizeFcn', @(src, evnt)obj.sizeChanged());
%                 end                   
%                 
%                 obj.createContextMenu();
%                 set(obj.handle, 'uicontextmenu', obj.contextMenu);

            if(isempty(obj.handle) || ~ishandle(obj.handle))
                createFigure@Editor(obj);
                
                obj.beforeLabel = uicontrol(obj.handle, 'Style', 'text', 'Units', 'normalized', ...
                    'Position', [0.2 0.90 0.15 0.05], 'String', 'Before');
%                 obj.beforeAxis = axes('Parent', obj.handle, 'Position', [.1 .55 .35 .35]);
                obj.afterLabel = uicontrol(obj.handle, 'Style', 'text', 'Units', 'normalized', ...
                    'Position', [0.65 0.90 0.15 0.05], 'String', 'After');
%                 obj.afterAxis = axes('Parent', obj.handle, 'Position', [.55 .55 .35 .35]);
                
                obj.preprocessingWorkflowList = uicontrol(obj.handle, 'Style', 'listbox', ...
                    'Units', 'normalized', 'Position', [0.1 0.1 0.25 0.35]);

                obj.moveUpButton = uicontrol(obj.handle, 'String', '^', ...
                    'Units', 'normalized', 'Position', [0.36 0.35 0.05 0.05], 'Callback', @(src, evnt)obj.moveUpButtonCallback());
                obj.moveDownButton = uicontrol(obj.handle, 'String', 'v', ...
                    'Units', 'normalized', 'Position', [0.36 0.2 0.05 0.05], 'Callback', @(src, evnt)obj.moveDownButtonCallback());
                obj.removeButton = uicontrol(obj.handle, 'String', '-', ...
                    'Units', 'normalized', 'Position', [0.36 0.275 0.05 0.05], 'Callback', @(src, evnt)obj.removeButtonCallback());
                
                obj.saveWorkflowButton = uicontrol(obj.handle, 'String', 'Save', ...
                    'Units', 'normalized', 'Position', [0.1 0.05 0.1 0.05], 'Callback', @(src, evnt)obj.saveWorkflowCallback());
                obj.loadWorkflowButton = uicontrol(obj.handle, 'String', 'Load', ...
                    'Units', 'normalized', 'Position', [0.25 0.05 0.1 0.05], 'Callback', @(src, evnt)obj.loadWorkflowCallback());
                
                obj.zeroFillingLabel = uicontrol(obj.handle, 'Style', 'text', 'Units', 'normalized', ...
                    'Position', [0.48 0.4 0.22 0.04], 'String', 'Zero filling', 'HorizontalAlignment', 'left');
                obj.zeroFillingSelectionPopup = uicontrol(obj.handle, 'Style', 'popup', 'Units', 'normalized', ...
                    'Position', [0.7 0.4 0.2 0.04], 'String', 'None');
                obj.zeroFillingAddButton = uicontrol(obj.handle, 'Units', 'normalized', ...
                    'Position', [0.9 0.4 0.04 0.04], 'String', '+', ...
                    'Callback', @(src, evnt)obj.addPreprocessingMethodCallback('zeroFilling'));
                
                obj.smoothingLabel = uicontrol(obj.handle, 'Style', 'text', 'Units', 'normalized', ...
                    'Position', [0.48 0.35 0.22 0.04], 'String', 'Smoothing', 'HorizontalAlignment', 'left');
                obj.smoothingSelectionPopup = uicontrol(obj.handle, 'Style', 'popup', 'Units', 'normalized', ...
                    'Position', [0.7 0.35 0.2 0.04], 'String', 'None');
                obj.smoothingAddButton = uicontrol(obj.handle, 'Units', 'normalized', ...
                    'Position', [0.9 0.35 0.04 0.04], 'String', '+', ...
                    'Callback', @(src, evnt)obj.addPreprocessingMethodCallback('smoothing'));
                
                obj.baselineCorrectionLabel = uicontrol(obj.handle, 'Style', 'text', 'Units', 'normalized', ...
                    'Position', [0.48 0.3 0.22 0.04], 'String', 'Baseline Correction', 'HorizontalAlignment', 'left');
                obj.baselineCorrectionSelectionPopup = uicontrol(obj.handle, 'Style', 'popup', 'Units', 'normalized', ...
                    'Position', [0.7 0.3 0.2 0.04], 'String', 'None');
                obj.baselineCorrectionAddButton = uicontrol(obj.handle, 'Units', 'normalized', ...
                    'Position', [0.9 0.3 0.04 0.04], 'String', '+', ...
                    'Callback', @(src, evnt)obj.addPreprocessingMethodCallback('baselineCorrection'));
                
%                 obj.peakDetectionLabel = uicontrol(obj.handle, 'Style', 'text', 'Units', 'normalized', ...
%                     'Position', [0.48 0.25 0.22 0.04], 'String', 'Peak Detection', 'HorizontalAlignment', 'left');
%                 obj.peakDetectionSelectionPopup = uicontrol(obj.handle, 'Style', 'popup', 'Units', 'normalized', ...
%                     'Position', [0.7 0.25 0.2 0.04], 'String', 'None');
%                 obj.peakDetectionAddButton = uicontrol(obj.handle, 'Units', 'normalized', ...
%                     'Position', [0.9 0.25 0.04 0.04], 'String', '+', ...
%                     'Callback', @(src, evnt)obj.addPreprocessingMethodCallback('peakDetection'));
                
                obj.normalisationLabel = uicontrol(obj.handle, 'Style', 'text', 'Units', 'normalized', ...
                    'Position', [0.48 0.25 0.22 0.04], 'String', 'Normalisation', 'HorizontalAlignment', 'left');
                obj.normalisationSelectionPopup = uicontrol(obj.handle, 'Style', 'popup', 'Units', 'normalized', ...
                    'Position', [0.7 0.25 0.2 0.04], 'String', 'None');
                obj.normalisationAddButton = uicontrol(obj.handle, 'Units', 'normalized', ...
                    'Position', [0.9 0.25 0.04 0.04], 'String', '+', ...
                    'Callback', @(src, evnt)obj.addPreprocessingMethodCallback('normalisation'));
                
%                 obj.okButton = uicontrol(obj.handle, 'String', 'OK', ...
%                     'Units', 'normalized', 'Position', [0.8 0.05 0.15 0.05], 'Callback', @(src, evnt)obj.okButtonCallback());
                
                obj.updatePreprocessingPopups();
            end
        end
        
        function sizeChanged(obj, src, evnt)
            if(obj.handle ~= 0)
                oldUnits = get(obj.handle, 'Units');
                set(obj.handle, 'Units', 'pixels');
            
                newPosition = get(obj.handle, 'Position');

                %obj.beforeSpectrumDisplay.axisHandle
                Figure.setObjectPositionInPixels(obj.beforeSpectrumPanel.handle, [30 newPosition(4)/2 newPosition(3)/2-40 newPosition(4)/2-20]);
                
%                 axisOldUnits = get(obj.beforeAxis, 'Units');
%                 set(obj.beforeAxis, 'Units', 'pixels');
%                 set(obj.beforeAxis, 'Position', [50 newPosition(4)/2 newPosition(3)/2-80 newPosition(4)/2-30]);
%                 set(obj.beforeAxis, 'Units', axisOldUnits);

                Figure.setObjectPositionInPixels(obj.afterSpectrumPanel.handle, [newPosition(3)/2+20 newPosition(4)/2 newPosition(3)/2-40 newPosition(4)/2-20]);

%                 axisOldUnits = get(obj.afterAxis, 'Units');
%                 set(obj.afterAxis, 'Units', 'pixels');
%                 set(obj.afterAxis, 'Position', [newPosition(3)/2+40 newPosition(4)/2 newPosition(3)/2-80 newPosition(4)/2-30]);
%                 set(obj.afterAxis, 'Units', axisOldUnits);

                % Sort out the 'Before' label
                labelOldUnits = get(obj.beforeLabel, 'Units');
                set(obj.beforeLabel, 'Units', 'pixels');
                labelOldPosition = get(obj.beforeLabel, 'Position');
                set(obj.beforeLabel, 'Position', [labelOldPosition(1) newPosition(4)-28 labelOldPosition(3) 20]);
                set(obj.beforeLabel, 'Units', labelOldUnits);
                
                % Sort out the 'After' label
                labelOldUnits = get(obj.afterLabel, 'Units');
                set(obj.afterLabel, 'Units', 'pixels');
                labelOldPosition = get(obj.afterLabel, 'Position');
                set(obj.afterLabel, 'Position', [labelOldPosition(1) newPosition(4)-28 labelOldPosition(3) 20]);
                set(obj.afterLabel, 'Units', labelOldUnits);

                set(obj.handle, 'Units', oldUnits);
            end
            
            sizeChanged@Figure(obj);
        end
        
        function createContextMenu(obj)
            % Set up the context menu
            obj.contextMenu = uicontextmenu();
            %exportDataMenu = uimenu(obj.contextMenu, 'Label', 'Export Data', 'Callback', []);
            %uimenu(exportDataMenu, 'Label', 'To workspace', 'Callback', @(src,evnt)obj.b.exportToWorkspace());
            
            exportWorkflowMenu = uimenu(obj.contextMenu, 'Label', 'Export Workflow', 'Callback', []);
            uimenu(exportWorkflowMenu, 'Label', 'To workspace', 'Callback', @(src,evnt)obj.preprocessingWorkflow.exportToWorkspace());
        end
        
%         function closeRequest(obj)
%             obj.delete();
%         end
    end
end