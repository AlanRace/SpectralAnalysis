classdef SpectrumDisplay < Display
    % SpectrumDisplay handles displaying a spectrum, either continuous or
    % centroided (displaying as a plot and bar chart respectively).
    
    properties (SetAccess = protected)
        plotHandle; % Handle for either the bar or line plot
        
        peakList;
    end
    
    properties (Access = protected)
        
        zoomingIn = 0; % Variable used to determine if we are in zoom mode
        aboveAxis = 0; % Determines whether mouse was clicked above axis
        
        xLimit; % Display limit in x direction
        yLimit; % Display limir in y direction
        
        startPoint; 
        mouseLocation;
        currentLine;
        leftMouseDown = 0;
        
        peakDetectionMethod;
        
        peakDetectionMethods;
        peakDetectionMenuItem;
        
        peakFilterListEditor;
        
        continuousDisplay;
        
        xLabel;
        yLabel;
    end
    
    events
        % PeakSelected is triggered when a peak has been selected within
        % the display.
        PeakSelected;
        
        PeakListUpdated;
    end
    
    methods
        function obj = SpectrumDisplay(parent, spectrum)
            obj = obj@Display(parent, spectrum);
            
            if(~isa(spectrum, 'SpectralData'))
                exception = MException('SpectrumDisplay:invalidArgument', 'Must provide an instance of a class that extends SpectralData');
                throw(exception);
            end
            
            % Set up the mouse motion and button callbacks for zooming
            addlistener(parent, 'ButtonDown', @(src, evnt)obj.buttonDownCallback());
            addlistener(parent, 'ButtonMotion', @(src,evnt)obj.mouseMovedCallback());
            addlistener(parent, 'ButtonUp', @(src, evnt)obj.mouseButtonUpCallback());
        end
        
        function setLabels(this, xLabel, yLabel) 
            this.xLabel = xLabel;
            this.yLabel = yLabel;
            
            this.updateDisplay();
        end
        
        function createContextMenu(obj)
            createContextMenu@Display(obj);
            
            uimenu(obj.exportMenu, 'Label', 'To CSV', 'Callback', @(src, evnt)obj.exportToCSV());
            
            % Checks if getSubclasses is on the path, if so likely to be
            % SpectralAnalysis running, so add in the peak detection menu
            % automatically
            % TODO: Have a better way of automatically adding the peak
            % picking menu, or move the menu elsewhere in the interface
            if(exist('getSubclasses', 'file'))
                [obj.peakDetectionMethods, classNames] = getSubclasses('SpectralPeakDetection', 1);
                
                obj.addPeakDetectionMenu(classNames);
            end
            
            obj.continuousDisplay = uimenu(obj.contextMenu, 'Label', 'Continuous Display', 'Checked', 'on', 'Callback', @(src, evnt)obj.switchContinuousDisplay());
        end
        
        function setContinousDisplay(this, onoff)
            if islogical(onoff)
                if onoff
                    onoff = 'on';
                else 
                    onoff = 'off';
                end
            end
            
            set(this.continuousDisplay, 'Checked', onoff);
            
            this.updateDisplay();
        end
        
        function switchContinuousDisplay(this)
            % switchContinuousDisplay Toggle the display between continuous and discrete.
            %
            %   switchContinuousDisplay()
            
            isContinuous = get(this.continuousDisplay, 'Checked');
            
            if(strcmp(isContinuous, 'on'))
                set(this.continuousDisplay, 'Checked', 'off');
            else
                set(this.continuousDisplay, 'Checked', 'on');
            end
            
            this.updateDisplay();
        end
        
        function addPeakDetectionMenu(obj, classNames)
            % addPeakDetectionMenu Add the peak detection menu with the
            % specified methods.
            %
            %   addPeakDetectionMenu()
            
            labelPeaks = uimenu(obj.contextMenu, 'Label', 'Label Peaks', 'Separator', 'on');
                        
            for i = 1:length(classNames)
                obj.peakDetectionMenuItem(i) = uimenu(labelPeaks, 'Label', classNames{i}, 'Callback', @(src, evnt)obj.labelPeaksWithMethod(i));
            end
            
            set(obj.peakDetectionMenuItem(1), 'Checked', 'on');
        end
        
        function exportToCSV(obj)
            % exportToCSV exports the current data to a CSV file. If peak
            % detection has been activated, then just the peaks are
            % written out, otherwise the entire spectrum is written.
            
            [FileName,PathName,FilterIndex] = uiputfile('*.csv', 'Save spectrum as', 'spectrum.csv');
            
            % Check that the user has not cancelled
            if(FilterIndex == 1)
                % Check whether peak detection has been performed
                if(isempty(obj.peakList) || isempty(obj.peakHeight))
                    xToWrite = obj.data.spectralChannels;
                    yToWrite = obj.data.intensities;
                else
                    xToWrite = obj.peakList;
                    yToWrite = obj.peakHeight;
                end
                
                try
                    % Determine which decimal separator is used so that it
                    % works with German separators
                    decimalSeparator = java.text.DecimalFormat().getDecimalFormatSymbols().getDecimalSeparator();
                    
                    if(strcmp(decimalSeparator, ','))
                        decimalSeparator = ',';
                        csvSeparator = ';';
                    else
                        decimalSeparator = '.';
                        csvSeparator = ',';
                    end
                    
                    fid = fopen([PathName filesep FileName], 'w');
                    
                    for i = 1:length(xToWrite)
                        fprintf(fid, strrep(strrep(sprintf('%0.10f%s%0.10f\n', xToWrite(i), '#', yToWrite(i)), '.', decimalSeparator), '#', csvSeparator));
                    end
                    
                    fclose(fid);
                catch err
                    msgbox(err.message, err.identifier);
                    
                    dbstack
                end
            end
        end
        
        function setData(obj, spectrum)
            obj.xLimit = [min(spectrum.spectralChannels) max(spectrum.spectralChannels)];
            obj.yLimit = [min(spectrum.intensities) max(spectrum.intensities)];
            
            setData@Display(obj, spectrum);
            
            % If peak picking is on then make sure we peak pick on the new
            % spectrum
            if(~isempty(obj.peakDetectionMethod))
                obj.updatePeakDetection();
            end
            
            if(~spectrum.isContinuous)
                obj.setContinousDisplay('off');
            end
        end
        
        function xLimit = getXLimit(obj)
            xLimit = obj.xLimit;
        end
        
        function yLimit = getYLimit(obj)
            yLimit = obj.yLimit;
        end
        
        function setXLimit(obj, xLimit)
            obj.xLimit = xLimit;
            obj.updateDisplay();
        end
        
        function setYLimit(obj, yLimit)
            obj.yLimit = yLimit;
            obj.updateDisplay();
        end
        
        function labelPeaksWithMethod(obj, index)
            for i = 1:length(obj.peakDetectionMenuItem)
                try
                    set(obj.peakDetectionMenuItem(i), 'Checked', 'off');
                catch 
                    % Do nothing, happens if the peak detection menu item
                    % no longer exists
                end
            end
            
            try
                set(obj.peakDetectionMenuItem(index), 'Checked', 'on');
            catch
                % Do nothing, happens if the peak detection menu item
                % no longer exists
            end
            
            if(index > 1)
                obj.peakDetectionMethod = eval([obj.peakDetectionMethods{index} '()']);
                
                if(isa(obj.peakFilterListEditor, 'PeakFilterListEditor') && isvalid(obj.peakFilterListEditor))
                    figure(obj.peakFilterListEditor.figureHandle);
                else
                    obj.peakFilterListEditor = PeakFilterListEditor(obj.data, obj.peakDetectionMethod);
                    addlistener(obj.peakFilterListEditor, 'FinishedEditing', @(src, evnt)obj.updatePeakDetection());
                end
            else
                obj.peakDetectionMethod = [];
                
                obj.peakList = [];
            end
            
            obj.updateDisplay();
        end
        
        function setPeakDetection(obj, peakDetection)
            obj.peakDetectionMethod = peakDetection;
            
            obj.updatePeakDetection();
        end
        
        function updatePeakDetection(obj)
            obj.peakList = obj.peakDetectionMethod.process(obj.data);
            notify(obj, 'PeakListUpdated', PeakListChangedEventData(obj.peakList));
            
            assignin('base', 'peakList', obj.peakList);
            
            obj.updateDisplay();
        end
                
        function display = openInNewWindow(obj)
            % openInNewWindow Opens the spectral data in a new window.
            %
            %   openInNewWindow()
            %
            %   Open the spectral data in a new window with same display 
            %   options applied. Any changes made the the underlying 
            %   spectrum will be updated in the new display too.
            
            figure = Figure;
            figure.showStandardFigure();
            
            set(figure.handle, 'Color', 'w');
            
            spectrumPanel = SpectrumPanel(figure, obj.data);
           
            set(spectrumPanel.handle, 'BackgroundColor', 'w');
            
            display = spectrumPanel.spectrumDisplay;
            display.updateDisplay();
        end
        
        function display = openCopyInNewWindow(obj)
            % openCopyInNewWindow Opens a copy of the spectral data in a new window.
            %
            %   openCopyInNewWindow()
            %
            %   Open a copy of the spectral data in a new window so that if 
            %   any changes are made to the spectrum in this display they 
            %   aren't updated in the new display.
        
            
            figure = Figure;
            figure.showStandardFigure();
            
            spectrumPanel = SpectrumPanel(figure, SpectralData(obj.data.spectralChannels, obj.data.intensities));
            
            display = spectrumPanel.spectrumDisplay;
            display.updateDisplay();
        end
        
        
        function exportToImage(obj)
            % exportToImage exports a spectrum to a PDF image. 
            
            [fileName, pathName, filterIndex] = uiputfile([obj.lastSavedPath 'spectrum.pdf'], 'Export image');
            
            if(filterIndex > 0)
                obj.lastSavedPath = [pathName filesep];
                
                f = figure('Visible', 'off');
                axisHandle = axes;
                normPos = get(axisHandle, 'Position');
                delete(axisHandle);
                
                newAxis = copyobj(obj.axisHandle, f);
                
                % Fix aspect ratio
                pos = get(newAxis, 'Position');
                aspectRatio = pos(4) / pos(3);
                set(newAxis, 'Position', normPos);
                
                posOfFigure = get(f, 'PaperPosition');
                posOfFigure(1) = 0;
                posOfFigure(2) = 0;
                posOfFigure(4) = round(posOfFigure(3) * aspectRatio / 1.5);
                set(f, 'PaperSize', [posOfFigure(3) posOfFigure(4)]);
                set(f, 'PaperPosition', posOfFigure);
                set(f, 'PaperPositionMode', 'manual');
                
                print(f, [pathName filesep fileName], '-dpdf', '-painters', '-r0');
                
                delete(f);
            end
        end
        
        function exportToLaTeX(obj)
            %TODO
        end
        
        
        function updateDisplay(obj)            
            obj.plotSpectrum();
            
            obj.fixLimits();
            obj.updateLimits();
            
            if(~isempty(obj.peakList))
                peakCentroids = [obj.peakList.centroid];
                
                indicies = peakCentroids >= obj.xLimit(1) & peakCentroids <= obj.xLimit(2);
                
                peaksToDisplay = obj.peakList(indicies);
                
                xData = [peaksToDisplay.centroid];
                yData = [peaksToDisplay.intensity];
                
                yPos = ((obj.yLimit(2) - obj.yLimit(1)) * 0.95) + obj.yLimit(1);
                
                text(obj.xLimit(1), yPos, ['Detected peaks: ' num2str(length(obj.peakList))], 'Parent', obj.axisHandle);
                
                [m, indicies] = sort(yData, 'descend');
                
                for i = 1:min(10, length(xData))
                    text(xData(indicies(i)), yData(indicies(i)), num2str(xData(indicies(i))), 'Parent', obj.axisHandle);
                end
            end
            
            if ~obj.isUIFigure
                % Set up callback functions such as button down functions
                set(obj.plotHandle, 'ButtonDownFcn', @(src, evnt)obj.buttonDownCallback());
                set(obj.axisHandle, 'ButtonDownFcn', @(src, evnt)obj.buttonDownCallback());
            else
%                 tb = axtoolbar(obj.axisHandle, {'pan', 'zoomin','zoomout','restoreview'});
%                 btn = axtoolbarbtn(tb,'state');
%                 % btn.Icon = 'mygridicon.png';
%                 btn.Tooltip = 'Grid Lines';
%                 btn.ValueChangedFcn = @(src, event) obj.test(src, event);
                
                
            end
            
            if(~isempty(obj.contextMenu))
                set(obj.axisHandle, 'UIContextMenu', obj.contextMenu);
            end
            
            % Ensure that notifications are made that the display has
            % changed
            updateDisplay@Display(obj);
        end
        
        function mouseMovedCallback(obj)
            obj.deleteLine();
                        
            if(obj.leftMouseDown)
                axes(obj.axisHandle);
                
                currentPoint = get(obj.axisHandle, 'CurrentPoint');
                obj.mouseLocation = [currentPoint(1, 1) currentPoint(1, 2)];
                
                if(obj.aboveAxis == 1)
                    obj.currentLine = line([obj.startPoint(1) obj.mouseLocation(1)], [obj.startPoint(2) obj.startPoint(2)], 'Color', [0 1 0]);
                elseif(obj.zoomingIn == 2)
                    if(~isempty(obj.xLimit))
                        xMidPoint = ((obj.xLimit(2)-obj.xLimit(1))/2)+obj.xLimit(1);
                        obj.currentLine = line([xMidPoint xMidPoint], [obj.startPoint(2) obj.mouseLocation(2)], 'Color', [1 0 0]);
                    end
                elseif(obj.zoomingIn == 1)
                    if(~isempty(obj.yLimit))
                        yMidPoint = ((obj.yLimit(2)-obj.yLimit(1))/2)+obj.yLimit(1);
                        obj.currentLine = line([obj.startPoint(1) obj.mouseLocation(1)], [yMidPoint yMidPoint], 'Color', [1 0 0]);
                    end
                end
            end
            
        end
        
        function mouseButtonUpCallback(obj)
            obj.leftMouseDown = 0;
            
            if(~isempty(obj.startPoint))
                isNotSamePoint = ~(isequal(obj.startPoint(1), obj.mouseLocation(1)) && isequal(obj.startPoint(2), obj.mouseLocation(2)));
                
                currentPoint = get(obj.axisHandle, 'CurrentPoint');
                
                if(~isempty(obj.continuousDisplay) && isvalid(obj.continuousDisplay))
                    isContinuous = strcmp(get(obj.continuousDisplay, 'Checked'), 'on');
                else
                    isContinuous = true;
                end
                
                if((~isNotSamePoint && obj.aboveAxis == 1 && ~isContinuous))
                    obj.mouseClickInsideAxis();
                    
                    [minVal, minLoc] = min(abs(obj.data.spectralChannels - currentPoint(1)));
                    minVal = obj.data.spectralChannels(minLoc);
                    
                    peakSelectionEvent = PeakSelectionEvent(PeakSelectionEvent.Exact, minVal); 
                    notify(obj, 'PeakSelected', peakSelectionEvent);
                else
                    if(obj.aboveAxis ~= 0 && isNotSamePoint) 
                        obj.deleteLine();
                        
                        xPoint = currentPoint(1, 1);
                        
                        obj.aboveAxis = 0;
                        
                        peakRange = [obj.startPoint(1) xPoint];
                        peakRange = sort(peakRange, 'ascend');
                        
                        peakSelectionEvent = PeakSelectionEvent(PeakSelectionEvent.Range, peakRange);
                        notify(obj, 'PeakSelected', peakSelectionEvent);
                    elseif(obj.zoomingIn ~= 0 && isNotSamePoint)
                        obj.deleteLine();
                        
                        if(obj.zoomingIn == 1)
                            obj.xLimit = sort([obj.startPoint(1) obj.mouseLocation(1)], 'ascend');
                            obj.yLimit = [];
                        else
                            obj.yLimit = sort([obj.startPoint(2) obj.mouseLocation(2)], 'ascend');
                        end
                        
                        obj.updateDisplay();
                    end
                end
            end
            
            obj.aboveAxis = 0;
            obj.zoomingIn = 0;
        end
    end
    
    methods (Access = protected)
        
        function plotSpectrum(this)
            % Check if the continuousDisplay (tick box in the context menu)
            % has been assigned and is still valid, otherwise default to
            % continuous data
            if(~isempty(this.continuousDisplay) && isvalid(this.continuousDisplay))
                isContinuous = strcmp(get(this.continuousDisplay, 'Checked'), 'on');
            else
                isContinuous = true;
            end
            
            % If the display is set to continuous, then plot with 'plot'
            % otherwise use 'bar'
            if(~isContinuous)
                % Ensure that an edge colour is applied to the bar so that
                % it is visualised correctly in MATLAB R2016+
                this.plotHandle = bar(this.axisHandle, this.data.spectralChannels, this.data.intensities, 'k', 'EdgeColor', [0 0 0]);
            else
                this.plotHandle = plot(this.axisHandle, this.data.spectralChannels, this.data.intensities);
            end
            
            xlabel(this.axisHandle, this.xLabel);
            ylabel(this.axisHandle, this.yLabel);
        end
        
        function fixLimits(this)
            
            if(isempty(this.xLimit))
                if(isempty(min(this.data.spectralChannels)) || isempty(max(this.data.spectralChannels)))
                    this.xLimit = [0 1];
                else
                    this.xLimit = [min(this.data.spectralChannels) max(this.data.spectralChannels)];
                end
            end
            
            if(isempty(this.yLimit))
                currentViewMask = this.data.spectralChannels >= this.xLimit(1) & this.data.spectralChannels <= this.xLimit(2);
                
                minVal = min(this.data.intensities(currentViewMask));
                maxVal = max(this.data.intensities(currentViewMask));
                
                if(minVal < maxVal)
                    this.yLimit = [minVal maxVal];
                end
            end
        end
        
        function updateLimits(this)
            % Ensure that the limits are increasing and not empty
            if(isempty(this.xLimit) || isequal(this.xLimit, [0 0]))
                this.xLimit = [0 1];
            end
            if(isempty(this.yLimit) || isequal(this.yLimit, [0 0]) || max(isnan(this.yLimit) == 1))
                this.yLimit = [0 1];
            end
            
            if(this.xLimit(2) < this.xLimit(1) || this.xLimit(1) == this.xLimit(2))
                return;
            end
            if(this.yLimit(2) < this.yLimit(1) || this.yLimit(1) == this.yLimit(2))
                return;
            end
            
            set(this.axisHandle, 'xLim', this.xLimit);
            set(this.axisHandle, 'yLim', this.yLimit);
        end
        
        
        function deleteLine(obj)
            if(~isempty(obj.currentLine))
                try
                    delete(obj.currentLine);
                catch 
                    warning('TODO: Handle error')
                end
                
                obj.currentLine = [];
            end
        end
        
        function mouseClickInsideAxis(obj)
            %TODO: Fit to peak
            
        end
        
        function buttonDownCallback(obj)
            currentPoint = get(obj.axisHandle, 'CurrentPoint');
                        
            xPoint = currentPoint(1, 1);
            yPoint = currentPoint(1, 2);
            
            figureHandle = obj.parent.getParentFigure().handle;
            
            mouseClick = get(figureHandle, 'SelectionType');
            
            if(strcmp(mouseClick, 'normal')) % Left click
                obj.startPoint = [xPoint yPoint];
                obj.mouseLocation = obj.startPoint;
                obj.leftMouseDown = 1;
            end
            
            % Ensure that we are below the x-axis, otherwise call the above
            % axis dragging function
            if(xPoint > obj.xLimit(1) && yPoint > obj.yLimit(1))
                if(strcmp(mouseClick, 'normal'))
                    obj.aboveAxis = 1;
                end
            else
                if(currentPoint(1, 1) < obj.xLimit(1))
                    obj.zoomingIn = 2;
                else
                    obj.zoomingIn = 1;
                end
                
                if(strcmp(mouseClick, 'open')) % Double left click
                    obj.zoomingIn = 0;
                    
                    if(currentPoint(1, 1) < obj.xLimit(1))
                        currentIntensities = obj.data.intensities(obj.data.spectralChannels >= obj.xLimit(1) & obj.data.spectralChannels <= obj.xLimit(2));
                        obj.yLimit = [min(currentIntensities) max(currentIntensities)];
                    end
                    if(isempty(obj.yLimit) || currentPoint(2, 2) < obj.yLimit(1))
                        obj.xLimit = [min(obj.data.spectralChannels) max(obj.data.spectralChannels)];
                        obj.yLimit = [];
                    end
                    
                    obj.updateDisplay();
                end
            end
        end
    end
end