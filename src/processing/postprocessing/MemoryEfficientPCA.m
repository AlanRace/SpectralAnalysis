classdef MemoryEfficientPCA < DataReduction
    properties (Constant)
        Name = 'Memory Efficient PCA';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Retain', ParameterType.List, [ParameterDescription('Principal Component', ParameterType.Integer, 50), ParameterDescription('Variance', ParameterType.Double, 99)]), ...
            ParameterDescription('Scaling', ParameterType.List, [ParameterDescription('None', ParameterType.Boolean, 1), ...
                                                                ParameterDescription('Auto', ParameterType.Boolean, 1), ...
                                                                ParameterDescription('Root Mean', ParameterType.Boolean, 1), ...
                                                                ParameterDescription('Shift Variance', ParameterType.Integer, 1)])];
    end
    
    properties (Access = private)
        retainPCs = 0;
        retainVariance = 1;
        
        scalingNone = 1;
        scalingAuto = 0
    end
    
    methods
        function obj = MemoryEfficientPCA(retainOption, retainValue, scalingOption, scalingValue)
            obj.Parameters = [Parameter(MemoryEfficientPCA.ParameterDefinitions(1).defaultValue(retainOption), retainValue), ...
                Parameter(MemoryEfficientPCA.ParameterDefinitions(2).defaultValue(scalingOption), scalingValue)];
            
            switch(retainOption)
                case 1
                    obj.retainPCs = 1;
                    obj.retainVariance = 0;
                case 2
                    obj.retainPCs = 0;
                    obj.retainVariance = 1;
            end
            
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
            
            retainValue = this.Parameters(1).value;
            
            scaling = this.Parameters(2).parameterDescription.name;
            
            nSpectra = 0;
            
            pixels = this.getPixelListToProcess(dataRepresentation);
            rois = this.regionOfInterestList.getObjects();    
            
            % Set up the memory required
            L_list = {};
            Q_list = {};
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
                L_list{end+1} = zeros(1, channelSize);
                Q_list{end+1} = zeros(channelSize*(channelSize+1)/2, 1);
                pixelLists{end+1} = pixels;
            end
            
            for roiIndex = 1:numel(rois)
                pixelLists{end+1} = rois{roiIndex}.getPixelList();
                L_list{end+1} = zeros(1, channelSize);
                Q_list{end+1} = zeros(channelSize*(channelSize+1)/2, 1);
            end
            
            nSpectra = zeros(numel(pixelLists), 1);

%             if(isempty(obj.peakList))
%                 L = [];
%                 Q = [];
%             else
%                 L = zeros(1, length(obj.peakList));
%                 Q = zeros(length(obj.peakList)*(length(obj.peakList)+1)/2, 1);
%             end
% 
%             pixels = dataRepresentation.pixels;

            % If some form of scaling has been applied we 
            
            scalingValue = ones(numel(pixelLists), channelSize);
            
            if(~strcmp(scaling, 'None'))
                n = zeros(numel(pixelLists), 1);
                mean_ = zeros(numel(pixelLists), channelSize);
                M2 = zeros(numel(pixelLists), channelSize);
                
                for i = 1:length(pixels)
                    % PAPER STEP:  Pre-process spectrum
                    spectrum = this.getProcessedSpectrum(dataRepresentation, pixels(i, 1), pixels(i, 2));
                    
                    % If we aren't dealing with a square image then no point
                    % pre-processing
                    if(isempty(spectrum.intensities))
                        continue;
                    end
                                                            
                    if(strcmp(scaling, 'Shift Variance'))
                        shiftSpectrum = this.getProcessedSpectrum(dataRepresentation, pixels(i, 1)-1, pixels(i, 2)-1);
                        
                        if(isempty(shiftSpectrum.intensities))
                            continue;
                        end
                        
                        spectralChannels = spectrum.intensities - shiftSpectrum.intensities;
                    else
                        spectralChannels = spectrum.intensities;
                    end
                    
                    for pixelListIndex = 1:numel(pixelLists)
                        [pixel, row, col] = intersect(pixelLists{pixelListIndex}, pixels(i, :), 'rows');
                        
                        if(~isempty(row))
                            n(pixelListIndex) = n(pixelListIndex) + 1;
                            delta = spectralChannels - mean_(pixelListIndex, :);
                            mean_(pixelListIndex, :) = mean_(pixelListIndex, :) + delta ./ n(pixelListIndex);
                            M2(pixelListIndex, :) = M2(pixelListIndex, :) + delta .* (spectralChannels - mean_(pixelListIndex, :));
                        end
                    end
                    
                    progressEvent = ProgressEventData(i / length(pixels), 'Memory Efficient PCA: Generating scaling');
                    notify(this, 'ProcessingProgress', progressEvent);
                end
                
                for pixelListIndex = 1:numel(pixelLists)
                    if(strcmp(scaling, 'Auto') || strcmp(scaling, 'Shift Variance'))
                        scalingValue(pixelListIndex, :) = sqrt(M2(pixelListIndex, :) ./ (n(pixelListIndex) - 1));
                    elseif(strcmp(scaling, 'Root Mean'))
                        scalingValue(pixelListIndex, :) = sqrt(mean_(pixelListIndex, :));
                    end
                end
            end
            
            assignin('base', 'scaling', scalingValue);
            
            for i = 1:length(pixels)
                % PAPER STEP:  Read in spectrum
                
                % PAPER STEP:  Pre-process spectrum
                spectrum = this.getProcessedSpectrum(dataRepresentation, pixels(i, 1), pixels(i, 2));
                
                % If we aren't dealing with a square image then no point
                % pre-processing
                if(isempty(spectrum.intensities))
                    continue;
                end
                
                for pixelListIndex = 1:numel(pixelLists)
                    [pixel, row, col] = intersect(pixelLists{pixelListIndex}, pixels(i, :), 'rows');
                    
                    if(~isempty(row))
                        data = spectrum.intensities ./ scalingValue(pixelListIndex, :);
                        
                        % PAPER STEP:  Update summarisation matrices
                        L_list{pixelListIndex} = L_list{pixelListIndex} + data;

                        % Attempt to update Q using the mex file update
                        updateQ(Q_list{pixelListIndex}, data);

                        nSpectra(pixelListIndex) = nSpectra(pixelListIndex) + 1;
                    end
                end
                
                progressEvent = ProgressEventData(i / length(pixels), 'Memory Efficient PCA: Calculate summary spectra');
                notify(this, 'ProcessingProgress', progressEvent);
            end
            
            progressEvent = ProgressEventData(0, 'Memory Efficient PCA: Eigen decomposition');
            notify(this, 'ProcessingProgress', progressEvent);
            
            for pixelListIndex = 1:numel(pixelLists)
                calculateE(Q_list{pixelListIndex}, L_list{pixelListIndex}, nSpectra(pixelListIndex));
            
                [lambda{pixelListIndex}, coeff{pixelListIndex}] = symmeig(Q_list{pixelListIndex}, channelSize);
            end
            
            assignin('base', 'E', Q_list);
            progressEvent = ProgressEventData(1, 'Memory Efficient PCA: Eigen decomposition');
            notify(this, 'ProcessingProgress', progressEvent);
            
            % Change L to now be the mean
            for pixelListIndex = 1:numel(pixelLists)
                L_list{pixelListIndex} = L_list{pixelListIndex} ./ nSpectra(pixelListIndex);
            
                % Eigenvalues are returned in descending order, so to be compatibile with
                % common assumptions, rearrange the eigenvalues and eigenvectors
                lambda{pixelListIndex} = lambda{pixelListIndex}(end:-1:1);
                coeff{pixelListIndex} = coeff{pixelListIndex}(:, end:-1:1);

                % CHANGE: variance to retain as a percentage
    %             varianceToRetain = 99;

                explained{pixelListIndex} = (cumsum(lambda{pixelListIndex}) ./ sum(lambda{pixelListIndex})) * 100;
            
                % Ensure that the retained PCs is at most the number of PCs
                % that exist
                if(this.retainPCs)
                    numPCs(pixelListIndex) = min(retainValue, size(coeff{pixelListIndex}, 2));
                else
                    numPCs(pixelListIndex) = min(sum(explained{pixelListIndex} <= retainValue), size(coeff{pixelListIndex}, 2));
                end

                % PAPER STEP:  Calculate scores
                scores{pixelListIndex} = zeros(size(pixelLists{pixelListIndex}, 1), numPCs(pixelListIndex));

%                 size(coeff)
%                 size(coeff{pixelListIndex})
                
                coeff{pixelListIndex} = coeff{pixelListIndex}(:, 1:numPCs(pixelListIndex));
            end
            
            for i = 1:length(pixels)
                % PAPER STEP:  Pre-process spectrum
                spectrum = this.getProcessedSpectrum(dataRepresentation, pixels(i, 1), pixels(i, 2));
                
                % If we aren't dealing with a square image then no point
                % pre-processing
                if(isempty(spectrum.intensities))
                    continue;
                end
                
                for pixelListIndex = 1:numel(pixelLists)
                    [pixel, row, col] = intersect(pixelLists{pixelListIndex}, pixels(i, :), 'rows');
                    
                    if(~isempty(row))
                        data = (spectrum.intensities ./ scalingValue(pixelListIndex, :)) - L_list{pixelListIndex};
                        scores{pixelListIndex}(row, :) = data * coeff{pixelListIndex};
                    end
                end
                
                progressEvent = ProgressEventData(i / length(pixels), 'Memory Efficient PCA: Calculate scores');
                notify(this, 'ProcessingProgress', progressEvent);
            end
            
            dataRepresentationList = DataRepresentationList();
            
            for pixelListIndex = 1:numel(pixelLists)
                % Enforce the same sign convention as MATLAB's princomp
                [t, maxind] = max(abs(coeff{pixelListIndex}), [], 1);
                d = size(coeff{pixelListIndex}, 2);
                colsign = sign(coeff{pixelListIndex}(maxind + (0:length(peakList):(d-1)*length(peakList))));
                coeff{pixelListIndex} = bsxfun(@times, coeff{pixelListIndex}, colsign);
                scores{pixelListIndex} = bsxfun(@times, scores{pixelListIndex}, colsign);
                
                % Create projection data representation
                projectedDataRepresentation = ProjectedDataInMemory();
                
                if(this.processEntireDataset && pixelListIndex == 1)
                    projectedDataRepresentation.setData(scores{pixelListIndex}, coeff{pixelListIndex}, ...
                        RegionOfInterest(dataRepresentation.width, dataRepresentation.height), ...
                        dataRepresentation.isRowMajor, peakList, [dataRepresentation.name ' (ME PCA)']);
                elseif(this.processEntireDataset)
                    projectedDataRepresentation.setData(scores{pixelListIndex}, coeff{pixelListIndex}, rois{pixelListIndex-1}, ...
                        dataRepresentation.isRowMajor, peakList, [rois{pixelListIndex-1}.getName() ' (ME PCA)']);
                else
                    projectedDataRepresentation.setData(scores{pixelListIndex}, coeff{pixelListIndex}, rois{pixelListIndex}, ...
                        dataRepresentation.isRowMajor, peakList, [rois{pixelListIndex}.getName() ' (ME PCA)']);
                end
                
                dataRepresentationList.add(projectedDataRepresentation);
            end
        end
    end
end