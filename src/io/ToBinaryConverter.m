classdef ToBinaryConverter < Converter

    properties (Abstract, Constant)
        Name;
    end
    
    properties (Access = public, Constant)
        SpectrumWise = 1;
        ImageWise = 2;
        
        Processed = 1;
        Continuous = 2;
    end
    
    properties (Access = protected)
        oldFilename;
        newFilename;
        fileID;
        
        width;
        height;
        depth;
        dataOrientation;
        
        pixelInfoWritten = 0;
        fileStorageType = 0;
    end
    
    properties (Constant)
        version = 0.1;
    end
    
    events
        ParsingStarted;
        ParsingComplete;
        ConversionStarted;
        ConversionProgress;
        ConversionComplete;
    end
    
    methods (Static, Abstract)
        % Get the filter spec(s) for this converter as required by uigetfile
        filterSpec = getFilterSpec(obj);
    end
    
    methods
        function this = ToBinaryConverter(oldFilename, newFilename)
            this.oldFilename = oldFilename;
            this.newFilename = newFilename;
            this.fileID = fopen(this.newFilename, 'w');
        end
        
        function setPixelInformation(this, width, height, depth, dataOrientation) 
            this.fileStorageType = 0;
            
            this.width = width;
            this.height = height;
            this.depth = depth;
            this.dataOrientation = dataOrientation;
            
            fseek(this.fileID, 0, 'bof');
            fwrite(this.fileID, this.version, 'single');
            fwrite(this.fileID, this.width, 'uint32');
            fwrite(this.fileID, this.height, 'uint32');
            fwrite(this.fileID, this.depth, 'uint32');
            fwrite(this.fileID, this.dataOrientation, 'uint32');
            
            this.pixelInfoWritten = 1;
        end

        function setFileStorageType(this, fileStorageType, varargin)
            if(this.pixelInfoWritten ~= 1)
                exception = MException('ToBinaryConverter:NoPixelInfoWritten', ...
                    ['Ensure that pixel information is written first by calling setPixelInformation']);
                throw(exception);
            end
            
            fwrite(this.fileID, fileStorageType, 'uint32');
            
            if(fileStorageType == ToBinaryConverter.Processed)
                narginchk(3, 3);
                
                fwrite(this.fileID, length(varargin{1}), 'uint32');
                fwrite(this.fileID, varargin{1}, 'double');
            elseif(fileStorageType == ToBinaryConverter.Continuous)
                fwrite(this.fileID, zeros(1, this.width * this.height), 'uint64');
            else
                exception = MException('ToBinaryConverter:InvalidFileStorageType', ...
                    ['Invalid storage type selected']);
                throw(exception);
            end 
            
            this.fileStorageType = fileStorageType;
        end
        
        function writeSpectrum(this, varargin)
            if(this.fileStorageType == 0)
                exception = MException('ToBinaryConverter:NoFileStorageTypeSelected', ...
                    ['Ensure that file storage type has been selected by calling setFileStorageType']);
                throw(exception);
            end
            
            if(this.fileStorageType == ToBinaryConverter.Processed)
                fwrite(this.fileID, varargin{1}, 'double');
            end
        end
        
        function close(this) 
            fclose(this.fileID);
        end
    end
end
