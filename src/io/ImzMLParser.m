classdef ImzMLParser < Parser

    properties (Constant)
        Name = 'ImzML';
    end
    
    properties (SetAccess = private)
        imzML;
    end
    
    properties (Access = private)
        % If the imzML file is continuous then we don't need to constantly
        % read in the spectral channels list, we can just read it in once 
        isContinuous;
        spectralChannels;
    end
    
    methods (Static) 
        function filterSpec = getFilterSpec() 
            filterSpec = {'*.imzML', 'Mass Spectrometry Imaging (*.imzML)'};
        end
    end
    
    methods
        function obj = ImzMLParser(filename)
            obj.filename = filename;
            
            % Check that the filename ends in imzML
            [pathstr,name,ext] = fileparts(filename);
            
            if(~strcmpi(ext, '.imzML'))
                exception = MException('ImzMLParser:FailedToParse', ...
                    'Must supply an imzML file (*.imzML)');
                throw(exception);
            end

            % Need to be sure that imzMLConverter.jar has been added to the
            % path prior to using this class
            try
                addJARsToClassPath();
            catch err
                if(strcmp(err.identifier, 'addJARsToClassPath:FailedToAddJAR'))
                    exception = MException('ImzMLParser:FailedToParse', ...
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
            obj.imzML = com.alanmrace.jimzmlparser.parser.ImzMLHandler.parseimzML(obj.filename);
            notify(obj, 'ParsingComplete');

            obj.width = obj.imzML.getWidth();
            obj.height = obj.imzML.getHeight();
            obj.depth = 1;

        end
        
        function spectrum = getSpectrum(obj, x, y, z)
            imzMLSpectrum = obj.imzML.getSpectrum(x, y);
            
            if(isempty(imzMLSpectrum))
                spectralChannels = [];
                intensities = [];
            else
                spectralChannels = imzMLSpectrum.getmzArray();
                intensities = imzMLSpectrum.getIntensityArray();
            end
                        
            spectrum = SpectralData(spectralChannels, intensities);
            
            if(~isempty(imzMLSpectrum))
                spectrum.setIsContinuous(~imzMLSpectrum.isCentroid());
            end
        end
        
        function image = getImage(obj, spectralChannel, channelWidth)
            image = zeros(obj.height, obj.width);
            
%             warning('TODO: Check if the imzML is continuous, if so generating ion images can be made faster');
            
            for y = 1:obj.height
                for x = 1:obj.width
                    [spectralChannels, intensities] = obj.getSpectrum(x, y);
                    
                    indicies = spectralChannels >= (spectralChannel-channelWidth) & spectralChannels <= (spectralChannel + channelWidth);
                    
                    image(y, x) = sum(intensities(indicies));
                    
                end
                
                ped = ProgressEventData(y / obj.height, ['Generating ' num2str(spectralChannel) ' +/- ' num2str(channelWidth)]);
                notify(obj, 'DataLoadProgress', ped);
            end
            
            image = Image(image);
        end
        
        % Generate multiple images from the data
        function imageList = getImages(obj, spectralChannelList, channelWidthList)
            images = zeros(obj.height, obj.width, length(spectralChannelList));
            
%             warning('TODO: Check if the imzML is continuous, if so generating ion images can be made faster');
            
            for y = 1:obj.height
                for x = 1:obj.width
                    [spectralChannels, intensities] = obj.getSpectrum(x, y);
                    
                    for z = 1:length(spectralChannelList)
                        indicies = spectralChannels >= (spectralChannelList(z)-channelWidthList(z)) & spectralChannels <= (spectralChannelList(z) + channelWidthList(z));

                        images(y, x, z) = sum(intensities(indicies));
                    end
                end
                
                ped = ProgressEventData(y / obj.height, ['Generating ' num2str(length(spectralChannelList)) ' image(s)']);
                
                notify(obj, 'DataLoadProgress', ped);
            end
            
            for i = 1:length(spectralChannelList)
                imageList(i) = Image(images(:, :, i));
            end
        end

        function image = getOverviewImage(obj)
            image = Image(obj.imzML.generateTICImage());
            image.setDescription('TIC Image');
        end
                
        function delete(obj) 
            obj.imzML.close();
        end
        
        function dataRepresentation = getDefaultDataRepresentation(this)
            dataRepresentation = DataOnDisk(this);
        end
        
        function workflow = getDefaultPreprocessingWorkflow(this)
            workflow = PreprocessingWorkflow();
            
            instrumentModel = this.getMassSpectrometer();
            
            obo = instrumentModel.getOntology();
            sciexInstrument = obo.getTerm('MS:1000121');
            watersInstrument = obo.getTerm('MS:1000126');
            thermoInstrument = obo.getTerm('MS:1000494');
            
            if sciexInstrument.isParentOf(instrumentModel.getID())
                switch(char(instrumentModel.getID()))
                    case {'MS:1000190', 'MS:1000655', 'MS:1000656', 'MS:1000657'}
                        % QSTAR, QSTAR Elite, QSTAR Pulsar or QSTAR XL
                        % Add in QSTAR zero filling to the preprocessing list

                        % TODO: Could check multiple spectra to find the best
                        % values for zero filling
                        spectralData = this.getSpectrum(1, 1);

                        workflow.addPreprocessingMethod(QSTARZeroFilling.generateFromSpectrum(spectralData));
                end
            elseif watersInstrument.isParentOf(instrumentModel.getID()) || instrumentModel.equals(watersInstrument)
                firstSpectrum = this.imzML.getSpectrumList().getSpectrum(0);
                firstScan = firstSpectrum.getScanList().getScan(0);
                scanWindow = firstScan.getScanWindowList().getScanWindow(0);
                
                lowerLimit = scanWindow.getCVParam('MS:1000501').getValueAsDouble();
                upperLimit = scanWindow.getCVParam('MS:1000500').getValueAsDouble();
                
                workflow.addPreprocessingMethod(InterpolationPPMRebinZeroFilling(lowerLimit, upperLimit, 5));
            elseif thermoInstrument.isParentOf(instrumentModel.getID())
            end
        end
        
        function instrumentModel = getMassSpectrometer(this)
            instrumentConfiguration = this.imzML.getInstrumentConfigurationList().getInstrumentConfiguration(0);
            
            % Check whether the 'instrument model' (MS:1000031) parameter
            % is included
            instrumentModel = instrumentConfiguration.getCVParamOrChild('MS:1000031').getTerm();
        end
        
        
        function label = getSpectrumXAxisLabel(this)
            label = '{\it m/z}';
        end
        
        function label = getSpectrumYAxisLabel(this)
            label = 'Intensity (a.u.)';
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