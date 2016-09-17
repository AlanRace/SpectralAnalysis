classdef InMemoryNMF < DataReduction
    properties (Constant)
        Name = 'NMF';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('k', ParameterType.Integer, 5)]; 
        %ParameterDescription('Retain', ParameterType.List, [ParameterDescription('Principal Component', ParameterType.Integer, 50), ParameterDescription('Variance', ParameterType.Double, 99)]), ...
%             ParameterDescription('Scaling', ParameterType.List, [ParameterDescription('None', ParameterType.Boolean, 1), ...
%                                                                 ParameterDescription('Auto', ParameterType.Boolean, 1), ...
%                                                                 ParameterDescription('Root Mean', ParameterType.Boolean, 1), ...
%                                                                 ParameterDescription('Shift Variance', ParameterType.Integer, 1)])];
    end
    
    properties (Access = private)
        k
    end
    
    methods
        function obj = InMemoryNMF(k)
            obj.k = k;
        end
        
        function dataRepresentationList = process(this, dataRepresentation)
%             warning('TODO: Go over each spectrum');
%             warning('TODO: PreprocessingWorkflow?');

            if(~isa(dataRepresentation, 'DataInMemory'))
                exception = MException('InMemoryNMF:DataNotInMemory', ...
                        'Data must be loaded into memory to use this command.');
                throw(exception);
            end
            
            if(exist('nnmf', 'file') == 0)
                exception = MException('InMemoryNMF:FunctionMissing', ...
                        'nnmf could not be found on the path.  The Statistics Toolbox is required to use this command.');
                throw(exception);
            end
            
            if(this.preprocessEverySpectrum)
                exception = MException('InMemoryNMF:NotSupported', ...
                        'Preprocessing prior to in memory NMF is not currently supported.');
                throw(exception);
            end
            
%             nSpectra = 0;
            
            pixels = 1:size(dataRepresentation.data, 1);
            rois = this.regionOfInterestList.getObjects();    
            
            % Set up the memory required
            coeff = {};
            scores = {};
            pixelLists = {};
            
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
            end
            
            for roiIndex = 1:numel(rois)
                pixelLists{end+1} = rois{roiIndex}.getPixelMask()';
            end
                        
            % Change L to now be the mean
            for pixelListIndex = 1:numel(pixelLists)
                [scores_, coeffs_] = nnmf(dataRepresentation.data(pixelLists{pixelListIndex}, :), this.k);
                
                coeff{pixelListIndex} = coeffs_';
                scores{pixelListIndex} = scores_;
            end
            
            dataRepresentationList = DataRepresentationList();
            
            for pixelListIndex = 1:numel(pixelLists)
                
                
                % Create projection data representation
                projectedDataRepresentation = ProjectedDataInMemory();
                
                if(this.processEntireDataset && pixelListIndex == 1)
                    projectedDataRepresentation.setData(scores{pixelListIndex}, coeff{pixelListIndex}, ...
                        dataRepresentation.regionOfInterest, ...
                        dataRepresentation.isRowMajor, peakList, [dataRepresentation.name ' (NMF)']);
                elseif(this.processEntireDataset)
                    projectedDataRepresentation.setData(scores{pixelListIndex}, coeff{pixelListIndex}, rois{pixelListIndex-1}, ...
                        dataRepresentation.isRowMajor, peakList, [rois{pixelListIndex-1}.getName() ' (NMF)']);
                else
                    projectedDataRepresentation.setData(scores{pixelListIndex}, coeff{pixelListIndex}, rois{pixelListIndex}, ...
                        dataRepresentation.isRowMajor, peakList, [rois{pixelListIndex}.getName() ' (NMF)']);
                end
                
                dataRepresentationList.add(projectedDataRepresentation);
            end
        end
    end
end