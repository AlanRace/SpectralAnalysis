classdef SelectDataRepresentation < handle
    
    properties (SetAccess = private)
        figureHandle = 0;
        
        parser;
        dataRepresentation;
    end
    
    properties (Access = private)
        dataRepresentationLabel;
        dataRepresentationSelectionPopup;
        okButton;
        
        dataInMemoryPanel;
        
        spectralChannelRangeLabel;
        minSpectralChannelEdit;
        maxSpectralChannelEdit;
        
%         pixelSelection;
        regionOfInterest;
        pixelSelectionPanel;
        
        zeroFillingLabel;
        zeroFillingSelectionPopup;        
        zeroFillingSetButton;
        zeroFillingDescription;
        
        preprocessingMethodEditor;
        zeroFillingMethodFiles;
        zeroFilling;
    end        
    
    events 
        DataRepresentationSelected
        DataRepresentationLoaded
    end
    
    methods
        function obj = SelectDataRepresentation(parser)
            if(~isa(parser, 'Parser'))
                exception = MException('SelectDataRepresentation:invalidArgument', 'Must provide an instance of Parser');
                throw(exception);
            end
            
            obj.parser = parser;
            
            obj.createFigure();
        end
        
        function createFigure(obj)
            if(~obj.figureHandle)
                obj.figureHandle = figure(...
                    'Name', ['Select Data Representation: ' obj.parser.getShortFilename()], 'NumberTitle','off',...
                    'Units','characters',...
                    'MenuBar','none',...
                    'Toolbar','none', ...
                    'CloseRequestFcn', @(src, evnt)obj.closeRequest());
                
                % Make sure that we can see the SpectralAnalysis panel so
                % its obvious to the user that that shows the progress bar
                % for loading data files
                figurePos = get(obj.figureHandle, 'Position');
                figurePos(2) = figurePos(2) - 5;
                set(obj.figureHandle, 'Position', figurePos);
                
                obj.dataRepresentationLabel = uicontrol(obj.figureHandle, 'Style', 'text', 'String', 'Data Representation', ...
                    'Units', 'normalized', 'Position', [0.15 0.9 0.3 0.05], 'HorizontalAlignment', 'left');
                
                
                % Create the options for loading data into memory
                if(obj.parser.isProjectedData())
                    representations = {'Projected Data In Memory'};
                elseif(obj.parser.isSparseData())
                    representations = {'Sparse Data In Memory'};
                else
                    representations = {'Data In Memory', 'Data On Disk'};
                end
                
                obj.dataRepresentationSelectionPopup = uicontrol(obj.figureHandle, 'Style', 'popupmenu', 'String', representations, ...
                    'Units', 'normalized', 'Position', [0.5 0.9 0.35 0.05], 'Callback', @(src, evnt)obj.dataRepresentationChanged());
                
                obj.okButton = uicontrol(obj.figureHandle, 'String', 'OK', 'Callback', @(src, evnt)obj.okButtonCallback(), ...
                    'Units', 'normalized', 'Position', [0.85 0.05 0.1 0.05]);
                
                obj.dataInMemoryPanel = uipanel(obj.figureHandle, 'Title', 'Data In Memory', ...
                    'Units', 'normalized', 'Position', [0.05 0.15 0.9 0.7]);
                
                obj.spectralChannelRangeLabel = uicontrol(obj.dataInMemoryPanel, 'Style', 'text', 'String', 'Spectral Channel Range', ...
                    'Units', 'normalized', 'Position', [0.05 0.825 0.3 0.1], 'HorizontalAlignment', 'left');
                obj.minSpectralChannelEdit = uicontrol(obj.dataInMemoryPanel, 'Style', 'edit', 'String', 'Min', ...
                    'Units', 'normalized', 'Position', [0.4 0.85 0.15 0.1]);
                obj.maxSpectralChannelEdit = uicontrol(obj.dataInMemoryPanel, 'Style', 'edit', 'String', 'Max', ...
                    'Units', 'normalized', 'Position', [0.6 0.85 0.15 0.1]);
                
                panel = uipanel(obj.dataInMemoryPanel, ...
                    'Units', 'normalized', 'Position', [0 0.2 1 0.6]);
                
                obj.pixelSelectionPanel = PixelSelectionPanel(panel);
                
                messageBox = msgbox('Generating overview image, please wait...', 'Generating Overview Image');
                
                try
                    backgroundImage = obj.parser.getOverviewImage();
                catch err
                    if(ishandle(messageBox))
                        delete(messageBox);
                    end
                    
                    rethrow(err)
                end
                
                % Close the message box
                if(ishandle(messageBox))
                    delete(messageBox);
                end
                
                obj.regionOfInterest = RegionOfInterest(backgroundImage.getWidth(), backgroundImage.getHeight());
                % Set the region of interest to be all pixels that have
                % value
                
                if(isa(obj.parser, 'SIMSParser'))
                    disp('SelectDataRepresentation: Detected SIMSParser. ROI must contain whole image or DatacubeReduction will not work correctly');
                    obj.regionOfInterest.addPixels(ones(size(backgroundImage.imageData)));
                else
                    obj.regionOfInterest.addPixels(backgroundImage.imageData ~= 0);
                end
                
                obj.pixelSelectionPanel.setBackgroundImage(backgroundImage);
                obj.pixelSelectionPanel.setRegionOfInterest(obj.regionOfInterest);
                
                obj.zeroFillingLabel = uicontrol(obj.dataInMemoryPanel, 'Style', 'text', 'Units', 'normalized', ...
                    'Position', [0.05 0.05 0.2 0.085], 'String', 'Zero filling', 'HorizontalAlignment', 'left');
                obj.zeroFillingSelectionPopup = uicontrol(obj.dataInMemoryPanel, 'Style', 'popup', 'Units', 'normalized', ...
                    'Position', [0.3 0.05 0.3 0.1], 'String', 'None');
                obj.zeroFillingSetButton = uicontrol(obj.dataInMemoryPanel, 'String', '>', ...
                    'Units', 'normalized', 'Position', [0.65 0.05 0.075 0.1], 'Callback', @(src, evnt)obj.setZeroFilling());
                obj.zeroFillingDescription = uicontrol(obj.dataInMemoryPanel, 'Style', 'text', 'String', 'None', ...
                    'Units', 'normalized', 'Position', [0.75 0.05 0.2 0.085], 'HorizontalAlignment', 'left');
                
                obj.updateZeroFillingPopup();
            end
        end
        
        function dataRepresentationChanged(obj)
            representations = get(obj.dataRepresentationSelectionPopup, 'String');
            selectedRep = get(obj.dataRepresentationSelectionPopup, 'Value');
            
            representation = representations{selectedRep};
            
            if(contains(representation, 'In Memory'))
                set(obj.dataInMemoryPanel, 'Visible', 'on');
            else
                set(obj.dataInMemoryPanel, 'Visible', 'off');
            end
        end
        
        function setZeroFilling(obj)
            % Check if we have already opened the
            % PreprocessingWorkflowEditor and if so if it is still a valid
            % instance of the class. If so show it, otherwise recreate it
            if(isa(obj.preprocessingMethodEditor, 'PreprocessingMethodEditor') && isvalid(obj.preprocessingMethodEditor))
                figure(obj.preprocessingMethodEditor.figureHandle);
            else
                index = get(obj.zeroFillingSelectionPopup, 'Value');
                
                if(index > 1)
                    y = floor(obj.parser.getHeight()/2);
                    if(y <= 0)
                        y = 1;
                    end
                    
                    [spectralChannels, intensities] = obj.parser.getSpectrum(floor(obj.parser.getWidth()/2), y);
                    
                    obj.preprocessingMethodEditor = PreprocessingMethodEditor(SpectralData(spectralChannels, intensities), obj.zeroFillingMethodFiles{index});
                    
                    % Add a listener for updating preprocessingMethod list
                    addlistener(obj.preprocessingMethodEditor, 'FinishedEditing', @(src, evnt)obj.finishedEditingPreprocessingMethod());
                else
                    obj.zeroFilling = [];
                    set(obj.zeroFillingDescription, 'String', 'None');
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
        
        function updateZeroFillingPopup(obj)
            % Find all classes to populate the selection drop-down
            % boxes
%             currentPath = mfilename('fullpath');
%             [pathstr, name, ext] = fileparts(currentPath)
%             
%             warning('TODO: Update this with the correct structure');
%             spectralAnalysisPath = pathstr;
%             
%             fileList = dir([spectralAnalysisPath filesep '*.m'])
            
            [obj.zeroFillingMethodFiles, zeroFillingClasses] = getSubclasses('SpectralZeroFilling', 1);
            
%             zeroFillingClasses = {'None'};
%             obj.zeroFillingMethodFiles = {'None'};
%             
%             for i = 1:length(fileList)
%                 filename = fileList(i).name(1:end-2); % Strip off the .m
%                 
%                 if(exist(filename, 'class'))
% %                     try
%                         if(ismember('SpectralZeroFilling', superclasses(filename)))
%                             zeroFillingClasses{end+1} = eval([filename '.Name']);
%                             obj.zeroFillingMethodFiles{end+1} = filename;
%                         end
% %                     catch err
% %                         err.message
% %                         warning('TODO: Handle error');
% %                     end
%                 end
%             end
            
            set(obj.zeroFillingSelectionPopup, 'String', zeroFillingClasses);
        end
        
        function delete(obj)
            delete(obj.figureHandle);
            obj.figureHandle = 0;
        end
        
        function closeRequest(obj)
            obj.delete();
        end
    end
    
    methods (Access = protected)
        function okButtonCallback(obj)
            % Check which data representation has been selected and then
            % check the neccessary input boxes            
            minValue = get(obj.minSpectralChannelEdit, 'String');
            maxValue = get(obj.maxSpectralChannelEdit, 'String');
            
            if(~strcmp(minValue, 'Min'))
                minValue = str2double(minValue);
                
                if(isnan(minValue))
                    msgbox('Minimum value must either be a number or ''Min'' for the minimum detected value.');
                    return;
                end
            else
                minValue = Inf;
            end
            
            if(~strcmp(maxValue, 'Max'))
                maxValue = str2double(maxValue);
                
                if(isnan(maxValue))
                    msgbox('Maximum value must either be a number or ''Max'' for the maximum detected value.');
                    return;
                end
            else
                maxValue = Inf;
            end
            
%             pixels = obj.pixelSelection.getPixelList();
            
            % Check which data representation is required
            representations = get(obj.dataRepresentationSelectionPopup, 'String');
            selectedRep = get(obj.dataRepresentationSelectionPopup, 'Value');
            
            representation = representations{selectedRep};
                        
            if(contains(representation, 'In Memory'))
                if(obj.parser.isProjectedData())
                    obj.dataRepresentation = ProjectedDataInMemory();
                elseif(obj.parser.isSparseData())
                    obj.dataRepresentation = SparseDataInMemory();
                else
                    obj.dataRepresentation = DataInMemory();
                end
            else
                obj.dataRepresentation = DataOnDisk(obj.parser);
                obj.dataRepresentation.setRegionOfInterest(obj.regionOfInterest);
            end
            
            notify(obj, 'DataRepresentationSelected');
            
            % Load data if necessary
            if(contains(representation, 'In Memory'))
                try
                    obj.dataRepresentation.loadData(obj.parser, obj.regionOfInterest, [minValue maxValue], obj.zeroFilling);
                    
                    notify(obj, 'DataRepresentationLoaded');

                    obj.closeRequest();
                catch err
                    if((strcmp(err.identifier,'MATLAB:badsubscript')))
                        errordlg('Cannot load data. If no zero filling is selected, the data must have the same number of channels in each pixel.', 'Index exceeds matrix dimensions');
                    else
                        rethrow(err);
                    end
                end
            else
                notify(obj, 'DataRepresentationLoaded');

                obj.closeRequest();
            end
        end
    end
end