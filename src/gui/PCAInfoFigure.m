classdef PCAInfoFigure < Figure
    
    properties %(Access = private)
        projectedDataInMemory;
        
        pcXSelectionBox;
        pcXImageDisplay;
        pcXSpectrumPanel;
        
        pcYSelectionBox;
        pcYImageDisplay;
        pcYSpectrumPanel;
        
        combinedAxis;
        roiAxis;
        
        colourOrder;
        
        roiList;
        roiPanel;
        roiMatrix;
        roiImage;
    end
    
    methods
        function this = PCAInfoFigure(projectedDataInMemory, roiList)
            this.projectedDataInMemory = projectedDataInMemory;
            
            this.setTitle('PCA Details');
            this.roiList = roiList;
            
            this.pcXImageDisplay = ImageDisplay(this, Image(projectedDataInMemory.getProjectedImage(1)));
            this.pcXSpectrumPanel = SpectrumPanel(this, projectedDataInMemory.getProjectedSpectrum(1));
            
            this.pcYImageDisplay = ImageDisplay(this, Image(projectedDataInMemory.getProjectedImage(2)));
            this.pcYSpectrumPanel = SpectrumPanel(this, projectedDataInMemory.getProjectedSpectrum(2));
            
            this.populateSelectionBoxes();
            
            this.combinedAxis = axes('Parent', this.handle);
            plot(projectedDataInMemory.getProjectedSpectrum(1).intensities, projectedDataInMemory.getProjectedSpectrum(2).intensities, '.');
            
            this.roiAxis = axes('Parent', this.handle);
            this.colourOrder = get(gca, 'ColorOrder');
            
            while size(this.colourOrder, 1) < roiList.getSize()
                this.colourOrder = [this.colourOrder; this.colourOrder * 0.5];
            end
            
            this.roiListChanged();
            
            for j = 1:roiList.getSize()
                roiList.get(j).setColour(Colour(round(this.colourOrder(j, 1) * 255), round(this.colourOrder(j, 2) * 255), round(this.colourOrder(j, 3) * 255)));
            end
            
            this.roiPanel.setRegionOfInterestList(roiList);
            
            % Ensure that all proportions are correct
            this.sizeChanged();
        end
    end
    
    methods (Access = protected)
        function populateSelectionBoxes(this)
            numPCs = size(this.projectedDataInMemory.projectionMatrix, 2);
            pcNames = cellstr(num2str((1:numPCs)', 'PC %d'));
            
            set(this.pcXSelectionBox, 'String', pcNames');
            set(this.pcYSelectionBox, 'String', pcNames');
            
            set(this.pcYSelectionBox, 'Value', 2);
        end
        
        function pcSelected(this, src, event, pc)
            newPC = get(src, 'Value');
            
            if(pc == 1)
                this.pcXImageDisplay.setData(Image(this.projectedDataInMemory.getProjectedImage(newPC)));
                this.pcXSpectrumPanel.spectrumDisplay.setData(this.projectedDataInMemory.getProjectedSpectrum(newPC));
                this.pcXImageDisplay.setDivergingColourMap();
            else
                this.pcYImageDisplay.setData(Image(this.projectedDataInMemory.getProjectedImage(newPC)));
                this.pcYSpectrumPanel.spectrumDisplay.setData(this.projectedDataInMemory.getProjectedSpectrum(newPC));
                this.pcYImageDisplay.setDivergingColourMap();
            end
            
            this.redrawPlot();
        end
           
        function redrawPlot(this)
            pcX = get(this.pcXSelectionBox, 'Value');
            pcY = get(this.pcYSelectionBox, 'Value');
            
            pcXScores = this.projectedDataInMemory.data(:, pcX);
            pcYScores = this.projectedDataInMemory.data(:, pcY);

            if(~isempty(this.roiList) && this.roiList.getSize() > 0)
                this.plotROIPCvsPC(1, pcXScores, pcYScores);

                hold(this.combinedAxis, 'on');
                for i = 2:size(this.roiMatrix, 2)
                    this.plotROIPCvsPC(i, pcXScores, pcYScores);
                end
                hold(this.combinedAxis, 'off');
            else
                 plot(this.combinedAxis, pcXScores, pcYScores, '.');
            end
        end
        
        function plotROIPCvsPC(this, roi, pcXScores, pcYScores) 
            pcXSub = pcXScores(this.roiMatrix(:, roi));
            pcYSub = pcYScores(this.roiMatrix(:, roi));
            
            plot(this.combinedAxis, pcXSub, pcYSub, '.');
            
            colourOrder = get(gca, 'ColorOrder');
            
            if(roi < size(colourOrder, 1))
                colour = colourOrder(roi, :);
            else
                colour = [0 0 0];
            end
            
            this.confellipse2([pcXSub pcYSub], 0.95, colour);
        end
        
        % https://de.mathworks.com/matlabcentral/answers/24312-pca-for-confidence-ellipses
        function hh = confellipse2(this, xy, conf, colour)
            %CONFELLIPSE2 Draws a confidence ellipse.
            % CONFELLIPSE2(XY,CONF) draws a confidence ellipse on the current axes
            % which is calculated from the n-by-2 matrix XY and encloses the
            % fraction CONF (e.g., 0.95 for a 95% confidence ellipse).
            % H = CONFELLIPSE2(...) returns a handle to the line.
            n = size(xy,1);
            mxy = mean(xy);
            numPts = 200; % The number of points in the ellipse.
            th = linspace(0,2*pi,numPts)';
            %dimensionality of the data
            p = 2;
            %convert confidence rating (eg 0.95) into z score - relative to size of
            %sample(n) and the dimensionality of the data, n-p is therefore the degrees
            %of freedom.
            k = finv(conf,p,n-p)*p*(n-1)/(n-p);
            
            % principle components analysis, lat gives eigenvalues
            if(exist('pca', 'file'))
                [pc,score,lat] = pca(xy);
            else
                [pc,score,lat] = princomp(xy);
            end
            
            ab = diag(sqrt(k*lat));
            exy = [cos(th),sin(th)]*ab*pc' + repmat(mxy,numPts,1);
            
            % Add ellipse to current plot
            h = line(this.combinedAxis, exy(:,1),exy(:,2), 'Clipping','off', 'Color', colour);
            if nargout > 0
                hh = h;
            end
        end
        
        function roiListChanged(this)
            this.roiList = this.roiPanel.regionOfInterestList;
            
            if(~isempty(this.roiList) && this.roiList.getSize() > 0)
                this.roiImage = zeros(size(this.roiList.get(1).pixelSelection, 1), size(this.roiList.get(1).pixelSelection, 2), 3);

                this.roiMatrix = false(size(this.projectedDataInMemory.pixels, 1), this.roiList.getSize());

                for i = 1:size(this.projectedDataInMemory.pixels, 1)
                    coord = this.projectedDataInMemory.pixels(i, :);

                    for j = 1:this.roiList.getSize()
                        this.roiMatrix(i, j) = this.roiList.get(j).pixelSelection(coord(2), coord(1));

                        if(this.roiMatrix(i, j))
                            this.roiImage(coord(2), coord(1), :) = this.colourOrder(j, :);
    %                         this.roiImage(coord(2), coord(1), :) = [roiList.get(j).colour.r, roiList.get(j).colour.g, roiList.get(j).colour.b]./255;
                        end
                    end
                end

                imagesc(this.roiAxis, this.roiImage);
                axis(this.roiAxis, 'image');
                axis(this.roiAxis, 'off');
            end
            
            this.redrawPlot();
        end
        
        function createFigure(this)
            % createFigure Create figure.
            %
            %   createFigure()
            
            createFigure@Figure(this);
            
            this.pcXSelectionBox = uicontrol('Parent', this.handle, 'Style', 'popup', ...
                'String', {''}, 'Units', 'normalized', 'Position', [0.05, 0.85, 0.15, 0.1], 'Callback', @(src, event) this.pcSelected(src, event, 1));
            this.pcYSelectionBox = uicontrol('Parent', this.handle, 'Style', 'popup', ...
                'String', {''}, 'Units', 'normalized', 'Position', [0.65, 0.85, 0.15, 0.1], 'Callback', @(src, event) this.pcSelected(src, event, 2));
            
            this.roiPanel = RegionOfInterestPanel(this);
            addlistener(this.roiPanel, 'RegionOfInterestListChanged', @(src, event) this.roiListChanged());
        end
        
        function sizeChanged(this, src, evnt)
            if(this.handle ~= 0)
                oldUnits = get(this.handle, 'Units');
                set(this.handle, 'Units', 'pixels');
            
                newPosition = get(this.handle, 'Position');
                
                margin = 10;
                
                dropDownBoxHeight = 20;
                
                leftColumnWidth = newPosition(3) / 4;
                rightColumnWidth = leftColumnWidth;
                middleColumnWidth = newPosition(3) / 2;
                
                bottomPanelHeight = newPosition(4) / 3;
                
                colourBarSize = 80;
                spectrumExtraSize = 30;
                spectrumExtraSize = 0;
                buttonHeight = 25;
                
                widthForImage = leftColumnWidth-2*margin - colourBarSize;
                widthForSpectrum = leftColumnWidth-2*margin - spectrumExtraSize;
                
                Figure.setObjectPositionInPixels(this.pcXSelectionBox, [margin, newPosition(4)-margin-dropDownBoxHeight, leftColumnWidth-2*margin, dropDownBoxHeight]);
                Figure.setObjectPositionInPixels(this.pcXImageDisplay.axisHandle, [margin margin*2+(newPosition(4)/2-margin*3) widthForImage newPosition(4)/2-margin*3]);
                Figure.setObjectPositionInPixels(this.pcXSpectrumPanel.handle, [margin margin widthForSpectrum newPosition(4)/2-margin*3]);
                
                Figure.setObjectPositionInPixels(this.pcYSelectionBox, [margin+leftColumnWidth+middleColumnWidth, newPosition(4)-margin-dropDownBoxHeight, leftColumnWidth-2*margin, dropDownBoxHeight]);
                Figure.setObjectPositionInPixels(this.pcYImageDisplay.axisHandle, [margin+leftColumnWidth+middleColumnWidth margin*2+(newPosition(4)/2-margin*3) widthForImage newPosition(4)/2-margin*3]);
                Figure.setObjectPositionInPixels(this.pcYSpectrumPanel.handle, [margin+leftColumnWidth+middleColumnWidth margin widthForSpectrum newPosition(4)/2-margin*3]);
                
                Figure.setObjectPositionInPixels(this.combinedAxis, [margin*4+leftColumnWidth margin+bottomPanelHeight middleColumnWidth-8*margin newPosition(4)-bottomPanelHeight-2*margin]);
                Figure.setObjectPositionInPixels(this.roiAxis, [margin*4+leftColumnWidth margin middleColumnWidth/2-8*margin bottomPanelHeight-2*margin]);
                Figure.setObjectPositionInPixels(this.roiPanel.handle, [margin+leftColumnWidth+middleColumnWidth/2 margin middleColumnWidth/2-2*margin bottomPanelHeight-2*margin]);
            end
            
            sizeChanged@Figure(this);
        end
    end
end