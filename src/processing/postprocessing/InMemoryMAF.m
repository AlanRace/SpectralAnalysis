classdef InMemoryMAF < DataReduction
    properties (Constant)
        Name = 'MAF';
        Description = '';
        
        ParameterDefinitions = []; 
        %ParameterDescription('Retain', ParameterType.List, [ParameterDescription('Principal Component', ParameterType.Integer, 50), ParameterDescription('Variance', ParameterType.Double, 99)]), ...
%             ParameterDescription('Scaling', ParameterType.List, [ParameterDescription('None', ParameterType.Boolean, 1), ...
%                                                                 ParameterDescription('Auto', ParameterType.Boolean, 1), ...
%                                                                 ParameterDescription('Root Mean', ParameterType.Boolean, 1), ...
%                                                                 ParameterDescription('Shift Variance', ParameterType.Integer, 1)])];
    end
    
    properties (Access = private)
    end
    
    methods
        function obj = InMemoryMAF()
            
        end
        
        function dataRepresentationList = process(this, dataRepresentation)
%             warning('TODO: Go over each spectrum');
%             warning('TODO: PreprocessingWorkflow?');

            if(~isa(dataRepresentation, 'DataInMemory'))
                exception = MException('InMemoryMAF:DataNotInMemory', ...
                        'Data must be loaded into memory to use this command.');
                throw(exception);
            end
            
            [pathstr,name,ext] = fileparts(mfilename('fullpath'))
            
            % Add the mip_plsa folder to the path
            folderPath = [pathstr filesep 'maf'];
            addpath(folderPath);
            
            if(exist('maf', 'file') ~= 2)
                exception = MException('InMemoryMAF:FunctionMissing', ...
                        'maf could not be found on the path.  If you would like to use this command, please download from http://www.imm.dtu.dk/~alan/software.html extract into a folder called maf in the SpectralAnalysis folder and cite the relevant publication.');
                throw(exception);
            end
            
            if(this.preprocessEverySpectrum)
                exception = MException('InMemoryMAF:NotSupported', ...
                        'Preprocessing prior to in memory MAF is not currently supported.');
                throw(exception);
            end
                       
%             nSpectra = 0;
            
            pixels = 1:size(dataRepresentation.data, 1);
            rois = this.regionOfInterestList.getObjects();    
            
            % Set up the memory required
            coeff = {};
            scores = {};
            pixelLists = {};
            xyPos = {};
            
            % Load in the first spectrum in the pixel list to create the
            % memory necessary
            spectrum = this.getProcessedSpectrum(dataRepresentation, pixels(1, 1), pixels(1, 2));
            % Allocate memory based on the first spectrum acquired
            if(isempty(this.peakList))
                channelSize = length(spectrum.spectralChannels);
                peakList = spectrum.spectralChannels;
            else
                channelSize = length(this.peakList);
                peakList = this.peakList;
            end
            
            if(this.processEntireDataset)
                pixelLists{end+1} = pixels;
                xyPos{end+1} = this.getPixelListToProcess(dataRepresentation);
            end
            
            for roiIndex = 1:numel(rois)
                pixelLists{end+1} = dataRepresentation.getDataIndiciesForROI(rois{roiIndex});
                xyPos{end+1} = rois{roiIndex}.getPixelList();
            end
                        
            % Change L to now be the mean
            for pixelListIndex = 1:numel(pixelLists)
                [mafs,ac,v,d,sigmad,sigma] = maf(dataRepresentation.data(pixelLists{pixelListIndex}, :), dataRepresentation.height, dataRepresentation.width, size(dataRepresentation.data, 2), 2);
                
                
                
                coeff{pixelListIndex} = v;
                scores{pixelListIndex} = mafs;
            end
            
            dataRepresentationList = DataRepresentationList();
            
            for pixelListIndex = 1:numel(pixelLists)
                
                
                % Create projection data representation
                projectedDataRepresentation = ProjectedDataInMemory();
                
                if(this.processEntireDataset && pixelListIndex == 1)
                    projectedDataRepresentation.setData(scores{pixelListIndex}, coeff{pixelListIndex}, ...
                        dataRepresentation.regionOfInterest, ...
                        dataRepresentation.isRowMajor, peakList, [dataRepresentation.name ' (MAF)']);
                elseif(this.processEntireDataset)
                    projectedDataRepresentation.setData(scores{pixelListIndex}, coeff{pixelListIndex}, rois{pixelListIndex-1}, ...
                        dataRepresentation.isRowMajor, peakList, [rois{pixelListIndex-1}.getName() ' (MAF)']);
                else
                    dataROI = RegionOfInterest(dataRepresentation.width, dataRepresentation.height);
                    dataROI.addPixels(and(rois{pixelListIndex}.getPixelMask(), dataRepresentation.regionOfInterest.getPixelMask()));
                    
                    projectedDataRepresentation.setData(scores{pixelListIndex}, coeff{pixelListIndex}, dataROI, ...
                        dataRepresentation.isRowMajor, peakList, [rois{pixelListIndex}.getName() ' (MAF)']);
                end
                
                dataRepresentationList.add(projectedDataRepresentation);
            end
        end
    end
end