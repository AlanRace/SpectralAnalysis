classdef SIMSParser < Parser

    properties (Constant)
        Name = 'SIMS';
    end
    
    properties (SetAccess = private)
        simsParser;
    end
    
    methods (Static) 
        function filterSpec = getFilterSpec() 
            filterSpec = {'*.grd', 'GRD (*.grd)'; '*.tofs', 'TOFS (*.tofs)'};
        end
    end
    
    methods
        function obj = SIMSParser(filename)
            obj.filename = filename;
            
            % Check that the filename ends in .grd or .tofs
            [pathstr,name,ext] = fileparts(filename);
            
            if(~strcmpi(ext, '.tofs') && ~strcmpi(ext, '.grd'))
                exception = MException('SIMSParser:FailedToParse', ...
                    ['Must supply either a GRD (*.grd) or a TOFS (*tofs) file']);
                throw(exception);
            end

            % Need to be sure that imzMLConverter.jar has been added to the
            % path prior to using this class
            try
                addJARsToClassPath();
            catch err
                if(strcmp(err.identifier, 'addJARsToClassPath:FailedToAddJAR'))
                    exception = MException('SIMSParser:FailedToParse', ...
                        ['Failed to add JAR file ''' 'imzMLConverter/imzMLConverter.jar' ''', please ensure that it exists. It can be downloaded from www.imzMLConverter.co.uk']);
                    throw(exception);
                else
                    rethrow(err);
                end
            end
        end
        
        
        function parse(obj)
            % Parse the imzML 
            notify(obj, 'ParsingStarted');
%             obj.simsParser = com.alanmrace.JSpectralAnalysis.io.SIMSParser(obj.filename);
            obj.simsParser = com.alanmrace.JSIMS.SIMSParser(obj.filename);
            obj.simsParser.parse();
            notify(obj, 'ParsingComplete');

            obj.width = obj.simsParser.getWidth();
            obj.height = obj.simsParser.getHeight();
            obj.depth = 1;

        end
        
        function [spectralChannels, intensities] = getSpectrum(obj, x, y, z)
            spectrum = obj.simsParser.getSpectrum(x, y, z);
            
            if(isempty(spectrum))
                spectralChannels = [];
                intensities = [];
                
                return;
            end
            
            spectralChannels = spectrum.getSpectralChannels();
            intensities = spectrum.getIntensities();
        end
        
        function imageList = getImages(obj, spectralChannelList, channelWidthList)
            images = obj.simsParser.generateImages(spectralChannelList, channelWidthList);
            'hi'
            for i = 1:length(spectralChannelList)
                imageList(i) = Image(images(i).getImage());
            end
        end
        
        function image = getImage(obj, spectralChannel, channelWidth)
            %image = zeros(obj.height, obj.width);
            
            image = obj.simsParser.generateImage(spectralChannel, channelWidth, []).getImage();
            
%             warning('TODO: Check if the imzML is continuous, if so generating ion images can be made faster');
            
%             for y = 1:obj.height
%                 for x = 1:obj.width
%                     [spectralChannels, intensities] = obj.getSpectrum(x, y);
%                     
%                     indicies = spectralChannels >= (spectralChannel-channelWidth) & spectralChannels <= (spectralChannel + channelWidth);
%                     
%                     image(y, x) = sum(intensities(indicies));
%                     
%                 end
%                 
%                 ped = ProgressEventData(y / obj.height, ['Generating ' num2str(spectralChannel) ' +/- ' num2str(channelWidth)]);
%                 notify(obj, 'DataLoadProgress', ped);
%             end
            
            image = Image(image);
        end

        function image = getOverviewImage(obj)
            tic;
            image = Image(obj.simsParser.getOverviewImage().getImage());
            toc;
        end
        
        function spectrum = getOverviewSpectrum(obj)
            spectrum = SpectralData(obj.simsParser.getOverviewSpectrum().getSpectralChannels(), obj.simsParser.getOverviewSpectrum().getIntensities());
            
            spectrum.setDescription('Total Spectrum');
        end
        
        % For faster access to data, determine wether the data is stored by
        % spectrum or by image
%         function bool = isSpectrumOrientated(obj)
%             bool = 1;
%         end
%         
%         function bool = isImageOrientated(obj)
%             bool = 0;
%         end
%         
%         function bool = isProjectedData(obj)
%             bool = 0;
%         end
%         
%         function bool = isSparseData(obj)
%             bool = 0;
%         end
    end
end