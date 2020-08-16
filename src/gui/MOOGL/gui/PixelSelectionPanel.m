%% WARNING: Using PixelSelectionPanel will override any 
% WindowButtonMotionFcn or WindowButtonUpFcn
classdef PixelSelectionPanel < handle
    properties (SetAccess = private)
        panelHandle;
        parent;
                
        regionOfInterest = [];
    end
    
    properties (GetAccess = private, Constant)
        PencilActive = 1;
        LineActive = 2;
        SquareActive = 3;
        CircleActive = 4;
        PolyActive = 5;
        EraserActive = 6;
        MoveActive = 7;
    end
    
    properties (Access = private)
        pencilButton;
        lineButton;
        squareButton;
        circleButton;
        polyButton;
        eraserButton;
        thresholdButton;
        moveButton;
        
        backgroundImageData;
        backgroundImage;
        
        axisHandle;
        imageHandle;
        
        transparencySlider;
        
        transparency = 0.3;
        
        toolActive = PixelSelectionPanel.PencilActive;
        eraserActive = 0;
        mouseDown = 0;
        lastPosition;
        startPosition;
        
        shapeHandle = [];
    end
    
    properties (Access = private, Constant)
        noROISelectedError = 'Please select or create an ROI first.';
    end
    
    
    methods
        function obj = PixelSelectionPanel(panel)
            if(~ishandle(panel) && strcmpi(get(panel, 'Type'), 'uipanel'))
                exception = MException('PixelSelection:InvalidArgument', ...
                    ['First argument must be a uipanel']);
                throw(exception);
            end
            
            obj.panelHandle = panel;
            
            % Set up the mouse motion and button callbacks for zooming
            obj.parent = get(panel, 'Parent');
            
            while(~strcmp(get(obj.parent, 'Type'), 'figure'))
                obj.parent = get(obj.parent, 'Parent');
            end
            
            set(obj.parent, 'WindowButtonMotionFcn', @(src,evnt)obj.mouseMovedCallback());
            set(obj.parent, 'WindowButtonUpFcn', @(src, evnt)obj.mouseButtonUpCallback());
            
            set(panel, 'Title', 'Select pixels');
            
            obj.pencilButton = uicontrol(panel, 'Style', 'togglebutton', 'String', 'Pencil', 'Value', 1, ...
                'Units', 'normalized', 'Position', [0.06 0.825 0.11 0.15], 'Callback', @(src, evnt)obj.pencilButtonSelected());
            obj.lineButton = uicontrol(panel, 'Style', 'togglebutton', 'String', 'Line', ...
                'Units', 'normalized', 'Position', [0.17 0.825 0.11 0.15], 'Callback', @(src, evnt)obj.lineButtonSelected());
            obj.squareButton = uicontrol(panel, 'Style', 'togglebutton', 'String', 'Rectangle', ...
                'Units', 'normalized', 'Position', [0.28 0.825 0.11 0.15], 'Callback', @(src, evnt)obj.squareButtonSelected());
            obj.circleButton = uicontrol(panel, 'Style', 'togglebutton', 'String', 'Ellipse', ...
                'Units', 'normalized', 'Position', [0.39 0.825 0.11 0.15], 'Callback', @(src, evnt)obj.circleButtonSelected());
            obj.polyButton = uicontrol(panel, 'Style', 'togglebutton', 'String', 'Poly', ...
                'Units', 'normalized', 'Position', [0.50 0.825 0.11 0.15], 'Callback', @(src, evnt)obj.polyButtonSelected());
            obj.eraserButton = uicontrol(panel, 'Style', 'togglebutton', 'String', 'Eraser', ...
                'Units', 'normalized', 'Position', [0.61 0.825 0.11 0.15], 'Callback', @(src, evnt)obj.eraserButtonSelected());
            obj.thresholdButton = uicontrol(panel, 'Style', 'pushbutton', 'String', 'Threshold', ...
                'Units', 'normalized', 'Position', [0.72 0.825 0.11 0.15], 'Callback', @(src, evnt)obj.thresholdButtonSelected());
            obj.moveButton = uicontrol(panel, 'Style', 'pushbutton', 'String', 'Move', ...
                'Units', 'normalized', 'Position', [0.83 0.825 0.11 0.15], 'Callback', @(src, evnt)obj.moveButtonSelected());
            
            obj.axisHandle = axes('Parent', panel, 'Units', 'normalized', 'Position', [0.1 0.2 0.8 0.6]);
            
            obj.transparencySlider = uicontrol(panel, 'Style', 'slider', 'String', 'Transparency', 'Value', obj.transparency, ...
                'Units', 'normalized', 'Position', [0.25 0.05 0.5 0.05], 'Callback', @(src, evnt)obj.transparencyChanged(src, evnt));
        end
        
        function setRegionOfInterest(this, regionOfInterest)
            this.regionOfInterest = regionOfInterest;
            
            this.displaySelectionData();
        end
        
        function removeRegionOfInterest(this)
            this.regionOfInterest = [];
            
            this.displaySelectionData();
        end
        
        function transparencyChanged(this, src, evnt)
            this.transparency = get(src, 'Value');
            
            this.displaySelectionData();
        end
        
        function setBackgroundImage(obj, image)
            if(~isa(image, 'Image'))
                exception = MException('PixelSelectionPanel:InvalidArgument', 'setBackgroundImage: Must supply an instance of Image.');
                throw(exception);
            end
            
            obj.backgroundImageData = image.imageData;
            obj.backgroundImage = image.normalisedTo(255);
            
            obj.displaySelectionData();
        end
        
        function displaySelectionData(this)
            axes(this.axisHandle);
            
            if(~isempty(this.backgroundImage))
                bgImage = imagesc(this.backgroundImage.imageData);
                colormap gray;
                
                hold(this.axisHandle, 'on');
            end
            
            axis image;
            
            if(~isempty(this.regionOfInterest))
                selectionImage = this.regionOfInterest.getImage();
                
                this.imageHandle = imagesc(selectionImage);

                if(~isempty(this.backgroundImage))
                    set(this.imageHandle, 'AlphaData', this.transparency);
                    
                    hold off;
                end
                
                axis image;
                
                set(this.imageHandle, 'ButtonDownFcn', @(src, evnt)this.buttonDown());
            end
        end
        
        function mouseMovedCallback(obj)
            if(obj.mouseDown)
                currentPosition = get(obj.axisHandle, 'CurrentPoint');
                currentPosition = round([currentPosition(1, 1) currentPosition(1, 2)]);
                
                switch obj.toolActive
                    case PixelSelectionPanel.PencilActive
                        if(currentPosition(1) ~= obj.lastPosition(1) || currentPosition(2) ~= obj.lastPosition(2))
                            try
                                if(obj.eraserActive)
                                    obj.regionOfInterest.removePixel(currentPosition(1), currentPosition(2));
                                else
                                    obj.regionOfInterest.addPixel(currentPosition(1), currentPosition(2));
                                end

                                obj.displaySelectionData();
                            catch err
                                % If it is simply an out of bounds error
                                % then we don't need to worry or warn the
                                % user - they simply moved their mouse too
                                % far to the right/bottom
                                if(~strcmp(err.identifier, 'RegionOfInterest:InvalidArgument'))
                                    rethrow(err);
                                end
                            end
                        end
                    case PixelSelectionPanel.LineActive
                        if(~isempty(obj.shapeHandle))
                            delete(obj.shapeHandle);
                            obj.shapeHandle = [];
                        end

                        obj.shapeHandle = line([obj.startPosition(1) currentPosition(1)], [obj.startPosition(2) currentPosition(2)]);
                    case PixelSelectionPanel.SquareActive
                        if(currentPosition(1) ~= obj.startPosition(1) || currentPosition(2) ~= obj.startPosition(2))
                            
                            startX = min(currentPosition(1), obj.startPosition(1));
                            startY = min(currentPosition(2), obj.startPosition(2));
                            endX = max(currentPosition(1), obj.startPosition(1));
                            endY = max(currentPosition(2), obj.startPosition(2));
                            
                            if(startX <= 0)
                                startX = 1;
                            end
                            if(startY <= 0)
                                startY = 1;
                            end
                            if(endX > obj.regionOfInterest.width)
                                endX = obj.regionOfInterest.width;
                            end
                            if(endY > obj.regionOfInterest.height)
                                endY = obj.regionOfInterest.height;
                            end
                            
                            rectWidth = abs(endX - startX);
                            rectHeight = abs(endY - startY);
                            
                            if(rectWidth > 0 && rectHeight > 0)
                                if(~isempty(obj.shapeHandle))
                                    delete(obj.shapeHandle);
                                    obj.shapeHandle = [];
                                end

                                obj.shapeHandle = rectangle('Position', [startX, startY, rectWidth, rectHeight]);
                            end
                        end
                    case PixelSelectionPanel.CircleActive
                        if(currentPosition(1) ~= obj.startPosition(1) || currentPosition(2) ~= obj.startPosition(2))
                            
                            startX = min(currentPosition(1), obj.startPosition(1));
                            startY = min(currentPosition(2), obj.startPosition(2));
                            endX = max(currentPosition(1), obj.startPosition(1));
                            endY = max(currentPosition(2), obj.startPosition(2));
                            
                            if(startX <= 0)
                                startX = 1;
                            end
                            if(startY <= 0)
                                startY = 1;
                            end
                            if(endX > obj.regionOfInterest.width)
                                endX = obj.regionOfInterest.width;
                            end
                            if(endY > obj.regionOfInterest.height)
                                endY = obj.regionOfInterest.height;
                            end
                            
                            rectWidth = abs(endX - startX);
                            rectHeight = abs(endY - startY);
                            
                            if(rectWidth > 0 && rectHeight > 0)
                                if(~isempty(obj.shapeHandle))
                                    delete(obj.shapeHandle);
                                    obj.shapeHandle = [];
                                end

                                obj.shapeHandle = rectangle('Position', [startX, startY, rectWidth, rectHeight], ...
                                    'EdgeColor', [1 1 1], 'Curvature', [1 1]);
                            end
                        end   
                    case PixelSelectionPanel.MoveActive
                        if(currentPosition(1) ~= obj.lastPosition(1) || currentPosition(2) ~= obj.lastPosition(2))
                            try
                                if(obj.lastPosition(1) > currentPosition(1))
                                    obj.regionOfInterest.shiftLeft(obj.lastPosition(1) - currentPosition(1));
                                end
                                if(currentPosition(1) > obj.lastPosition(1))
                                    obj.regionOfInterest.shiftRight(currentPosition(1) - obj.lastPosition(1));
                                end
                                if(obj.lastPosition(2) > currentPosition(2))
                                    obj.regionOfInterest.shiftUp(obj.lastPosition(2) - currentPosition(2));
                                end
                                if(currentPosition(2) > obj.lastPosition(2))
                                    obj.regionOfInterest.shiftDown(currentPosition(2) - obj.lastPosition(2));
                                end

                                obj.displaySelectionData();
                            catch err
                                % If it is simply an out of bounds error
                                % then we don't need to worry or warn the
                                % user - they simply moved their mouse too
                                % far to the right/bottom
                                if(~strcmp(err.identifier, 'RegionOfInterest:InvalidArgument'))
                                    rethrow(err);
                                end
                            end
                        end
                end
                
                obj.lastPosition = currentPosition;
            end
        end
        
        function shape = addLineToShape(obj, shape, startPos, endPos)
            actual_startX = round(startPos(1));
            actual_startY = round(startPos(2));
            actual_endX = round(endPos(1));
            actual_endY = round(endPos(2));
            
            x = sort([actual_startX, actual_endX], 'ascend');
            startX = x(1);
            endX = x(2);
            
            y = sort([actual_startY, actual_endY], 'ascend');
            startY = y(1);
            endY = y(2);
            
            gradient = (actual_endY - actual_startY) / (actual_endX - actual_startX);
            
            if(isinf(gradient) && startX == endX)
                % Downward line
                shape(startY:endY, startX) = 1;
            else
                constant = actual_startY-gradient*actual_startX;
                
                for y = startY:endY
                    for x = startX:endX
                        val = y - (gradient*x + constant);
  
                        if(abs(val) < max(abs(gradient), 1))
                            shape(y, x) = 1;
                        end
                    end
                end
            end
        end
        
        function mouseButtonUpCallback(obj)
            obj.mouseDown = 0;
            
            if(~isempty(obj.regionOfInterest))
                if(obj.toolActive ~= PixelSelectionPanel.PolyActive)
                    if(~isempty(obj.shapeHandle))
                        delete(obj.shapeHandle);
                        obj.shapeHandle = [];
                    end
                end
                
                if(isempty(obj.lastPosition))
                    return;
                end
                
                startX = round(min(obj.lastPosition(1), obj.startPosition(1)));
                startY = round(min(obj.lastPosition(2), obj.startPosition(2)));
                endX = round(max(obj.lastPosition(1), obj.startPosition(1)));
                endY = round(max(obj.lastPosition(2), obj.startPosition(2)));
                
                if(startX <= 0)
                    startX = 1;
                end
                if(startY <= 0)
                    startY = 1;
                end
                if(endX > obj.regionOfInterest.width)
                    endX = obj.regionOfInterest.width;
                end
                if(endY > obj.regionOfInterest.height)
                    endY = obj.regionOfInterest.height;
                end
                
                shape = false(obj.regionOfInterest.height, obj.regionOfInterest.width); 
                
                switch obj.toolActive
                    case PixelSelectionPanel.LineActive
                        actual_startX = round(obj.startPosition(1));
                        actual_startY = round(obj.startPosition(2));
                        actual_endX = round(obj.lastPosition(1));
                        actual_endY = round(obj.lastPosition(2));
                        
                        shape = obj.addLineToShape(shape, [actual_startX actual_startY], [actual_endX actual_endY]);

%                         obj.displaySelectionData();
                    case PixelSelectionPanel.SquareActive                
                        shape(startY:endY, startX:endX) = 1;
                    case PixelSelectionPanel.CircleActive
                        r1 = (endX - startX) / 2;
                        r2 = (endY - startY) / 2;
                        
                        for y = startY:endY
                            for x = startX:endX
                                if((x - startX - r1)^2/r1^2 + (y - startY - r2)^2/r2^2  <= 1)
                                    shape(y, x) = 1;
                                end
                            end
                        end
                    case PixelSelectionPanel.PolyActive
                        obj.shapeHandle(end+1) = rectangle('Position', [startX-5, startY-5, 10  10], ...
                                    'EdgeColor', [1 1 1], 'Curvature', [1 1]);
                                
                        if(length(obj.shapeHandle) > 1)
                            lastPos = get(obj.shapeHandle(end-1), 'Position');
                            
                            line([startX lastPos(1)+5], [startY lastPos(2)+5]);
                        end
                end
                
                if(obj.toolActive == PixelSelectionPanel.PolyActive && ...
                    strcmp(get(obj.parent, 'SelectionType'), 'open'))
                
                    if(~isempty(obj.shapeHandle))
                        lastPos = get(obj.shapeHandle(1), 'Position');

                        line([startX lastPos(1)+5], [startY lastPos(2)+5]);

                        for i = 1:length(obj.shapeHandle)
                            endIndex = i + 1;
                            if(endIndex > length(obj.shapeHandle))
                                endIndex = 1;
                            end

                            startPos = get(obj.shapeHandle(i), 'Position');
                            endPos = get(obj.shapeHandle(endIndex), 'Position');

                            shape = obj.addLineToShape(shape, startPos(1:2)+5, endPos(1:2)+5);
                        end
                    end
                    
                    shape = imfill(shape, 'holes');
                    
                    obj.shapeHandle = [];
                end
                
                if(obj.toolActive ~= PixelSelectionPanel.PolyActive || ...
                    strcmp(get(obj.parent, 'SelectionType'), 'open')) 
                    if(obj.eraserActive)
                        obj.regionOfInterest.removePixels(shape);
                    else
                        obj.regionOfInterest.addPixels(shape);
                    end

                    obj.displaySelectionData();
                end
            else
                msgbox(obj.noROISelectedError);
            end
        end
    end
    
    methods (Access = private)
        function buttonDown(obj)
            % Determine which button has been pressed
            obj.mouseDown = 1;
            obj.lastPosition = get(obj.axisHandle, 'CurrentPoint');
            obj.lastPosition = round([obj.lastPosition(1, 1) obj.lastPosition(1, 2)]);
            obj.startPosition = obj.lastPosition;
            
            if(obj.toolActive == PixelSelectionPanel.PencilActive)
                if(obj.eraserActive)
                    obj.regionOfInterest.removePixel(obj.lastPosition(1), obj.lastPosition(2));
                else
                    obj.regionOfInterest.addPixel(obj.lastPosition(1), obj.lastPosition(2));
                end

                obj.displaySelectionData();
            end
        end
        
        function pencilButtonSelected(obj)
            currentValue = get(obj.pencilButton, 'Value');
            
            if(currentValue)
                set(obj.lineButton, 'Value', 0);
                set(obj.squareButton, 'Value', 0);
                set(obj.circleButton, 'Value', 0);
                set(obj.polyButton, 'Value', 0);
            else
                set(obj.pencilButton, 'Value', 1);
            end
            
            obj.toolActive = PixelSelectionPanel.PencilActive;
        end
        
        function lineButtonSelected(obj)
            currentValue = get(obj.lineButton, 'Value');
            
            if(currentValue)
                set(obj.pencilButton, 'Value', 0);
                set(obj.squareButton, 'Value', 0);
                set(obj.circleButton, 'Value', 0);
                set(obj.polyButton, 'Value', 0);
            else
                set(obj.lineButton, 'Value', 1);
            end
            
            obj.toolActive = PixelSelectionPanel.LineActive;
        end
        
        function squareButtonSelected(obj)
            currentValue = get(obj.squareButton, 'Value');
            
            if(currentValue)
                set(obj.pencilButton, 'Value', 0);
                set(obj.lineButton, 'Value', 0);
                set(obj.circleButton, 'Value', 0);
                set(obj.polyButton, 'Value', 0);
            else
                set(obj.squareButton, 'Value', 1);
            end
            
            obj.toolActive = PixelSelectionPanel.SquareActive;
        end
        
        function circleButtonSelected(obj)
            currentValue = get(obj.circleButton, 'Value');
            
            if(currentValue)
                set(obj.pencilButton, 'Value', 0);
                set(obj.squareButton, 'Value', 0);
                set(obj.lineButton, 'Value', 0);
                set(obj.polyButton, 'Value', 0);
            else
                set(obj.circleButton, 'Value', 1);
            end
            
            obj.toolActive = PixelSelectionPanel.CircleActive;
        end
        
        function polyButtonSelected(obj)
            currentValue = get(obj.polyButton, 'Value');
            
            if(currentValue)
                set(obj.pencilButton, 'Value', 0);
                set(obj.squareButton, 'Value', 0);
                set(obj.lineButton, 'Value', 0);
                set(obj.circleButton, 'Value', 0);
            else
                set(obj.polyButton, 'Value', 1);
            end
            
            obj.toolActive = PixelSelectionPanel.PolyActive;
        end
        
        function eraserButtonSelected(obj)
            obj.eraserActive = get(obj.eraserButton, 'Value');
        end
        
        function setSingleButtonActive(obj, button)
            set(obj.pencilButton, 'Value', 0);
            set(obj.squareButton, 'Value', 0);
            set(obj.lineButton, 'Value', 0);
            set(obj.polyButton, 'Value', 0);
            set(obj.circleButton, 'Value', 0);
            set(obj.moveButton, 'Value', 0);
            
            set(button, 'Value', 1);
        end
        
        function moveButtonSelected(obj)            
            obj.setSingleButtonActive(obj.moveButton);
            
            obj.toolActive = PixelSelectionPanel.MoveActive;
        end
        
        function thresholdButtonSelected(this)
            if(~isempty(this.regionOfInterest))
                prompt = {'Larger than (>)', 'Or equal to?', 'Less than (<)', 'Or equal to?'};
                dialogTitle = 'Select threshold values';
                default = {num2str(min(min(this.backgroundImageData))), 'yes', num2str(max(max(this.backgroundImageData))), 'yes'};
                
                result = inputdlg(prompt, dialogTitle, 1, default);
                
                minVal = str2double(result{1});
                maxVal = str2double(result{3});
                
                minEqualTo = isempty(strfind(result{2}, 'n'));
                maxEqualTo = isempty(strfind(result{4}, 'n'));
                
                if(minEqualTo && maxEqualTo)
                    threshold = this.backgroundImageData >= minVal & this.backgroundImageData <= maxVal;
                elseif(minEqualTo)
                    threshold = this.backgroundImageData >= minVal & this.backgroundImageData < maxVal;
                elseif(maxEqualTo)
                    threshold = this.backgroundImageData > minVal & this.backgroundImageData <= maxVal;
                else
                    threshold = this.backgroundImageData > minVal & this.backgroundImageData < maxVal;
                end
                
                this.regionOfInterest.removePixels(ones(size(this.backgroundImageData)));
                this.regionOfInterest.addPixels(threshold);
                
                this.displaySelectionData();
            else
                msgbox(this.noROISelectedError);
            end
        end
    end
end