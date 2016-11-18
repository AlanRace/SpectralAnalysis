classdef PostProcessingMethodEditor < handle
    properties (SetAccess = private)
        figureHandle = 0;
        
        postProcessingMethodName;
        postProcessingMethod;
    end
    
    properties (Access = private)
        specificOptionsPanel;
        parameterInterfaceHandles;
        parameterDefinitions;
        parameters;
        
        commonOptionsPanel;
        preprocessEachSpectrumCheckbox;
        processEntireDataset;
        regionOfInterestTable;
        
        regionOfInterestList;
        
        okButton;
        backButton;
    end
    
    events
        FinishedEditingPostProcessingMethod;
    end
    
    methods
        function obj = PostProcessingMethodEditor(postProcessingMethod)
            
            
            % TODO: if preprocessingMethod is an instance of a class then
            % get the class name 
            
            if(~exist(postProcessingMethod, 'class') || ~ismember('PostProcessing', superclasses(postProcessingMethod)))
                exception = MException('PostProcessingMethodEditor:invalidArgument', 'Must provide an instance of a class that extends PostProcessing');
                throw(exception);
            end
            
            obj.postProcessingMethodName = postProcessingMethod;
            
            obj.createFigure();
            
            %TODO: Update the parameters if an instance of the class was
            % passed in
            
            warning('TODO: add listener to PostProcessingMethodChanged');
            % TODO: Use listeners for checking parameters changed
        end
        
        function createFigure(obj)
            if(~obj.figureHandle)
                postProcessingName = eval([obj.postProcessingMethodName '.Name']);
                
                obj.figureHandle = figure(...
                    'Name', ['PostProcessing Method Editor: ' postProcessingName], 'NumberTitle','off',...
                    'Units','characters',...
                    'MenuBar','none',...
                    'Toolbar','none', ...
                    'CloseRequestFcn', @(src, evnt)obj.closeRequest());
                
                currentPosition = get(obj.figureHandle, 'Position');
                currentPosition(4) = currentPosition(4) * 0.8;
                set(obj.figureHandle, 'Position', currentPosition);                
                
                % Set up the standard options
                obj.commonOptionsPanel = uipanel(obj.figureHandle, 'Title', 'Common PostProcessing Options', ...
                    'Position', [0.05 0.2 0.9 0.7]);
                
                obj.preprocessEachSpectrumCheckbox = uicontrol(obj.commonOptionsPanel, 'Style', 'checkbox', ...
                    'String', 'Preprocess every spectrum', 'Units', 'normalized', ...
                    'Position', [0.05 0.85 0.9 0.1]);
                
                obj.processEntireDataset = uicontrol(obj.commonOptionsPanel, 'Style', 'checkbox', ...
                    'Value', 1, ...
                    'String', 'Process entire dataset (doesn''t affect ROI choices)', 'Units', 'normalized', ...
                    'Position', [0.05 0.7 0.9 0.1]);
                
                %Set up the region of interest table
                columnNames = {'Region', 'Process Separately'};
                columnFormat = {'char', 'logical'};
                columnEditable = [false, true];
                
                obj.regionOfInterestTable = uitable(obj.commonOptionsPanel, ...
                    'ColumnName', columnNames, 'ColumnFormat', columnFormat, 'ColumnEditable', columnEditable, ...
                    'RowName', [], 'ColumnWidth', {290 150}, ... 'CellEditCallback', @(src, evnt) obj.updateRegionOfInterestDisplay(), ...
                    'Units', 'normalized', 'Position', [0.05 0.1 0.9 0.5]);
                
%                 set(obj.commonOptionsPanel, 'Visible', 'off');
                
%                 dataReductionPanel = uipanel(obj.figureHandle, 'Title', 'Data Reduction Options', ...
%                     'Position', [0.05 0.2 0.9 0.7]);
%                 
%                 spectralRepresentation
%                 
%                 peakPickingMethodLabel = uicontrol(dataReductionPanel, 'Style', 'text', 'String', 'Peak Picking Method', ...
%                     'Units', 'normalized', 'Position', [0.05 0.85 0.4 0.06]);
%
%                 set(dataReductionPanel, 'Visible', 'off');

                obj.specificOptionsPanel = uipanel(obj.figureHandle, 'Title', 'Common PostProcessing Options', ...
                    'Position', [0.05 0.2 0.9 0.7], 'Visible', 'off');
                
                
                obj.parameterDefinitions = eval([obj.postProcessingMethodName '.ParameterDefinitions']);
                
                yPosition = 0.80;
                
                for i = 1:length(obj.parameterDefinitions)
                    type = obj.parameterDefinitions(i).type;
                    
                    defaultValue = obj.parameterDefinitions(i).defaultValue;
                    
                    height = 0.075;
                    
                    if(type == ParameterType.List)
                        height = height *2;
                        
                        obj.parameterInterfaceHandles(i) = uipanel(obj.specificOptionsPanel, 'Title', obj.parameterDefinitions(i).name, ...
                            'Units', 'normalized', 'Position', [.15 yPosition .75 height]);
                        
                        uicontrol(obj.parameterInterfaceHandles(i), 'Style', 'popup', 'String', {defaultValue.name}, ...
                            'Units', 'normalized', 'Position', [0.05 0.05 0.4 0.9], 'Callback', @(src, evnt)obj.changedListChoice(i));
                        uicontrol(obj.parameterInterfaceHandles(i), 'Style', 'edit', 'String', defaultValue(i).defaultValue, ...
                            'Units', 'normalized', 'Position', [0.55 0.05 0.4 0.9]);
                    else
%                         height = 0.05;
                        
                        uicontrol(obj.specificOptionsPanel, 'Style', 'text', 'String', obj.parameterDefinitions(i).name, 'HorizontalAlignment', 'left', ...
                            'Units', 'normalized', 'Position', [.25 yPosition .25 height]);

                        if(type == ParameterType.Integer || type == ParameterType.Double)
                            obj.parameterInterfaceHandles(i) = uicontrol(obj.specificOptionsPanel, 'Style', 'edit', 'String', defaultValue, ...
                                'Units', 'normalized', 'Position', [.55 yPosition .2 height], 'Callback', @(src, evnt)obj.parameterChanged());
                        elseif(type == ParameterType.Selection)
                            obj.parameterInterfaceHandles(i) = uicontrol(obj.specificOptionsPanel, 'Style', 'popup', 'String', defaultValue, ...
                                'Units', 'normalized', 'Position', [.55 yPosition .2 height], 'Callback', @(src, evnt)obj.parameterChanged());
                        end
                    end
                    
                    yPosition = yPosition - height;
                end
                
                obj.okButton = uicontrol(obj.figureHandle, 'String', 'Next >', ...
                    'Units', 'normalized', 'Position', [0.8 0.05 0.15 0.05], 'Callback', @(src, evnt)obj.okButtonCallback());
                obj.backButton = uicontrol(obj.figureHandle, 'String', '< Back', 'Visible', 'off', ...
                    'Units', 'normalized', 'Position', [0.05 0.05 0.15 0.05], 'Callback', @(src, evnt)obj.backButtonCallback());
            end
        end
       
        function setRegionOfInterestList(this, regionOfInterestList)
            if(~isa(regionOfInterestList, 'RegionOfInterestList'))
                exception = MException('PostProcessingMethodEditor:InvalidArgument', ...
                    'setRegionOfInterestList: Must supply an instance of RegionOfInterestList');
                throw(exception);                
            end
            
            this.regionOfInterestList = regionOfInterestList;
            
            rois = this.regionOfInterestList.getObjects();
            data = {};
            
            for i = 1:numel(rois)
                data{i, 1} = ['<HTML><font color="' rois{i}.getColour().toHex() '">' rois{i}.getName() '</font></HTML>' ];
                data{i, 2} = false;
            end
            
            set(this.regionOfInterestTable, 'Data', data);
        end
        
        function changedListChoice(obj, parameterIndex)
            children = get(obj.parameterInterfaceHandles(parameterIndex), 'Children');
            
            for i = 1:length(children)
                if(strcmp(get(children(i), 'Style'), 'popupmenu'))
                    popupmenu = children(i);
                elseif(strcmp(get(children(i), 'Style'), 'edit'))
                    edit = children(i);
                end
            end
            
            selected = get(popupmenu, 'Value');
            
            set(edit, 'String', obj.parameterDefinitions(parameterIndex).defaultValue(selected).defaultValue);
        end
        
        function postProcessingMethod = getPostProcessingMethod(obj)
            postProcessingMethod = obj.postProcessingMethod;
        end
        
        function delete(obj)
            delete(obj.figureHandle);
            obj.figureHandle = 0;
        end
    end
    
    methods (Access = private)
        function parameterChanged(obj)
%             warning('TODO: Check each parameter value is suitable');
        end
        
%         function reduceParameter(obj, index)
%             type = obj.parameterDefinitions(index).type;
%             
%             if(type == ParameterType.Integer)
% %                 obj.parameters(index).setValue(obj.parameters(index).value - 1);
%                 currentValue = str2num(get(obj.parameterInterfaceHandles(index), 'String'));
%                 set(obj.parameterInterfaceHandles(index), 'String', num2str(currentValue - 1));
%             end
%             
%             obj.parameterChanged();
%         end
%         
%         function increaseParameter(obj, index)
%             type = obj.parameterDefinitions(index).type;
%             
%             if(type == ParameterType.Integer)
% %                 obj.parameters(index).setValue(obj.parameters(index).value + 1);
%                 currentValue = str2num(get(obj.parameterInterfaceHandles(index), 'String'));
%                 set(obj.parameterInterfaceHandles(index), 'String', num2str(currentValue + 1));
%             end
%             
%             obj.parameterChanged();
%         end

        function backButtonCallback(this)
            set(this.commonOptionsPanel, 'Visible', 'on');
            set(this.specificOptionsPanel, 'Visible', 'off');
                
            set(this.okButton, 'String', 'Next >');
            set(this.backButton, 'Visible', 'off');
        end
        
        function okButtonCallback(obj)
            % Check if the common options panel is displayed, if so then
            % swap to the next one
            if(strcmp(get(obj.commonOptionsPanel, 'Visible'), 'on'))
                set(obj.commonOptionsPanel, 'Visible', 'off');
                set(obj.specificOptionsPanel, 'Visible', 'on');
                
                set(obj.okButton, 'String', 'OK');
                set(obj.backButton, 'Visible', 'on');
            else
                set(obj.figureHandle, 'Visible', 'off');
                
                try
                    % Make sure any last updates are performed
                    obj.parameterChanged();

                    parameterString = ['obj.postProcessingMethod = ' obj.postProcessingMethodName '('];

                    % Create a preprocessing method instance
                    for i = 1:length(obj.parameterInterfaceHandles)
                        type = obj.parameterDefinitions(i).type;

                        if(type == ParameterType.List)
                            children = get(obj.parameterInterfaceHandles(i), 'Children');

                            for j = 1:length(children)
                                if(strcmp(get(children(j), 'Style'), 'popupmenu'))
                                    popupmenu = children(j);
                                elseif(strcmp(get(children(j), 'Style'), 'edit'))
                                    edit = children(j);
                                end
                            end

                            parameterString = [parameterString num2str(get(popupmenu, 'Value')) ', ' get(edit, 'String') ', '];
                        elseif(type == ParameterType.Selection)
                            selectedIndex = get(obj.parameterInterfaceHandles(i), 'Value');
                            options = get(obj.parameterInterfaceHandles(i), 'String');

                            parameterString = [parameterString '''' options{selectedIndex} ''', '];
                        else
                            parameterString = [parameterString get(obj.parameterInterfaceHandles(i), 'String') ', '];
                        end
                    end

                    if(length(parameterString) > 2 && length(obj.parameterInterfaceHandles) >= 1)
                        parameterString = parameterString(1:end-2); % Strip off the last ', '
                    end

                    parameterString = [parameterString ');']

                    eval(parameterString);

                    % Set common options
                    obj.postProcessingMethod.applyPreprocessingToEverySpectrum(get(obj.preprocessEachSpectrumCheckbox, 'Value'));
                    obj.postProcessingMethod.postProcessEntireDataset(get(obj.processEntireDataset, 'Value'));

                    roiData = get(obj.regionOfInterestTable, 'Data');

                    for i = 1:size(roiData, 1)
                        if(roiData{i, 2})
                            obj.postProcessingMethod.addRegionOfInterest(obj.regionOfInterestList.get(i));
                        end
                    end

                    notify(obj, 'FinishedEditingPostProcessingMethod'); %, obj.preprocessingMethod);

                    obj.delete();
                catch err
                    set(obj.figureHandle, 'Visible', 'on');
                    
                    throw(err);
                end
            end
        end
    end    
    
    methods (Access = protected)
        function closeRequest(obj)
            obj.delete();
        end
    end
end