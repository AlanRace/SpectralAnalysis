classdef MathematicalManipulationFigure < Figure
    properties
        dataViewList;
        
        firstDataSelectionBox;
        secondDataSelectionBox;
        thirdDataSelectionBox;
        
        firstImageSelectionBox;
        secondImageSelectionBox;
        thirdImageSelectionBox;
        
        firstOperationSelectionBox;
        secondOperationSelectionBox;
        
        firstImageDisplay;
        secondImageDisplay;
        thirdImageDisplay;
        
        useThirdImageCheckbox;
        
        resultingImageDisplay;
    end
    
    methods
        function this = MathematicalManipulationFigure(dataViewList)
            this.dataViewList = dataViewList;
            
            this.updateLists();
        end
        
        function updateLists(this)
            dataViews = this.dataViewList.getObjects();
            titles = {};
            
            for i = 1:length(dataViews)
                titles{i} = dataViews{i}.title;
            end
            
            set(this.firstDataSelectionBox, 'String', titles)
            set(this.secondDataSelectionBox, 'String', titles)
            set(this.thirdDataSelectionBox, 'String', titles)
        end
        
        function dataSelected(this, src, event, imageSelectionBox)
            dataViewer = this.dataViewList.get(get(src, 'Value'));
            
            set(imageSelectionBox, 'String', {dataViewer.imageList.description});
            set(imageSelectionBox, 'Value', 1)
        end
        
        function imageSelected(this, src, event, dataSelectionBox, imageDisplay)
            dataViewer = this.dataViewList.get(get(dataSelectionBox, 'Value'));
            image = dataViewer.imageList(get(src, 'Value'));
            
%             set(minEditbox, 'String', num2str(min(image.imageData(:))))
%             set(maxEditbox, 'String', num2str(max(image.imageData(:))))
            
            imageDisplay.setData(image);
            
            this.updateResultingImage();
        end
        
        function updateUseThirdImage(this, src, event)
            this.updateResultingImage();
        end
        
        function updateResultingImage(this)
            firstImageData = medfilt2(this.firstImageDisplay.getVisualisedData(), [1 1]);
            secondImageData = medfilt2(this.secondImageDisplay.getVisualisedData(), [1 1]);
            thirdImageData = medfilt2(this.thirdImageDisplay.getVisualisedData(), [1 1]);
                        
            if(~isempty(firstImageData) && ~isempty(secondImageData))
                operations = get(this.firstOperationSelectionBox, 'String');
                operation = operations{get(this.firstOperationSelectionBox, 'Value')};
                
%                 secondImageData(secondImageData < 30) = 0;
                
                if(strcmp(operation, 'Divide'))
                    resultingImage = firstImageData ./ secondImageData;
                elseif(strcmp(operation, 'Multiply'))
                    resultingImage = firstImageData .* secondImageData;
                elseif(strcmp(operation, 'Subtract'))
                    resultingImage = firstImageData - secondImageData;
                end
                
                resultingImage(sum(secondImageData, 2) == 0, :) = 0;
                resultingImage(:, sum(secondImageData, 1) == 0) = 0;
                
                
                if(get(this.useThirdImageCheckbox, 'Value'))
                    if(~isempty(thirdImageData))
                        operations = get(this.secondOperationSelectionBox, 'String');
                    operation = operations{get(this.secondOperationSelectionBox, 'Value')};

                        if(strcmp(operation, 'Divide'))
                            resultingImage = resultingImage ./ thirdImageData;
                        elseif(strcmp(operation, 'Multiply'))
                            resultingImage = resultingImage .* thirdImageData;
                        elseif(strcmp(operation, 'Subtract'))
                            resultingImage = resultingImage - thirdImageData;
                        end
                    end
                end
                
                resultingImage(isinf(resultingImage)) = 0;
                resultingImage = resultingImage ./ quantile(resultingImage(:), 0.9999);
                resultingImage(resultingImage > 1) = 1;

                resultingImage = resultingImage - min(resultingImage(:));
                
%                 resultingImage = medfilt2(resultingImage, [3 3]);
                
                
                this.resultingImageDisplay.setData(Image(resultingImage));
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
                
                Figure.setObjectPositionInPixels(this.firstDataSelectionBox, [margin, newPosition(4)-buttonHeight-margin, leftPanelSize*2, buttonHeight]);
                Figure.setObjectPositionInPixels(this.firstImageSelectionBox, [margin, newPosition(4)-buttonHeight*2-margin, leftPanelSize, buttonHeight]);
                
                Figure.setObjectPositionInPixels(this.firstImageDisplay.axisHandle, [margin, newPosition(4)*2/3+margin, leftPanelSize - colourBarSize, individualImageHeights]);
                
                Figure.setObjectPositionInPixels(this.secondDataSelectionBox, [margin, newPosition(4)*2/3-buttonHeight-margin, leftPanelSize*2, buttonHeight]);
                Figure.setObjectPositionInPixels(this.secondImageSelectionBox, [margin, newPosition(4)*2/3-buttonHeight*2-margin, leftPanelSize, buttonHeight]);
                
                Figure.setObjectPositionInPixels(this.firstOperationSelectionBox, [margin*2+leftPanelSize, newPosition(4)*2/3-buttonHeight*2-margin, leftPanelSize, buttonHeight]);
                
                Figure.setObjectPositionInPixels(this.secondImageDisplay.axisHandle, [margin, newPosition(4)/3+margin, leftPanelSize - colourBarSize, individualImageHeights]);
                
                Figure.setObjectPositionInPixels(this.thirdDataSelectionBox, [margin, newPosition(4)/3-buttonHeight-margin, leftPanelSize*2, buttonHeight]);
                Figure.setObjectPositionInPixels(this.thirdImageSelectionBox, [margin, newPosition(4)/3-buttonHeight*2-margin, leftPanelSize, buttonHeight]);
                
                Figure.setObjectPositionInPixels(this.secondOperationSelectionBox, [margin*2+leftPanelSize, newPosition(4)/3-buttonHeight*2-margin, leftPanelSize, buttonHeight]);
                
                Figure.setObjectPositionInPixels(this.thirdImageDisplay.axisHandle, [margin, margin, leftPanelSize - colourBarSize, individualImageHeights]);
                
                Figure.setObjectPositionInPixels(this.useThirdImageCheckbox, [margin + leftPanelSize, newPosition(4)/3-buttonHeight*3-margin, leftPanelSize, buttonHeight]);
                
                Figure.setObjectPositionInPixels(this.resultingImageDisplay.axisHandle, [margin+leftPanelSize*2, margin, newPosition(3) - leftPanelSize*2 - margin*2, newPosition(4) - margin*2]);
            end
        end
        
        function createFigure(this)
            % createFigure Create figure.
            %
            %   createFigure()
            
            createFigure@Figure(this);
            
            this.setTitle('Mathematical Manipulation');
            
            this.firstDataSelectionBox = uicontrol('Parent', this.handle, 'Style', 'popup', ...
                'String', {''}, 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.dataSelected(src, event, this.firstImageSelectionBox));
            this.secondDataSelectionBox = uicontrol('Parent', this.handle, 'Style', 'popup', ...
                'String', {''}, 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.dataSelected(src, event, this.secondImageSelectionBox));
            this.thirdDataSelectionBox = uicontrol('Parent', this.handle, 'Style', 'popup', ...
                'String', {''}, 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.dataSelected(src, event, this.thirdImageSelectionBox));
            
            this.firstImageSelectionBox = uicontrol('Parent', this.handle, 'Style', 'popup', ...
                'String', {''}, 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.imageSelected(src, event, this.firstDataSelectionBox, this.firstImageDisplay));
            this.secondImageSelectionBox = uicontrol('Parent', this.handle, 'Style', 'popup', ...
                'String', {''}, 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.imageSelected(src, event, this.secondDataSelectionBox, this.secondImageDisplay));
            this.thirdImageSelectionBox = uicontrol('Parent', this.handle, 'Style', 'popup', ...
                'String', {''}, 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.imageSelected(src, event, this.thirdDataSelectionBox, this.thirdImageDisplay));
            
            this.firstOperationSelectionBox = uicontrol('Parent', this.handle, 'Style', 'popup', ...
                'String', {'Divide', 'Multiply', 'Subtract'}, 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.updateResultingImage());
            this.secondOperationSelectionBox = uicontrol('Parent', this.handle, 'Style', 'popup', ...
                'String', {'Divide', 'Multiply', 'Subtract'}, 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.updateResultingImage());
            
            this.useThirdImageCheckbox = uicontrol('Parent', this.handle, 'Style', 'checkbox', ...
                'String', {'Include?'}, 'Units', 'normalized', 'Position', [0.05, 0.85, 0.3, 0.1], 'Callback', @(src, event) this.updateUseThirdImage(src, event));
            
            this.firstImageDisplay = ImageDisplay(this, Image(1));
%             this.firstImageDisplay.setColourMap([(0:255)' zeros(256, 1) zeros(256, 1)]./255);
            this.secondImageDisplay = ImageDisplay(this, Image(1));
            this.thirdImageDisplay = ImageDisplay(this, Image(1));
            
            this.resultingImageDisplay = ImageDisplay(this, Image(1));

            set(this.handle, 'units','normalized','outerposition',[0.2 0.4 0.5 0.5]);
        end
    end
    
    
end
