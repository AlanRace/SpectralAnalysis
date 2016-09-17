classdef InMemoryPCA < DataReduction
    properties (Constant)
        Name = 'PCA';
        Description = '';
        
        ParameterDefinitions = []; %ParameterDescription('Retain', ParameterType.List, [ParameterDescription('Principal Component', ParameterType.Integer, 50), ParameterDescription('Variance', ParameterType.Double, 99)]), ...
%             ParameterDescription('Scaling', ParameterType.List, [ParameterDescription('None', ParameterType.Boolean, 1), ...
%                                                                 ParameterDescription('Auto', ParameterType.Boolean, 1), ...
%                                                                 ParameterDescription('Root Mean', ParameterType.Boolean, 1), ...
%                                                                 ParameterDescription('Shift Variance', ParameterType.Integer, 1)])];
    end
    
    properties (Access = private)
        retainPCs = 0;
        retainVariance = 1;
        
        scalingNone = 1;
        scalingAuto = 0
    end
    
    methods
        function obj = InMemoryPCA()
%             obj.Parameters = [Parameter(MemoryEfficientPCA.ParameterDefinitions(1).defaultValue(retainOption), retainValue), ...
%                 Parameter(MemoryEfficientPCA.ParameterDefinitions(2).defaultValue(scalingOption), scalingValue)];
%             
%             switch(retainOption)
%                 case 1
%                     obj.retainPCs = 1;
%                     obj.retainVariance = 0;
%                 case 2
%                     obj.retainPCs = 0;
%                     obj.retainVariance = 1;
%             end
            
%             switch(scalingOption)
%                 case 1
%                     obj.scalingNone = 1;
%                 case 2
%                     obj.scalingAuto = 1;
%             end
        end
        
        function dataRepresentationList = process(this, dataRepresentation)
%             warning('TODO: Go over each spectrum');
%             warning('TODO: PreprocessingWorkflow?');

            if(~isa(dataRepresentation, 'DataInMemory'))
                exception = MException('InMemoryPCA:DataNotInMemory', ...
                        'Data must be loaded into memory to use this command.');
                throw(exception);
            end
            
            if(exist('princomp', 'file') == 0)
                exception = MException('InMemoryPCA:FunctionMissing', ...
                        'princomp could not be found on the path.  The Statistics Toolbox is required to use this command.');
                throw(exception);
            end
            
            if(this.preprocessEverySpectrum)
                exception = MException('InMemoryPCA:NotSupported', ...
                        'Preprocessing prior to in memory PCA is not currently supported.');
                throw(exception);
            end
            
%             nSpectra = 0;
            
            pixels = 1:size(dataRepresentation.data, 1);
            rois = this.regionOfInterestList.getObjects();    
            
            % Set up the memory required
            coeffs = {};
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
                [coeffs_, scores_] = princomp(dataRepresentation.data(pixelLists{pixelListIndex}, :), 'econ');
                
                coeff{pixelListIndex} = coeffs_;
                scores{pixelListIndex} = scores_;
            end
            
            dataRepresentationList = DataRepresentationList();
            
            for pixelListIndex = 1:numel(pixelLists)
                
                
                % Create projection data representation
                projectedDataRepresentation = ProjectedDataInMemory();
                
                if(this.processEntireDataset && pixelListIndex == 1)
                    projectedDataRepresentation.setData(scores{pixelListIndex}, coeff{pixelListIndex}, ...
                        dataRepresentation.regionOfInterest, ...
                        dataRepresentation.isRowMajor, peakList, [dataRepresentation.name ' (PCA)']);
                elseif(this.processEntireDataset)
                    projectedDataRepresentation.setData(scores{pixelListIndex}, coeff{pixelListIndex}, rois{pixelListIndex-1}, ...
                        dataRepresentation.isRowMajor, peakList, [rois{pixelListIndex-1}.getName() ' (PCA)']);
                else
                    projectedDataRepresentation.setData(scores{pixelListIndex}, coeff{pixelListIndex}, rois{pixelListIndex}, ...
                        dataRepresentation.isRowMajor, peakList, [rois{pixelListIndex}.getName() ' (PCA)']);
                end
                
                dataRepresentationList.add(projectedDataRepresentation);
            end
        end
    end
end