classdef CombineSpectraIntoPixels < Figure
 
    properties (SetAccess = private)
        version = '1.0';
    end
    
    properties (Access = protected)
        openFileMenu;
        saveFileMenu;
        
        mzML;
        currentSpectrumViewed;
        numSpectra;
        
        chromatogramAxis;
        chromatogramDisplay;
        chromatogramPanel;
        
        spectrumAxis;
        spectrumDisplay;
        spectrumPanel;
        
        mouseDownInsideSpectrumLocation;
        
        removePixelButton;
        startSpectrumButton;
        endSpectrumButton;
        
        currentChromatogramSegment;
        chromatogramSegmentList;
        chromatogramSegmentListBox;
        
        combinationPanel;
        startTimeLabel;
        startTimeEditBox;
        endTimeLabel;
        endTimeEditBox;
        
        zeroFillingLabel;
        zeroFillingSelectionPopup;        
        zeroFillingSetButton;
        zeroFillingDescription;
        
        combinationLabel;
        combinationPopup;
        
        addChromatogramSegmentButton;
        
        preprocessingMethodEditor;
        zeroFillingMethodFiles;
        zeroFilling;
    end
    
    methods
        function this = CombineSpectraIntoPixels()
            % Need to be sure that imzMLConverter.jar has been added to the
            % path prior to using this class
            try
                addJARsToClassPath();
            catch err
                if(strcmp(err.identifier, 'addJARsToClassPath:FailedToAddJAR'))
                    exception = MException('ImzMLParser:FailedToParse', ...
                        ['Failed to add JAR file ''' 'imzMLConverter/imzMLConverter.jar' ''', please ensure that it exists. It can be downloaded from www.imzMLConverter.co.uk']);
                    throw(exception);
                else
                    rethrow(err);
                end
            end
            
            this.chromatogramSegmentList = ChromatogramSegmentList();
            
            this.createFigure();
        end
        
        function openmzMLFile(this) 
            [fileName, pathName, filterIndex] = uigetfile({'*.mzML', 'Mass Spectrometry (*.mzML)'}, 'Select File');
            
            if(filterIndex > 0)
                this.mzML = com.alanmrace.jimzmlparser.parser.MzMLHeaderHandler.parsemzMLHeader([pathName fileName]);
                
                spectrumList = this.mzML.getRun().getSpectrumList();
                this.numSpectra = spectrumList.size();
                
                time = zeros(this.numSpectra, 1);
                intensities = zeros(this.numSpectra, 1);
                
                for i = 0:this.numSpectra-1
                    currentSpectrum = spectrumList.getSpectrum(i);
                    
                    intensities(i+1) = str2double(currentSpectrum.getCVParam('MS:1000285').getValue());
                    time(i+1) = (currentSpectrum.getScanList().getScan(0).getCVParam('MS:1000016').getValueAsDouble());
                end
                
                this.chromatogramDisplay.setData(Chromatogram(time, intensities));
                this.spectrumDisplay.setData(SpectralData(0, 0));
                this.currentSpectrumViewed = [];
            end
        end
        
        function savemzMLFile(this)
            [fileName, pathName, filterIndex] = uiputfile({'*.mzML', 'Mass Spectrometry (*.mzML)'}, 'Select File', 'combined.mzML');
            
            if(filterIndex > 0)
                segments = this.chromatogramSegmentList.getObjects();

                chromatogram = this.chromatogramDisplay.data;
                
                newmzML = com.alanmrace.jimzmlparser.mzML.MzML(this.mzML)
                    
                software = com.alanmrace.jimzmlparser.mzML.Software('SpectralAnalysis', SpectralAnalysisInterface.version);
                dp = com.alanmrace.jimzmlparser.mzML.DataProcessing('CombineSpectraFromChromatogram');
                pm = com.alanmrace.jimzmlparser.mzML.ProcessingMethod(1,   software);
                
                dp.addProcessingMethod(pm);
                
                newmzML.getSoftwareList().addSoftware(software);
                newmzML.getDataProcessingList().addDataProcessing(dp);
                
                newmzML.getRun().setSpectrumList(com.alanmrace.jimzmlparser.mzML.SpectrumList(0, dp));
                newmzML.getRun().setChromatogramList(com.alanmrace.jimzmlparser.mzML.ChromatogramList(0, dp));
                
%                 newmzML.getRun().getSpectrumList().addSpectrum(this.mzML.getRun().getSpectrumList().getSpectrum(0));
                
                obo = this.mzML.getOBO();
                
                for i = 1:numel(segments)
                    segment = segments{i};
                    zeroFilling = segment.getZeroFilling();
                    combination = segment.getCombination();
                    
                    % 60 us threshold to account for rounding errors
                    threshold = 1e-6;
                    
                    % Change into 0 indexing
                    indicesToProcess = find(chromatogram.spectralChannels >= segment.getStartTime-threshold & ...
                        chromatogram.spectralChannels <= segment.getEndTime+threshold) - 1;
                    
                    combinedSpectrum = 0;
                    
                    for idx = indicesToProcess
                        currentSpectrum = this.mzML.getRun().getSpectrumList().getSpectrum(idx);
                        mzArray = currentSpectrum.getmzArray();
                        counts = currentSpectrum.getIntensityArray();
                        
                        if(~isempty(zeroFilling))
                            [mzArray, counts] = zeroFilling.process(mzArray, counts);
                        end
                        
                        if(combination == 1 || combination == 2) % Mean || Sum
                            combinedSpectrum = combinedSpectrum + counts;
                        end
                    end
                    
                    if(combination == 1) % Mean
                        combinedSpectrum = combinedSpectrum ./ length(indicesToProcess);
                    end
                       
                    spectrumTypeCV = currentSpectrum.getCVParamOrChild('MS:1000559');
                    spectrumRepresentationCV = currentSpectrum.getCVParamOrChild('MS:1000525');
                    
                    scanPolarity = currentSpectrum.getCVParamOrChild('MS:1000465');
                    
                    mzMLSpectrum = com.alanmrace.jimzmlparser.mzML.Spectrum(['Combined' num2str(i-1)], length(combinedSpectrum), i-1);
                    
                    mzMLSpectrum.addCVParam(spectrumTypeCV);
                    mzMLSpectrum.addCVParam(spectrumRepresentationCV);
                    
                    if(~isempty(scanPolarity))
                        mzMLSpectrum.addCVParam(scanPolarity);
                    end
                    
                    % Calculate and store basepeak
                    [basepeak, basepeakIdx] = max(combinedSpectrum);
                    mzMLSpectrum.addCVParam(com.alanmrace.jimzmlparser.mzML.DoubleCVParam(obo.getTerm('MS:1000504'), (mzArray(basepeakIdx))));
                    mzMLSpectrum.addCVParam(com.alanmrace.jimzmlparser.mzML.DoubleCVParam(obo.getTerm('MS:1000505'), (basepeak)));
                    
                    % Calculate and store TIC
                    mzMLSpectrum.addCVParam(com.alanmrace.jimzmlparser.mzML.DoubleCVParam(obo.getTerm('MS:1000285'), (sum(combinedSpectrum))));
                    
                    % Store min and max m/z
                    mzMLSpectrum.addCVParam(com.alanmrace.jimzmlparser.mzML.DoubleCVParam(obo.getTerm('MS:1000528'), (min(mzArray)), obo.getTerm('MS:1000040')));
                    mzMLSpectrum.addCVParam(com.alanmrace.jimzmlparser.mzML.DoubleCVParam(obo.getTerm('MS:1000527'), (max(mzArray)), obo.getTerm('MS:1000040')));
                    
                    scanList = com.alanmrace.jimzmlparser.mzML.ScanList(1);
                    
                    if(combination == 1) % Mean
                        scanList.addCVParam(com.alanmrace.jimzmlparser.mzML.EmptyCVParam(obo.getTerm('MS:1000575')));
                    elseif(combination == 2) % Sum
                        scanList.addCVParam(com.alanmrace.jimzmlparser.mzML.EmptyCVParam(obo.getTerm('MS:1000571')));
                    end
                    
                    mzMLSpectrum.setScanList(scanList);
                    
                    scan = com.alanmrace.jimzmlparser.mzML.Scan();
                    
                    % Store start time of the summed spectra and dwell time
                    % as the different between start and end
                    scan.addCVParam(com.alanmrace.jimzmlparser.mzML.DoubleCVParam(obo.getTerm('MS:1000016'), (segment.getStartTime()), obo.getTerm('UO:0000031')));
                    scan.addCVParam(com.alanmrace.jimzmlparser.mzML.DoubleCVParam(obo.getTerm('MS:1000502'), (segment.getEndTime()-segment.getStartTime()), obo.getTerm('UO:0000031')));
                    
                    scanList.addScan(scan);
                    
                    bdal = com.alanmrace.jimzmlparser.mzML.BinaryDataArrayList(2);
                    bda_mz = com.alanmrace.jimzmlparser.mzML.BinaryDataArray(length(mzArray) * 8);
                    bda_mz.addCVParam(com.alanmrace.jimzmlparser.mzML.EmptyCVParam(obo.getTerm('MS:1000523'))); % double precision
                    bda_mz.addCVParam(com.alanmrace.jimzmlparser.mzML.EmptyCVParam(obo.getTerm('MS:1000576'))); % no compression
                    bda_mz.addCVParam(com.alanmrace.jimzmlparser.mzML.EmptyCVParam(obo.getTerm('MS:1000514'))); % m/z array
                    bda_mz.setBinary(com.alanmrace.jimzmlparser.mzML.Binary(mzArray));
                    bdal.addBinaryDataArray(bda_mz);
                    
                    bda_counts = com.alanmrace.jimzmlparser.mzML.BinaryDataArray(length(combinedSpectrum) * 8);
                    bda_counts.addCVParam(com.alanmrace.jimzmlparser.mzML.EmptyCVParam(obo.getTerm('MS:1000523'))); % double precision
                    bda_counts.addCVParam(com.alanmrace.jimzmlparser.mzML.EmptyCVParam(obo.getTerm('MS:1000576'))); % no compression
                    bda_counts.addCVParam(com.alanmrace.jimzmlparser.mzML.EmptyCVParam(obo.getTerm('MS:1000515'))); % m/z array
                    bda_counts.setBinary(com.alanmrace.jimzmlparser.mzML.Binary(combinedSpectrum));
                    bdal.addBinaryDataArray(bda_counts);
                    
                    mzMLSpectrum.setBinaryDataArrayList(bdal);
                    
                    
%                     time = str2double(currentSpectrum.getScanList().getScan(0).getCVParam('MS:1000016').getValue())
%                     currentSpectrum = this.mzML.getRun().getSpectrumList().getSpectrum(indicesToProcess(end));
%                     time = str2double(currentSpectrum.getScanList().getScan(0).getCVParam('MS:1000016').getValue())
                    
                    % Description of the style of summing goes in the
                    % <scanList> tag
%                     [Term]
%                     id: MS:1000570
%                     name: spectra combination
%                     def: "Method used to combine the mass spectra." [PSI:MS]
%                     relationship: part_of MS:1000442 ! spectrum
%                     [Term]
%                     id: MS:1000571
%                     name: sum of spectra
%                     def: "Spectra Sum." [PSI:MS]
%                     is_a: MS:1000570 ! spectra combination
%                     [Term]
%                     id: MS:1000573
%                     name: median of spectra
%                     def: "Spectra is combined by calculating the median of the spectra." [PSI:MS]
%                     is_a: MS:1000570 ! spectra combination
%                     [Term]
%                     id: MS:1000575
%                     name: mean of spectra
%                     def: "Spectra is combined by calculating the mean of the spectra." [PSI:MS]
%                     is_a: MS:1000570 ! spectra combination

                    
                    
%                     newmzML.getRun().getSpectrumList().getSpectrum(0).getBinaryDataArrayList().getBinaryDataArray(0).setBinary(mzML.Binary(this.mzML.getRun().getSpectrumList().getSpectrum(0).getmzArray()));
                    
                    
                    
                    % Check to see if a child of scan polarity is there MS:1000465
                    % MUST have child of MS:1000559
                    % MUST have child of MS:1000525
                    
                    % Add in basepeak, TIC, highest m/z, lowest m/z
                    
                    newmzML.getRun().getSpectrumList().addSpectrum(mzMLSpectrum);
                end
                
                newmzML.write([pathName filesep fileName]);
            end
        end
        
        function mouseMovedCallback(this) 
            this.chromatogramDisplay.mouseMovedCallback();
            this.spectrumDisplay.mouseMovedCallback();
        end
        
        function mouseButtonUpCallback(this)
            this.chromatogramDisplay.mouseButtonUpCallback();
            this.spectrumDisplay.mouseButtonUpCallback();
        end
        
        function displaySpectrumAtChromatogramLine(this)
            time = this.chromatogramDisplay.data.spectralChannels;
            
            linePos = this.chromatogramDisplay.getChromatogramLinePosition();
            
            if(~isempty(linePos) && linePos ~= 0)
                [distance, idx] = min(abs(time - linePos));
                
                this.displaySpectrumAtIndex(idx-1);
            end
        end
        
        function displaySpectrumAtIndex(this, index)
            spectrum = this.mzML.getRun().getSpectrumList().getSpectrum(index);
                
            this.spectrumDisplay.setData(SpectralData(spectrum.getmzArray(), spectrum.getIntensityArray()));
            this.currentSpectrumViewed = index;
        end
        
        function updateZeroFillingPopup(this)
            % Find all classes to populate the selection drop-down
            % boxes            
            [this.zeroFillingMethodFiles, zeroFillingClasses] = getSubclasses('SpectralZeroFilling', 1);
            
            set(this.zeroFillingSelectionPopup, 'String', zeroFillingClasses);
        end
        
        function mouseDownInsideSpectrum(this, x)
            this.mouseDownInsideSpectrumLocation = x;
        end
        
        function mouseUpInsideSpectrum(this, x)
            spectralRange = [min(x, this.mouseDownInsideSpectrumLocation) max(x, this.mouseDownInsideSpectrumLocation)];
            
%             spectralRange
        end 
        
        function keyPressCallback(this, event)
            if(isempty(this.currentSpectrumViewed))
                this.currentSpectrumViewed = -1;
            end
            
            spectrumToView = this.currentSpectrumViewed;
            
            switch event.Key
                case 'rightarrow'
                    spectrumToView = spectrumToView + 1;
                case 'leftarrow'
                    spectrumToView = spectrumToView - 1;
            end

            if(isempty(spectrumToView) || spectrumToView < 0)
                spectrumToView = 0;
            elseif(spectrumToView > this.numSpectra-1)
                spectrumToView = this.numSpectra-1;
            end

            if(spectrumToView ~= this.currentSpectrumViewed)
                this.displaySpectrumAtIndex(spectrumToView);
                this.chromatogramDisplay.moveChromatogramLine(this.chromatogramDisplay.data.spectralChannels(this.currentSpectrumViewed+1));
            end
        end
        
        function removeChromatogramSegment(this, segment)
            this.chromatogramSegmentList.remove(segment);
            
            this.updateChromatogramSegmentList();
        end
    end
    
    methods (Access = protected)
        function createFigure(this)
            if(isempty(this.handle) || ~ishandle(this.handle))
                createFigure@Figure(this);

                this.setTitle('Combine Spectra Into Pixels');

                this.openFileMenu = uimenu(this.handle, 'Label', 'Open', 'Callback', @(src, evnt) this.openmzMLFile());
                this.saveFileMenu = uimenu(this.handle, 'Label', 'Save', 'Callback', @(src, evnt) this.savemzMLFile());

    %             this.chromatogramAxis = axes('Parent', this.handle, 'Position', [.1 .7 .8 .25]);
                this.chromatogramPanel = ChromatogramPanel(this, Chromatogram(0, 0));
                this.chromatogramDisplay = this.chromatogramPanel.chromatogramDisplay;

                addlistener(this.chromatogramDisplay, 'PeakSelected', @(src, evnt)this.displaySpectrumAtChromatogramLine());
                
    %             addlistener(this.chromatogramDisplay, 'MouseClickInsideAxis', @(src, evnt)this.displaySpectrumAtChromatogramLine());

                this.spectrumPanel = SpectrumPanel(this, SpectralData(0, 0));
                this.spectrumDisplay = this.spectrumPanel.spectrumDisplay;
                
%                 this.spectrumAxis = axes('Parent', this.handle, 'Position', [.1 .35 .8 .25]);
%                 this.spectrumDisplay = SpectrumDisplay(this, SpectralData(0, 0));

    %             addlistener(this.spectrumDisplay, 'MouseDownInsideAxis', @(src, evnt)this.mouseDownInsideSpectrum(evnt.x));
    %             addlistener(this.spectrumDisplay, 'MouseUpInsideAxis', @(src, evnt)this.mouseUpInsideSpectrum(evnt.x));

                this.startSpectrumButton = uicontrol(this.handle, 'Units', 'normalized', 'Position', [.4 .26 .2 .04], ...
                    'String', 'Start Spectrum', 'Callback', @(src, evnt)this.setStartSpectrum());
                this.endSpectrumButton = uicontrol(this.handle, 'Units', 'normalized', 'Position', [.75 .26 .2 .04], ...
                    'String', 'End Spectrum', 'Callback', @(src, evnt)this.setEndSpectrum());

                this.removePixelButton = uicontrol(this.handle, 'Units', 'normalized', 'Position', [.05 .26 .2 .04], 'String', 'Remove Pixel', ...
                    'Callback', @(src, evnt)this.removeSelectedPixel());
                this.chromatogramSegmentListBox = uicontrol(this.handle, 'Style', 'listbox', 'Units', 'normalized', ...
                    'Position', [0.05 0.05 0.3 0.2], 'BackgroundColor', 'w');

                this.combinationPanel = uipanel(this.handle, 'Position', [.4 .05 .55 .2], 'Title', 'Chromatogram Segment');
                set(this.handle, 'Color', get(this.combinationPanel, 'BackgroundColor'))
                this.startTimeLabel = uicontrol(this.combinationPanel, 'Style', 'text', 'Units', 'normalized', 'Position', [.05 .8 .2 .1], 'String', 'Start time', 'HorizontalAlignment', 'left');
                this.startTimeEditBox = uicontrol(this.combinationPanel, 'Style', 'edit', 'Units', 'normalized', 'Position', [.3 .75 .2 .15], 'BackgroundColor', 'w');

                this.endTimeLabel = uicontrol(this.combinationPanel, 'Style', 'text', 'Units', 'normalized', 'Position', [.55 .8 .2 .1], 'String', 'End time', 'HorizontalAlignment', 'left');
                this.endTimeEditBox = uicontrol(this.combinationPanel, 'Style', 'edit', 'Units', 'normalized', 'Position', [.75 .75 .2 .15], 'BackgroundColor', 'w');

                this.zeroFillingLabel = uicontrol(this.combinationPanel, 'Style', 'text', 'Units', 'normalized', ...
                    'Position', [0.05 0.47 0.2 0.15], 'String', 'Zero filling', 'HorizontalAlignment', 'left');
                this.zeroFillingSelectionPopup = uicontrol(this.combinationPanel, 'Style', 'popup', 'Units', 'normalized', ...
                    'Position', [0.3 0.55 0.3 0.1], 'String', 'None', 'BackgroundColor', 'w');
                this.zeroFillingSetButton = uicontrol(this.combinationPanel, 'String', '>', ...
                    'Units', 'normalized', 'Position', [0.65 0.45 0.075 0.2], 'Callback', @(src, evnt)this.setZeroFilling());
                this.zeroFillingDescription = uicontrol(this.combinationPanel, 'Style', 'text', 'String', 'None', ...
                    'Units', 'normalized', 'Position', [0.75 0.47 0.2 0.15], 'HorizontalAlignment', 'left');

                this.updateZeroFillingPopup();

                this.combinationLabel = uicontrol(this.combinationPanel, 'Style', 'text', 'String', 'Combination', ...
                    'Units', 'normalized', 'Position', [0.05 0.2 0.25 0.15], 'HorizontalAlignment', 'left');
                this.combinationPopup = uicontrol(this.combinationPanel, 'Style', 'Popup', 'String', {'Mean', 'Sum'}, ...
                    'Units', 'normalized', 'Position', [0.3 0.22 0.35 0.15], 'BackgroundColor', 'w');

                this.addChromatogramSegmentButton = uicontrol(this.combinationPanel, 'String', 'Add Pixel', ...
                    'Units', 'normalized', 'Position', [0.7 0.15 0.25 0.25], 'Callback', @(src, evnt)this.addChromatogramSegment());

                % Overwrite the mouse moved and mouse button up handles so that
                % both events from the two windows are called
                set(this.handle, 'WindowButtonMotionFcn', @(src,evnt)this.mouseMovedCallback());
                set(this.handle, 'WindowButtonUpFcn', @(src, evnt)this.mouseButtonUpCallback());

                set(this.handle, 'KeyPressFcn', @(src, evnt)this.keyPressCallback(evnt));
                
                % Resize the figure
                screenSize = get(0,'ScreenSize');
                idealWidth = 500;
                idealHeight = 600;
                posX = (screenSize(3) / 2) - (idealWidth/2);
                posY = (screenSize(4) / 2) - (idealHeight/2);

                set(this.handle, 'Units', 'Pixels', 'Position', [posX posY idealWidth idealHeight]);
            end
        end
        
        function sizeChanged(obj, src, evnt)
            if(obj.handle ~= 0)
                oldUnits = get(obj.handle, 'Units');
                set(obj.handle, 'Units', 'pixels');
            
                newPosition = get(obj.handle, 'Position');

                Figure.setObjectPositionInPixels(obj.chromatogramPanel.handle, [30 newPosition(4)*2/3 newPosition(3)-40 newPosition(4)/3-20]);
                Figure.setObjectPositionInPixels(obj.spectrumPanel.handle, [30 newPosition(4)/3 newPosition(3)-40 newPosition(4)/3-20]);

                set(obj.handle, 'Units', oldUnits);
            end
            
            sizeChanged@Figure(obj);
        end
        
        function addChromatogramSegment(this)
            startTime = str2double(get(this.startTimeEditBox, 'String'));
            endTime = str2double(get(this.endTimeEditBox, 'String'));
            
            if(~isnan(startTime) && ~isnan(endTime))
                this.chromatogramSegmentList.add(ChromatogramSegment(startTime, endTime, this.zeroFilling, get(this.combinationPopup, 'Value')));
                this.updateChromatogramSegmentList();
            else
                msgbox('Set a start and end time by entering values or using the ''Start Spectrum'' and ''End Spectrum'' buttons');
            end
        end
        
        function removeSelectedPixel(this)
            if(this.chromatogramSegmentList.getSize() > 0)
                indexToRemove = get(this.chromatogramSegmentListBox, 'Value');
                this.removeChromatogramSegment(this.chromatogramSegmentList.get(indexToRemove));
            end
        end
        
        function setStartSpectrum(this)
            if(~isempty(this.currentSpectrumViewed))
                set(this.startTimeEditBox, 'String', num2str(this.chromatogramDisplay.data.spectralChannels(this.currentSpectrumViewed+1)));
            end
        end
        
        function setEndSpectrum(this)
            if(~isempty(this.currentSpectrumViewed))
                set(this.endTimeEditBox, 'String', num2str(this.chromatogramDisplay.data.spectralChannels(this.currentSpectrumViewed+1)));
            end
        end
        
        function setZeroFilling(this)
            % Check we have loaded a spectrum
            if(isempty(this.mzML))
                msgbox('Please open an mzML file first');
                return;
            elseif(isempty(this.spectrumDisplay.data.spectralChannels) | this.spectrumDisplay.data.spectralChannels == 0)
                msgbox('Please select a spectrum by clicking on the chromatogram first');
                return;
            end
            
            % Check if we have already opened the
            % PreprocessingWorkflowEditor and if so if it is still a valid
            % instance of the class. If so show it, otherwise recreate it
            if(isa(this.preprocessingMethodEditor, 'PreprocessingMethodEditor') && isvalid(this.preprocessingMethodEditor))
                figure(this.preprocessingMethodEditor.handle);
            else
                index = get(this.zeroFillingSelectionPopup, 'Value');
                
                if(index > 1)                    
                    this.preprocessingMethodEditor = PreprocessingMethodEditor(this.spectrumDisplay.data, this.zeroFillingMethodFiles{index});
                    
                    % Add a listener for updating preprocessingMethod list
                    addlistener(this.preprocessingMethodEditor, 'FinishedEditing', @(src, evnt)this.finishedEditingPreprocessingMethod());
                else
                    this.zeroFilling = [];
                    set(this.zeroFillingDescription, 'String', 'None');
                end
            end
        end
        
        function finishedEditingPreprocessingMethod(obj)
            if(isa(obj.preprocessingMethodEditor, 'PreprocessingMethodEditor'))
                obj.zeroFilling = obj.preprocessingMethodEditor.preprocessingMethod;
                
                obj.preprocessingMethodEditor = [];
                
                set(obj.zeroFillingDescription, 'String', obj.zeroFilling.toString());
            end
        end
        
        function updateChromatogramSegmentList(this)
            segments = this.chromatogramSegmentList.getObjects();
            names = {};
            
            for i = 1:numel(segments)
                names{i} = segments{i}.toString();
            end
            
            if(~isempty(names))
                curSelected = get(this.chromatogramSegmentListBox, 'Value');
                
                if(curSelected > numel(names))
                    set(this.chromatogramSegmentListBox, 'Value', numel(names));
                elseif(isempty(curSelected))
                    set(this.chromatogramSegmentListBox, 'Value', 1);
                end
            end
            
            set(this.chromatogramSegmentListBox, 'String', names);
        end
    end
    
end