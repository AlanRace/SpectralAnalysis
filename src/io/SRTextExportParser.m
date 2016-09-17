classdef SRTextExportParser < Parser
    properties (Constant)
        Name = 'SR Text Export';
    end
    
    methods (Static) 
        function filterSpec = getFilterSpec() 
            filterSpec = {'*.txt', 'SR Exported to ASCII (*.txt)'};
        end
    end
        
    properties (SetAccess = private)
        spectralChannels;
    end
    
    methods
        function this = SRTextExportParser(filename)
            this.filename = filename;
            
            % Check that all the required files exist
            if(exist(this.filename, 'file') ~= 2)
                exception = MException('SRTextExportParser:InvalidFile', ...
                    ['Could not find the file ' this.filename]);
                throw(exception);
            end
        end
        
        
        function parse(this)
            % Display a message to the user that parsing has started
            notify(this, 'ParsingStarted');
            
            fileID = fopen(this.filename, 'r');
            
            currentLine = fgetl(fileID);
            fileDetails = strsplit(currentLine, '\t');
            this.width = str2num(fileDetails{1});
            this.height = str2num(fileDetails{2});
            this.numSpectralChannels = str2num(fileDetails{3});
            
            currentLine = fgetl(fileID);
            this.spectralChannels = str2double(strsplit(currentLine, '\t'));
            
            fclose(fileID);
            
            % Close the message and notify the user that parsing is complete
            notify(this, 'ParsingComplete');
        end
        
        function [spectralChannels, intensities] = getSpectrum(this, x, y, z)
            % TODO: Read in the data for the spectrum at location (x, y). If one doesn't exist then set spectralChannels and intensities to be empty
            
            pixelNum = (y-1)*this.width + (x-1);
            
            intensities = zeros(this.numSpectralChannels, 1);
            
            fileID = fopen(this.filename, 'r');
                
            for i = 1:pixelNum+2
                fgetl(fileID);
            end
            
            currentLine = fgetl(fileID);
            intensities = str2double(strsplit(currentLine, '\t'));
            
            fclose(fileID);
            
            spectralChannels = this.spectralChannels;
        end
        
        function image = getOverviewImage(this)
            imageData = zeros(this.height, this.width);        
        
            % TODO: Create an image that describes the dataset. This is displayed in the `Select Data Representation' interface when loading a dataset
            
            image = Image(imageData);
        end        
    end
end
