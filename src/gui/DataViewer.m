%% DataViewer
%
%%
classdef DataViewer < Figure
    properties (SetAccess = private)
        %handle = 0;
        
        %%
        % <html>
        % <a href="ImageDisplay.html">ImageDisplay</a>
        % imageDisplay;
        % </html>
        imageDisplay;
        %%
        % <html>
        % <a href="SpectrumDisplay.html">SpectrumDisplay</a>
        % spectrumDisplay;
        % </html>
        spectrumDisplay;
        
        spectrumPanel;
        
        %%
        % <html>
        % <a href="PreprocessingWorkflow.html">PreprocessingWorkflow</a>
        % preprocessingWorkflow;
        % </html>
        preprocessingWorkflow;
        
        % Data that has been generated and should be shown in the 
        imageListGenerated;
        imageList;
        spectrumList;
        
        dataRepresentation;
        
        title;
    end
    
    % Options
    properties
        showImageList = 1;
        showROIList = 1;
        showSpectrumList = 1;
        showPreprocessingList = 1;
        
        percentageImage = 60;
    end
    
    properties (Access = private)
        currentSpectrumLocation;
        
        spectralRepresentationsMenu;
        spectralRepresentationMethods;
        
        dataReductionMenu;
        dataReductionMethods;
        
        clusteringMenu;
        clusteringMethods;
        
        contextMenu;
        
        % Store handles of each child interface element
        imageSelectionPopup;
        imageTitleLabel;
        imageAxis;
        spectrumSelectionPopup;
        spectrumTitleLabel;
        spectrumAxis;
        
        imageListPanel;
        imageListPanelLastSelected;
        imageListTable;
        % Buttons for interacting with the image list
        generateImageListButton;
        overlayImagesButton;
        removeImageButton;
        saveImageListButton;
        loadImageListButton;
        
        spectrumListPanel;
        spectrumListTable;
        spectrumListTableLastSelected;
        % Buttons for interacting with the spectrum list
        addSpectrumButton;
        overlaySpectrumButton;
        subtractSpectrumButton;
        removeSpectrumButton;
        
        switchSpectrumViewButton;
        previousCoefficientButton;
        nextCoefficientButton;
        coefficientEditBox;
        coefficientLabel;

        regionOfInterestPanel;
        
        preprocessingPanel;
        preprocessingLabel;
%         appliedPreprocessingPanel;
%         appliedPreprocessingLabel;
%         currentPreprocessingPanel;
%         currentPreprocessingLabel;
        editPreprocessingButton;
        
        progressBarAxis
        progressBar;
        
        statusBar;
        
%         regionOfInterestListEditor;
        preprocessingWorkflowEditor;
        
        postProcessingMethodEditor;
        
        mouseDownInsideSpectrumLocation;
    end
    
    events
        DataViewerClosed;
        
        % Triggered when a new DataViewer is created from within this
        % DataViewer, for example when creating reducing to a datacube and
        % opening in a new window
        NewDataViewerCreated;
    end
    
    methods
        %% Constructor
        %
        function obj = DataViewer(dataRepresentation)
%             obj = obj@Figure();
            
            if(~isa(dataRepresentation, 'DataRepresentation'))
                exception = MException('DataViewer:InvalidArgument', ...
                    'Must supply an instance of a subclass of DataRepresentation to the DataViewer constructor');
                throw(exception);
            end
            
            obj.dataRepresentation = dataRepresentation;
            
            if(~isempty(obj.dataRepresentation.parser))
                obj.title = obj.dataRepresentation.parser.getShortFilename();
            else
                obj.title = obj.dataRepresentation.name;
            end
            
            obj.setTitle(['DataViewer: ' obj.title]);
            
%             obj.sizeChanged();
            
            %obj.createFigure();
            
%             obj.regionOfInterestList = RegionOfInterestList();
%             obj.regionOfInterestPanel.setRegionOfInterestList(obj.regionOfInterestList);
            obj.spectrumList = SpectrumList();
            
            obj.imageDisplay = ImageDisplay(obj, Image(1));
            addlistener(obj.imageDisplay, 'PixelSelected', @(src, evnt)obj.pixelSelectedCallback(evnt));
            
            % Add the overview image to the list of images
            obj.addImage(obj.dataRepresentation.getOverviewImage());
            
            % Display the overview image
            obj.displayImage(1);
            
            if(isa(dataRepresentation, 'ProjectedDataInMemory'))
                obj.showProjectedInterface();
                
                obj.coefficientEditBoxCallback();
            end
            
            if(isa(dataRepresentation.parser, 'SIMSParser'))
                totalSpectrum = dataRepresentation.parser.getOverviewSpectrum();
                
                totalSpectrum.setIsContinuous(obj.dataRepresentation.isContinuous);
                
                obj.spectrumList.add(totalSpectrum);
                obj.spectrumList.add(totalSpectrum);
            
                obj.updateSpectrumSelectionPopup();
                obj.spectrumDisplay.setData(totalSpectrum);
            end
            
            % Ensure that all proportions are correct
            obj.sizeChanged();
            
            % Finally add the colour bar
            obj.imageDisplay.setColourBarOn(1);
        end
        
        
        
        function switchSpectrumView(obj)
            f = PCAInfoFigure(obj.dataRepresentation, obj.regionOfInterestPanel.regionOfInterestList);
            
            isVisible = strcmp(get(obj.previousCoefficientButton, 'Visible'), 'on');
            
            obj.makeCoefficientControlsVisible(~isVisible);
        end
        
        function makeCoefficientControlsVisible(obj, isVisible)
            if(isVisible)
                set(obj.previousCoefficientButton, 'Visible', 'on');
                set(obj.nextCoefficientButton, 'Visible', 'on');
                set(obj.coefficientEditBox, 'Visible', 'on');
                set(obj.coefficientLabel, 'Visible', 'on');
            else
                set(obj.previousCoefficientButton, 'Visible', 'off');
                set(obj.nextCoefficientButton, 'Visible', 'off');
                set(obj.coefficientEditBox, 'Visible', 'off');
                set(obj.coefficientLabel, 'Visible', 'off');
            end
        end
        
        function previousCoefficientPlotCallback(obj)
            newValue = str2num(get(obj.coefficientEditBox, 'String')) - 1;
            
            if(newValue <= 0)
                newValue = 1;
            end
            
            set(obj.coefficientEditBox, 'String', num2str(newValue));
            obj.coefficientEditBoxCallback();
        end
        
        function nextCoefficientPlotCallback(obj)
            newValue = str2num(get(obj.coefficientEditBox, 'String')) + 1;
            
            if(newValue > size(obj.dataRepresentation.projectionMatrix, 2))
                newValue = size(obj.dataRepresentation.projectionMatrix, 2);
            end
            
            set(obj.coefficientEditBox, 'String', num2str(newValue));
            obj.coefficientEditBoxCallback();
        end
        
        function coefficientEditBoxCallback(obj)
            coeffString = get(obj.coefficientEditBox, 'String');
%             obj.coefficientEditBox
            
            value = str2num(coeffString);
            
            if(isempty(value) || value <= 0 || isinf(value) || isnan(value))
                value = 1;
                
                set(obj.coefficientEditBox, 'String', num2str(value));
            end
            
            if(value > obj.dataRepresentation.getNumberOfDimensions())
                value = obj.dataRepresentation.getNumberOfDimensions();
                
                set(obj.coefficientEditBox, 'String', num2str(value));
            end
            
            imageData = obj.dataRepresentation.getProjectedImage(value);
            obj.imageDisplay.setData(Image(imageData));
                obj.regionOfInterestPanel.setImageForEditor(Image(imageData));
            
            if(sum(obj.dataRepresentation.data(:) < 0) > 0)
                minVal = min(0, min(imageData(:)));
                maxVal = max(0, max(imageData(:)));

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

                obj.imageDisplay.setColourMap(colourMap);
                obj.imageDisplay.setColourBarOn(1);
            end
            
            spectrum = SpectralData(obj.dataRepresentation.spectralChannels, obj.dataRepresentation.projectionMatrix(:, value));
            spectrum.setIsContinuous(0);
            
            spectrum.setDescription(['Coefficient ' num2str(value) ' (Out of ' num2str(size(obj.dataRepresentation.projectionMatrix, 2)) ')']);
            obj.spectrumList.set(1, spectrum);
            obj.updateSpectrumSelectionPopup();
            set(obj.spectrumSelectionPopup, 'Value', 1);
            
            obj.spectrumDisplay.setData(spectrum);
        end
        
        function generateSpectralRepresentation(obj, representationIndex)
            if(isa(obj.postProcessingMethodEditor, 'PostProcessingEditor') && isvalid(obj.postProcessingMethodEditor))
                figure(obj.postProcessingMethodEditor.handle);
            else
                obj.postProcessingMethodEditor = PostProcessingMethodEditor(obj.spectralRepresentationMethods{representationIndex});%MemoryEfficientPCAEditor(obj.spectrumDisplay.peakList, obj.preprocessingWorkflow);
                
                obj.postProcessingMethodEditor.setRegionOfInterestList(obj.regionOfInterestPanel.regionOfInterestList);

                addlistener(obj.postProcessingMethodEditor, 'FinishedEditingPostProcessingMethod', @(src, evnt)obj.finishedEditingPostProcessingMethod());
            end
            
%             
%             spectralRepresentation = eval([obj.spectralRepresentationMethods{representationIndex} '()']);
%             
%             spectrum = spectralRepresentation.process(obj.dataRepresentation);
%             
% %             warning('DataViewer:TODO', 'TODO: Apply preprocessingWorkflow if necessary');
%             
%             obj.spectrumDisplay.setData(spectrum);
        end
        
        function performDataReduction(obj, dataReductionIndex)
            if(isa(obj.postProcessingMethodEditor, 'PostProcessingEditor') && isvalid(obj.postProcessingMethodEditor))
                figure(obj.postProcessingMethodEditor.handle);
            else
                obj.postProcessingMethodEditor = PostProcessingMethodEditor(obj.dataReductionMethods{dataReductionIndex});%MemoryEfficientPCAEditor(obj.spectrumDisplay.peakList, obj.preprocessingWorkflow);
                
                obj.postProcessingMethodEditor.setRegionOfInterestList(obj.regionOfInterestPanel.regionOfInterestList);

                addlistener(obj.postProcessingMethodEditor, 'FinishedEditingPostProcessingMethod', @(src, evnt)obj.finishedEditingPostProcessingMethod());
            end
            
            
%             dataReductionIndex
        end
        
        function performClustering(obj, clusteringIndex)
            if(isa(obj.postProcessingMethodEditor, 'PostProcessingEditor') && isvalid(obj.postProcessingMethodEditor))
                figure(obj.postProcessingMethodEditor.handle);
            else
                obj.postProcessingMethodEditor = PostProcessingMethodEditor(obj.clusteringMethods{clusteringIndex});
                
                obj.postProcessingMethodEditor.setRegionOfInterestList(obj.regionOfInterestPanel.regionOfInterestList);

                addlistener(obj.postProcessingMethodEditor, 'FinishedEditingPostProcessingMethod', @(src, evnt)obj.finishedEditingPostProcessingMethod());
            end
        end
        
        function finishedEditingPostProcessingMethod(obj)
            postProcessingMethod = obj.postProcessingMethodEditor.postProcessingMethod;
            
%             mePCA = MemoryEfficientPCA(obj.memoryEfficientPCAEditor.getNumberOfPrincipalComponents());
% warning('MAKE THIS A DATA REDUCTION THING ONLY?');
            if(isa(postProcessingMethod, 'DataReduction'))
                postProcessingMethod.setPeakList(obj.spectrumDisplay.peakList);
                postProcessingMethod.setPeakDetails(obj.spectrumDisplay.peakDetails);
            end
            
            postProcessingMethod.setPreprocessingWorkflow(obj.preprocessingWorkflow);
            
            obj.progressBar.updateProgress(ProgressEventData(0, ''));
            addlistener(postProcessingMethod, 'ProcessingProgress', @(src, evnt)obj.progressBar.updateProgress(evnt));
            
            set(obj.progressBar.axisHandle, 'Visible', 'on');
            
            try
                if(isa(postProcessingMethod, 'SpectralRepresentation'))
                    spectrumList = postProcessingMethod.process(obj.dataRepresentation);
                    spectrumList.getSize()
                    for i = 1:spectrumList.getSize()
                        obj.spectrumList.add(spectrumList.get(i));
                    end
                    obj.spectrumList.getSize()
                    obj.updateSpectrumSelectionPopup();
                else
                    if(isa(postProcessingMethod, 'Clustering'))
                        [dataRepresentationList, regionOfInterestLists] = postProcessingMethod.process(obj.dataRepresentation);
                    else
                        dataRepresentationList = postProcessingMethod.process(obj.dataRepresentation);
                    end

                    dataRepresentations = dataRepresentationList.getObjects;

                    for i = 1:numel(dataRepresentations)
                        dv = DataViewer(dataRepresentations{i});

                        notify(obj, 'NewDataViewerCreated', DataViewerEventData(dv));
                        
                        if(isa(postProcessingMethod, 'Clustering'))
                            dv.setRegionOfInterestList(regionOfInterestLists{i});
                        end
                    end
                end
            catch err
                if(strcmp(err.identifier, 'MATLAB:Java:GenericException') && ...
                        ~isempty(strfind(err.message, 'java.lang.ArrayIndexOutOfBoundsException')))
                    errordlg(['Could not perform ''' postProcessingMethod.Name ''' because spectra are different lengths. ' ...
                        'Did you set up appropriate zero filling and turn on preprocessing?'], ...
                        'Array Index Out Of Bounds');
                else
                    errordlg(err.message, err.identifier);
                    rethrow(err);
                end
            end
            
            set(obj.progressBar.axisHandle, 'Visible', 'off');
        end
        
        function pixelSelectedCallback(obj, event)
%             if(event.button == MouseEventData.LeftButton) 
                obj.displaySpectrum(event.x, event.y);
%             end
        end
        
        
        function displaySpectrum(obj, x, y)
            x = round(x);
            y = round(y);

            if(x <= 0 || y <= 0)
                return;
            end
            
            obj.currentSpectrumLocation = [x y];
            
            spectrum = obj.dataRepresentation.getSpectrum(x, y, 1, 1);
            
            if(isempty(spectrum) || isempty(spectrum.spectralChannels))
                return;
            end
            
            spectrum.setIsContinuous(obj.dataRepresentation.isContinuous);
            spectrum.setDescription(['Spectrum at (' num2str(x) ', ' num2str(y) ')']);
            obj.spectrumList.set(1, spectrum);
            obj.updateSpectrumSelectionPopup();
            set(obj.spectrumSelectionPopup, 'Value', 1);
            
            if(~isempty(obj.preprocessingWorkflow))
                spectrum = obj.preprocessingWorkflow.performWorkflow(spectrum);
                
%                 spectrum = SpectralData(spectralChannels, intensities);
                
                
%             else
%                 spectrum = SpectralData(spectralChannels, intensities);
            end
%             sum(spectrum.intensities)
%            obj.unprocessedSpectrum = spectrum.copy();
            
%             currentList = get(obj.spectrumSelectionPopup, 'String');
%             currentList{1} = ['Spectrum at (' num2str(x) ', ' num2str(y) ')'];
%             set(obj.spectrumSelectionPopup, 'String', currentList);
            
            
            obj.spectrumDisplay.setData(spectrum);
        end
        
%         function mouseDownInsideSpectrum(obj, x)
%             obj.mouseDownInsideSpectrumLocation = x;
%         end
        
        function peakSelected(obj, peakSelectionEvent)
            
%         end
% 
%         function mouseUpInsideSpectrum(obj, x)
%             spectralRange = [min(x, obj.mouseDownInsideSpectrumLocation) max(x, obj.mouseDownInsideSpectrumLocation)];
            
            if(peakSelectionEvent.selectionType == PeakSelectionEvent.Exact)
                if(~obj.dataRepresentation.isContinuous)
                    peakToView = peakSelectionEvent.peakDetails;
                    
                    [minVal, minLoc] = min(abs(obj.dataRepresentation.spectralChannels - peakToView));
                    
                    spectralRange = [obj.dataRepresentation.spectralChannels(minLoc) obj.dataRepresentation.spectralChannels(minLoc)];
                    description = num2str(obj.dataRepresentation.spectralChannels(minLoc));
                else
                    spectralRange = [peakSelectionEvent.peakDetails peakSelectionEvent.peakDetails];
                    description = num2str(peakSelectionEvent.peakDetails, 10);
                end
            else
                spectralRange = peakSelectionEvent.peakDetails;
                description = [num2str(spectralRange(1)) ' - ' num2str(spectralRange(2))];
            end

                width = spectralRange(2) - spectralRange(1);
                halfWidth = width/2;

                if(isa(obj.dataRepresentation.parser, 'SIMSParser') || ~isa(obj.dataRepresentation, 'DataInMemory'))
                    blankImage = Image(zeros(obj.dataRepresentation.height, obj.dataRepresentation.width));
                    blankImage.setDescription(description);

                    obj.imageListGenerated(end+1) = false;
                    obj.imageList(end+1) = blankImage;

                    obj.updateImageSelectionPopup();
                else
                    listener = addlistener(obj.dataRepresentation, 'DataLoadProgress', @(src, evnt)obj.progressBar.updateProgress(evnt));

                    image = obj.dataRepresentation.generateImages(spectralRange(1)+halfWidth, halfWidth, obj.preprocessingWorkflow);

                    delete(listener);

        %             imageInstance = Image(image);
                    image.setDescription(description);

                    obj.addImage(image);
                    obj.displayImage(length(obj.imageList));
                end
        end
        
        function infoRegionOfInterest(this) 
            
            roiInfo = RegionOfInterestInfoFigure(this.regionOfInterestPanel.regionOfInterestList, this.imageList);
            roiInfo.selectImageIndex(1);
        end
        
        
        function updateRegionOfInterestDisplay(this)
            this.imageDisplay.removeAllRegionsOfInterest();
            
            roiData = get(this.regionOfInterestPanel.regionOfInterestTable, 'Data');
            
            for i = 1:size(roiData, 1)
                if(roiData{i, 2})
                    this.imageDisplay.addRegionOfInterest(this.regionOfInterestPanel.regionOfInterestList.get(i));
                end
            end
            
            this.imageDisplay.updateDisplay();
        end
        
        % Check which images are selected in the image list.
        % If 1 selected show ion image in new window
        % If 2 selected show composite with magenta/green
        % If 3 selected show composited with RGB
        % If 4+ selected error message
        function overlayImagesCallback(obj)
            if(isempty(obj.imageListPanelLastSelected) || size(obj.imageListPanelLastSelected, 1) > 3)
                msgbox('Please select between 1 and 3 images to overlay', 'Cannot overlay');
            else
                imagesToOverlay = obj.imageListPanelLastSelected(:, 1);
                
                if(sum(obj.imageListGenerated(imagesToOverlay)) ~= length(imagesToOverlay))
                    msgbox('All images must already be generated to overlay', 'Cannot overlay');
                else
                    compositeImage = obj.imageList(imagesToOverlay(1)).imageData;
                    
                    if(length(imagesToOverlay) == 2)
                        compositeImage(:, :, 3) = compositeImage;
                        compositeImage(:, :, 2) = obj.imageList(imagesToOverlay(2)).imageData;
                    elseif(length(imagesToOverlay) == 3)
                        compositeImage(:, :, 2) = obj.imageList(imagesToOverlay(2)).imageData;
                        compositeImage(:, :, 3) = obj.imageList(imagesToOverlay(3)).imageData;
                    end
                    
                    if(length(imagesToOverlay) > 1)
                        % Ensure that each channel is normalised between 0 .. 1
                        compositeImage = normaliseRGBChannels(compositeImage);
                    end
                    
                    figure = Figure();
                    figure.showStandardFigure();
%                     axisHandle = axes;
                    display = ImageDisplay(figure, Image(compositeImage));
                    
                    if(length(imagesToOverlay) > 1)
                        display.setColourBarOn(false);
                    end
                end
            end
        end
        
        % Remove images from the generated list
        function removeImagesCallback(obj)
            if(~isempty(obj.imageListPanelLastSelected))
                imagesToRemove = obj.imageListPanelLastSelected(:, 1);
                
                % Remove the final box if selected
                imagesToRemove(imagesToRemove > length(obj.imageList)) = [];
                
                obj.imageList(imagesToRemove) = [];
                obj.imageListGenerated(imagesToRemove) = [];
                
                obj.updateImageSelectionPopup();
            end
        end
        
        function [spectralChannelList, channelWidthList, imageIndex] = imageListToValues(obj, imagesToGenerate)
            spectralChannelList = [];
            channelWidthList = [];
            imageIndex = [];
            
            for i = 1:length(imagesToGenerate)
                limits = strtrim(strsplit(imagesToGenerate(i).description, '-'));
                
                if(length(limits) == 2)
                    min = str2double(limits(1));
                    max = str2double(limits(2));
                elseif(length(limits) == 1)
                    numSplit = strsplit(limits(1), '\.');
                    smallest = 10^-(length(numSplit{2})) * 0.5;
                    
                    min = str2double(limits(1)) - smallest;
                    max = min + smallest*2;
                else
                    continue;
                end
                
                if(isnan(min) || isnan(max))
                    continue;
                end
                
                channelWidthList(end+1) = ((max - min) / 2);
                spectralChannelList(end+1) = channelWidthList(end) + min;
                imageIndex(end+1) = i;
            end
        end
        
        function generateImagesCallback(obj)
            notify(obj, 'InfoMessage', MessageEventData(['Generating images.']));
            
            imageIndices = find(~obj.imageListGenerated);
            imagesToGenerate = obj.imageList(imageIndices);
                        
            [spectralChannelList, channelWidthList, imageIndex] = obj.imageListToValues(imagesToGenerate);
            
            if(~isempty(spectralChannelList))
                listener = addlistener(obj.dataRepresentation, 'DataLoadProgress', @(src, evnt)obj.progressBar.updateProgress(evnt));
            
                imageList = obj.dataRepresentation.generateImages(spectralChannelList, channelWidthList, obj.preprocessingWorkflow);
                
                delete(listener);
                
                for i = 1:length(imageIndex)
                    % Make sure that the description is correct
                    imageList(i).setDescription(imagesToGenerate(imageIndex(i)).description);
                    
                    obj.imageList(imageIndices(imageIndex(i))) = imageList(i);
                    obj.imageListGenerated(imageIndices(imageIndex(i))) = 1;
                end
                
                obj.updateImageSelectionPopup();
                obj.displayImage(imageIndices(imageIndex(1)));
            end
            
            notify(obj, 'InfoMessage', MessageEventData(['Images generated.']));
            
            % Store the imageList to the workspace
            assignin('base', 'imageList', obj.imageList);
        end
        
        function saveImageListCallback(obj)
            [FileName,PathName,FilterIndex] = uiputfile('*.csv', 'Save image list as', 'imageList.csv');
            
            if(FilterIndex == 1)
                [spectralChannelList, channelWidthList, imageIndex] = obj.imageListToValues(obj.imageList);
                
                try
                    dlmwrite([PathName filesep FileName], [spectralChannelList' channelWidthList'], 'precision', 16);
                catch err
                    msgbox(err.message, err.identifier);
                    err
                end
            end
        end
        
        function loadImageListCallback(obj)
            [FileName,PathName,FilterIndex] = uigetfile('*.csv', 'Load image list');
            
            if(FilterIndex == 1)
                imagesToAdd = dlmread([PathName filesep FileName]);
                
                for i = 1:size(imagesToAdd, 1)
                    blankImage = Image(zeros(obj.dataRepresentation.height, obj.dataRepresentation.width));
                    blankImage.setDescription([num2str(imagesToAdd(i, 1) - imagesToAdd(i, 2)) ' - ' num2str(imagesToAdd(i, 1) + imagesToAdd(i, 2))]);

                    obj.imageListGenerated(end+1) = false;
                    obj.imageList(end+1) = blankImage;
                end

                obj.updateImageSelectionPopup();
            end
        end
        
        function addSpectrumToListCallback(this)
            this.spectrumList.add(this.spectrumList.get(1));
            
            this.updateSpectrumSelectionPopup();
        end
        
        function removeSpectraFromListCallback(obj)
        end
        
        function overlaySpectrumCallback(obj)
            spectraToOverlay = obj.spectrumListTableLastSelected(:, 1);
            
            if(~isempty(spectraToOverlay))
                figure = Figure();
                figure.showStandardFigure();
                
%                 axisHandle = axes;
                multiSpectrumPanel = MultiSpectrumPanel(figure, obj.spectrumList.get(spectraToOverlay(1)));
                
                spectraToOverlayList = [];
                
                for i = 1:length(spectraToOverlay)
                    if(i == 1)
                        spectraToOverlayList = obj.spectrumList.get(spectraToOverlay(i));
                    else
                        spectraToOverlayList(i) = obj.spectrumList.get(spectraToOverlay(i));
                    end
                    
                    if(~isempty(obj.preprocessingWorkflow))
                        spectraToOverlayList(i) = obj.preprocessingWorkflow.performWorkflow(spectraToOverlayList(i));
                    end
                end
                                
                multiSpectrumDisplay = multiSpectrumPanel.spectrumDisplay;
                
                for i = 2:length(spectraToOverlay)
                    multiSpectrumDisplay.setSpectrum(i, spectraToOverlayList(i));
                end
                
                multiSpectrumDisplay.updateDisplay();
            end
        end
        
        function subtractSpectrumCallback(this)
            spectraToSubstract = this.spectrumListTableLastSelected(:, 1);
            
            if(~isempty(spectraToSubstract) && length(spectraToSubstract) == 2)
                
                spectrum1 = this.spectrumList.get(spectraToSubstract(1));
                spectrum2 = this.spectrumList.get(spectraToSubstract(2));
                
                if(~isempty(this.preprocessingWorkflow))
                    spectrum1 = this.preprocessingWorkflow.performWorkflow(spectrum1);
                    spectrum2 = this.preprocessingWorkflow.performWorkflow(spectrum2);
                end
                
                try 
                    differenceSpectrum = SpectralData(spectrum1.spectralChannels, spectrum1.intensities - spectrum2.intensities);

                    figure = Figure();
                    figure.showStandardFigure();
                    spectrumPanel = SpectrumPanel(figure, differenceSpectrum);
                    
                    figure.setTitle(['Difference between ' spectrum1.getDescription() ' and ' spectrum2.getDescription()]);
                catch err 
                    errordlg(err.message);
                end
            else
                errordlg('Please select 2 spectra to subtract', 'DataViewer:NoSpectraSelected');
            end
        end
        
        %% editPreprocessingWorkflow()
        function editPreprocessingWorkflow(obj)
            assignin('base', 'dataViewer', obj);
            % Check if we have already opened the
            % PreprocessingWorkflowEditor and if so if it is still a valid
            % instance of the class. If so show it, otherwise recreate it
            if(isa(obj.preprocessingWorkflowEditor, 'PreprocessingWorkflowEditor') && isvalid(obj.preprocessingWorkflowEditor))
                figure(obj.preprocessingWorkflowEditor.handle);
            else
                % Get the currently viewed spectrum
%                 spectrumIndex = get(obj.spectrumSelectionPopup, 'Value');
                if(isempty(obj.spectrumListTableLastSelected))
                    spectrumIndex = 1;
                else
                    spectrumIndex = obj.spectrumListTableLastSelected(1);
                end
                
                if(obj.spectrumList.getSize() == 0)
                    errordlg('Please select a spectrum first by clicking on a pixel', 'DataViewer:NoSpectrumSelected');
                else
                    spectrum = obj.spectrumList.get(spectrumIndex);

                    obj.preprocessingWorkflowEditor = PreprocessingWorkflowEditor(spectrum, obj.preprocessingWorkflow);

                    addlistener(obj.preprocessingWorkflowEditor, 'FinishedEditing', @(src, evnt)obj.finishedEditingPreprocessingWorkflow());
                end
            end
        end
        
        %% finishedEditingPreprocessingWorkflow()
        function finishedEditingPreprocessingWorkflow(obj)
            obj.preprocessingWorkflow = obj.preprocessingWorkflowEditor.preprocessingWorkflow;
            obj.preprocessingWorkflowEditor = [];
            
            set(obj.preprocessingLabel, 'String', obj.preprocessingWorkflow.toCellArrayOfStrings());
            
%             spectrumIndex = get(obj.spectrumSelectionPopup, 'Value');
            if(isempty(obj.spectrumListTableLastSelected))
                spectrumIndex = 1;
            else
                spectrumIndex = obj.spectrumListTableLastSelected(1);
            end
            
            obj.displayStoredSpectrum(spectrumIndex);
            
            %obj.displaySpectrum(obj.currentSpectrumLocation(1), obj.currentSpectrumLocation(2));
        end
        
        %% addImage(Image image)
        function addImage(obj, image)
            if(~isa(image, 'Image'))
                exception = MException('Image:invalidArgument', 'Must provide an instance of Image or of a class that extends Image');
                throw(exception);
            end
            
            if(isempty(obj.imageList))
                obj.imageList = image;
                
%                 obj.displayImage(1);
%                 obj.imageDisplay.setData(obj.imageList(1));
            else
                obj.imageList(end+1) = image;
            end
            
            obj.imageListGenerated(length(obj.imageList)) = true;
            
            obj.updateImageSelectionPopup();                
        end
        
        %% removeImage(Image image) removeImage(int imageIndex)
        % Remove an image from the list by either passing in the instance
        % of the image or the index of the image in the list
        function removeImage(obj, image)
            warning('DataViewer:TODO', 'TODO: Check that the image is an instance of the correct class or a number');
            warning('DataViewer:TODO', 'TODO: Implement removal of an image by passing the instance in');
            
            if(isnumeric(image) && image <= length(obj.imageList))
                % Remove the image from the list with the given index
                obj.imageList(image) = [];
                
                warning('DataViewer:TODO', 'TODO: Check if the currently viewed image has been removed');
            end
            
            obj.updateImageSelectionPopup();
        end

        %% displayImage(int imageIndex)
        function displayImage(obj, imageIndex)
            % Check that there is actually an image to view
            if(isnumeric(imageIndex) && imageIndex <= length(obj.imageList) && obj.imageListGenerated(imageIndex))
                set(obj.imageSelectionPopup, 'Value', imageIndex);
                set(obj.imageTitleLabel, 'String', obj.imageList(imageIndex).getDescription());
                
                obj.imageDisplay.setData(obj.imageList(imageIndex));
                obj.regionOfInterestPanel.setImageForEditor(obj.imageList(imageIndex));
                
                set(obj.imageAxis, 'ButtonDownFcn', @(src, evnt)obj.imageAxisClicked());
            end
        end
        
        
        function displayStoredSpectrum(this, spectrumIndex)
            % Check that there is actually an image to view
            if(isnumeric(spectrumIndex) && spectrumIndex <= this.spectrumList.getSize())
                spectrum = this.spectrumList.get(spectrumIndex);
                
%                 figure; plot(spectrum.spectralChannels, spectrum.intensities);
%                 
                if(~isempty(this.preprocessingWorkflow))
                    spectrum = this.preprocessingWorkflow.performWorkflow(spectrum);
                end
            
                this.spectrumDisplay.setData(spectrum);
            end
        end
        
        function imageAxisClicked(obj)
            
        end

        function updateSpectrumSelectionPopup(obj)
            currentList = get(obj.spectrumSelectionPopup, 'String');
                    
            newList = {''};
            
            if(~isempty(obj.spectrumList))
                for i = 1:obj.spectrumList.getSize();
                    newList{i} = obj.spectrumList.get(i).getDescription();
                end
                
                set(obj.spectrumSelectionPopup, 'String', newList);
            end
                    
            set(obj.spectrumSelectionPopup, 'Value', 1);
            
            set(obj.spectrumListTable, 'Data', newList');
        end
        
        %% updateImageSelectionPopup()
        function updateImageSelectionPopup(obj)
            if(~isempty(obj.imageList))
                descriptionList = {obj.imageList(1).getDescription()};

                for i = 2:length(obj.imageList)
                    descriptionList{i} = obj.imageList(i).getDescription();
                end
                
                set(obj.imageSelectionPopup, 'String', descriptionList);
                
                descriptionList = descriptionList';
                
                for i = 1:length(obj.imageListGenerated)
                    descriptionList(i, 2) = {obj.imageListGenerated(i) == 1};
                end
                
                descriptionList(end+1, :) = {'', false};
                
                set(obj.imageListTable, 'Data', descriptionList);
            else
                set(obj.imageListTable, 'Data', {'', false});
            end
        end
        
        %% Destructor
        % Overloaded delete function for clean up purposes
        function delete(obj)
            notify(obj, 'DataViewerClosed');
            
            delete(obj.handle);
            obj.handle = 0;
        end
    end
    
%     methods (Access = protected)
%         function closeRequest(obj)
% %             warning('DataViewer:TODO', 'TODO: Present the user with the option to not close this figure');
%             
%             obj.delete();
%         end
%     end

    methods (Access = protected)
        %% createFigure()
        function createFigure(obj) 
            if(isempty(obj.handle) || ~obj.handle)
                createFigure@Figure(obj);
                
                set(obj.handle, 'Units', 'pixels');
                
                position = get(obj.handle, 'Position');
                position(4) = 460;
                set(obj.handle, 'Position', position);
                
                % Create the menu bar
                obj.spectralRepresentationsMenu = uimenu(obj.handle, 'Label', 'Spectral Representation');
                [obj.spectralRepresentationMethods spectralRepresentationNames] = getSubclasses('SpectralRepresentation', 0);
                
                for i = 1:length(spectralRepresentationNames)
                    uimenu(obj.spectralRepresentationsMenu, 'Label', spectralRepresentationNames{i}, ...
                        'Callback', @(src, evnt) obj.generateSpectralRepresentation(i));
                end
                
                obj.dataReductionMenu = uimenu(obj.handle, 'Label', 'Data Reduction');
                [obj.dataReductionMethods dataReductionNames] = getSubclasses('DataReduction', 0);
                
                for i = 1:length(dataReductionNames)
                    uimenu(obj.dataReductionMenu, 'Label', dataReductionNames{i}, ...
                        'Callback', @(src, evnt) obj.performDataReduction(i));
                end
                
                obj.clusteringMenu = uimenu(obj.handle, 'Label', 'Clustering');
                [obj.clusteringMethods clusteringNames] = getSubclasses('Clustering', 0);
                
                for i = 1:length(clusteringNames)
                    uimenu(obj.clusteringMenu, 'Label', clusteringNames{i}, ...
                        'Callback', @(src, evnt) obj.performClustering(i));
                end
                
                obj.createContextMenu();
                set(obj.handle, 'uicontextmenu', obj.contextMenu);
                
                % Create GUI controls
                
                % --- Image View Details ---
                obj.imageSelectionPopup = uicontrol('Style', 'popup', 'String', {'Default'}, ...
                    'Units', 'normalized', 'Position', [.1 .925 .8 .05], 'Callback', @(src, evnt)obj.displayImage(get(src, 'Value')), ...
                    'Visible', 'off');
%                 obj.imageSelectionPopup = uitable('ColumnName', {'m/z'}, 'RowName', [], ...
%                     'Units', 'normalized', 'Position', [.025 .62 .2 .35], 'CellSelectionCallback', @(src, evnt)obj.displayImage(get(src, 'Value'))); 
%                 get( obj.imageSelectionPopup)
                
                obj.imageListPanel = uipanel('Parent', obj.handle, 'Title', 'Image List');
                
                obj.imageListTable = uitable('Parent', obj.imageListPanel,'RowName', [], ...
                    'ColumnName', {'Image', 'Generated'}, ...
                    'ColumnFormat', {'char', 'logical'}, ...
                    'ColumnEditable', [false, false], ...
                    'ColumnWidth', {120, 40} , ...
                    'CellSelectionCallback', @(src, evnt) obj.imageListTableSelected(src, evnt), ...
                    'CellEditCallback', @(src, evnt) obj.imageListTableEdited(src, evnt));
                
                obj.generateImageListButton = uicontrol('Parent', obj.imageListPanel, 'String', 'G', ...
                    'Callback', @(src, evnt) obj.generateImagesCallback(), ...
                    'TooltipString', 'Generate all images in the list');
                obj.overlayImagesButton = uicontrol('Parent', obj.imageListPanel, 'String', 'O', ...
                    'Callback', @(src, evnt) obj.overlayImagesCallback(), ...
                    'TooltipString', 'Overlay selected images');
                obj.removeImageButton = uicontrol('Parent', obj.imageListPanel, 'String', '-', ...
                    'Callback', @(src, evnt) obj.removeImagesCallback(), ...
                    'TooltipString', 'Remove all selected images');
                obj.saveImageListButton = uicontrol('Parent', obj.imageListPanel, 'String', 'S', ...
                    'Callback', @(src, evnt) obj.saveImageListCallback(), ...
                    'TooltipString', 'Save image list');
                obj.loadImageListButton = uicontrol('Parent', obj.imageListPanel, 'String', 'L', ...
                    'Callback', @(src, evnt) obj.loadImageListCallback(), ...
                    'TooltipString', 'Load image list');

                obj.regionOfInterestPanel = RegionOfInterestPanel(obj);
                addlistener(obj.regionOfInterestPanel, 'InfoButtonClicked', @(src, evnt) obj.infoRegionOfInterest());
                addlistener(obj.regionOfInterestPanel, 'RegionOfInterestSelected', @(src, evnt) obj.updateRegionOfInterestDisplay());
                              
                
%                 obj.imageAxis = axes('Parent', obj.handle, 'Position', [.25 .62 .7 .3]);
                
                obj.imageTitleLabel = uicontrol('Parent', obj.handle, 'Style', 'text');
                
                % --- Spectrum View Details ---
                obj.spectrumSelectionPopup = uicontrol('Style', 'popup', 'String', {''}, ...
                    'Units', 'normalized', 'Position', [.2 .375 .6 .05], 'Callback', @(src, evnt)obj.displayStoredSpectrum(get(src, 'Value')), ...
                    'Visible', 'off');
                
                obj.spectrumListPanel = uipanel('Parent', obj.handle, 'Title', 'Spectrum List');
                obj.spectrumListTable = uitable('Parent', obj.spectrumListPanel, 'ColumnName', {'Spectrum'}, 'RowName', [], ...
                    'ColumnWidth', {200}, 'CellSelectionCallback', @(src, evnt) obj.spectrumListTableSelected(src, evnt));
                
                obj.addSpectrumButton = uicontrol('Parent', obj.spectrumListPanel, 'String', '+', ...
                    'Callback', @(src, evnt) obj.addSpectrumToListCallback(), ...
                    'TooltipString', 'Add current spectrum to the list');
                obj.overlaySpectrumButton = uicontrol('Parent', obj.spectrumListPanel, 'String', 'O', ...
                    'Callback', @(src, evnt) obj.overlaySpectrumCallback(), ...
                    'TooltipString', 'Overlay selected spectra');
                obj.subtractSpectrumButton = uicontrol('Parent', obj.spectrumListPanel, 'String', 'S', ...
                    'Callback', @(src, evnt) obj.subtractSpectrumCallback(), ...
                    'TooltipString', 'Subtract selected spectra');
                obj.removeSpectrumButton = uicontrol('Parent', obj.spectrumListPanel, 'String', '-', ...
                    'Callback', @(src, evnt) obj.removeSpectraFromListCallback(), ...
                    'TooltipString', 'Remove selected spectra from the list');
                
%                 obj.spectrumAxis = axes('Parent', obj.handle, 'Position', [.1 .3 .8 .25]);
                
                obj.spectrumPanel = SpectrumPanel(obj, SpectralData(0, 0));
                obj.spectrumDisplay = obj.spectrumPanel.spectrumDisplay; %SpectrumDisplay(obj, SpectralData(0, 0));
                
%                 addlistener(obj.spectrumDisplay, 'MouseDownInsideAxis', @(src, evnt)obj.mouseDownInsideSpectrum(evnt.x));
%                 addlistener(obj.spectrumDisplay, 'MouseUpInsideAxis', @(src, evnt)obj.mouseUpInsideSpectrum(evnt.x));
                                
                addlistener(obj.spectrumDisplay, 'PeakSelected', @(src, evnt)obj.peakSelected(evnt));
                
                obj.switchSpectrumViewButton = uicontrol('Parent', obj.handle, 'String', '<>', 'Callback', @(src, evnt)obj.switchSpectrumView(), ...
                        'Units', 'normalized', 'Position', [0.85 0.55 0.05 0.05], 'Visible', 'Off');
                    
                    obj.previousCoefficientButton = uicontrol('Parent', obj.handle, 'String', '<', 'Callback', @(src, evnt)obj.previousCoefficientPlotCallback(), ...
                        'Units', 'normalized', 'Position', [0.1 0.55 0.05 0.05], 'Visible', 'Off');
                    obj.nextCoefficientButton = uicontrol('Parent', obj.handle, 'String', '>', 'Callback', @(src, evnt)obj.nextCoefficientPlotCallback(), ...
                        'Units', 'normalized', 'Position', [0.8 0.55 0.05 0.05], 'Visible', 'Off');
                    obj.coefficientEditBox = uicontrol('Parent', obj.handle, 'Style', 'edit', 'Callback', @(src, evnt)obj.coefficientEditBoxCallback(), ...
                        'Units', 'normalized', 'Position', [0.15 0.55 0.05 0.05], 'String', '1', 'Visible', 'Off');
                    obj.coefficientLabel = uicontrol('Parent', obj.handle, 'Style', 'text', 'String', [''], ...
                        'Units', 'normalized', 'Position', [0.49 0.56 0.1 0.05], 'HorizontalAlignment', 'left');
                
                obj.preprocessingPanel = uipanel('Parent', obj.handle, 'Title', 'Spectral Preprocessing', ...
                    'Position', [.525 .05 .425 .2]);
                obj.preprocessingLabel = uicontrol('Parent', obj.preprocessingPanel, 'Style', 'text', ...
                    'String', '', 'HorizontalAlignment', 'left', 'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.9]);
                obj.editPreprocessingButton = uicontrol('Parent', obj.preprocessingPanel, 'String', 'Edit', ...
                    'Units', 'normalized', 'Position', [0.65 0.1 0.3 0.3], 'Callback', @(src, evnt)obj.editPreprocessingWorkflow());
                
                obj.progressBarAxis = axes('Parent', obj.handle, 'Position', [.05 .01 .9 .03], 'Visible', 'off');
                obj.progressBar = ProgressBar(obj.progressBarAxis);          
                
                set(obj.handle, 'units','normalized','outerposition',[0.2 0.4 0.5 0.5]);
            end
        end
        
        function showProjectedInterface(obj)
            set(obj.switchSpectrumViewButton, 'Visible', 'On');
            set(obj.previousCoefficientButton, 'Visible', 'On');
            set(obj.nextCoefficientButton, 'Visible', 'On');
            set(obj.coefficientEditBox, 'Visible', 'On');
            set(obj.coefficientLabel, 'Visible', 'On');
            
            set(obj.coefficientLabel, 'String', [' / ' num2str(obj.dataRepresentation.getNumberOfDimensions())]);
        end
        
        function imageListTableSelected(obj, src, evnt)
            obj.imageListPanelLastSelected = evnt.Indices;
            
            if(~isempty(evnt.Indices))
                imageToDisplay = evnt.Indices(1);
                                
                % Get the current state of editable
                currentState = get(src,'ColumnEditable');
                
                if(evnt.Indices(2) == 1 && evnt.Indices(1) == length(obj.imageList)+1)
                    % Change the first column to be editable
                    currentState(1) = true;
                else
                    currentState(1) = false;
                end
                
                set(src,'ColumnEditable', currentState);

                if(imageToDisplay <= length(obj.imageList))
                    obj.displayImage(imageToDisplay);
                end
            end
        end
        
        function imageListTableEdited(obj, src, evnt)
            blankImage = Image(zeros(obj.dataRepresentation.height, obj.dataRepresentation.width));
            blankImage.setDescription(evnt.NewData);
            
            obj.imageListGenerated(evnt.Indices(1)) = false;
            obj.imageList(evnt.Indices(1)) = blankImage;
            
            obj.updateImageSelectionPopup();
        end
        
        function spectrumListTableSelected(obj, src, evnt)
            obj.spectrumListTableLastSelected = evnt.Indices;
            
            if(~isempty(evnt.Indices))
                obj.displayStoredSpectrum(evnt.Indices(1))
            end
        end
        
        function sizeChanged(obj)
            
            if(obj.handle ~= 0)
                % Get the new position of the figure in pixels
                newPosition = Figure.getPositionInPixels(obj.handle);
                
                margin = 5;
                
                colourBarSize = 80;
                spectrumExtraSize = 30;
                spectrumExtraSize = 0;
                buttonHeight = 25;
                
                widthForImage = newPosition(3) - margin*2 - colourBarSize;
                widthForSpectrum = newPosition(3) - margin*2 - spectrumExtraSize;
                
                xPositionForImage = margin;
                xPositionForSpectrum = margin + spectrumExtraSize;
                
                spectrumRegionY = 50;
                spectrumRegionHeight = newPosition(4) * (1-(obj.percentageImage/100)) - 50;
                                
                imageRegionY = (spectrumRegionHeight + spectrumRegionY) + 25;
                imageRegionHeight = newPosition(4) * (obj.percentageImage/100) - 50;
                
                progressBarHeight = 15;
                
                % Sort Image part of the view
                if(obj.showImageList)
                    widthOfImageList = 200;
                    
                    Figure.setObjectPositionInPixels(obj.imageListPanel, [margin, imageRegionY, widthOfImageList, imageRegionHeight]);
                    
                    panelPosition = Figure.getPositionInPixels(obj.imageListPanel);
                    
                    if(~isempty(panelPosition))
                        Figure.setObjectPositionInPixels(obj.imageListTable, [margin, buttonHeight + margin, panelPosition(3) - margin*2, panelPosition(4) - margin*2 - buttonHeight - 20]);

    %                     generateImageListButton;
    %         removeImageButton;
    %         saveImageListButton;
    %         loadImageListButton;

                        Figure.setObjectPositionInPixels(obj.generateImageListButton, [margin, margin, panelPosition(3)/5 - margin*2, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.overlayImagesButton, [margin+panelPosition(3)/5, margin, panelPosition(3)/5 - margin*2, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.removeImageButton, [margin+panelPosition(3)*2/5, margin, panelPosition(3)/5 - margin*2, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.saveImageListButton, [margin+panelPosition(3)*3/5, margin, panelPosition(3)/5 - margin*2, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.loadImageListButton, [margin+panelPosition(3)*4/5, margin, panelPosition(3)/5 - margin*2, buttonHeight]);
                    end
                    
                    widthForImage = widthForImage - widthOfImageList - margin;
                    xPositionForImage = margin*2 + widthOfImageList;
                end
                
                if(obj.showROIList)
                    widthOfROIList = 200;
                    widthForImage = widthForImage - widthOfROIList - margin;
                    
                    if(~isempty(obj.regionOfInterestPanel))
                        Figure.setObjectPositionInPixels(obj.regionOfInterestPanel.handle, [newPosition(3)-widthOfROIList-margin, imageRegionY, widthOfROIList, imageRegionHeight]);
                    end
                end
                
                if(~isempty(obj.imageDisplay))
                    Figure.setObjectPositionInPixels(obj.imageDisplay.axisHandle, [xPositionForImage, imageRegionY, widthForImage, imageRegionHeight]);
                end
                
                Figure.setObjectPositionInPixels(obj.imageTitleLabel, [xPositionForImage+widthForImage/2-100, imageRegionY+imageRegionHeight+2, 200, 15]);
                
                xPositionForCoeffs = xPositionForImage+widthForImage/2 - 90;
                
                Figure.setObjectPositionInPixels(obj.previousCoefficientButton, [xPositionForCoeffs, imageRegionY-20, 50, 30]);
                Figure.setObjectPositionInPixels(obj.coefficientEditBox, [xPositionForCoeffs+60, imageRegionY-20, 50, 30]);
                Figure.setObjectPositionInPixels(obj.coefficientLabel, [xPositionForCoeffs+120, imageRegionY-20, 50, 20]);
                Figure.setObjectPositionInPixels(obj.nextCoefficientButton, [xPositionForCoeffs + 180, imageRegionY-20, 50, 30]);
%                 get(obj.coefficientLabel)
                
                % Sort spectrum region
                if(obj.showSpectrumList)
                    widthOfSpectrumList = 200;
                    
                    Figure.setObjectPositionInPixels(obj.spectrumListPanel, [margin, spectrumRegionY, widthOfSpectrumList, spectrumRegionHeight]);
                    
                    panelPosition = Figure.getPositionInPixels(obj.spectrumListPanel);
                    
                    if(~isempty(panelPosition))
                        Figure.setObjectPositionInPixels(obj.spectrumListTable, [margin, buttonHeight + margin, panelPosition(3) - margin*2, panelPosition(4) - margin*2 - buttonHeight - 20]);

                        Figure.setObjectPositionInPixels(obj.addSpectrumButton, [margin, margin, panelPosition(3)/5 - margin*2, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.overlaySpectrumButton, [margin+panelPosition(3)/5, margin, panelPosition(3)/5 - margin*2, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.subtractSpectrumButton, [margin+panelPosition(3)*2/5, margin, panelPosition(3)/5 - margin*2, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.removeSpectrumButton, [margin+panelPosition(3)*3/5, margin, panelPosition(3)/5 - margin*2, buttonHeight]);
                    end
                    
                    widthForSpectrum = widthForSpectrum - widthOfSpectrumList - margin;
                    xPositionForSpectrum = xPositionForSpectrum + widthOfSpectrumList + margin;
                end
                
                if(obj.showPreprocessingList)
                    widthOfProcessingList = 200;
                    widthForSpectrum = widthForSpectrum - widthOfProcessingList - margin;
                    
                    Figure.setObjectPositionInPixels(obj.preprocessingPanel, [newPosition(3)-widthOfProcessingList-margin, spectrumRegionY, widthOfProcessingList, spectrumRegionHeight]);
                    
                    panelPosition = Figure.getPositionInPixels(obj.preprocessingPanel);
                    
                    if(~isempty(panelPosition))
%                     Figure.setObjectPositionInPixels(obj.regionOfInterestTable, [margin, buttonHeight + margin, panelPosition(3) - margin*2, panelPosition(4) - margin*2 - buttonHeight - 20]);

                        Figure.setObjectPositionInPixels(obj.editPreprocessingButton, [panelPosition(3)/2, margin, panelPosition(3)/2 - margin, buttonHeight]);
                    end
                end
                
                if(~isempty(obj.spectrumDisplay))
                    Figure.setObjectPositionInPixels(obj.spectrumPanel.handle, [xPositionForSpectrum, spectrumRegionY, widthForSpectrum, spectrumRegionHeight]);
%                     Figure.setObjectPositionInPixels(obj.spectrumDisplay.axisHandle, [xPositionForSpectrum, spectrumRegionY, widthForSpectrum, spectrumRegionHeight]);
                end
                
                Figure.setObjectPositionInPixels(obj.progressBarAxis, [margin, margin, newPosition(3)-margin*2, progressBarHeight]);
            end
            
            sizeChanged@Figure(obj);
        end
        
        function createContextMenu(obj)
            % Set up the context menu
            obj.contextMenu = uicontextmenu();
            exportMenu = uimenu(obj.contextMenu, 'Label', 'Export Data', 'Callback', []);
            uimenu(exportMenu, 'Label', 'To workspace', 'Callback', @(src,evnt)obj.dataRepresentation.exportToWorkspace());
        end
    end

end