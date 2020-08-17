classdef ImageDisplay < Display
    properties (SetAccess = private)
        imageHandle;
        
        regionOfInterestList;
        
        isDiverging = false;
    end
    
    properties (Constant)
        defaultColourmap = Viridis;
    end
    
    properties (Access = protected)
        
        colourMap;
        colourMapData;
        
        axisVisibility = 'off';
        colourBarOn = 1;
        
        minValueToDisplay = 0;
        maxValueToDisplay = 1;
        
        equaliseHistogram = 0;
        
        pixelSizeX = 0;
        pixelSizeY = 0;
        
        colourMaps;
        colourMapMenuItem;
        
        scaleBarMenu;
        scaleBarDisplay;
        scaleBarText;
        
        dataToVisualise;
    end
    
    events
        PixelSelected
    end
    
    methods
        function obj = ImageDisplay(axisHandle, image)
            obj = obj@Display(axisHandle, image);
            
            if(~isa(image, 'Image'))
                exception = MException('ImageDisplay:invalidArgument', 'Must provide an instance of a class that extends Image');
                throw(exception);
            end
            
            obj.regionOfInterestList = RegionOfInterestList();
            
            obj.setColourMap(ImageDisplay.defaultColourmap);
            obj.updateDisplay();
            
            addlistener(image, 'DataChanged', @(src, evnt)obj.updateDisplay());
        end
        
        function setData(this, data)
            this.minValueToDisplay = min(data.imageData(:));
            this.maxValueToDisplay = max(data.imageData(:));
            
            if(this.minValueToDisplay == this.maxValueToDisplay)
                this.minValueToDisplay = 0;
            end
            
            title(this.axisHandle, data.description);
            
            setData@Display(this, data);
        end
        
        % Open the data in a new window. Any changes made the the
        % underlying image will be updated in the new display too
        function display = openInNewWindow(obj)
            figure = Figure;
            figure.showStandardFigure();
            figure.setTitle(['ImageDisplay: ' obj.data.description]);

            display = ImageDisplay(figure, obj.data);
            
            display.copy(obj);
            
            set(figure.handle, 'Color', [1 1 1])
            t = title(display.axisHandle, obj.data.description);
            set(t, 'Visible', 'on')
        end
        
        % Open a copy of the data in a new window so that if any changes
        % are made to the image in this display they aren't updated in
        % the new display
        function display = openCopyInNewWindow(obj)
            figure = Figure;
            figure.showStandardFigure();
%             axisHandle = axes;
            display = ImageDisplay(figure, Image(obj.data.imageData));
            
            display.copy(obj);
        end
        
        function exportToImageFile(this, filename)
            print(this.parent.getParentFigure().handle, filename, '-dpng', '-painters', '-r600');
        end
        
        function exportToImage(obj)
            [fileName, pathName, filterIndex] = uiputfile([obj.lastSavedPath 'image.pdf'], 'Export image');
            
            if(filterIndex > 0)
                obj.lastSavedPath = [pathName filesep];
                
                f = figure;%('Visible', 'off');
                pos = get(f, 'Position');
                set(f, 'Position', pos*2);
                
                axisHandle = axes;
                colorbar(axisHandle);
                normPos = get(axisHandle, 'Position');
                delete(axisHandle);

%                 axisHandle = axes;
%                 display = ImageDisplay(axisHandle, obj.data);
% 
%                 display.copy(obj);
%                 
%                 set(f, 'Color', 'none');
%                 
%                 export_fig(f, [pathName filesep fileName], '-painters', '-transparent');

                newAxis = copyobj(obj.axisHandle, f);
                colormap(f, obj.colourMapData);
                
                
                cb = colorbar(newAxis, 'southoutside');
                
                set(cb, 'Units', get(f, 'PaperUnits'));
                cbSouthPos = get(cb, 'Position');
                set(cb, 'Units', 'normalized');
                
                delete(cb);
                
                cb = colorbar(newAxis);
                
                set(cb, 'Units', get(f, 'PaperUnits'));
                cbPos = get(cb, 'Position');
                set(cb, 'Units', 'normalized');
                    
                if(~obj.colourBarOn)
                    delete(cb);
                end
                
                
                set(newAxis, 'Position', normPos);                
                
%                 set(newAxis, 'Units', get(f, 'PaperUnits'));
%                 axisPos = get(newAxis, 'Position');
%                 set(newAxis, 'Units', 'normalized');
                
                
                
%                 get(cb, 'Position')
%                 get(newAxis, 'Position')
                
                
                % Use the colour bar as a better indicator of the height
                imageWidth = cbSouthPos(3) + 3;
                imageHeight = cbPos(4) + 1;
                
                set(f, 'PaperSize', [imageWidth imageHeight]);
                set(f, 'PaperPosition', [-0.5 -0.25 imageWidth imageHeight]);
                set(f, 'PaperPositionMode', 'manual');
                set(f, 'Color', 'None');
                
                print(f, [pathName filesep fileName], '-dpdf', '-painters', '-r600');

%                 delete(f);
            end
        end
        
        function exportToLaTeX(obj)
        end
        
        function setDivergingColourMap(this)
            this.isDiverging = true;
            
            minVal = min(0, min(this.data.imageData(:)));
            maxVal = max(0, max(this.data.imageData(:)));
            
            %             scale = (maxVal - minVal) / 64;
            scaleSize = 256;
            zeroLoc = round((abs(minVal) / (maxVal - minVal)) * scaleSize);
            
            if(zeroLoc <= 0)
                zeroLoc = 1;
            elseif(zeroLoc >= scaleSize)
                zeroLoc = scaleSize;
            end
            
            colourMap = zeros(scaleSize, 3);
            
            for i = 1:zeroLoc
                colourMap(i, 2) = ((zeroLoc - (i - 1)) / zeroLoc);
            end
            
            for i = zeroLoc:scaleSize
                colourMap(i, [1 3]) = (i - zeroLoc) / (scaleSize - zeroLoc);
            end
            
            colourMap(zeroLoc, :) = [0 0 0];
            
            this.setColourMap(colourMap);
            this.setColourBarOn(1);
        end
        
        function setColourMap(obj, colourMap)
            if(isa(colourMap, 'Colourmap'))
                obj.colourMapData = colourMap.getColourMap();
                
                % Ensure the correct colour map is denoted as selected
                for i = 1:length(obj.colourMapMenuItem)
                    if(strcmp(get(obj.colourMapMenuItem(i), 'Label'), colourMap.Name))
                        set(obj.colourMapMenuItem(i), 'Checked', 'on');
                    else
                        set(obj.colourMapMenuItem(i), 'Checked', 'off');
                    end
                end
            else
                obj.colourMapData = colourMap;
            end
            
%             obj.colourMap = colourMap;
            
            obj.updateDisplay();
        end
        
        function setColourBarOn(obj, colourBarOn)
            obj.colourBarOn = colourBarOn;
            
            obj.updateDisplay();
        end
                
        function addRegionOfInterest(this, regionOfInterest)
            this.regionOfInterestList.add(regionOfInterest);
        end
        
        function removeAllRegionsOfInterest(this)
            this.regionOfInterestList.removeAll();
            
            this.updateDisplay();
        end
        
        function setEqualiseHistogram(this, equalise)
            this.equaliseHistogram = equalise;
            
            this.updateDisplay();
        end
        
        function visualisedData = getVisualisedData(this) 
            visualisedData = this.dataToVisualise;
        end
        
        function setMinValueToDisplay(this, minValue)
            this.minValueToDisplay = minValue;
            
            this.updateDisplay();
        end
        
        function setMaxValueToDisplay(this, maxValue)
            this.maxValueToDisplay = maxValue;
            
            this.updateDisplay();
        end
        
        function updateDisplay(obj)            
%             axes(obj.axisHandle);

            
            obj.dataToVisualise = obj.data.imageData;
            
            if(obj.equaliseHistogram && ismatrix(obj.dataToVisualise))
                maxValue = max(obj.dataToVisualise(:));
                
                obj.dataToVisualise = histeq(obj.dataToVisualise ./ maxValue) .* maxValue;
            end
            
            obj.dataToVisualise(obj.dataToVisualise < obj.minValueToDisplay) = obj.minValueToDisplay;
            obj.dataToVisualise(obj.dataToVisualise > obj.maxValueToDisplay) = obj.maxValueToDisplay;
            
            cLims = [obj.minValueToDisplay obj.maxValueToDisplay];
            
            if(cLims == [0 0])
                cLims = [0 1];
            end
            
            if(isempty(obj.imageHandle))
                obj.imageHandle = imagesc(obj.axisHandle, 'CData', obj.dataToVisualise, cLims);
            else
%                 set(obj.imageHandle, 'CData', obj.data.imageData);
                obj.imageHandle = imagesc(obj.axisHandle, 'CData', obj.dataToVisualise, cLims);
            end
            
            set(obj.imageHandle, 'AlphaData', 1);
%             
            if(isempty(obj.colourMapData))
                obj.colourMapData = obj.defaultColourmap.getColourMap();
            end
            
            if(isa(obj.colourMapData, 'Colourmap'))
                obj.colourMapData = obj.colourMapData.getColourMap();
            end
            
%             obj.colourMapData
            colormap(obj.axisHandle, obj.colourMapData);
            set(obj.axisHandle, 'Visible', obj.axisVisibility);
            
            if(obj.colourBarOn)
                colorbar(obj.axisHandle);
            else
                colorbar(obj.axisHandle, 'off');
            end
            
            if(isa(obj.regionOfInterestList, 'RegionOfInterestList'))
                roisToDisplay = obj.regionOfInterestList.getObjects();

                if(~isempty(roisToDisplay))
                    % Display the image in grayscale if we're showing ROIs for
                    % ease of visbility
                    colormap gray;

                    hold(obj.axisHandle, 'on');
                    
                    maxDisplayedVal = max(obj.data.imageData(:));
                    
                    roiImage = zeros(size(obj.data.imageData, 1), size(obj.data.imageData, 2), 3);
                    alphaChannel = zeros(size(obj.data.imageData));
                    
                    for i = 1:numel(roisToDisplay)
%                         roisToDisplay{i}.getImage()
                        currentROIImage = roisToDisplay{i}.getImage();
                        if size(currentROIImage, 1) < size(roiImage, 1)
                            currentROIImage(size(roiImage, 1), 1, :) = 0;
                        end
                        if size(currentROIImage, 2) < size(roiImage, 2)
                            size(roiImage, 2)
                            currentROIImage(1, size(roiImage, 2), :) = 0;
                        end
                        if size(currentROIImage, 1) > size(roiImage, 1)
                            currentROIImage = currentROIImage(1:size(roiImage, 1), :, :);
                        end
                        if size(currentROIImage, 2) > size(roiImage, 2)
                            currentROIImage = currentROIImage(:, 1:size(roiImage, 2), :);
                        end

                        roiImage = roiImage + double(currentROIImage);

                        alphaChannel = alphaChannel + (sum(roiImage, 3) ~= 0);
    %                     roiImage = (roiImage ./ 255);
    %                     max(roiImage(:))
    %                     maxDisplayedVal
    %                     obj.imageHandle = imagesc(roiImage);
    %                     set(obj.imageHandle, 'AlphaData', 0.5 / numel(roisToDisplay));
                    end
                    
                    obj.imageHandle = imagesc(obj.axisHandle, 'CData', roiImage./max(roiImage(:)));
                    set(obj.imageHandle, 'AlphaData', 0.5);
                    
                    hold(obj.axisHandle, 'off');
                end
            end
            
            
            if(strcmp(get(obj.scaleBarMenu, 'Checked'), 'on'))
                [height, width] = size(obj.data.imageData);
                widthUm = width * obj.pixelSizeX;
                heightUm = height * obj.pixelSizeY;
                
                roughScaleBarSize = widthUm * 0.1;
                
                nearestTen = floor(log10(roughScaleBarSize));
                roundValueUm = round(roughScaleBarSize / 10^nearestTen) * 10^nearestTen;
                roundValuePixels = roundValueUm/obj.pixelSizeX;
                
                units = 'μm';
                
                if(roundValueUm > 1000)
                    roundValueUm = roundValueUm / 1000;
                    units = 'mm';
                end
                
                rectangle('Position',[width * 0.05, height * 0.85, roundValuePixels, height * 0.015],...
                'FaceColor',[1 1 1], 'EdgeColor','w');
            
                obj.scaleBarText = text(round(width * 0.05)+roundValuePixels/2, height * 0.82, [num2str(roundValueUm) ' ' units], 'FontSize', 13, 'Color', 'w', ...
                    'HorizontalAlignment', 'center');
            end
                
            axis(obj.axisHandle, 'image', 'ij');
            
            set(obj.imageHandle, 'ButtonDownFcn', @(src, evnt)obj.buttonDownCallback());
            
            % Reset necessary callbacks
            set(obj.axisHandle, 'UIContextMenu', obj.contextMenu);
            set(obj.imageHandle, 'UIContextMenu', obj.contextMenu);
            
            % Ensure that notifications are made that the display has
            % changed
            updateDisplay@Display(obj);
        end
        
        function createContextMenu(obj)
            createContextMenu@Display(obj);
            
            uimenu(obj.exportMenu, 'Label', 'To CSV', 'Callback', @(src, evnt)obj.exportToCSV());
            
            % Checks if getSubclasses is on the path, if so likely to be
            % SpectralAnalysis running, so add in the colour map menu
            % automatically
            if(exist('getSubclasses', 'file'))
                [obj.colourMaps, classNames] = getSubclasses('Colourmap', 0);
                
                obj.addColourmapMenu(obj.colourMaps, classNames);
            end
            
            % Add in scale bar menu
            uimenu(obj.contextMenu, 'Label', 'Set pixel size', 'Callback', @(src, evnt)obj.setPixelSize());
            obj.scaleBarMenu = uimenu(obj.contextMenu, 'Label', 'Scale bar', 'Callback', @(src, evnt)obj.toggleScaleBarDisplay());
            %obj.scaleBarDisplay = uimenu(obj.scaleBarMenu, 'Label', 'Display', 'Callback', @(src, evnt)obj.toggleScaleBarDisplay());
        end
        
        function toggleScaleBarDisplay(this)
            if(this.pixelSizeX == 0)
                this.setPixelSize();
            end
            
            showScaleBar = get(this.scaleBarMenu, 'Checked');
            
            if(strcmp(showScaleBar, 'on'))
                set(this.scaleBarMenu, 'Checked', 'off');
            else
                set(this.scaleBarMenu, 'Checked', 'on');
            end
            
            this.updateDisplay();
        end
        
        function setPixelSize(this)
            prompt = {'Pixel size x (μm):', 'Pixel size y (μm):'};
            dlgtitle = 'Set pixel size';
            
            answer = inputdlg(prompt,dlgtitle);
            
            this.pixelSizeX = str2double(answer{1});
            if ~isempty(answer{2})
                this.pixelSizeY = str2double(answer{2});
            else
                this.pixelSizeY = this.pixelSizeX;
            end
            
            this.updateDisplay();
        end
        
        function addColourmapMenu(obj, colourMaps, classNames)
            % addColourmapMenu Toggle the display between continuous and discrete.
            %
            %   addColourmapMenu()
            
            colourmapMenu = uimenu(obj.contextMenu, 'Label', 'Colourmaps', 'Separator', 'on');
            
            for i = 1:length(classNames)
                obj.colourMapMenuItem(i) = uimenu(colourmapMenu, 'Label', classNames{i}, 'Callback', @(src, evnt)obj.setColourMap(eval(colourMaps{i})));
            end
        end
    end
    
    methods (Access = protected)
        function copy(obj, oldobj)
            obj.setColourMap(oldobj.colourMap);
            
            obj.axisVisibility = oldobj.axisVisibility;
            obj.colourBarOn = oldobj.colourBarOn;
            
            obj.regionOfInterestList = oldobj.regionOfInterestList;
            
            if(oldobj.isDiverging)
                obj.setDivergingColourMap()
            end
            
            obj.updateDisplay();
        end
        
        function buttonDownCallback(obj)
            currentPoint = get(obj.axisHandle, 'CurrentPoint');
            
            fig = gcbf;
            
            if(strcmp(get(fig, 'SelectionType'), 'normal'))
                xPoint = currentPoint(1, 1);
                yPoint = currentPoint(1, 2);

                pse = PixelSelectionEvent(xPoint, yPoint);

                notify(obj, 'PixelSelected', pse);
            end
        end
    end
end
