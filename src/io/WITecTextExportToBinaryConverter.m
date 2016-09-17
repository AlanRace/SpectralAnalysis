classdef WITecTextExportToBinaryConverter < ToBinaryConverter
    properties (Constant)
        Name = 'WITec Exported to ASCII';
    end
    
    properties (Access = protected)
        headerFilename;
        xDataFilename;
        yDataFilename;
    end
    
    methods (Static) 
        function filterSpec = getFilterSpec() 
            filterSpec = {'*.txt', 'WITec Exported to ASCII (*.txt)'};
        end
    end
    
    methods
        function this = WITecTextExportToBinaryConverter(oldFilename, newFilename)
            this = this@ToBinaryConverter(oldFilename, newFilename);
            
            filename = oldFilename;
            
            % Check if the header file has been selected
            headerLocation = strfind(filename, '(Header)');
            
            if(isempty(headerLocation))
                % Now check if X-Axis has been selected
                xAxisLocation = strfind(filename, '(X-Axis)');
                
                if(isempty(xAxisLocation))
                    % Finally check if Y-Axis has been selected
                    yAxisLocation = strfind(filename, '(Y-Axis)');
                    filename
                    if(isempty(yAxisLocation))
                        exception = MException('WITecTextExportToBinaryConverter:InvalidFile', ...
                            'Requires 3 files exported from WITec Project (Header, X-Axis and Y-Axis)');
                        throw(exception);
                    else
                        filenameStart = filename(1:yAxisLocation-1);
                    end
                else
                    filenameStart = filename(1:xAxisLocation-1);
                end
            else
                filenameStart = filename(1:headerLocation-1);
            end
            
            this.headerFilename = [filenameStart '(Header).txt'];
            this.xDataFilename = [filenameStart '(X-Axis).txt'];
            this.yDataFilename = [filenameStart '(Y-Axis).txt'];
            
            % Check that all the required files exist
            if(exist(this.headerFilename, 'file') ~= 2)
                exception = MException('WITecTextExportToBinaryConverter:InvalidFile', ...
                    'Could not find the ''Header'' file');
                throw(exception);
            end
            
            if(exist(this.xDataFilename, 'file') ~= 2)
                exception = MException('WITecTextExportToBinaryConverter:InvalidFile', ...
                    'Could not find the ''X-Axis'' file');
                throw(exception);
            end
            
            if(exist(this.yDataFilename, 'file') ~= 2)
                exception = MException('WITecTextExportToBinaryConverter:InvalidFile', ...
                    'Could not find the ''Y-Axis'' file');
                throw(exception);
            end
        end
        
        function convert(this)
            % Display a message to the user that parsing has started
            notify(this, 'ParsingStarted');
            
            fileID = fopen(this.headerFilename, 'r');
            
            currentLine = fgetl(fileID);
            while ischar(currentLine)
                sizeXLocation = strfind(currentLine, 'SizeX = ');
                sizeYLocation = strfind(currentLine, 'SizeY = ');
                sizeGraphLocation = strfind(currentLine, 'SizeGraph = ');
                
                if(~isempty(sizeXLocation))
                    width = str2num(currentLine(length('SizeX = '):end));
                end
                
                if(~isempty(sizeYLocation))
                    height = str2num(currentLine(length('SizeY = '):end));
                end
                
                if(~isempty(sizeGraphLocation))
                    numSpectralChannels = str2num(currentLine(length('SizeGraph = '):end));
                end
                
                currentLine = fgetl(fileID);
            end
            
            fclose(fileID);
            
            % Close the message and notify the user that parsing is complete
            notify(this, 'ParsingComplete');
            
            this.setPixelInformation(width, height, 1, ToBinaryConverter.SpectrumWise);
            
            spectralChannels = zeros(numSpectralChannels, 1);
            
            notify(this, 'ConversionStarted');
            fileID = fopen(this.xDataFilename, 'r');
            
            for i = 1:numSpectralChannels
                currentLine = fgetl(fileID);
                spectralChannels(i) = str2double(currentLine);
            end
            
            fclose(fileID);
                
            this.setFileStorageType(ToBinaryConverter.Processed, spectralChannels);
            
            fileID = fopen(this.yDataFilename, 'r');
            
            currentPixel = 1;
            maxPixels = width * height;
            
            while ~feof(fileID)
                intensities = zeros(numSpectralChannels, 1);
                
                for i = 1:numSpectralChannels
                    currentLine = fgetl(fileID);
                    intensities(i) = str2double(currentLine);
                end
                
                this.writeSpectrum(intensities);
                
                ped = ProgressEventData(currentPixel / maxPixels, ['Converting ' strrep(this.oldFilename, '\', '\\')]);
                notify(this, 'ConversionProgress', ped);
                
                currentPixel = currentPixel + 1;
            end
            
            this.close();
            
            notify(this, 'ConversionComplete');
        end
    end
end