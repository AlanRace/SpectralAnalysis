classdef RegionOfInterestListEditor < Editor
    properties (SetAccess = private)
        image;
        regionOfInterestList;
    end
    
    properties (Access = private)    
        pixelSelectionPanel;
        
        listBox;
        addROIButton;
        editROIButton;
        removeROIButton;
        duplicateROIButton;
        
        autoROIButton;
        
        lastPath;
        loadROIDataButton;
        
        regionOfInterestEditor = [];
        
        roiFinishedEditingListener = [];
    end
    
    methods
        function obj = RegionOfInterestListEditor(image, regionOfInterestList)
            if(~isa(image, 'Image'))
                exception = MException('RegionOfInterestListEditor:InvalidArgument', ...
                    'image must be of type Image');
                throw(exception);
            end
            if(~isa(regionOfInterestList, 'RegionOfInterestList'))
                exception = MException('RegionOfInterestListEditor:InvalidArgument', ...
                    'regionOfInterestList must be of type RegionOfInterestList');
                throw(exception);
            end
            
            obj.createFigure();
            
            obj.image = image;
            obj.regionOfInterestList = regionOfInterestList.copy();
            
            obj.pixelSelectionPanel = PixelSelectionPanel(obj.pixelSelectionPanel);
            obj.pixelSelectionPanel.setBackgroundImage(image);
            
            obj.updateRegionOfInterestList();
        end
               
        
        function addRegionOfInterestCallback(this)
            % TODO: This class can query and set up default names/colours
            newROI = RegionOfInterest(this.image.getWidth(), this.image.getHeight());
            newROI.setName(['ROI ' num2str(this.regionOfInterestList.getSize() + 1)]);
            
            if(isa(this.regionOfInterestEditor, 'RegionEditor') && isvalid(this.regionOfInterestEditor))
                this.regionOfInterestEditor.setRegionOfInterest(newROI);
                
                figure(this.regionOfInterestEditor.handle);
            else
                this.regionOfInterestEditor = RegionEditor(newROI);
            end
            
            if(~isempty(this.roiFinishedEditingListener) && this.roiFinishedEditingListener ~= 0)
                delete(this.roiFinishedEditingListener);
            end
            
            this.roiFinishedEditingListener = addlistener(this.regionOfInterestEditor, ...
                'FinishedEditing', @(src, evnt)this.finishedEditingRegionOfInterest(src.getRegionOfInterest()));
        end
        
        function autoRegionOfInterestCallback(this)
            for i = 1:this.image.getHeight()
                newROI = RegionOfInterest(this.image.getWidth(), this.image.getHeight());
                newROI.setName(['Line ' num2str(i)]);
                
                roi = zeros(this.image.getHeight(), this.image.getWidth());
                roi(i, :) = 1;
                
                newROI.addPixels(roi);
                
                this.regionOfInterestList.add(newROI);
                
                this.updateRegionOfInterestList();
            end
        end
        
        function loadROIDataCallback(this)
            selectedIndex = get(this.listBox, 'Value');
            
            if(selectedIndex > this.regionOfInterestList.getSize() || selectedIndex <= 0)
                exception = MException('RegionOfInterestListEditor:LoadROIData', 'Must select a region of interest');
                
                % Make sure the user sees that we have had an error
                errordlg(exception.message, exception.identifier);
                throw(exception);
            end
            
            selectedROI = this.regionOfInterestList.get(selectedIndex);
            
            % Get the fiter specification of the parser
            filterSpec = {'*.txt', 'ROI pixel list (*.txt)'};
                       
            % Show file select interface
            tic;
            [fileName, pathName, filterIndex] = uigetfile(filterSpec, 'Select File', this.lastPath);
            % Included to try and remove the occasional long delay (up to 7s) 
            % http://undocumentedmatlab.com/blog/solving-a-matlab-hang-problem
            drawnow; pause(0.5);
            toc;
            
            % Check that the Open dialog was not cancelled
            if(filterIndex > 0)
                % Update the last path so that next time we open a file we
                % start where we left off
                this.lastPath = pathName;
                
                data = dlmread([pathName filesep fileName]);
                
                % Check if the data is 4 column data, such as that produced
                % by MSiReader
                if(size(data, 2) == 4)
                    % Remove pixels which are marked with -1 or 0 
                    data(data(:, 4) <= 0, :) = [];
                    
                    % Add all of the pixels in the file to the ROI
                    for i = 1:size(data, 1)
                        if(data(i, 2) <= this.image.getWidth() && data(i, 3) <= this.image.getHeight())
                            selectedROI.addPixel(data(i, 2), data(i, 3));
                        end
                    end
                    
                    % Update the ROI view
                    this.pixelSelectionPanel.displaySelectionData();
                end
            end
        end
        
        function duplicateROIDataCallback(this)
            selectedIndex = get(this.listBox, 'Value');
            
            if(selectedIndex > this.regionOfInterestList.getSize() || selectedIndex <= 0)
                exception = MException('RegionOfInterestListEditor:DuplicateROI', 'Must select a region of interest');
                
                % Make sure the user sees that we have had an error
                errordlg(exception.message, exception.identifier);
                throw(exception);
            end
            
            selectedROI = this.regionOfInterestList.get(selectedIndex);
            newROI = selectedROI.copy();
            
            this.regionOfInterestList.add(newROI);
            
            this.updateRegionOfInterestList();
            
            roiIndex = this.regionOfInterestList.getSize();
            
            % Select the new ROI
            set(this.listBox, 'Value', roiIndex);
            this.selectRegionOfInterest(roiIndex);
        end
        
        function finishedEditingRegionOfInterest(this, regionOfInterest)
            if(~isa(regionOfInterest, 'RegionOfInterest'))
                exception = MException('RegionOfInterestListEditor:InvalidArgument', 'addRegionOfInterest: Must supply a RegionOfInterest.');
                throw(exception);
            end
            
            found = 0;
            
            rois = this.regionOfInterestList.getObjects();
            
            for i = 1:numel(rois)
                % Check if the ROI already exists, and if it does then we
                % don't need to add it
                if(isequal(rois{i}, regionOfInterest))
                    found = i;
                    break
                end
            end
            
            % If the ROI isn't already part of the list, add it
            if(found == 0)
                this.regionOfInterestList.add(regionOfInterest);
                
                found = numel(rois) + 1;
            end
            
            this.updateRegionOfInterestList();
            
            % Select the new ROI
            set(this.listBox, 'Value', found);
            this.selectRegionOfInterest(found);
        end
        
%         function addRegionOfInterest(this, regionOfInterest)
%             if(~isa(regionOfInterest, 'RegionOfInterest'))
%                 exception = MException('RegionOfInterestListEditor:InvalidArgument', 'addRegionOfInterest: Must suply a RegionOfInterest.');
%                 throw(exception);
%             end
%             
%             this.regionOfInterestList.add(regionOfInterest);
%             
%             this.updateRegionOfInterestList();
%             
%             % Select the new ROI
%             set(this.listBox, 'Value', this.regionOfInterestList.getSize());
%             this.selectRegionOfInterest(this.regionOfInterestList.getSize());
%         end
        
        function editRegionOfInterest(this)
            % Check that there is actually a ROI to edit
            if(isempty(get(this.listBox, 'String')))
                return;
            end
            
            if(isa(this.regionOfInterestEditor, 'RegionEditor') && isvalid(this.regionOfInterestEditor))
                this.regionOfInterestEditor.setRegionOfInterest();
                
                figure(this.regionOfInterestEditor.handle);
            else
                this.regionOfInterestEditor = RegionEditor(RegionOfInterest(this.image.getWidth(), this.image.getHeight()));
                this.regionOfInterestEditor.setRegionOfInterest(this.regionOfInterestList.get(get(this.listBox, 'Value')));
            end
            
            if(~isempty(this.roiFinishedEditingListener) && this.roiFinishedEditingListener ~= 0)
                delete(this.roiFinishedEditingListener);
            end
            
            this.roiFinishedEditingListener = addlistener(this.regionOfInterestEditor, ...
                'FinishedEditing', @(src, evnt)this.finishedEditingRegionOfInterest(src.getRegionOfInterest()));
        end
        
        function removeRegionOfInterestCallback(this)
            this.removeRegionOfInterest(this.regionOfInterestList.get(get(this.listBox, 'Value')));
        end
        
        function removeRegionOfInterest(this, regionOfInterest)
            this.regionOfInterestList.remove(regionOfInterest);
            
            this.updateRegionOfInterestList();
        end
        
        function updateRegionOfInterestList(this)
            rois = this.regionOfInterestList.getObjects();
            names = {};
            
            for i = 1:numel(rois)
                names{i} = ['<HTML><font color="' rois{i}.getColour().toHex() '">' rois{i}.getName() '</font></HTML>' ];
            end
            
            if(isempty(names))
                this.pixelSelectionPanel.removeRegionOfInterest();
            else
                curSelected = get(this.listBox, 'Value');
                if(curSelected > numel(names))
                    set(this.listBox, 'Value', numel(names));
                end
                
                curSelected = get(this.listBox, 'Value');
                this.selectRegionOfInterest(curSelected);
            end
            
            set(this.listBox, 'String', names);
        end
        
        function selectRegionOfInterest(this, index)
            this.pixelSelectionPanel.setRegionOfInterest(this.regionOfInterestList.get(index));
        end
    end
    
    methods (Access = protected)
        function createFigure(this)
            createFigure@Editor(this);
            
            this.setTitle('ROI List Editor');
                
            this.pixelSelectionPanel = uipanel(this.handle, ...
                    'Units', 'normalized', 'Position', [0.05 0.3 0.9 0.65]);
            
            this.listBox = uicontrol(this.handle, 'Style', 'listbox', 'Units', 'normalized', ...
                'Position', [0.05 0.05 0.5 0.2], 'Callback', @(src, evnt) this.selectRegionOfInterest(get(this.listBox, 'Value')));
            
            this.addROIButton = uicontrol(this.handle, 'String', '+', ...
                'Units', 'normalized', 'Position', [0.575 0.2 0.1 0.05], 'Callback', @(src, evnt) this.addRegionOfInterestCallback());
            this.editROIButton = uicontrol(this.handle, 'String', 'Edit', ...
                'Units', 'normalized', 'Position', [0.575 0.125 0.1 0.05], 'Callback', @(src, evnt) this.editRegionOfInterest());
            this.removeROIButton = uicontrol(this.handle, 'String', '-', ...
                'Units', 'normalized', 'Position', [0.575 0.05 0.1 0.05], 'Callback', @(src, evnt) this.removeRegionOfInterestCallback());
            
            this.autoROIButton = uicontrol(this.handle, 'String', 'Auto Line', ...
                'Units', 'normalized', 'Position', [0.8 0.2 0.15 0.05], 'Callback', @(src, evnt) this.autoRegionOfInterestCallback());
            
            this.loadROIDataButton = uicontrol(this.handle, 'String', 'Load pixel data', ...
                'Units', 'normalized', 'Position', [0.8 0.125 0.15 0.05], 'Callback', @(src, evnt) this.loadROIDataCallback());
            
            this.duplicateROIButton = uicontrol(this.handle, 'String', 'Duplicate', ...
                'Units', 'normalized', 'Position', [0.675 0.125 0.1 0.05], 'Callback', @(src, evnt) this.duplicateROIDataCallback());
        end
    end
end