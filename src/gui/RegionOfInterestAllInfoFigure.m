classdef RegionOfInterestAllInfoFigure < Figure
    
    properties (Access = private)
        roiList;
        imageList;
        
        regionOfInterestTable;
        exportButton;
        previousPath;
    end
    
    methods
        function this = RegionOfInterestAllInfoFigure(roiList, imageList)
            this.roiList = roiList;
            this.imageList = imageList;
            
            this.setTitle('All Region of Interest Details');
            
            this.updateData();
        end
        
        function updateData(this)
            index = 1;
            
            tableData = {};
            
            for j = 1:length(this.imageList)
                image = this.imageList(j);
                
                for i = 1:this.roiList.getSize()
                    roi = this.roiList.get(i);

                    tableData{index, 1} = image.description;
                    tableData{index, 2} = ['<HTML><font color="' roi.getColour().toHex() '">' roi.getName() '</font></HTML>' ];%roi.name;
                    tableData{index, 3} = mean(image.imageData(roi.pixelSelection));
                    tableData{index, 4} = std(image.imageData(roi.pixelSelection));
                    tableData{index, 5} = sum(roi.pixelSelection(:));
                    tableData{index, 6} = max(image.imageData(roi.pixelSelection));
                    tableData{index, 7} = min(image.imageData(roi.pixelSelection));
                    
                    index = index + 1;
                end
            end
            
            set(this.regionOfInterestTable, 'Data', tableData);
        end
        
        function export(this)
            [filename, path, filter] = uiputfile({'*.csv', 'CSV File'}, 'Export to CSV', [this.previousPath filesep 'ROIDetails.csv']);
            
            if(filter > 0)
                this.previousPath = path;
                location = [path filesep filename];
                
                [fid, errmsg] = fopen(location, 'w');
                
                if(fid < 0)
                    errordlg(errmsg, 'Could not export to CSV');
                else
                    fprintf(fid, 'm/z, ROI, Mean, SD, #Pixels, Max, Min\n');

                    for j = 1:length(this.imageList)
                        selectedImage = this.imageList(j);
                        
                        for i = 1:this.roiList.getSize()
                            roi = this.roiList.get(i);

                            fprintf(fid, '%s,%s,%f,%f,%d,%f,%f\n', selectedImage.description, roi.getName(), ...
                                mean(selectedImage.imageData(roi.pixelSelection)), ...
                                std(selectedImage.imageData(roi.pixelSelection)), ...
                                sum(roi.pixelSelection(:)), ...
                                max(selectedImage.imageData(roi.pixelSelection)), ...
                                min(selectedImage.imageData(roi.pixelSelection)));
                        end
                    end

                    fclose(fid);
                end
            end
        end
    end
        
    methods (Access = protected)        
        function createFigure(this)
            % createFigure Create figure.
            %
            %   createFigure()
            
            createFigure@Figure(this);
            
            columnNames = {'m/z', 'ROI', 'Mean', 'SD', '# Pixels', 'Max', 'Min'};
            columnFormat = {'numeric', 'char', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric'};
            columnEditable = [false, false, false, false, false, false, false];
            
            this.regionOfInterestTable = uitable('Parent', this.handle, ...
                    'ColumnName', columnNames, 'ColumnFormat', columnFormat, 'ColumnEditable', columnEditable, ...
                    'RowName', [], 'Units', 'normalized', 'Position', [0.05 0.15 0.9 0.8]);
            this.exportButton = uicontrol('Parent', this.handle, ...
                'String', 'Export', 'Units', 'normalized', 'Position', [0.75, 0.05, 0.2, 0.05], 'Callback', @(src, event) this.export());    
        end
    end
end