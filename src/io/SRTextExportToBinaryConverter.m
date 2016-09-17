classdef SRTextExportToBinaryConverter < ToBinaryConverter
    properties (Constant)
        Name = 'SR Exported to ASCII';
    end
    
    methods (Static) 
        function filterSpec = getFilterSpec() 
            filterSpec = {'*.txt', 'SR Exported to ASCII (*.txt)'};
        end
    end
    
    methods
        function this = SRTextExportToBinaryConverter(oldFilename, newFilename)
            this = this@ToBinaryConverter(oldFilename, newFilename);
        end
        
        function convert(this)
            fileID = fopen(this.oldFilename, 'r');
            
            currentLine = fgetl(fileID);
            
            fileDetails = strsplit(currentLine, '\t');
            width = str2num(fileDetails{1});
            height = str2num(fileDetails{2});
            numSpectralChannels = str2num(fileDetails{3});
            laserWavelength = str2double(fileDetails{4})
            
            this.setPixelInformation(width, height, 1, ToBinaryConverter.SpectrumWise);
            
            currentLine = fgetl(fileID);
            spectralChannels = (1./laserWavelength - 1./str2double(strsplit(currentLine, '\t'))) * 1e7;
            
            this.setFileStorageType(ToBinaryConverter.Processed, spectralChannels);
            
            while ~feof(fileID)
                currentLine = fgetl(fileID);
                intensities = str2double(strsplit(currentLine, '\t'));
                
                this.writeSpectrum(intensities);
            end
            
            this.close();
        end
    end
end