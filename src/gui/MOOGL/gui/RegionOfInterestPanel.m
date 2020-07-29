classdef RegionOfInterestPanel < Panel
    properties (SetAccess = protected)
        regionOfInterestList;
        
        regionOfInterestTable;
        editRegionOfInterestButton;
        saveRegionOfInterestButton;
        loadRegionOfInterestButton;
        infoRegionOfInterestButton;
        % TODO: Evaluate whether this is necessary
        selectedROIs;
        
        regionOfInterestListEditor;
        
        roiListListener;
        
        imageForEditor;
        
        lastPath;
    end
    
    events
        RegionOfInterestListChanged
        RegionOfInterestSelected
        InfoButtonClicked
    end
    
    methods
        function this = RegionOfInterestPanel(parent)
            this = this@Panel(parent);
            
            this.regionOfInterestList = RegionOfInterestList();
            this.roiListListener = addlistener(this.regionOfInterestList, 'ListChanged', @(src, event) notify(this, 'RegionOfInterestListChanged', event));
            
            this.imageForEditor = Image(1);
        end
        
        function addRegionOfInterest(this, regionOfInterest)
            this.regionOfInterestList.add(regionOfInterest);
        end
        
        function addRegionOfInterestList(this, regionOfInterestList)
            this.regionOfInterestList.addAll(regionOfInterestList);
            this.updateRegionOfInterestList();
        end
        
        function setRegionOfInterestList(this, regionOfInterestList)
            this.regionOfInterestList = regionOfInterestList;
            
            if(~isempty(this.roiListListener))
                delete(this.roiListListener);
            end
            
            this.roiListListener = addlistener(regionOfInterestList, 'ListChanged', @(src, event) notify(this, 'RegionOfInterestListChanged', event));
            
            this.updateRegionOfInterestList();
        end
        
        function setImageForEditor(this, image)
            this.imageForEditor = image;
            image
        end
    end
    
    methods
        
    end
    
    methods(Access = protected)   
        function editRegionOfInterestList(this)
            % Check if we have already opened the
            % RegionOfInterestListEditor and if so if it is still a valid
            % instance of the class. If so show it, otherwise recreate it
            if(isa(this.regionOfInterestListEditor, 'RegionOfInterestListEditor') && isvalid(this.regionOfInterestListEditor))
                figure(this.regionOfInterestListEditor.handle);
            else
                this.regionOfInterestListEditor = RegionOfInterestListEditor(this.imageForEditor, this.regionOfInterestList);

                addlistener(this.regionOfInterestListEditor, 'FinishedEditing', @(src, evnt)this.finishedEditingRegionOfInterestList());
            end
            
            assignin('base', 'dvroiList', this.regionOfInterestList);
        end
        
        function selectRegionOfInterest(this, src, event)
             this.selectedROIs = event.Indices(:, 1)';
             
             notify(this, 'RegionOfInterestSelected', event);
        end
        
        function finishedEditingRegionOfInterestList(this)
            this.regionOfInterestList = this.regionOfInterestListEditor.regionOfInterestList;
            notify(this, 'RegionOfInterestListChanged')
            
            this.updateRegionOfInterestList();
        end
        
        function saveRegionOfInterest(this)
            list = {'Save list', 'Save selected', 'Save list individually (auto named)', 'Save selected individually (auto named)', ...
                'Save list individually (manually named)', 'Save selected individually (manually named)'};
            
            if(~isdeployed())
                list{end+1} = 'Save list to workspace';
                list{end+1} = 'Save selected to workspace';
            end            
            
            [savingOption, ok] = listdlg('ListString', list, 'SelectionMode', 'single', 'Name', 'Saving option', 'ListSize', [300, 160]);
            
            
            if(ok)
                % Get selected ROIs
                if(mod(savingOption, 2) == 0)
                    selectedROIList = RegionOfInterestList();
                    data = get(this.regionOfInterestTable, 'Data');
                    this.selectedROIs
                    selectedROIs = [data{:, 2}];
                    
                    for i = 1:length(selectedROIs)
                        if(selectedROIs(i))
                            selectedROIList.add(this.regionOfInterestList.get(i));
                        end
                    end
                end
                
                if(mod(savingOption, 2) == 1)
                    listToProcess = this.regionOfInterestList;
                else
                    listToProcess = selectedROIList;
                end
                
                if(savingOption == 1 || savingOption == 2)
                    % Get the fiter specification of the parser
                    filterSpec = {'*.rois', 'ROI List (*.rois)'};

                    % Show file select interface
                    [fileName, pathName, filterIndex] = uiputfile(filterSpec, 'Save ROI List', this.lastPath);

                    % Check that the Open dialog was not cancelled
                    if(filterIndex > 0)
                        % Update the last path so that next time we open a file we
                        % start where we left off
                        this.lastPath = pathName;

                        fid = fopen([pathName filesep fileName], 'w');
                        listToProcess.outputXML(fid, 0);                        
                        fclose(fid);
                    end
                elseif(savingOption == 3 || savingOption == 4)
                    selectedPath = uigetdir(this.lastPath, 'Save ROIs');
                    
                    if(selectedPath ~= 0)
                        for i = 1:listToProcess.getSize()
                            roi = listToProcess.get(i);
                            
                            filename = [selectedPath filesep roi.getName() '.roi'];
                            count = 2;
                            while(exist(filename, 'file'))
                                filename = [selectedPath filesep roi.getName() '_' num2str(count) '.roi'];
                                count = count + 1;
                            end
                            
                            fid = fopen(filename, 'w');
                            roi.outputXML(fid, 0);                        
                            fclose(fid);
                        end
                    end
                elseif(savingOption == 5 || savingOption == 6)
                    % Get the fiter specification of the parser
                    filterSpec = {'*.roi', 'ROI (*.roi)'};
                    
                    for i = 1:listToProcess.getSize()
                        roi = listToProcess.get(i);
                        
                        filename = [this.lastPath filesep roi.getName() '.roi'];
                        count = 2;
                        while(exist(filename, 'file'))
                            filename = [this.lastPath filesep roi.getName() '_' num2str(count) '.roi'];
                            count = count + 1;
                        end

                        % Show file select interface
                        [fileName, pathName, filterIndex] = uiputfile(filterSpec, 'Save ROI', filename);

                        % Check that the Open dialog was not cancelled
                        if(filterIndex > 0)
                            % Update the last path so that next time we open a file we
                            % start where we left off
                            this.lastPath = pathName;
                            
                            fid = fopen([pathName filesep fileName], 'w');
                            roi.outputXML(fid, 0);                        
                            fclose(fid);
                        end
                    end
                elseif(savingOption == 7 || savingOption == 8)
                    variableName = requestVariableName('Variable name for ROI list', 'Save ROI list to workspace');
                    
                    if(~isempty(variableName))
                        assignin('base', variableName, listToProcess);
                    end
                end
            end
        end
        
        function loadRegionOfInterest(this)
            filterSpec = {'*.roi;*.rois', 'ROI (List) (*.roi,*.rois)'};
                       
            % Show file select interface
            [fileName, pathName, filterIndex] = uigetfile(filterSpec, 'Load ROI List', this.lastPath, 'MultiSelect', 'on')
            
            % Check that the Open dialog was not cancelled
            if(filterIndex > 0)
                % Update the last path so that next time we open a file we
                % start where we left off
                this.lastPath = pathName;
                
                if(~iscell(fileName))
                    filenames{1} = fileName;
                else
                    filenames = fileName;
                end
                
                for fileIndex = 1:numel(filenames) 
                    currentFileName = filenames{fileIndex}
                    
                    [fp, name, ext] = fileparts(currentFileName);

                    if(strcmp(ext, '.rois'))
                        regionOfInterestList = parseRegionOfInterestList([pathName filesep currentFileName]);
                        this.regionOfInterestList.addAll(regionOfInterestList);
                    else
                        regionOfInterest = parseRegionOfInterest([pathName filesep currentFileName]);
                        this.regionOfInterestList.add(regionOfInterest);
                    end

                    this.updateRegionOfInterestList();
                end
                
%                 if(regionOfInterestList.getSize() > 0)                
%                     newROI = regionOfInterestList.get(1);
%                     
%                     if(newROI.width == size(this.imageForEditor, 2) && newROI.height == size(this.imageForEditor, 1))
                        

                        
%                     else
%                         roiListSize = ['(' num2str(size(this.imageForEditor, 2)) ', ' num2str(size(this.imageForEditor, 1)) ')'];
%                         expectedSize = ['(' num2str(newROI.width) ', ' num2str(newROI.height) ')'];
%                         
%                         exception = MException('RegionOfInterestPanel:invalidROIList', ['ROIs are of a different size than expected ' expectedSize ' but got ' roiListSize] );
%                         
%                         % Make sure the user sees that we have had an error
%                         errordlg(exception.message, exception.identifier);
%                         throw(exception);
%                     end
%                 end
            end
        end
                
        function updateRegionOfInterestList(this)
            rois = this.regionOfInterestList.getObjects();
            data = {};
            
            for i = 1:numel(rois)
                data{i, 1} = ['<HTML><font color="' rois{i}.getColour().toHex() '">' rois{i}.getName() '</font></HTML>' ];
                data{i, 2} = false;
            end
            
            set(this.regionOfInterestTable, 'Data', data);
            
%             this.updateRegionOfInterestDisplay();
        end
        
        function createPanel(this)
            createPanel@Panel(this);
            
            set(this.handle, 'Title', 'Regions of Interest')
            %             set(this.handle, 'BorderWidth', 1)
            
            %Set up the region of interest table
            columnNames = {'Region', 'Display'};
            columnFormat = {'char', 'logical'};
            columnEditable = [false, true];
            
            this.regionOfInterestTable = uitable('Parent', this.handle, ...
                'ColumnName', columnNames, 'ColumnFormat', columnFormat, 'ColumnEditable', columnEditable, ...
                'RowName', [], 'CellEditCallback', @(src, evnt) notify(this, 'RegionOfInterestSelected'), ...
                'CellSelectionCallback', @this.selectRegionOfInterest);
            
            this.editRegionOfInterestButton = this.createButtonWithIcon(this.handle, ...
                @(src, evnt) this.editRegionOfInterestList(), 'edit', 'Add/Edit regions of interest');
            this.saveRegionOfInterestButton = this.createButtonWithIcon(this.handle, ...
                @(src, evnt)this.saveRegionOfInterest(), 'save_alt', 'Save region of interest list');
            this.loadRegionOfInterestButton = this.createButtonWithIcon(this.handle, ...
                @(src, evnt)this.loadRegionOfInterest(), 'folder_open', 'Load region of interest list');
            this.infoRegionOfInterestButton = this.createButtonWithIcon(this.handle, ...
                @(src, evnt)notify(this, 'InfoButtonClicked'), 'bar_chart', 'Display region of interest details');
        end
        
        function sizeChanged(this)
            oldUnits = get(this.handle, 'Units');
            set(this.handle, 'Units', 'pixels');
            
            panelPosition = get(this.handle, 'Position');
            
            margin = 5;
            buttonHeight = 28;
            
            if(~isempty(panelPosition))
                Figure.setObjectPositionInPixels(this.regionOfInterestTable, [margin, buttonHeight + margin, panelPosition(3) - margin*2, panelPosition(4) - margin*2 - buttonHeight - 20]);
                Figure.setObjectPositionInPixels(this.saveRegionOfInterestButton, [margin, margin, buttonHeight, buttonHeight]);
                Figure.setObjectPositionInPixels(this.loadRegionOfInterestButton, [margin+panelPosition(3)*1/5, margin, buttonHeight, buttonHeight]);
                Figure.setObjectPositionInPixels(this.infoRegionOfInterestButton, [margin+panelPosition(3)*2/5, margin, buttonHeight, buttonHeight]);
                Figure.setObjectPositionInPixels(this.editRegionOfInterestButton, [margin+panelPosition(3)*4/5, margin, buttonHeight, buttonHeight]);
            end
        end
    end
end