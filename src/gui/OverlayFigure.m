classdef OverlayFigure < Figure
    properties
        dataViewList;
        
        rImageDisplay;
        gImageDisplay;
        bImageDisplay;
        rgbImageDisplay;
        
        rDataSelectionBox;
        gDataSelectionBox;
        bDataSelectionBox;
        
        rImageSelectionBox;
        gImageSelectionBox;
        bImageSelectionBox;
        
        rHisteqCheckbox;
        gHisteqCheckbox;
        bHisteqCheckbox;
        
        rMinLabel;
        rMinEditbox;
        rMaxLabel;
        rMaxEditbox;
        
        gMinLabel;
        gMinEditbox;
        gMaxLabel;
        gMaxEditbox;
        
        bMinLabel;
        bMinEditbox;
        bMaxLabel;
        bMaxEditbox;
    end
    
    methods
        function this = OverlayFigure(dataViewList)
            this.dataViewList = dataViewList;
            
            this.updateLists();
        end
        
        function updateLists(this)
            dataViews = this.dataViewList.getObjects();
            titles = {};
            
            for i = 1:length(dataViews)
                titles{i} = dataViews{i}.title;
            end
            
            set(this.rDataSelectionBox, 'String', titles)
            set(this.gDataSelectionBox, 'String', titles)
            set(this.bDataSelectionBox, 'String', titles)
        end
        
        function dataSelected(this, src, event, imageSelectionBox)
            dataViewer = this.dataViewList.get(get(src, 'Value'));
            
            set(imageSelectionBox, 'String', {dataViewer.imageList.description});
            
        end
        
        function imageSelected(this, src, event, dataSelectionBox, imageDisplay, minEditbox, maxEditbox)
            dataViewer = this.dataViewList.get(get(dataSelectionBox, 'Value'));
            image = dataViewer.imageList(get(src, 'Value'));
            
            set(minEditbox, 'String', num2str(min(image.imageData(:))))
            set(maxEditbox, 'String', num2str(max(image.imageData(:))))
            
            imageDisplay.setData(image);
            
            this.updateRGBImage();
        end
        
        function editMinValue(this, src, event, imageDisplay)
            imageDisplay.setMinValueToDisplay(str2double(get(src, 'String')));
            
            this.updateRGBImage();
        end
        
        function editMaxValue(this, src, event, imageDisplay)
            imageDisplay.setMaxValueToDisplay(str2double(get(src, 'String')));
            
            this.updateRGBImage();
        end
        
        function toggleHistogramEqualisation(this, src, event, imageView)
            imageView.setEqualiseHistogram(get(src, 'Value'));
            
            this.updateRGBImage();
        end
        
        function updateRGBImage(this)
            rImageData = this.rImageDisplay.getVisualisedData();
            gImageData = this.gImageDisplay.getVisualisedData();
            bImageData = this.bImageDisplay.getVisualisedData();
            
            rgbImageData = [];
            
            if(~isequal(size(rImageData), [1 1]))
                rgbImageData(:, :, 1) = rImageData;
            end
            if(~isequal(size(gImageData), [1 1]))
                rgbImageData(:, :, 2) = gImageData;
            end
            if(~isequal(size(bImageData), [1 1]))
                rgbImageData(:, :, 3) = bImageData;
            end
            
            if(~isempty(rgbImageData))
                if(size(rgbImageData, 3) ~= 3)
                    rgbImageData(1, 1, 3) = 0;
                end
                
                rgbImageData(:, :, 1) = rgbImageData(:, :, 1) ./ max(max(rgbImageData(:, :, 1)));
                rgbImageData(:, :, 2) = rgbImageData(:, :, 2) ./ max(max(rgbImageData(:, :, 2)));
                rgbImageData(:, :, 3) = rgbImageData(:, :, 3) ./ max(max(rgbImageData(:, :, 3)));
                
                imageToDisplay = Image(rgbImageData);
                
                imageToDisplay.setDescription(sprintf(['R = ' this.rImageDisplay.data.description '\n' ...
                    'G = ' this.gImageDisplay.data.description '\n' ...
                    'B = ' this.bImageDisplay.data.description]));
                
                this.rgbImageDisplay.setData(imageToDisplay);
            end
        end
    end
    
    methods (Access = protected)
        function sizeChanged(this)
            
            if(this.handle ~= 0)
                newPosition = Figure.getPositionInPixels(this.handle);
                
                margin = 5;
                
                colourBarSize = 80;
                leftPanelSize = newPosition(3) / 6;
                buttonHeight = 25;
                
                widthForImage = newPosition(3) - leftPanelSize - margin*3 - colourBarSize;
                
                individualImageHeights = newPosition(4)/3 - buttonHeight*2 - margin*5;
                
                Figure.setObjectPositionInPixels(this.rDataSelectionBox, [margin, newPosition(4)-buttonHeight-margin, leftPanelSize*2, buttonHeight]);
                Figure.setObjectPositionInPixels(this.rImageSelectionBox, [margin, newPosition(4)-buttonHeight*2-margin, leftPanelSize, buttonHeight]);
                Figure.setObjectPositionInPixels(this.rHisteqCheckbox, [margin + leftPanelSize, newPosition(4)-buttonHeight*3-margin, leftPanelSize, buttonHeight]);
                
                Figure.setObjectPositionInPixels(this.rMinLabel, [margin + leftPanelSize, newPosition(4)*2/3, 30, buttonHeight]);
                Figure.setObjectPositionInPixels(this.rMinEditbox, [margin*2 + leftPanelSize + 30, newPosition(4)*2/3+margin, 60, buttonHeight]);
                
                Figure.setObjectPositionInPixels(this.rMaxLabel, [margin + leftPanelSize + 100, newPosition(4)*2/3, 30, buttonHeight]);
                Figure.setObjectPositionInPixels(this.rMaxEditbox, [margin*2 + leftPanelSize + 130, newPosition(4)*2/3+margin, 60, buttonHeight]);
                
                Figure.setObjectPositionInPixels(this.rImageDisplay.axisHandle, [margin, newPosition(4)*2/3+margin, leftPanelSize - colourBarSize, individualImageHeights]);
                
                Figure.setObjectPositionInPixels(this.gDataSelectionBox, [margin, newPosition(4)*2/3-buttonHeight-margin, leftPanelSize*2, buttonHeight]);
                Figure.setObjectPositionInPixels(this.gImageSelectionBox, [margin, newPosition(4)*2/3-buttonHeight*2-margin, leftPanelSize, buttonHeight]);
                Figure.setObjectPositionInPixels(this.gHisteqCheckbox, [margin + leftPanelSize, newPosition(4)*2/3-buttonHeight*3-margin, leftPanelSize, buttonHeight]);
                
                Figure.setObjectPositionInPixels(this.gMinLabel, [margin + leftPanelSize, newPosition(4)/3, 30, buttonHeight]);
                Figure.setObjectPositionInPixels(this.gMinEditbox, [margin*2 + leftPanelSize + 30, newPosition(4)/3+margin, 60, buttonHeight]);
                
                Figure.setObjectPositionInPixels(this.gMaxLabel, [margin + leftPanelSize + 100, newPosition(4)/3, 30, buttonHeight]);
                Figure.setObjectPositionInPixels(this.gMaxEditbox, [margin*2 + leftPanelSize + 130, newPosition(4)/3+margin, 60, buttonHeight]);
                
                Figure.setObjectPositionInPixels(this.gImageDisplay.axisHandle, [margin, newPosition(4)/3+margin, leftPanelSize - colourBarSize, individualImageHeights]);
                
                Figure.setObjectPositionInPixels(this.bDataSelectionBox, [margin, newPosition(4)/3-buttonHeight-margin, leftPanelSize*2, buttonHeight]);
                Figure.setObjectPositionInPixels(this.bImageSelectionBox, [margin, newPosition(4)/3-buttonHeight*2-margin, leftPanelSize, buttonHeight]);
                Figure.setObjectPositionInPixels(this.bHisteqCheckbox, [margin + leftPanelSize, newPosition(4)/3-buttonHeight*3-margin, leftPanelSize, buttonHeight]);
                
                Figure.setObjectPositionInPixels(this.bMinLabel, [margin + leftPanelSize, 0, 30, buttonHeight]);
                Figure.setObjectPositionInPixels(this.bMinEditbox, [margin*2 + leftPanelSize + 30, margin, 60, buttonHeight]);
                
                Figure.setObjectPositionInPixels(this.bMaxLabel, [margin + leftPanelSize + 100, 0, 30, buttonHeight]);
                Figure.setObjectPositionInPixels(this.bMaxEditbox, [margin*2 + leftPanelSize + 130, margin, 60, buttonHeight]);
                
                Figure.setObjectPositionInPixels(this.bImageDisplay.axisHandle, [margin, margin, leftPanelSize - colourBarSize, individualImageHeights]);
                
                Figure.setObjectPositionInPixels(this.rgbImageDisplay.axisHandle, [margin+leftPanelSize*2, margin, newPosition(3) - leftPanelSize*2 - margin*2, newPosition(4) - margin*2]);
            end
        end
        
        function createFigure(this)
            % createFigure Create figure.
            %
            %   createFigure()
            
            createFigure@Figure(this);
            
            this.setTitle('RGB Composite');
            
            this.rDataSelectionBox = uicontrol('Parent', this.handle, 'Style', 'popup', ...
                'String', {''}, 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.dataSelected(src, event, this.rImageSelectionBox));
            this.gDataSelectionBox = uicontrol('Parent', this.handle, 'Style', 'popup', ...
                'String', {''}, 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.dataSelected(src, event, this.gImageSelectionBox));
            this.bDataSelectionBox = uicontrol('Parent', this.handle, 'Style', 'popup', ...
                'String', {''}, 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.dataSelected(src, event, this.bImageSelectionBox));
            
            this.rImageSelectionBox = uicontrol('Parent', this.handle, 'Style', 'popup', ...
                'String', {''}, 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.imageSelected(src, event, this.rDataSelectionBox, this.rImageDisplay, this.rMinEditbox, this.rMaxEditbox));
            this.gImageSelectionBox = uicontrol('Parent', this.handle, 'Style', 'popup', ...
                'String', {''}, 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.imageSelected(src, event, this.gDataSelectionBox, this.gImageDisplay, this.gMinEditbox, this.gMaxEditbox));
            this.bImageSelectionBox = uicontrol('Parent', this.handle, 'Style', 'popup', ...
                'String', {''}, 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.imageSelected(src, event, this.bDataSelectionBox, this.bImageDisplay, this.bMinEditbox, this.bMaxEditbox));
            
            this.rImageDisplay = ImageDisplay(this, Image(1));
            this.rImageDisplay.setColourMap([(0:255)' zeros(256, 1) zeros(256, 1)]./255);
%             set(this.rImageDisplay.axisHandle, 'Position', [0.05, 0.5, 0.4, 0.35]);
            
            this.gImageDisplay = ImageDisplay(this, Image(1));
            this.gImageDisplay.setColourMap([zeros(256, 1) (0:255)' zeros(256, 1)]./255);
%             set(this.gImageDisplay.axisHandle, 'Position', [0.05, 0.5, 0.4, 0.35]);
            
            this.bImageDisplay = ImageDisplay(this, Image(1));
            this.bImageDisplay.setColourMap([zeros(256, 1) zeros(256, 1) (0:255)']./255);
%             set(this.bImageDisplay.axisHandle, 'Position', [0.05, 0.5, 0.4, 0.35]);
            
            this.rHisteqCheckbox = uicontrol('Parent', this.handle, 'Style', 'checkbox', ...
                'String', 'Histogram Equalisation', 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.toggleHistogramEqualisation(src, event, this.rImageDisplay));
            this.gHisteqCheckbox = uicontrol('Parent', this.handle, 'Style', 'checkbox', ...
                'String', 'Histogram Equalisation', 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.toggleHistogramEqualisation(src, event, this.gImageDisplay));
            this.bHisteqCheckbox = uicontrol('Parent', this.handle, 'Style', 'checkbox', ...
                'String', 'Histogram Equalisation', 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.toggleHistogramEqualisation(src, event, this.bImageDisplay));
            
            this.rMinLabel = uicontrol('Parent', this.handle, 'Style', 'text', ...
                'String', 'Min', 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1]);
            this.rMinEditbox = uicontrol('Parent', this.handle, 'Style', 'edit', ...
                'String', '', 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.editMinValue(src, event, this.rImageDisplay));
            this.rMaxLabel = uicontrol('Parent', this.handle, 'Style', 'text', ...
                'String', 'Max', 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1]);
            this.rMaxEditbox = uicontrol('Parent', this.handle, 'Style', 'edit', ...
                'String', '', 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.editMaxValue(src, event, this.rImageDisplay));
            
            this.gMinLabel = uicontrol('Parent', this.handle, 'Style', 'text', ...
                'String', 'Min', 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1]);
            this.gMinEditbox = uicontrol('Parent', this.handle, 'Style', 'edit', ...
                'String', '', 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.editMinValue(src, event, this.gImageDisplay));
            this.gMaxLabel = uicontrol('Parent', this.handle, 'Style', 'text', ...
                'String', 'Max', 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1]);
            this.gMaxEditbox = uicontrol('Parent', this.handle, 'Style', 'edit', ...
                'String', '', 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.editMaxValue(src, event, this.gImageDisplay));
            
            this.bMinLabel = uicontrol('Parent', this.handle, 'Style', 'text', ...
                'String', 'Min', 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1]);
            this.bMinEditbox = uicontrol('Parent', this.handle, 'Style', 'edit', ...
                'String', '', 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.editMinValue(src, event, this.bImageDisplay));
            this.bMaxLabel = uicontrol('Parent', this.handle, 'Style', 'text', ...
                'String', 'Max', 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1]);
            this.bMaxEditbox = uicontrol('Parent', this.handle, 'Style', 'edit', ...
                'String', '', 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.editMaxValue(src, event, this.bImageDisplay));
            
            this.rgbImageDisplay = ImageDisplay(this, Image(1));
            this.rgbImageDisplay.setColourBarOn(0);
            
            set(this.handle, 'units','normalized','outerposition',[0.2 0.4 0.5 0.5]);
%             columnNames = {'ROI', 'Mean', 'SD', '# Pixels', 'Max', 'Min'};
%             columnFormat = {'char', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric'};
%             columnEditable = [false, false, false, false, false, false];
%             
%             this.imageListSelection = uicontrol('Parent', this.handle, 'Style', 'popup', ...
%                 'String', {''}, 'Units', 'normalized', 'Position', [0.05, 0.85, 0.7, 0.1], 'Callback', @(src, event) this.imageSelected(src, event));
%             
%             this.allDataButton = uicontrol('Parent', this.handle, ...
%                 'String', 'View all data', 'Units', 'normalized', 'Position', [0.75, 0.9, 0.2, 0.05], 'Callback', @(src, event) this.viewAllData());
%             
%             this.imageDisplay = ImageDisplay(this, Image(1));
%             set(this.imageDisplay.axisHandle, 'Position', [0.05, 0.5, 0.4, 0.35]);
%             
%             this.roiPlot = axes(this.handle, 'Units', 'normalized', 'Position', [0.525, 0.525, 0.425, 0.325]);
%             
%             this.regionOfInterestTable = uitable('Parent', this.handle, ...
%                     'ColumnName', columnNames, 'ColumnFormat', columnFormat, 'ColumnEditable', columnEditable, ...
%                     'RowName', [], 'Units', 'normalized', 'Position', [0.05 0.15 0.9 0.3]);
%                 
%             this.copyToClipboardButton = uicontrol('Parent', this.handle, ...
%                 'String', 'Copy to clipboard', 'Units', 'normalized', 'Position', [0.05, 0.05, 0.2, 0.05], 'Callback', @(src, event) this.copyToClipboard());    
%             this.exportButton = uicontrol('Parent', this.handle, ...
%                 'String', 'Export', 'Units', 'normalized', 'Position', [0.75, 0.05, 0.2, 0.05], 'Callback', @(src, event) this.export());    
        end
    end
end