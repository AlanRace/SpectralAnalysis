classdef SpectralAnalysisBinaryParser < Parser
    properties (Constant)
        Name = 'SpectralAnalysis Binary';
    end
    
    methods (Static) 
        function filterSpec = getFilterSpec() 
            filterSpec = {'*.sab', 'SpectralAnalysis Binary (*.sab)'};
        end
    end
        
    properties (SetAccess = private)
        dataOrientation;
        fileStorageType;
        
        spectralChannels;
        
        dataStartLocation;
    end
    
    methods
        function this = SpectralAnalysisBinaryParser(filename)
            this.filename = filename;
            
            % Check that all the required files exist
            if(exist(this.filename, 'file') ~= 2)
                exception = MException('SpectralAnalysisBinary:InvalidFile', ...
                    ['Could not find the file ' this.filename]);
                throw(exception);
            end
        end
        
        
        function parse(this)
            % Display a message to the user that parsing has started
            notify(this, 'ParsingStarted');
            
            fileID = fopen(this.filename, 'r');
            
            version = fread(fileID, 1, 'single');
            this.width = fread(fileID, 1, 'uint32');
            this.height = fread(fileID, 1, 'uint32');
            this.depth = fread(fileID, 1, 'uint32');
            
            this.dataOrientation = fread(fileID, 1, 'uint32');
            this.fileStorageType = fread(fileID, 1, 'uint32');
            
            this.numSpectralChannels = fread(fileID, 1, 'uint32')
            this.spectralChannels = fread(fileID, this.numSpectralChannels, 'double');
            
            this.dataStartLocation = ftell(fileID);
            
            fclose(fileID);
            
            % Close the message and notify the user that parsing is complete
            notify(this, 'ParsingComplete');
        end
        
        function spectrum = getSpectrum(this, x, y, z)
            % TODO: Read in the data for the spectrum at location (x, y). If one doesn't exist then set spectralChannels and intensities to be empty
            
            pixelNum = (y-1)*this.width + (x-1);
            
%             intensities = zeros(this.numSpectralChannels, 1);
            
            fileID = fopen(this.filename, 'r');
            
            fseek(fileID, this.dataStartLocation + (pixelNum*8*this.numSpectralChannels), 'bof');
            
            intensities = fread(fileID, this.numSpectralChannels, 'double');
            
            fclose(fileID);
            
            spectralChannels = this.spectralChannels;
            
            spectrum = SpectralData(spectralChannels, intensities);
        end
        
        function image = getOverviewImage(this)
            imageData = zeros(this.height, this.width);        
        
            % TODO: Create an image that describes the dataset. This is displayed in the `Select Data Representation' interface when loading a dataset
            
            image = Image(imageData);
        end        
    end
end
