classdef RegionOfInterestInfoFigure < Figure
    
    properties (Access = private)
        roiList;
        imageList;
        
        imageTitle;
        imageListSelection;
        allDataButton;
        imageDisplay;
        roiPlot;
        regionOfInterestTable;
        
        previousPath;
        
        copyToClipboardButton;
        exportButton;
    end
    
    methods
        function this = RegionOfInterestInfoFigure(roiList, imageList)
            this.roiList = roiList;
            this.imageList = imageList;
            
            this.setTitle('Region of Interest Details');
            this.updateList();
        end
        
        function updateList(this)
            set(this.imageListSelection, 'String', {this.imageList.description});
            
            this.imageDisplay.removeAllRegionsOfInterest();
            
            for i = 1:this.roiList.getSize()
                roi = this.roiList.get(i);
                
                this.imageDisplay.addRegionOfInterest(roi);
            end
        end
        
        function selectImageIndex(this, index)
            set(this.imageListSelection, 'Value', index);
            this.imageSelected([], []);
        end
        
        function viewAllData(this)
            RegionOfInterestAllInfoFigure(this.roiList, this.imageList);
        end
        
        function copyToClipboard(this)
            this.setVisibilityForControls('off');
            print -clipboard -dmeta
            this.setVisibilityForControls('on');
        end
        
        function export(this)
            selectedValue = get(this.imageListSelection, 'Value');
            selectedImage = this.imageList(selectedValue);
            
            [filename, path, filter] = uiputfile({'*.csv', 'CSV File'}, 'Export to CSV', [this.previousPath filesep selectedImage.description '.csv']);
            
            if(filter > 0)
                this.previousPath = path;
                location = [path filesep filename];
                
                [fid, errmsg] = fopen(location, 'w');
                
                if(fid < 0)
                    errordlg(errmsg, 'Could not export to CSV');
                else
                    fprintf(fid, 'ROI, Mean, SD, #Pixels, Max, Min\n');

                    for i = 1:this.roiList.getSize()
                        roi = this.roiList.get(i);

                        fprintf(fid, '%s,%f,%f,%d,%f,%f\n', roi.getName(), ...
                            mean(selectedImage.imageData(roi.pixelSelection)), ...
                            std(selectedImage.imageData(roi.pixelSelection)), ...
                            sum(roi.pixelSelection(:)), ...
                            max(selectedImage.imageData(roi.pixelSelection)), ...
                            min(selectedImage.imageData(roi.pixelSelection)));
                    end

                    fclose(fid);
                end
            end
        end
    end
    
    methods (Access = protected)
        function setVisibilityForControls(this, visibility)
            set(this.imageListSelection, 'Visible', visibility);
            set(this.allDataButton, 'Visible', visibility);
            set(this.copyToClipboardButton, 'Visible', visibility);
            set(this.exportButton, 'Visible', visibility);
            
            if(strcmp(visibility, 'on'))
                opposite = 'off';
            else
                opposite = 'on';
            end                
            
            set(this.imageTitle, 'Visible', opposite);
        end
        
        function imageSelected(this, source, event)
            selectedImageIndex = get(this.imageListSelection, 'Value');
            selectedImage = this.imageList(selectedImageIndex);
            
            set(this.imageTitle, 'String', selectedImage.getDescription());
            this.imageDisplay.setData(selectedImage);
            
            tableData = {};
            
            colourTable = [];
            
            axes(this.roiPlot);
            
            for i = 1:this.roiList.getSize()
                roi = this.roiList.get(i);
                
                colour = [roi.getColour().r roi.getColour().g roi.getColour().b];
                
                if(i == 2) 
                    hold on;
                end
                bar(i, mean(selectedImage.imageData(roi.pixelSelection)), 'FaceColor', colour ./ 255);
                
                tableData{i, 1} = ['<HTML><font color="' roi.getColour().toHex() '">' roi.getName() '</font></HTML>' ];%roi.name;
                tableData{i, 2} = mean(selectedImage.imageData(roi.pixelSelection));
                tableData{i, 3} = std(selectedImage.imageData(roi.pixelSelection));
                tableData{i, 4} = sum(roi.pixelSelection(:));
                tableData{i, 5} = max(selectedImage.imageData(roi.pixelSelection));
                tableData{i, 6} = min(selectedImage.imageData(roi.pixelSelection));
            end
            assignin('base', 'tableData', tableData);
            set(this.regionOfInterestTable, 'Data', tableData);
                        
            errorbar(1:this.roiList.getSize(), [tableData{:, 2}], [tableData{:, 3}], '.');
            set(gca, 'XTickLabel', '') 
            
            hold off;
        end
        
        function createFigure(this)
            % createFigure Create figure.
            %
            %   createFigure()
            
            createFigure@Figure(this);
            
            columnNames = {'ROI', 'Mean', 'SD', '# Pixels', 'Max', 'Min'};
            columnFormat = {'char', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric'};
            columnEditable = [false, false, false, false, false, false];
            
            this.imageTitle = uicontrol('Parent', this.handle, 'Style', 'text', ...
                'String', {''}, 'Units', 'normalized', 'Position', [0.05, 0.9, 0.7, 0.05], 'BackgroundColor', [1 1 1], 'Visible', 'off');
            
            this.imageListSelection = uicontrol('Parent', this.handle, 'Style', 'popup', ...
                'String', {''}, 'Units', 'normalized', 'Position', [0.05, 0.85, 0.7, 0.1], 'Callback', @(src, event) this.imageSelected(src, event));
            
            this.allDataButton = uicontrol('Parent', this.handle, ...
                'String', 'View all data', 'Units', 'normalized', 'Position', [0.75, 0.9, 0.2, 0.05], 'Callback', @(src, event) this.viewAllData());
            
            this.imageDisplay = ImageDisplay(this, Image(1));
            set(this.imageDisplay.axisHandle, 'Position', [0.05, 0.5, 0.4, 0.35]);
            
            this.roiPlot = axes(this.handle, 'Units', 'normalized', 'Position', [0.525, 0.525, 0.425, 0.325]);
            
            this.regionOfInterestTable = uitable('Parent', this.handle, ...
                    'ColumnName', columnNames, 'ColumnFormat', columnFormat, 'ColumnEditable', columnEditable, ...
                    'RowName', [], 'Units', 'normalized', 'Position', [0.05 0.15 0.9 0.3]);
                
            this.copyToClipboardButton = uicontrol('Parent', this.handle, ...
                'String', 'Copy to clipboard', 'Units', 'normalized', 'Position', [0.05, 0.05, 0.2, 0.05], 'Callback', @(src, event) this.copyToClipboard());    
            this.exportButton = uicontrol('Parent', this.handle, ...
                'String', 'Export', 'Units', 'normalized', 'Position', [0.75, 0.05, 0.2, 0.05], 'Callback', @(src, event) this.export());    
        end
    end
end