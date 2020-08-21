classdef DataViewer < Figure
    % DataViewer is the main interface for viewing data, including all 
    % controls for data manipulation and visualisation.
    
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
        spectrumPreprocessingWorkflow;
        imageGenPreprocessingWorkflow;
        
        % Data that has been generated and should be shown in the 
        imageListGenerated;
        imageList;
        spectrumList;
        
        peakList;
        
        dataRepresentation;
        
        regionOfInterestPanel;
        
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
    
    properties (Access = protected)
        currentSpectrumLocation;
        
        spectralRepresentationsMenu;
        spectralRepresentationMethods;
        
        dataReductionMenu;
        dataReductionMethods;
        
        clusteringMenu;
        clusteringMethods;
        
        toolsMenu;
        toolsMethods;
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
        
        imageListTabGroup;
        
        userImageTab;
        toleranceEditBox;
        toleranceSelectionPopup;
        imageListTable;
        % Buttons for interacting with the image list
        generateImageListButton;
        overlayImagesButton;
        removeImageButton;
        saveImageListButton;
        loadImageListButton;
        
        peaksImageTab;
        peakListTable;
        generatePeakImagesButton;
        overlayPeakImagesButton;
        annotatePeakImagesButton;
        savePeakImagesButton;
        
        annotatedImageTab;
        
        spectrumListPanel;
        spectrumListTable;
        spectrumListTableLastSelected;
        % Buttons for interacting with the spectrum list
        addSpectrumButton;
        overlaySpectrumButton;
        subtractSpectrumButton;
        removeSpectrumButton;
        
        
        % TODO: Separate this out into a different class
        preprocessingPanel;
        preprocessingLabel;
        editPreprocessingButton;
        
        spectrumPreprocessingLabel;
        viewSpectrumPreprocessingButton;
        editSpectrumPreprocessingButton;
        
        imageGenPreprocessingLabel;
        viewImageGenPreprocessingButton;
        editImageGenPreprocessingButton;
        
        progressBarAxis
        progressBar;
        
        statusBar;
        
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
            if(~isa(dataRepresentation, 'DataRepresentation'))
                exception = MException('DataViewer:InvalidArgument', ...
                    'Must supply an instance of a subclass of DataRepresentation to the DataViewer constructor');
                throw(exception);
            end
            
            obj.dataRepresentation = dataRepresentation;
            
            if(~isempty(obj.dataRepresentation.parser) && ~isa(dataRepresentation, 'DataInMemory'))
                obj.title = obj.dataRepresentation.parser.getShortFilename();
                
                obj.spectrumPreprocessingWorkflow = obj.dataRepresentation.parser.getDefaultPreprocessingWorkflow();
            else
                obj.title = obj.dataRepresentation.name;
            end
            
            obj.setTitle(['DataViewer (' saversion '): ' obj.title]);
            
            obj.spectrumList = SpectrumList();
            
            obj.spectrumDisplay.setContinousDisplay(dataRepresentation.isContinuous);
            
            obj.imageDisplay = ImageDisplay(obj, Image(1));
            addlistener(obj.imageDisplay, 'PixelSelected', @(src, evnt)obj.pixelSelectedCallback(evnt));
            
            % Add the overview image to the list of images
            obj.addImage(obj.dataRepresentation.getOverviewImage());
            
            % Display the overview image
            obj.displayImage(1);
                        
            if(isa(dataRepresentation.parser, 'SIMSParser'))
                totalSpectrum = dataRepresentation.parser.getOverviewSpectrum();
                
                totalSpectrum.setIsContinuous(obj.dataRepresentation.isContinuous);
                
                obj.spectrumList.add(totalSpectrum);
                obj.spectrumList.add(totalSpectrum);
            
                obj.updateSpectrumSelectionPopup();
                obj.spectrumDisplay.setData(totalSpectrum);
            end
            
            % If data is in memory, then automatically generate the mean
            % spectrum
            if(isa(dataRepresentation, 'DataInMemory') && ~isa(dataRepresentation, 'ProjectedDataInMemory'))
                meanSpectrumData = mean(dataRepresentation.data, 1);
                
                meanSpectrum = SpectralData(dataRepresentation.spectralChannels, meanSpectrumData);
                meanSpectrum.setDescription('Mean spectrum');
                meanSpectrum.setIsContinuous(dataRepresentation.isContinuous);
                
                obj.spectrumList.add(meanSpectrum);
                obj.spectrumList.add(meanSpectrum);
                
                obj.updateSpectrumSelectionPopup();
                obj.spectrumDisplay.setData(meanSpectrum);
                
                % Set up peak list
                obj.peakList = Peak(meanSpectrum, dataRepresentation.spectralChannels(1), meanSpectrumData(1));
                for i = 2:length(dataRepresentation.spectralChannels)
                    obj.peakList(i) = Peak(meanSpectrum, dataRepresentation.spectralChannels(i), meanSpectrumData(i));
                end
                obj.updatePeakList();
                
                obj.imageListTabGroup.SelectedTab = obj.peaksImageTab;
            end
            
            obj.spectrumDisplay.setLabels(dataRepresentation.spectrumXAxisLabel, dataRepresentation.spectrumYAxisLabel);
                        
            % Ensure that all proportions are correct
            obj.sizeChanged();
            
            % Finally add the colour bar
            obj.imageDisplay.setColourBarOn(1);
        end
        
        function generateSpectralRepresentation(obj, representationIndex)
            if(isa(obj.postProcessingMethodEditor, 'PostProcessingEditor') && isvalid(obj.postProcessingMethodEditor))
                figure(obj.postProcessingMethodEditor.handle);
            else
                obj.postProcessingMethodEditor = PostProcessingMethodEditor(obj.spectralRepresentationMethods{representationIndex});
                
                obj.postProcessingMethodEditor.setRegionOfInterestList(obj.regionOfInterestPanel.regionOfInterestList);

                addlistener(obj.postProcessingMethodEditor, 'FinishedEditingPostProcessingMethod', @(src, evnt)obj.finishedEditingSpectralRepresentationMethod());
            end
        end
        
        function performDataReduction(obj, dataReductionIndex)
            if(isa(obj.postProcessingMethodEditor, 'PostProcessingEditor') && isvalid(obj.postProcessingMethodEditor))
                figure(obj.postProcessingMethodEditor.handle);
            else
                obj.postProcessingMethodEditor = PostProcessingMethodEditor(obj.dataReductionMethods{dataReductionIndex});
                
                obj.postProcessingMethodEditor.setRegionOfInterestList(obj.regionOfInterestPanel.regionOfInterestList);

                addlistener(obj.postProcessingMethodEditor, 'FinishedEditingPostProcessingMethod', @(src, evnt)obj.finishedEditingPostProcessingMethod());
            end
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
        
        function performTool(obj, toolsIndex)
            if(isa(obj.postProcessingMethodEditor, 'PostProcessingEditor') && isvalid(obj.postProcessingMethodEditor))
                figure(obj.postProcessingMethodEditor.handle);
            else
                obj.postProcessingMethodEditor = PostProcessingMethodEditor(obj.toolsMethods{toolsIndex});
                
                obj.postProcessingMethodEditor.setRegionOfInterestList(obj.regionOfInterestPanel.regionOfInterestList);

                addlistener(obj.postProcessingMethodEditor, 'FinishedEditingPostProcessingMethod', @(src, evnt)obj.finishedEditingPostProcessingMethod());
            end
            close(gcf)
            eval([obj.toolsMethods{toolsIndex}])
        end
        
        function finishedEditingSpectralRepresentationMethod(obj)
            postProcessingMethod = obj.postProcessingMethodEditor.postProcessingMethod;
            
            if(isa(postProcessingMethod, 'DataReduction'))
                postProcessingMethod.setPeakList(obj.spectrumDisplay.peakList);
            end
            
            postProcessingMethod.setPreprocessingWorkflow(obj.spectrumPreprocessingWorkflow);
            
            obj.progressBar.updateProgress(ProgressEventData(0, ''));
            addlistener(postProcessingMethod, 'ProcessingProgress', @(src, evnt)obj.progressBar.updateProgress(evnt));
            
            set(obj.progressBar.axisHandle, 'Visible', 'on');
            
            postProcessingMethod.process(obj.dataRepresentation);
            postProcessingMethod.displayResults(obj);
            
            set(obj.progressBar.axisHandle, 'Visible', 'off');
        end
        
        function finishedEditingPostProcessingMethod(obj)
            postProcessingMethod = obj.postProcessingMethodEditor.postProcessingMethod;
            
            if(isa(postProcessingMethod, 'DataReduction'))
                postProcessingMethod.setPeakList(obj.spectrumDisplay.peakList);
            end
            
            postProcessingMethod.setPreprocessingWorkflow(obj.spectrumPreprocessingWorkflow);
            
            obj.progressBar.updateProgress(ProgressEventData(0, ''));
            addlistener(postProcessingMethod, 'ProcessingProgress', @(src, evnt)obj.progressBar.updateProgress(evnt));
            
            set(obj.progressBar.axisHandle, 'Visible', 'on');
            
            postProcessingMethod.process(obj.dataRepresentation);
            postProcessingMethod.displayResults(obj);
            
%             try
%                 if(isa(postProcessingMethod, 'SpectralRepresentation'))
%                     spectrumList = postProcessingMethod.process(obj.dataRepresentation);
%                     spectrumList.getSize()
%                     for i = 1:spectrumList.getSize()
%                         obj.spectrumList.add(spectrumList.get(i));
%                     end
%                     obj.spectrumList.getSize()
%                     obj.updateSpectrumSelectionPopup();
%                 else
%                     if(isa(postProcessingMethod, 'Clustering'))
%                         [dataRepresentationList, regionOfInterestLists] = postProcessingMethod.process(obj.dataRepresentation);
%                     else
%                         dataRepresentationList = postProcessingMethod.process(obj.dataRepresentation);
%                     end
% 
%                     dataRepresentations = dataRepresentationList.getObjects;
% 
%                     for i = 1:numel(dataRepresentations)
%                         dv = DataViewer(dataRepresentations{i});
% 
%                         notify(obj, 'NewDataViewerCreated', DataViewerEventData(dv));
%                         
%                         if(isa(postProcessingMethod, 'Clustering'))
%                             dv.setRegionOfInterestList(regionOfInterestLists{i});
%                         end
%                     end
%                 end
%             catch err
%                 if(strcmp(err.identifier, 'MATLAB:Java:GenericException') && ...
%                         ~isempty(strfind(err.message, 'java.lang.ArrayIndexOutOfBoundsException')))
%                     errordlg(['Could not perform ''' postProcessingMethod.Name ''' because spectra are different lengths. ' ...
%                         'Did you set up appropriate zero filling and turn on preprocessing?'], ...
%                         'Array Index Out Of Bounds');
%                 else
%                     errordlg(err.message, err.identifier);
%                     rethrow(err);
%                 end
%             end
            
            set(obj.progressBar.axisHandle, 'Visible', 'off');
        end
        
        function pixelSelectedCallback(obj, event)
            obj.displaySpectrum(event.x, event.y);
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
            
            obj.spectrumList.set(1, spectrum);
            obj.updateSpectrumSelectionPopup();
            set(obj.spectrumSelectionPopup, 'Value', 1);
            
            if(~isempty(obj.spectrumPreprocessingWorkflow))
                spectrum = obj.spectrumPreprocessingWorkflow.performWorkflow(spectrum);
            end
            
            obj.spectrumDisplay.setData(spectrum);
        end
        
        function peakSelected(obj, peakSelectionEvent)
            if(peakSelectionEvent.selectionType == PeakSelectionEvent.Exact)
                if(~obj.dataRepresentation.isContinuous && ~isa(obj.dataRepresentation, 'DataOnDisk'))
                    peakToView = peakSelectionEvent.peakDetails

                    [minVal, minLoc] = min(abs(obj.dataRepresentation.spectralChannels - peakToView));

                    spectralRange = [obj.dataRepresentation.spectralChannels(minLoc) obj.dataRepresentation.spectralChannels(minLoc)];
                    description = num2str(obj.dataRepresentation.spectralChannels(minLoc));
                else
                    if ~obj.isUIFigure
                        units = get(obj.toleranceSelectionPopup, 'String');
                        unit = units{get(obj.toleranceSelectionPopup, 'Value')};
                        
                        tolerance = get(obj.toleranceEditBox, 'String');
                    else
                        unit = get(obj.toleranceSelectionPopup, 'Value');
                        tolerance = get(obj.toleranceEditBox, 'Value');
                    end

                    spectralRange = [peakSelectionEvent.peakDetails peakSelectionEvent.peakDetails];
                    description = [num2str(peakSelectionEvent.peakDetails, 10) ' +/- ' tolerance ' ' unit];
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

                image = obj.dataRepresentation.generateImages(spectralRange(1)+halfWidth, halfWidth, obj.imageGenPreprocessingWorkflow);

                delete(listener);

                %             imageInstance = Image(image);
                image.setDescription(description);

                obj.addImage(image);
                obj.displayImage(length(obj.imageList));
            end
        end
        
        function peakListUpdated(this, event)
            this.peakList = event.peakList;
            
            this.updatePeakList()
        end
        
        function updatePeakList(this)    
            if(~isempty(this.peakList))
                descriptionList = {this.peakList(1).getDescription()};

                for i = 2:length(this.peakList)
                    descriptionList{i} = this.peakList(i).getDescription();
                end
                
                descriptionList = descriptionList';
                                
                set(this.peakListTable, 'Data', descriptionList);
            else
                set(this.peakListTable, 'Data', {});
            end
        end            
        
        function infoRegionOfInterest(this) 
            
            roiInfo = RegionOfInterestInfoFigure(this.regionOfInterestPanel.regionOfInterestList, this.imageList);
            roiInfo.selectImageIndex(1);
        end
        
        function setRegionOfInterestList(this, regionOfInterestList)
            this.regionOfInterestPanel.setRegionOfInterestList(regionOfInterestList);
        end
        
        function addRegionOfInterest(this, regionOfInterest)
            this.regionOfInterestPanel.addRegionOfInterest(regionOfInterest);
        end
        
        function addRegionOfInterestList(this, regionOfInterestList)
            this.regionOfInterestPanel.addRegionOfInterestList(regionOfInterestList);
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
        
        function [spectralChannelList, widthList, imageIndex] = imageListToValues(obj, imagesToGenerate)
            spectralChannelList = zeros(length(imagesToGenerate), 1);
            widthList = zeros(length(imagesToGenerate), 1);
            imageIndex = zeros(length(imagesToGenerate), 1);
            
            for i = 1:length(imagesToGenerate)
                matchedDescription = strtrim(regexp(imagesToGenerate(i).description, '(\s)*[0-9]*(\.)?[0-9]*(\s)*-?(\s)*[0-9]*(\.)?[0-9]*', 'match'));
                
                matchedDescription = matchedDescription(~cellfun('isempty',matchedDescription));
               
                if(isempty(matchedDescription) || length(matchedDescription) > 1)
                    % Try and match PPM / Da
                    matchedDescription = regexp(imagesToGenerate(i).description, '(\s)*[0-9]*(\.)?[0-9]*(\s)*\+/-?(\s)*[0-9]*(\.)?[0-9]*(\s)*(PPM|Da)', 'match');
                    
                    if(isempty(matchedDescription) || strcmp(strtrim(matchedDescription{1}), ''))
                        continue;
                    end
                    
                    parts = strtrim(strsplit(imagesToGenerate(i).description, ' '));
                    
                    if(strcmp(parts{4}, 'PPM'))
                        mz = str2double(parts{1});
                        ppm = str2double(parts{3});
                        deltam = ppm * mz / 1e6;
                        
                        min = mz - deltam;
                        max = mz + deltam;
                    elseif(strcmp(parts{4}, 'Da'))
                        mz = str2double(parts{1});
                        da = str2double(parts{3});
                        
                        min = mz - da;
                        max = mz + da;
                    end
                else
                    limits = strtrim(strsplit(imagesToGenerate(i).description, '-'));
                    
                    if(length(limits) == 2)
                        min = str2double(limits(1));
                        max = str2double(limits(2));
                        
                        mz = min + (max - min)/2;
                    elseif(length(limits) == 1)
                        units = get(obj.toleranceSelectionPopup, 'String');
                        unit = units{get(obj.toleranceSelectionPopup, 'Value')};

                        imagesToGenerate(i).setDescription([char(limits(1)) ' +/- ' get(obj.toleranceEditBox, 'String') ' ' unit]);
                        
                        if(strcmp(unit, 'PPM'))
                            mz = str2double(limits(1));
                            ppm = str2double(get(obj.toleranceEditBox, 'String'));
                            deltam = ppm * mz / 1e6;

                            min = mz - deltam;
                            max = mz + deltam;
                        elseif(strcmp(unit, 'Da'))
                            mz = str2double(limits(1));
                            da = str2double(get(obj.toleranceEditBox, 'String'));

                            min = mz - da;
                            max = mz + da;
                        end
                    else
                        continue;
                    end
                end
                
                if(isnan(min) || isnan(max))
                    continue;
                end
                
                widthList(i) = ((max - min));
                %TODO: WHY WAS THIS LIKE THIS BEFORE??
                spectralChannelList(i) = mz; %channelWidthList(end) + min;
                imageIndex(i) = i;
            end
        end
        
        function generateImagesCallback(obj)
            notify(obj, 'InfoMessage', MessageEventData('Generating images.'));
            
            imageIndices = find(~obj.imageListGenerated);
            imagesToGenerate = obj.imageList(imageIndices);
                        
            [spectralChannelList, widthList, imageIndex] = obj.imageListToValues(imagesToGenerate);
            
            if(~isempty(spectralChannelList))
                listener = addlistener(obj.dataRepresentation, 'DataLoadProgress', @(src, evnt)obj.progressBar.updateProgress(evnt));
            
                imageList = obj.dataRepresentation.generateImages(spectralChannelList, widthList, obj.imageGenPreprocessingWorkflow);
                
                delete(listener);
                
                imageToDisplay = 0;
                
                for i = 1:length(imageIndex)
                    if(imageIndex(i) <= 0)
                        continue;
                    end
                    
                    imageToDisplay = i;
                    
                    % Make sure that the description is correct
                    imageList(i).setDescription(imagesToGenerate(imageIndex(i)).description);
                    
                    obj.imageList(imageIndices(imageIndex(i))) = imageList(i);
                    obj.imageListGenerated(imageIndices(imageIndex(i))) = 1;
                end
                
                obj.updateImageSelectionPopup();
                
                if(imageToDisplay > 0)
                    obj.displayImage(imageIndices(imageIndex(imageToDisplay)));
                end
            end
            
            notify(obj, 'InfoMessage', MessageEventData(['Images generated.']));
            
            % Store the imageList to the workspace
            assignin('base', 'imageList', obj.imageList);
        end
        
        function saveImageListCallback(this)
            list = {'Save as list', 'Save selected as list', 'Save as images', 'Save selected as images'};
            [savingOption, ok] = listdlg('ListString', list, 'SelectionMode', 'single', 'Name', 'Saving option', 'ListSize', [300, 160]);
            
            if(ok)
                if(mod(savingOption, 2) == 0)
                    selectedIndicies = this.imageListPanelLastSelected(:, 1);
                
                    % Remove the final box if selected
                    selectedIndicies(selectedIndicies > length(this.imageList)) = [];

                    imagesToSave = this.imageList(selectedIndicies);
                else
                    imagesToSave = this.imageList;
                end
                
                if(savingOption == 1 || savingOption == 2)
                    [FileName,PathName,FilterIndex] = uiputfile('*.csv', 'Save image list as', 'imageList.csv');

                    if(FilterIndex == 1)
                        [spectralChannelList, channelWidthList, imageIndex] = this.imageListToValues(imagesToSave);

                        try
                            dlmwrite([PathName filesep FileName], [spectralChannelList channelWidthList], 'precision', 16);
                        catch err
                            msgbox(err.message, err.identifier);
                            err
                        end
                    end
                else
                    selectedPath = uigetdir('', 'Save ROIs');
                    
                    if(selectedPath ~= 0)
                        newDisplay = this.imageDisplay.openInNewWindow();
                        
                        for i = 1:length(imagesToSave)
                            image = imagesToSave(i);
                            
                            newDisplay.setData(image);
                            
                            description = image.getDescription();
                            description = strrep(description, '/', '_');
                            
                            newDisplay.exportToImageFile([selectedPath filesep description '.png']);
                        end
                        
                        delete(newDisplay.parent.getParentFigure().handle);
                    end
                end
            end
        end
        
        function savePeakImagesCallback(this)
            [fileName, pathName, filterIndex] = uiputfile('*.peaks', 'Save detected peaks as', 'peakList.peaks');
            
            if(filterIndex == 1)
                try
                    savePeakList(this.peakList, [pathName filesep fileName]);
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
                    
                    if(size(imagesToAdd, 2) == 1 || imagesToAdd(i, 2) == 0)
                        blankImage.setDescription(num2str(imagesToAdd(i, 1)));
                    else
                        blankImage.setDescription([num2str(imagesToAdd(i, 1) - imagesToAdd(i, 2)) ' - ' num2str(imagesToAdd(i, 1) + imagesToAdd(i, 2))]);
                    end

                    obj.imageListGenerated(end+1) = false;
                    obj.imageList(end+1) = blankImage;
                end

                obj.updateImageSelectionPopup();
            end
        end
        
        function addSpectra(this, spectrumList)
            this.spectrumList.addAll(spectrumList);
            this.updateSpectrumSelectionPopup();
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
                    
                    if(~isempty(obj.spectrumPreprocessingWorkflow))
                        spectraToOverlayList(i) = obj.spectrumPreprocessingWorkflow.performWorkflow(spectraToOverlayList(i));
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
                
                if(~isempty(this.spectrumPreprocessingWorkflow))
                    spectrum1 = this.spectrumPreprocessingWorkflow.performWorkflow(spectrum1);
                    spectrum2 = this.spectrumPreprocessingWorkflow.performWorkflow(spectrum2);
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
        
        function showExportImagesTool(obj)
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

                    obj.preprocessingWorkflowEditor = PreprocessingWorkflowEditor(spectrum, obj.spectrumPreprocessingWorkflow);

                    addlistener(obj.preprocessingWorkflowEditor, 'FinishedEditing', @(src, evnt)obj.finishedEditingPreprocessingWorkflow());
                end
            end
        end
        
        %% finishedEditingPreprocessingWorkflow()
        function finishedEditingPreprocessingWorkflow(obj)
            obj.spectrumPreprocessingWorkflow = obj.preprocessingWorkflowEditor.preprocessingWorkflow;
            obj.preprocessingWorkflowEditor = [];
            
            set(obj.preprocessingLabel, 'String', obj.spectrumPreprocessingWorkflow.toCellArrayOfStrings());
            
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
                
                if isprop(obj.imageTitleLabel, 'Text')
                    set(obj.imageTitleLabel, 'Text', obj.imageList(imageIndex).getDescription());
                else
                    set(obj.imageTitleLabel, 'String', obj.imageList(imageIndex).getDescription());
                end
                
                obj.imageDisplay.setData(obj.imageList(imageIndex));
                obj.regionOfInterestPanel.setImageForEditor(obj.imageList(imageIndex));
                
                set(obj.imageAxis, 'ButtonDownFcn', @(src, evnt)obj.imageAxisClicked());
            elseif(isa(imageIndex, 'Image'))
                if isprop(obj.imageTitleLabel, 'Text')
                    set(obj.imageTitleLabel, 'Text', imageIndex.getDescription());
                else
                    set(obj.imageTitleLabel, 'String', imageIndex.getDescription());
                end
                
                obj.imageDisplay.setData(imageIndex);
                obj.regionOfInterestPanel.setImageForEditor(imageIndex);
                
                set(obj.imageAxis, 'ButtonDownFcn', @(src, evnt)obj.imageAxisClicked());
            end
        end
        
        
        function displayStoredSpectrum(this, spectrumIndex)
            % Check that there is actually an image to view
            if(isnumeric(spectrumIndex) && spectrumIndex <= this.spectrumList.getSize())
                spectrum = this.spectrumList.get(spectrumIndex);
                
%                 figure; plot(spectrum.spectralChannels, spectrum.intensities);
%                 
                if(~isempty(this.spectrumPreprocessingWorkflow))
                    spectrum = this.spectrumPreprocessingWorkflow.performWorkflow(spectrum);
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
                position(3) = 800;
                position(4) = 500;
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
                
                obj.toolsMenu = uimenu(obj.handle, 'Label', 'Tools');
                [obj.toolsMethods toolsNames] = getSubclasses('Tools', 0);
                
                uimenu(obj.toolsMenu, 'Label', 'Load in memory', 'Callback', @(src, evnt) obj.selectNewDataRepresentation());
                
                for i = 1:length(toolsNames)
                    uimenu(obj.toolsMenu, 'Label', toolsNames{i}, ...
                        'Callback', @(src, evnt) obj.performTool(i));
                end 
                
                obj.createContextMenu();
                set(obj.handle, 'uicontextmenu', obj.contextMenu);
                
                % Create GUI controls
                
                % --- Image View Details ---
%                 obj.imageSelectionPopup = uicontrol('Style', 'popup', 'String', {'Default'}, ...
%                     'Units', 'normalized', 'Position', [.1 .925 .8 .05], 'Callback', @(src, evnt)obj.displayImage(get(src, 'Value')), ...
%                     'Visible', 'off');
%                 obj.imageSelectionPopup = uitable('ColumnName', {'m/z'}, 'RowName', [], ...
%                     'Units', 'normalized', 'Position', [.025 .62 .2 .35], 'CellSelectionCallback', @(src, evnt)obj.displayImage(get(src, 'Value'))); 
%                 get( obj.imageSelectionPopup)
                
                obj.imageListPanel = uipanel('Parent', obj.handle, 'Title', 'Image List', 'AutoResizeChildren', 'off');
                
                obj.imageListTabGroup = uitabgroup('Parent', obj.imageListPanel, 'TabLocation', 'top', 'AutoResizeChildren', 'off');
                obj.userImageTab = uitab('Parent', obj.imageListTabGroup, 'Title', 'User', 'AutoResizeChildren', 'off');
                obj.peaksImageTab = uitab('Parent', obj.imageListTabGroup, 'Title', 'Peaks', 'AutoResizeChildren', 'off');
                obj.annotatedImageTab = uitab('Parent', obj.imageListTabGroup, 'Title', 'Annotated', 'AutoResizeChildren', 'off');
                
                obj.toleranceEditBox = obj.createTextBox(obj.userImageTab, '3');%uicontrol('Parent', obj.userImageTab, 'Style', 'edit', 'String', '3');
                obj.toleranceSelectionPopup = obj.createDropDown(obj.userImageTab, {'PPM', 'Da'});
                
                obj.imageListTable = uitable('Parent', obj.userImageTab,'RowName', [], ...
                    'ColumnName', {'Image', 'Generated'}, ...
                    'ColumnFormat', {'char', 'logical'}, ...
                    'ColumnEditable', [false, false], ...
                    'ColumnWidth', {120, 40} , ...
                    'CellSelectionCallback', @(src, evnt) obj.imageListTableSelected(src, evnt), ...
                    'CellEditCallback', @(src, evnt) obj.imageListTableEdited(src, evnt));
                
                obj.generateImageListButton = obj.createButtonWithIcon(obj.userImageTab, ...
                    @(src, evnt) obj.generateImagesCallback(), 'add_photo_alternate', 'Generate all images in the list');
                
                obj.overlayImagesButton = obj.createButtonWithIcon(obj.userImageTab, ...
                    @(src, evnt) obj.overlayImagesCallback(), 'compare', 'Generate RGB composite of selected images');
                
                obj.removeImageButton = obj.createButtonWithIcon(obj.userImageTab, ...
                    @(src, evnt) obj.removeImagesCallback(), 'delete', 'Remove all selected images');
                
                obj.saveImageListButton = obj.createButtonWithIcon(obj.userImageTab, ...
                    @(src, evnt) obj.saveImageListCallback(), 'save_alt', 'Save image list');
                
                obj.loadImageListButton = obj.createButtonWithIcon(obj.userImageTab, ...
                    @(src, evnt) obj.loadImageListCallback(), 'folder_open', 'Load image list');
                                
                
                obj.peakListTable = uitable('Parent', obj.peaksImageTab,'RowName', [], ...
                    'ColumnName', {'Centroid', 'Generated'}, ...
                    'ColumnFormat', {'char', 'logical'}, ...
                    'ColumnEditable', [false, false], ...
                    'ColumnWidth', {120, 40} , ...
                    'CellSelectionCallback', @(src, evnt) obj.peakListTableSelected(src, evnt));
                
                obj.annotatePeakImagesButton = obj.createButtonWithIcon(obj.peaksImageTab, ...
                    @(src, evnt) obj.annotatePeakImagesCallback(), 'label', 'Annotate peaks in the list');
                obj.savePeakImagesButton = obj.createButtonWithIcon(obj.peaksImageTab, ...
                    @(src, evnt) obj.savePeakImagesCallback(), 'save_alt', 'Save peak list');

                obj.regionOfInterestPanel = RegionOfInterestPanel(obj);
                addlistener(obj.regionOfInterestPanel, 'InfoButtonClicked', @(src, evnt) obj.infoRegionOfInterest());
                addlistener(obj.regionOfInterestPanel, 'RegionOfInterestSelected', @(src, evnt) obj.updateRegionOfInterestDisplay());
                              
                
                obj.imageTitleLabel = obj.createLabel(obj.handle, '', 'center'); 
                
                % --- Spectrum View Details ---
                obj.spectrumSelectionPopup = uicontrol('Style', 'popup', 'String', {''}, ...
                    'Units', 'normalized', 'Position', [.2 .375 .6 .05], 'Callback', @(src, evnt)obj.displayStoredSpectrum(get(src, 'Value')), ...
                    'Visible', 'off');
                
                obj.spectrumListPanel = uipanel('Parent', obj.handle, 'Title', 'Spectrum List', 'AutoResizeChildren', 'off');
                obj.spectrumListTable = uitable('Parent', obj.spectrumListPanel, 'ColumnName', {'Spectrum'}, 'RowName', [], ...
                    'ColumnWidth', {200}, 'CellSelectionCallback', @(src, evnt) obj.spectrumListTableSelected(src, evnt));
                
                obj.addSpectrumButton = obj.createButtonWithIcon(obj.spectrumListPanel, ...
                    @(src, evnt) obj.addSpectrumToListCallback(), 'bookmark', 'Add current spectrum to the list');
                
                obj.overlaySpectrumButton = obj.createButtonWithIcon(obj.spectrumListPanel, ...
                    @(src, evnt) obj.overlaySpectrumCallback(), 'layers', 'Overlay selected spectra');
                
                obj.subtractSpectrumButton = obj.createButtonWithIcon(obj.spectrumListPanel, ...
                    @(src, evnt) obj.subtractSpectrumCallback(), 'remove', 'Subtract selected spectra');
                
                obj.removeSpectrumButton = obj.createButtonWithIcon(obj.spectrumListPanel, ...
                    @(src, evnt) obj.removeSpectraFromListCallback(), 'delete', 'Remove selected spectra from the list');
                                
               
                obj.spectrumPanel = SpectrumPanel(obj, SpectralData(0, 0));
                obj.spectrumDisplay = obj.spectrumPanel.spectrumDisplay; 
                
%                 addlistener(obj.spectrumDisplay, 'MouseDownInsideAxis', @(src, evnt)obj.mouseDownInsideSpectrum(evnt.x));
%                 addlistener(obj.spectrumDisplay, 'MouseUpInsideAxis', @(src, evnt)obj.mouseUpInsideSpectrum(evnt.x));
                                
                addlistener(obj.spectrumDisplay, 'PeakSelected', @(src, evnt)obj.peakSelected(evnt));
                addlistener(obj.spectrumDisplay, 'PeakListUpdated', @(src, evnt)obj.peakListUpdated(evnt));
                
                
                obj.preprocessingPanel = uipanel('Parent', obj.handle, 'Title', 'Preprocessing', 'AutoResizeChildren', 'off');
                
                obj.spectrumPreprocessingLabel = obj.createLabel(obj.preprocessingPanel, 'Spectrum', 'left');
                obj.viewSpectrumPreprocessingButton = obj.createButtonWithIcon(obj.preprocessingPanel, ...
                    @(src, evnt)obj.viewPreprocessingWorkflow(), 'notes', 'View spectrum preprocessing details');
                obj.editSpectrumPreprocessingButton = obj.createButtonWithIcon(obj.preprocessingPanel, ...
                    @(src, evnt)obj.editPreprocessingWorkflow(), 'edit', 'Edit spectrum preprocessing workflow');
                
                obj.imageGenPreprocessingLabel = obj.createLabel(obj.preprocessingPanel, 'Image Generation', 'left');
                
                obj.viewImageGenPreprocessingButton = obj.createButtonWithIcon(obj.preprocessingPanel, ...
                    @(src, evnt)obj.viewImageGenPreprocessingWorkflow(), 'notes', 'View image generation preprocessing details');
                obj.editImageGenPreprocessingButton = obj.createButtonWithIcon(obj.preprocessingPanel, ...
                    @(src, evnt)obj.editImageGenPreprocessingWorkflow(), 'edit', 'Edit image generation preprocessing workflow');
                
                                
                obj.progressBarAxis = axes('Parent', obj.handle, 'Position', [.05 .01 .9 .03], 'Visible', 'off');
                obj.progressBar = ProgressBar(obj.progressBarAxis);          
                
            end
        end
        
        function peakListTableSelected(this, src, event)
            if(isa(this.dataRepresentation, 'DataInMemory'))
                this.displayImage(this.dataRepresentation.getImageAtIndex(event.Indices(1, 1)));
            end
        end
        
        function selectNewDataRepresentation(obj)
            sdr = SelectDataRepresentation(obj.dataRepresentation.parser);
                        
%             addlistener(sdr, 'DataRepresentationSelected', @(src, evnt)this.dataRepresentationSelected(src.dataRepresentation));
            addlistener(sdr, 'DataRepresentationLoaded', @(src, evnt)obj.loadNewDataRepresentation(src.dataRepresentation));
        end
        
        function loadNewDataRepresentation(obj, dataRepresentation)
            dataViewer = DataViewer(dataRepresentation);
            
%             this.addDataViewer(dataViewer);
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
                buttonHeight = 28;
                editBoxHeight = buttonHeight - 4;
                selectBoxHeight = editBoxHeight;
                
                widthForImage = newPosition(3) - margin*2 - colourBarSize;
                widthForSpectrum = newPosition(3) - margin*2 - spectrumExtraSize;
                
                xPositionForImage = margin;
                xPositionForSpectrum = margin + spectrumExtraSize;
                
                spectrumRegionY = 30;
                spectrumRegionHeight = newPosition(4) * (1-(obj.percentageImage/100)) - 50;
                                
                imageRegionY = (spectrumRegionHeight + spectrumRegionY) + 25;
                imageRegionHeight = newPosition(4) * (obj.percentageImage/100) - 20;
                imageDisplayHeight = imageRegionHeight - 20;
                
                progressBarHeight = 15;
                
                % Sort Image part of the view
                if(obj.showImageList)
                    widthOfImageList = 200;
                    
                    Figure.setObjectPositionInPixels(obj.imageListPanel, [margin, imageRegionY, widthOfImageList, imageRegionHeight]);
                    
                    panelPosition = Figure.getPositionInPixels(obj.imageListPanel);
                    
                    
                    if(~isempty(panelPosition))
                        Figure.setObjectPositionInPixels(obj.imageListTabGroup, [margin, margin, panelPosition(3)-margin*2, panelPosition(4)-20-margin*2]);
                        
                        groupPosition = Figure.getPositionInPixels(obj.imageListTabGroup);
                        
                        Figure.setObjectPositionInPixels(obj.toleranceSelectionPopup, [margin, groupPosition(4) - editBoxHeight*2 - margin*5, groupPosition(3)/2 - margin*2, selectBoxHeight]);
                        Figure.setObjectPositionInPixels(obj.toleranceEditBox, [margin + groupPosition(3)/2, groupPosition(4) - editBoxHeight*2 - margin*5, groupPosition(3)/2 - margin*2, editBoxHeight]);
                        
                        Figure.setObjectPositionInPixels(obj.imageListTable, [margin, buttonHeight + margin, groupPosition(3) - margin*2, groupPosition(4) - margin*2 - (buttonHeight + editBoxHeight)*2]);

                        Figure.setObjectPositionInPixels(obj.generateImageListButton, [margin, margin, buttonHeight, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.overlayImagesButton, [margin+groupPosition(3)/5, margin, buttonHeight, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.removeImageButton, [margin+groupPosition(3)*2/5, margin, buttonHeight, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.saveImageListButton, [margin+groupPosition(3)*3/5, margin, buttonHeight, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.loadImageListButton, [margin+groupPosition(3)*4/5, margin, buttonHeight, buttonHeight]);
                        
                        % Fix sizes for 'Peaks' tab
                        Figure.setObjectPositionInPixels(obj.peakListTable, [margin, buttonHeight + margin, groupPosition(3) - margin*2, groupPosition(4) - margin*2 - (buttonHeight + editBoxHeight*2)]);
                        Figure.setObjectPositionInPixels(obj.annotatePeakImagesButton, [margin, margin, buttonHeight, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.savePeakImagesButton, [margin+groupPosition(3)*3/5, margin, buttonHeight, buttonHeight]);
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
                    Figure.setObjectPositionInPixels(obj.imageDisplay.axisHandle, [xPositionForImage, imageRegionY, widthForImage, imageDisplayHeight]);
                end
                
                Figure.setObjectPositionInPixels(obj.imageTitleLabel, [xPositionForImage+widthForImage/2-100, imageRegionY+imageDisplayHeight+2, 200, 15]);
                
                
                
                % Sort spectrum region
                if(obj.showSpectrumList)
                    widthOfSpectrumList = 200;
                    
                    Figure.setObjectPositionInPixels(obj.spectrumListPanel, [margin, spectrumRegionY, widthOfSpectrumList, spectrumRegionHeight]);
                    
                    panelPosition = Figure.getPositionInPixels(obj.spectrumListPanel);
                    
                    if(~isempty(panelPosition))
                        Figure.setObjectPositionInPixels(obj.spectrumListTable, [margin, buttonHeight + margin, panelPosition(3) - margin*2, panelPosition(4) - margin*2 - buttonHeight - 20]);

                        Figure.setObjectPositionInPixels(obj.addSpectrumButton, [margin, margin, buttonHeight, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.overlaySpectrumButton, [margin+panelPosition(3)/5, margin, buttonHeight, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.subtractSpectrumButton, [margin+panelPosition(3)*2/5, margin, buttonHeight, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.removeSpectrumButton, [margin+panelPosition(3)*3/5, margin, buttonHeight, buttonHeight]);
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
                        Figure.setObjectPositionInPixels(obj.spectrumPreprocessingLabel, [margin, panelPosition(4)-margin-buttonHeight*2.25, panelPosition(3)/2 - margin, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.viewSpectrumPreprocessingButton, [panelPosition(3)-margin*2-buttonHeight*2, panelPosition(4)-margin-buttonHeight*2, buttonHeight, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.editSpectrumPreprocessingButton, [panelPosition(3)-margin-buttonHeight, panelPosition(4)-margin-buttonHeight*2, buttonHeight, buttonHeight]);
                        
                        Figure.setObjectPositionInPixels(obj.imageGenPreprocessingLabel, [margin, panelPosition(4)-margin*2-buttonHeight*3.25, panelPosition(3) - margin, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.viewImageGenPreprocessingButton, [panelPosition(3)-margin*2-buttonHeight*2, panelPosition(4)-margin*2-buttonHeight*3, buttonHeight, buttonHeight]);
                        Figure.setObjectPositionInPixels(obj.editImageGenPreprocessingButton, [panelPosition(3)-margin-buttonHeight, panelPosition(4)-margin*2-buttonHeight*3, buttonHeight, buttonHeight]);

                        Figure.setObjectPositionInPixels(obj.editPreprocessingButton, [panelPosition(3)/2, margin, panelPosition(3)/2 - margin, buttonHeight]);
                    end
                end
                
                if(~isempty(obj.spectrumDisplay))
                    Figure.setObjectPositionInPixels(obj.spectrumPanel.handle, [xPositionForSpectrum, spectrumRegionY, widthForSpectrum, spectrumRegionHeight]);
                end
                
                Figure.setObjectPositionInPixels(obj.progressBarAxis, [margin, margin, newPosition(3)-margin*2, progressBarHeight]);
            end
            
            sizeChanged@Figure(obj);
        end
        
        function createContextMenu(obj)
            % Set up the context menu
            obj.contextMenu = uicontextmenu(obj.handle);
            exportMenu = uimenu(obj.contextMenu, 'Label', 'Export Data', 'Callback', []);
            uimenu(exportMenu, 'Label', 'To workspace', 'Callback', @(src,evnt)obj.dataRepresentation.exportToWorkspace());
        end
    end

end
