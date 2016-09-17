classdef NPLConfocalRamanTextExportToBinaryConverter < ToBinaryConverter
    properties (Constant)
        Name = 'NPL Confocal Exported to ASCII';
    end
    
    methods (Static)
        function filterSpec = getFilterSpec()
            filterSpec = {'*.txt', 'NPL Confocal Exported to ASCII (*.txt)'};
        end
    end
    
    methods
        function this = NPLConfocalRamanTextExportToBinaryConverter(oldFilename, newFilename)
            this = this@ToBinaryConverter(oldFilename, newFilename);
        end
        
        function convert(this)
            fid = fopen(this.oldFilename);
            line = fgets(fid);
            
            % Skip over the headers
            while(~isempty(strfind(line, '=')) && ~feof(fid))
                line = fgets(fid);
            end
            
            wavenumbers = str2double(strsplit(line, '\t'));
            wavenumbers(1) = [];
            
            startOfData = ftell(fid);
            
            ped = ProgressEventData(0, ['Determining number of spectra']);
            notify(this, 'ConversionProgress', ped);
            
            numLines = 1;
            fgetl(fid);
            
            while(~feof(fid))
                numLines = numLines + sum(fread(fid, 16384, 'char') == char(10));
                
                if(mod(numLines, 10) == 0)
                    ped = ProgressEventData(0, ['Determining number of spectra: ' num2str(numLines)]);
                    notify(this, 'ConversionProgress', ped);
                end
            end
            
            ped = ProgressEventData(0, ['Found ' num2str(numLines) ' spectra']);
            notify(this, 'ConversionProgress', ped);
            
            % Go back to the start of the data
            fseek(fid, startOfData, 'bof');
            
            intensities = zeros(numLines, length(wavenumbers));
            xy = zeros(numLines, 2);
            i = 1;
            
            while(~feof(fid))
                curLine = fgets(fid);

                % Faster implementation of the following:
                % lineVals = str2double(strsplit(curLine, '\t'));
                lineAsCell = strsplit(curLine, '\t'); 
                lineVals = reshape(sscanf(sprintf('%s#', lineAsCell{:}), '%g#'), size(lineAsCell));
                
                xy(i, :) = lineVals(2:-1:1);
                intensities(i, :) = lineVals(3:end);
                
                i = i + 1;
                
                ped = ProgressEventData(i/numLines, ['Reading data']);
                notify(this, 'ConversionProgress', ped);
            end
            
            fclose(fid);
            
            intensities(i:end, :) = [];
            xy(i:end, :) = [];
            
            
            pixelSize = xy(2, 1) - xy(1, 1)
            minX = min(xy(:, 1))
            minY = min(xy(:, 2))
            
            xyNorm = [round((xy(:, 1) - minX) / pixelSize) round((xy(:, 2) - minY) / pixelSize)] + 1;
            
            
            width = max(xyNorm(:, 1))
            height = max(xyNorm(:, 2))
            %             numSpectralChannels = length(wavenumbers);
            %             laserWavelength = str2double(fileDetails{4})
            
            this.setPixelInformation(width, height, 1, ToBinaryConverter.SpectrumWise);
            
            spectralChannels = wavenumbers;
            
            this.setFileStorageType(ToBinaryConverter.Processed, spectralChannels);
            
            for i = 1:size(intensities, 1)
                this.writeSpectrum(intensities(i, :));
                
                ped = ProgressEventData(i/size(intensities, 1), ['Converting to SAB']);
                notify(this, 'ConversionProgress', ped);
            end
            
            this.close();
        end
    end
end