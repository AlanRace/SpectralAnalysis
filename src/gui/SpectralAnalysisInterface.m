classdef SpectralAnalysisInterface < Figure
    %SpectralAnalysisInterface Primary interface for SpectralAnalysis.
    
    properties (Constant)
        version = '0.5';
    end
    
    properties (SetAccess = private)       
        % List containing all instances of DataViewer GUIs opened
        dataViewerList;
    end
    
    properties (Access = private)
        openFileMenu;
        convertMenu;
        memoryMenu;
        
        progressBarAxis;
        progressBar;
        
        messageBox;
        log = '';
        
        dataListViewer = 0;
        
        openFileMethods;
        toBinaryConverterMethods;
        
        lastPath = [];
    end
    
    events
    end
    
    methods
        function this = SpectralAnalysisInterface()
            % SpectralAnalysisInterface Create and display interface for SpectralAnalysis.
            %
            %   SpectralAnalysisInterface()
            
            this.setTitle('SpectralAnalysis');
            
            addlistener(this, 'InfoMessage', @(src, evnt) this.updateLog(evnt.message));
            
            % Create the necessary lists for storing any DataViewer
            % instances that are created and controlled by
            % SpectralAnalysisInterface
            this.dataViewerList = DataViewerList();
        end
        
        function openFile(this, parserClassName)
            % openFile Request user to select a file to open then open it.
            %
            %   openFile(parserClassName)
            %       parserClassName - Name of class to use to parse file user will select. Must inherit Parser.
                        
            % Get the fiter specification of the parser
            filterSpec = eval([parserClassName '.getFilterSpec()']);
                       
            % Show file select interface
            [fileName, pathName, filterIndex] = uigetfile(filterSpec, 'Select File', this.lastPath);
            
            % Check that the Open dialog was not cancelled
            if(filterIndex > 0)
                % Update the last path so that next time we open a file we
                % start where we left off
                this.lastPath = pathName;
                
                try
                    % Create an instance of the parser
                    parserCommand = [parserClassName '([pathName filesep fileName])'];
                    parser = eval(parserCommand);
                    
                    if(~isempty(parser))
                        addlistener(parser, 'ParsingStarted', @(src, evnt) this.updateLog(['Parsing ' parser.filename ', please wait.']));
                        addlistener(parser, 'ParsingComplete', @(src, evnt) this.updateLog(['Parsing ' parser.filename ' complete.']));

                        parser.parse();
                        
                        % Show SelectDataRepresentation interface now that
                        % the header information of the selected file has
                        % been parsed
                        sdr = SelectDataRepresentation(parser);
                        
                        addlistener(sdr, 'DataRepresentationSelected', @(src, evnt)this.dataRepresentationSelected(src.dataRepresentation));
                        addlistener(sdr, 'DataRepresentationLoaded', @(src, evnt)this.addDataRepresentation(src.dataRepresentation));
                    else
                        errordlg(['Failed to execute command: ' parserCommand], 'Failed to create parser');
                    end
                catch err
                    % Make sure the user sees that we have had an error
                    errordlg(err.message, err.identifier);
                    
                    % Rethrow so that the user gets the stack trace
                    rethrow(err);
                end
            end
        end
        
        function convertToBinary(this, converterClassName)
            % convertToBinary Request user to select a file to open then open it.
            %
            %   convertToBinary(converterClassName)
            %       converterClassName - Name of class to use to convert file user will select. Must inherit Converter.
            
            filterSpec = eval([converterClassName '.getFilterSpec()']);
            
            % Show file select interface
            [fileName, pathName, filterIndex] = uigetfile(filterSpec);
            
            if(filterIndex > 0)
                fullFilename = [pathName fileName];
                [pathstr, name, ext] = fileparts(fullFilename);
                
                % Select where to convert to
                [outFilename, outPath, outFilterIndex] = uiputfile({'*.sab', 'SpectralAnalysis Binary'}, 'Save file to', [pathstr, filesep, name, '.sab']);

                if(outFilterIndex > 0)                    
                    converterCommand = [converterClassName '(''' fullFilename ''', ''' outPath outFilename ''')'];
                    converter = eval(converterCommand);
                    
                    addlistener(converter, 'ConversionStarted', @(src, evnt) this.updateLog(['Converting ' fileName ', please wait.']));
                    addlistener(converter, 'ConversionProgress', @(src, evnt)this.progressBar.updateProgress(evnt));
                    addlistener(converter, 'ConversionComplete', @(src, evnt) this.updateLog(['Conversing ' fileName ' complete.']));
                    
                    converter.convert();
                end
            end
        end
                
        function updateLog(this, message)
            % updateLog Update the log displayed below progress bar with a message
            %
            %   updateLog(message)
            %       message - Message to add to the log
            
            this.log = sprintf('[%s] %s\n%s', datestr(now, 'HH:MM:SS'), message, this.log);
            
            set(this.messageBox, 'String', this.log);
            
            % Pause briefly to ensure that the edit box is updated so that
            % the user knows something has occured
            pause(0.01);
        end
                
        
        function addDataViewer(this, dataViewer)
            % addDataViewer Add new DataViewer to the list of open DataViewers
            %
            %   addDataViewer(dataViewer)
            %       dataViewer - Instance of DataViewer to add to the
            %       list of open DataViewers
            
            this.dataViewerList.add(dataViewer);
            
            addlistener(dataViewer, 'InfoMessage', @(src, evnt) this.updateLog(evnt.message));
            
            % Add listeners to the DataViewer window that ensures the
            % dataViewerList is kept up to date with creation and closing
            % of new DataViewer windows
            addlistener(dataViewer, 'NewDataViewerCreated', @(src, evnt)this.addDataViewer(evnt.dataViewer));
            addlistener(dataViewer, 'DataViewerClosed', @(src, evnt)this.removeDataViewer(src));
        end
        
        function addDataRepresentation(this, dataRepresentation)
            % addDataRepresentation Create and DataViewer for new DataRepresentation
            %
            %   addDataRepresentation(dataRepresentation)
            %       dataRepresentation - Instance of DataRepresentation 
            
            dataViewer = DataViewer(dataRepresentation);
            
            this.addDataViewer(dataViewer);
        end
        
        function removeDataViewer(this, dataViewer)
            % removeDataViewer Remove DataViewer from the list of open DataViewers
            %
            %   removeDataViewer(dataViewer)
            %       dataViewer - Instance of DataViewer to remove from the
            %       list of open DataViewers
            
            this.dataViewerList.remove(dataViewer);
        end
        
        function showDataListViewer(this)
            % showDataListViewer Create and show DataListViewer interface.
            %
            %   showDataListViewer()
            
            if(~this.isvalid())
                return;
            end
            
            % Check if we have already opened the
            % DataListViewer and if so if it is still a valid
            % instance of the class. If so show it, otherwise recreate it
            if(isa(this.dataListViewer, 'DataListViewer') && this.dataListViewer.isvalid() && ~isempty(this.dataListViewer.handle))
                figure(this.dataListViewer.handle);
            else
                this.dataListViewer = DataListViewer(this.dataViewerList);
                
                addlistener(this.dataListViewer, 'DataListViewerClosed', @(src, evnt)this.closeDataListViewer());
            end
        end
        
        function dataRepresentations = getDataRepresentations(this)
            % getDataRepresentations Get data representations associated with this SpectralAnalysisInterface.
            %
            %   dataRepresentations = getDataRepresentations()
            %       dataRepresentations - Cell array of instances of
            %       DataRepresentation that have been loaded within this
            %       SpectralAnalysisInterface
            
            dataRepresentations = {};
            
            dataViewers = this.dataViewerList.getObjects();
            
            for i = 1:numel(dataViewers)
                if(isa(dataViewers{i}, 'DataViewer') && dataViewers{i}.isvalid())
                    if(isempty(dataRepresentations))
                        dataRepresentations{1} = dataViewers{i}.dataRepresentation;
                    else
                        dataRepresentations{end+1} = dataViewers{i}.dataRepresentation;
                    end
                end
            end
        end
        
        function closeDataListViewer(this)        
            % closeDataListViewer Close the DataListViewer interface.
            %
            %   closeDataListViewer()
            %
            %   Close the DataListViewer interface associated with this SpectralAnalysisInterface.
            
            if(isa(this.dataListViewer, 'DataListViewer') && this.dataListViewer.isvalid())
                this.dataListViewer.delete();
                
                this.dataListViewer = 0;
            end
        end
        
        function delete(this)
            % delete Close and delete the figure.
            %
            %   delete()
            %
            %   The 'FigureClosed' event will be triggered prior to
            %   deleting the figure handle.
            
            try
                % Make sure that DataListViewer is closed if it exists
                this.closeDataListViewer();

                % Close all open DataRepresentations
                this.dataViewerList.closeAll();

                % Finally close SpectralAnalysis
                delete@Figure(this);
            catch err
                % Make sure that we dispose of the figure before rethrowing
                % the error
                delete@Figure(this);
                
                rethrow(err);
            end
        end
        
        function closeRequest(this)
            % closeRequest Trigger the 'CloseRequested' event and then delete the figure.
            %
            %   closeRequest()
            %
            
            answer = questdlg('Are you sure you want to close SpectralAnalysis and all open data files?', 'Close SpectralAnalysis');
            
            if(strcmpi(answer, 'Yes'))
            	closeRequest@Figure(this); 
            end
        end
        
    end
    
    methods (Access = protected)
        function createFigure(this)
            % createFigure Create figure.
            %
            %   createFigure()
            
            createFigure@Figure(this);
            
            currentUnits = get(this.handle, 'Units');
            
            % Set the width and the height
            set(this.handle, 'Units', 'pixels');
            curPos = get(this.handle, 'Position');
            set(this.handle, 'Position', [curPos(1) curPos(2)+curPos(4)-80 curPos(3) 80]);
            
            % Add in progress bar
            this.progressBarAxis = axes('Parent', this.handle, 'Position', [.05 .7 .9 .2], 'Visible', 'off');
            this.progressBar = ProgressBar(this.progressBarAxis);
            
            this.messageBox = uicontrol('Parent', this.handle, 'Style', 'edit', 'Position', [10 10 curPos(3)-20 40], ...
                'String', '', 'HorizontalAlignment', 'left', 'Max', 2);
            
            set(this.handle, 'Units', currentUnits);
        end
        
        function createMenu(this)
            % createMenu Create and add a menu to the figure.
            %
            %    createMenu()
            
            % Add 'Open' menu to the menu bar with all detected parsers
            this.openFileMenu = uimenu(this.handle, 'Label', 'Open');
            [this.openFileMethods, openFileMethodNames] = getSubclasses('Parser', 0);
            
            for i = 1:length(openFileMethodNames)
                uimenu(this.openFileMenu, 'Label', openFileMethodNames{i}, ...
                    'Callback', @(src, evnt) this.openFile(this.openFileMethods{i}));
            end
            
            % Add 'Convert' menu to the menu bar with all detected
            % converters
            this.convertMenu = uimenu(this.handle, 'Label', 'Convert To Binary');
            [this.toBinaryConverterMethods, toBinaryConverterNames] = getSubclasses('ToBinaryConverter', 0);
            
            for i = 1:length(toBinaryConverterNames)
                uimenu(this.convertMenu, 'Label', toBinaryConverterNames{i}, ...
                    'Callback', @(src, evnt) this.convertToBinary(this.toBinaryConverterMethods{i}));
            end
            
            % Add in memory menu
            this.memoryMenu = uimenu(this.handle, 'Label', 'Memory');
            uimenu(this.memoryMenu, 'Label', 'Memory Usage', 'Callback', @(src, evnt) this.showDataListViewer());
            
            % TODO: Add in options menu
        end
        
        function sizeChanged(this)
            % sizeChanged Callback function for when figure size is changed.
            %
            %   sizeChanged()
            
            
            % Get the new position of the figure in pixels
            newPosition = Figure.getPositionInPixels(this.handle);
            
            margin = 10;
            
            progressBarHeight = 25;
            
            Figure.setObjectPositionInPixels(this.progressBarAxis, [margin, newPosition(4)-margin-progressBarHeight, newPosition(3)-margin*2, progressBarHeight]);
            
            Figure.setObjectPositionInPixels(this.messageBox, [margin, margin, newPosition(3)-margin*2, newPosition(4)-margin*3-progressBarHeight]);
        end
        
        
        function dataRepresentationSelected(this, dataRepresentation)
            % dataRepresentationSelected Callback when user has selected a dataRepresentation for the data to be loaded
            %
            %   dataRepresentationSelected(dataRepresentation)
            %       dataRepresentation - Instance of DataRepresentation that will be visualised
            
            notify(this, 'InfoMessage', MessageEventData('Data representation selected.'));
            
            addlistener(dataRepresentation, 'DataLoadProgress', @(src, evnt)this.progressBar.updateProgress(evnt));
        end
    end
    
    
end

