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
        
        regionOfInterestEditor = 0;
        
        roiFinishedEditingListener = 0;
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
            
%             image.getWidth()
%             image.getHeight()
%             isinteger(image.getWidth())
%             roi = RegionOfInterest(image.getWidth(), image.getHeight());
%             obj.pixelSelectionPanel.setRegionOfInterest(roi);
        end
       
        
        
        function addRegionOfInterestCallback(this)
            % TODO: This class can query and set up default names/colours
            newROI = RegionOfInterest(this.image.getWidth(), this.image.getHeight());
            newROI.setName(['ROI ' num2str(this.regionOfInterestList.getSize() + 1)]);
            
            if(isa(this.regionOfInterestEditor, 'RegionEditor') && isvalid(this.regionOfInterestEditor))
                this.regionOfInterestEditor.setRegionOfInterest(newROI);
                
                figure(this.regionOfInterestEditor.figureHandle);
            else
                this.regionOfInterestEditor = RegionEditor(newROI);
            end
            
            if(~isempty(this.roiFinishedEditingListener) && this.roiFinishedEditingListener ~= 0)
                delete(this.roiFinishedEditingListener);
            end
            
            this.roiFinishedEditingListener = addlistener(this.regionOfInterestEditor, ...
                'FinishedEditing', @(src, evnt)this.finishedEditingRegionOfInterest(src.getRegionOfInterest()));
        end
        
        function finishedEditingRegionOfInterest(this, regionOfInterest)
            if(~isa(regionOfInterest, 'RegionOfInterest'))
                exception = MException('RegionOfInterestListEditor:InvalidArgument', 'addRegionOfInterest: Must suply a RegionOfInterest.');
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
                
                figure(this.regionOfInterestEditor.figureHandle);
            else
                this.regionOfInterestEditor = RegionEditor(RegionOfInterest(this.image.getWidth(), this.image.getHeight()));
                this.regionOfInterestEditor.setRegionOfInterest(this.regionOfInterestList.get(get(this.listBox, 'Value')));
            end
            
            if(~isempty(this.roiFinishedEditingListener))
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
                
            this.pixelSelectionPanel = uipanel(this.figureHandle, ...
                    'Units', 'normalized', 'Position', [0.05 0.3 0.9 0.65]);
            
            this.listBox = uicontrol(this.figureHandle, 'Style', 'listbox', 'Units', 'normalized', ...
                'Position', [0.05 0.05 0.5 0.2], 'Callback', @(src, evnt) this.selectRegionOfInterest(get(this.listBox, 'Value')));
            
            this.addROIButton = uicontrol(this.figureHandle, 'String', '+', ...
                'Units', 'normalized', 'Position', [0.6 0.2 0.1 0.05], 'Callback', @(src, evnt) this.addRegionOfInterestCallback());
            this.editROIButton = uicontrol(this.figureHandle, 'String', 'Edit', ...
                'Units', 'normalized', 'Position', [0.6 0.125 0.1 0.05], 'Callback', @(src, evnt) this.editRegionOfInterest());
            this.removeROIButton = uicontrol(this.figureHandle, 'String', '-', ...
                'Units', 'normalized', 'Position', [0.6 0.05 0.1 0.05], 'Callback', @(src, evnt) this.removeRegionOfInterestCallback());
        end
    end
end