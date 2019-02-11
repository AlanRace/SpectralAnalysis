classdef WITecTextExportParser < Parser
    properties (Constant)
        Name = 'WITec Text Export';
    end
    
    methods (Static) 
        function filterSpec = getFilterSpec() 
            filterSpec = {'*.txt', 'WITec Exported to ASCII (*.txt)'};
        end
    end
    
    properties (Access = private)
        headerFilename;
        xDataFilename;
        yDataFilename;
        
        yAxisFileID;
    end
    
    properties (SetAccess = private)
        spectralChannels;
    end
    
    methods
        function this = WITecTextExportParser(filename)
            this.filename = filename;
            
            % Check if the header file has been selected
            headerLocation = strfind(filename, '(Header)');
            
            if(isempty(headerLocation))
                % Now check if X-Axis has been selected
                xAxisLocation = strfind(filename, '(X-Axis)');
                
                if(isempty(xAxisLocation))
                    % Finally check if Y-Axis has been selected
                    yAxisLocation = strfind(filename, '(Y-Axis)');
                    
                    if(isempty(yAxisLocation))
                        exception = MException('WITecTextExportParser:InvalidFile', ...
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
                exception = MException('WITecTextExportParser:InvalidFile', ...
                    'Could not find the ''Header'' file');
                throw(exception);
            end
            
            if(exist(this.xDataFilename, 'file') ~= 2)
                exception = MException('WITecTextExportParser:InvalidFile', ...
                    'Could not find the ''X-Axis'' file');
                throw(exception);
            end
            
            if(exist(this.yDataFilename, 'file') ~= 2)
                exception = MException('WITecTextExportParser:InvalidFile', ...
                    'Could not find the ''Y-Axis'' file');
                throw(exception);
            end
        end
        
        
        function parse(this)
            % Display a message to the user that parsing has started
            notify(this, 'ParsingStarted');
            
            fileID = fopen(this.headerFilename, 'r');
            
            currentLine = fgetl(fileID);
            while ischar(currentLine)
                sizeXLocation = strfind(currentLine, 'SizeX = ');
                sizeYLocation = strfind(currentLine, 'SizeY = ');
                sizeGraphLocation = strfind(currentLine, 'SizeGraph = ');
                
                if(~isempty(sizeXLocation))
                    this.width = str2num(currentLine(length('SizeX = '):end));
                end
                
                if(~isempty(sizeYLocation))
                    this.height = str2num(currentLine(length('SizeY = '):end));
                end
                
                if(~isempty(sizeGraphLocation))
                    this.numSpectralChannels = str2num(currentLine(length('SizeGraph = '):end));
                end
                
                currentLine = fgetl(fileID);
            end
            
            fclose(fileID);
            
            % Close the message and notify the user that parsing is complete
            notify(this, 'ParsingComplete');
        end
        
        function spectrum = getSpectrum(this, x, y)
            % TODO: Read in the data for the spectrum at location (x, y). If one doesn't exist then set spectralChannels and intensities to be empty
            
            % Since spectral channels are stored in a separate file makes
            % sense to only load them once
            if(isempty(this.spectralChannels))
                this.spectralChannels = zeros(this.numSpectralChannels, 1);
                
                fileID = fopen(this.xDataFilename, 'r');
                
                for i = 1:this.numSpectralChannels
                    currentLine = fgetl(fileID);
                    this.spectralChannels(i) = str2double(currentLine);
                end
                
                fclose(fileID);
            end
            
            pixelNum = (y-1)*this.width + (x-1);
            
            charactersPerLine = 14;
            
            spectrumStart = pixelNum * this.numSpectralChannels * charactersPerLine;
            
            intensities = zeros(this.numSpectralChannels, 1);
            
            if(isempty(this.yAxisFileID))
                this.yAxisFileID = fopen(this.yDataFilename, 'r');
            end
                
            fseek(this.yAxisFileID, spectrumStart, 'bof');
            
            for i = 1:this.numSpectralChannels
                currentLine = fgetl(this.yAxisFileID);
                intensities(i) = str2double(currentLine);
            end
            
%             fclose(fileID);
            
            spectralChannels = this.spectralChannels;
            
            spectrum = SpectralData(spectralChannels, intensities);
        end
        
        function delete(this)
            if(~isempty(this.yAxisFileID))
                fclose(this.yAxisFileID);
            end
        end
        
        function image = getOverviewImage(this)
            imageData = zeros(this.height, this.width);        
        
            % TODO: Create an image that describes the dataset. This is displayed in the `Select Data Representation' interface when loading a dataset
            
            image = Image(imageData);
        end        
    end
end