classdef DataListViewer < Figure
    % DataListViewer GUI for visualising loaded data in the form of
    % instances of DataViewer in a DataViewerList
    
    properties (Access = protected)
        % UI listbox to display instances of DataViewer
        listBox
        % UI button for closing selected instances of DataViewer
        closeDataButton
        
        % Instance of DataViewerList to visualise
        dataViewerList
    end
    
    events
        % Triggered when 'Close Data' button is selected
        CloseData
                
        % Triggered when the DataListViewer interface is closed
        DataListViewerClosed
    end
    
    methods
        function this = DataListViewer(dataViewerList)
            % DataListViewer Create and display interface for SpectralAnalysis.
            %
            %   SpectralAnalysisInterface(dataViewerList)
            %       dataViewerList - Instance of DataViewerList to visualise

            this.dataViewerList = dataViewerList;
            this.updateDataList();

            this.setTitle('Memory Usage');
            
            addlistener(dataViewerList, 'ListChanged', @(src, evnt) this.updateDataList());
        end
                
        function updateDataList(this)
            % updateDataList Update the displayed data list.
            %
            %   updateDataList()
            
            % Can occur when the DatalistViewer is closed by the
            % SpectralAnalysisInterface, so just check object still valid
            if(~isvalid(this))
                return;
            end
            
            itemList = {};
            
            if(isvalid(this.dataViewerList))
                dataViewers = this.dataViewerList.getObjects();

                for i = 1:numel(dataViewers)
                    dataRepresentation = dataViewers{i}.dataRepresentation;

                    itemList{end+1} = ['(' DataListViewer.numBytesToHumanReadable(dataRepresentation.getEstimatedSizeInBytes()) ...
                        ') ' dataRepresentation.name];
                end
            end
            
            set(this.listBox, 'String', itemList);
        end
    end
    
    methods (Access = protected)
        function createFigure(this)
            % createFigure Create figure.
            %
            %   createFigure()
            
            createFigure@Figure(this);
            
            this.listBox = uicontrol(this.figureHandle, 'Style', 'listbox', 'Units', 'Pixels', ...
                'Position', [10 10 450 100]);
            
            this.closeDataButton = uicontrol(this.figureHandle, 'Units', 'Pixels', ...
                'Position', [470 90 60 20], 'String', 'Close Data');
        end
    end
    
    methods (Static)
        function humanReadable = numBytesToHumanReadable(numBytes)
            % numBytesToHumanReadable Convert a number of bytes to a human readable form.
            %
            %   humanReadable = numBytesToHumanReadable(numBytes)
            %       numBytes      - Number of bytes (integer or floating point)
            %       humanReadable - String representation of numBytes rounded to 2 decimal places
            
            if(numBytes > 2^30)
                humanReadable = [num2str(numBytes / 2^30, '% 10.2f') ' GB'];
            elseif(numBytes > 2^20)
                humanReadable = [num2str(numBytes / 2^20, '% 10.2f') ' MB'];
            elseif(numBytes > 2^10)
                humanReadable = [num2str(numBytes / 2^10, '% 10.2f') ' kB'];
            else
                humanReadable = [num2str(numBytes, '% 10.2f') ' B'];
            end
        end
    end
end