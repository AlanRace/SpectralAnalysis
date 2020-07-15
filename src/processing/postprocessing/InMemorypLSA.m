classdef InMemorypLSA < DataReduction
    properties (Constant)
        Name = 'pLSA';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Number of Components (0 for auto detect)', ParameterType.Integer, 5), ...
            ParameterDescription('Relative Change', ParameterType.Double, 1e-5), ...
            ParameterDescription('Maximum Iterations', ParameterType.Integer, 500)]; 
        %ParameterDescription('Retain', ParameterType.List, [ParameterDescription('Principal Component', ParameterType.Integer, 50), ParameterDescription('Variance', ParameterType.Double, 99)]), ...
%             ParameterDescription('Scaling', ParameterType.List, [ParameterDescription('None', ParameterType.Boolean, 1), ...
%                                                                 ParameterDescription('Auto', ParameterType.Boolean, 1), ...
%                                                                 ParameterDescription('Root Mean', ParameterType.Boolean, 1), ...
%                                                                 ParameterDescription('Shift Variance', ParameterType.Integer, 1)])];
    end
    
    properties (Access = private)
        numComponents
        relativeChange
        maxIter
    end
    
    methods
        function obj = InMemorypLSA(numComponents, relativeChange, maxIter)
            obj.numComponents = numComponents;
            obj.relativeChange = relativeChange;
            obj.maxIter = maxIter;
        end
        
        function dataRepresentationList = process(this, dataRepresentation)
%             warning('TODO: Go over each spectrum');
%             warning('TODO: PreprocessingWorkflow?');

            if(~isa(dataRepresentation, 'DataInMemory'))
                exception = MException('InMemorypLSA:DataNotInMemory', ...
                        'Data must be loaded into memory to use this command.');
                throw(exception);
            end
            
            [pathstr,name,ext] = fileparts(mfilename('fullpath'))
            
            % Add the mip_plsa folder to the path
            folderPath = [pathstr filesep 'mip_plsa'];
            addpath(folderPath);
            
            if(exist('mip_plsa', 'file') ~= 2)
                exception = MException('InMemorypLSA:FunctionMissing', ...
                        'mip_plsa could not be found on the path.  If you would like to use this command, please download from http://hci.iwr.uni-heidelberg.de/MIP/Software/plsa.php extract into a folder called mip_plsa in the SpectralAnalysis folder and cite the relevant publication.');
                throw(exception);
            end
            
            if(this.preprocessEverySpectrum)
                exception = MException('InMemorypLSA:NotSupported', ...
                        'Preprocessing prior to in memory pLSA is not currently supported.');
                throw(exception);
            end
            
            dataToProcess = dataRepresentation.data;
            dataToProcess(dataToProcess < 0) = 0;
            
            % Check if there are negative values (sometimes caused by
            % Savitzky-Golay smoothing) as this seems to break pLSA
            if(sum(sum(dataToProcess < 0)) > 0)
                exception = MException('InMemorypLSA:NegativeValues', ...
                        'Negative values found in data. These prevent pLSA from converging, please remove them before trying again.');
                throw(exception);
            end
            
%             nSpectra = 0;
            
            pixels = 1:size(dataToProcess, 1);
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
                % Auto detect the number of components based on the
                % mip_processData.m code
                if(this.numComponents == 0)
                    % do pLSA for various settings of numComponents
                    numComponents = 2;  % a decomposition with one component is not interesting
                    minFound = 0;       % minimum reached?
                    cts = [];           % stores solutions for ct
                    tss = [];           % stores solutions for ts
                    logliks = [];       % stores data log likelihoods
                    boundNumber = 0;   % stores the number of bounds calculated for stopping criterion

                    % search optimum value for numComponents
                    while(~minFound)
                        disp(['Performing pLSA with ', num2str(numComponents), ' components (', num2str(size(dataToProcess(pixelLists{pixelListIndex}, :), 1)), ' spectra à ', num2str(size(dataToProcess(pixelLists{pixelListIndex}, :), 2)), ' channels):']);
                        [coeffs_, scores_, loglik] = mip_plsa(dataToProcess(pixelLists{pixelListIndex}, :), numComponents, this.relativeChange, this.maxIter);
                        
                        % save log-likelihoods and decomposition results
                        cts{numComponents} = coeffs_;
                        tss{numComponents} = scores_;
                        logliks(numComponents) = loglik;
                        
                        numComponents = numComponents + 1;
                        % calculate AICc-trace
                        [AICc, lastPenalty] = mip_calculateAICcTrace(dataToProcess(pixelLists{pixelListIndex}, :), dataRepresentation.spectralChannels, xyPos{pixelListIndex}, logliks);

                        % check stopping criterion

                %        % 1. possibility: stop after a certain number of iterations
                %        if(numComponents == 10)        
                %        % 2. possibility: stop if AICc-curve has increased for several  
                %        % steps in a row
                %        steps = length(AICc);
                %        while(steps > 1)
                %            if(AICc(steps) <= AICc(steps-1))
                %                break;
                %            end
                %            steps = steps - 1;
                %        end
                %        inARow = length(AICc) - steps;
                %        if(inARow >= 5)    

                        % 3. possibility: stop if theoretical optimum reached
                        % theoretical optimum of loglik part is zero, therefore if one
                        % point in the AICc trace curve is below the current penalty
                        % function value we can stop the iterations, this bound is not
                        % very tight though; as the -2*loglik/N is monotonously decreasing
                        % and the penalty term is strictly increasing, we calculate the 
                        % loglik value corresponding to an upper bound that exceeds the number 
                        % of components in the tissue (like 100)
                        if(numComponents == 3)
                            bound = 30;
                            disp(['Searching for upper bound with ', num2str(bound), ' components:']);
                            [ct2, ts2, loglik] = mip_plsa(dataToProcess(pixelLists{pixelListIndex}, :), bound, this.relativeChange, 10*this.maxIter); 
                            maxloglik = 2*loglik/(size(dataToProcess(pixelLists{pixelListIndex}, :), 1) * size(dataToProcess(pixelLists{pixelListIndex}, :), 2));
                        end

                        penaltyBound = lastPenalty - maxloglik;
                        disp(['Penalty bound vs. minimum previous AICc value: ', num2str(penaltyBound), '<=', num2str(min(AICc(2:length(AICc))))]);

                        if(penaltyBound > min(AICc(2:length(AICc))))
                            disp('Iterations aborted as penalty bound higher than previous AICc value'); 

                            minFound = 1;
                        end
                    end
                    
                    [minVal, minIdx] = min(AICc(2:length(AICc)));
                    
                    coeffs_ = cts{minIdx+1};
                    scores_ = tss{minIdx+1};
                else
                    % User defined number of components
                    [coeffs_, scores_] = mip_plsa(dataToProcess(pixelLists{pixelListIndex}, :), this.numComponents, this.relativeChange, this.maxIter);
                end
                
                coeff{pixelListIndex} = coeffs_;
                scores{pixelListIndex} = scores_';
            end
            
            dataRepresentationList = DataRepresentationList();
            
            for pixelListIndex = 1:numel(pixelLists)
                
                
                % Create projection data representation
                projectedDataRepresentation = ProjectedDataInMemory();
                
                if(this.processEntireDataset && pixelListIndex == 1)
                    projectedDataRepresentation.setData(scores{pixelListIndex}, coeff{pixelListIndex}, ...
                        dataRepresentation.regionOfInterest, ...
                        dataRepresentation.isRowMajor, peakList, [dataRepresentation.name ' (pLSA)']);
                elseif(this.processEntireDataset)
                    projectedDataRepresentation.setData(scores{pixelListIndex}, coeff{pixelListIndex}, rois{pixelListIndex-1}, ...
                        dataRepresentation.isRowMajor, peakList, [rois{pixelListIndex-1}.getName() ' (pLSA)']);
                else
                    dataROI = RegionOfInterest(dataRepresentation.width, dataRepresentation.height);
                    dataROI.addPixels(and(rois{pixelListIndex}.getPixelMask(), dataRepresentation.regionOfInterest.getPixelMask()));
                    
                    projectedDataRepresentation.setData(scores{pixelListIndex}, coeff{pixelListIndex}, dataROI, ...
                        dataRepresentation.isRowMajor, peakList, [rois{pixelListIndex}.getName() ' (pLSA)']);
                end
                
                dataRepresentationList.add(projectedDataRepresentation);
            end
            
            this.dataRepresentationList = dataRepresentationList;
        end
    end
end