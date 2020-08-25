classdef AdvancedKMeansClustering < Clustering
    properties (Constant)
        Name = 'Advanced k-means';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('k (Number of clusters)', ParameterType.Integer, 5), ...
            ParameterDescription('Distance Metric', ParameterType.Selection, {'Squared Euclidean', 'Manhattan', 'Cosine', 'Correlation', 'Hamming'}), ...
            ParameterDescription('Initial Cluster Selection', ParameterType.Selection, {'Random', 'Uniform Random', 'Preclustered' }), ...
            ParameterDescription('Replicates', ParameterType.Integer, 1), ...
            ParameterDescription('Empty Cluster Action', ParameterType.Selection, {'Error', 'Remove', 'Create New' }), ...
            ParameterDescription('Online Update Phase', ParameterType.Selection, {'On', 'Off'})];
    end
    
    properties (Access = private)
        k;
        distanceMetric;
        InitialClusterSelection;
        Replicates;
        EmptyClusterAction;
        OnlineUpdatePhase;
    end
    
    methods
        function obj = AdvancedKMeansClustering(k, distanceMetric, InitialClusterSelection, Replicates, EmptyClusterAction, OnlineUpdatePhase)
            obj.k = k;
            obj.Replicates = Replicates;
            
            if(strcmp(distanceMetric, 'Squared Euclidean'))
                obj.distanceMetric = 'sqEuclidean';
            elseif(strcmp(distanceMetric, 'Manhattan'))
                obj.distanceMetric = 'cityblock' ;
            elseif(strcmp(distanceMetric, 'Cosine'))
                obj.distanceMetric = 'cosine' ;
            elseif(strcmp(distanceMetric, 'Correlation'))
                obj.distanceMetric = 'correlation' ;
            elseif(strcmp(distanceMetric, 'Hamming'))
                obj.distanceMetric = 'Hamming' ;
            end
            
            if(strcmp(InitialClusterSelection, 'Random'))
                obj.InitialClusterSelection = 'sample' ;
            elseif(strcmp(InitialClusterSelection, 'Uniform Random'))
                obj.InitialClusterSelection = 'uniform' ;
            elseif(strcmp(InitialClusterSelection, 'Preclustered'))
                obj.InitialClusterSelection = 'cluster' ;
            end
            
            if(strcmp(EmptyClusterAction, 'Error'))
                obj.EmptyClusterAction = 'error' ;
            elseif(strcmp(EmptyClusterAction, 'Remove'))
                obj.EmptyClusterAction = 'drop' ;
            elseif(strcmp(EmptyClusterAction, 'Create New'))
                obj.EmptyClusterAction = 'singleton' ;
            end
            
            if(strcmp(OnlineUpdatePhase, 'On'))
                obj.OnlineUpdatePhase = 'on' ;
            elseif(strcmp(OnlineUpdatePhase, 'Off'))
                obj.OnlineUpdatePhase = 'off' ;
            end
            
        end
        
        
        function [dataRepresentationList regionOfInterestLists] = process(this, dataRepresentation)
            if(~isa(dataRepresentation, 'DataInMemory'))
                exception = MException('InMemoryPCA:DataNotInMemory', ...
                        'Data must be loaded into memory to use this command.');
                throw(exception);
            end
            
            rois = this.regionOfInterestList.getObjects();
            
            if(this.preprocessEverySpectrum || ~isa(dataRepresentation, 'DataInMemory') || ~isempty(rois))
                % If not already in memory or requires processing then we need to
                % perform data cube reduction
                datacubeReduction = DatacubeReduction('New Window');
                
                datacubeReduction.applyPreprocessingToEverySpectrum(this.preprocessEverySpectrum);
                datacubeReduction.postProcessEntireDataset(this.processEntireDataset);
                datacubeReduction.setPreprocessingWorkflow(this.preprocessingWorkflow);
                datacubeReduction.setRegionOfInterestList(this.regionOfInterestList);
                
                dataRepresentationList = datacubeReduction.process(dataRepresentation);
            else
                dataRepresentationList = DataRepresentationList();
                dataRepresentationList.add(dataRepresentation);
            end
            
            
            dataRepresentations = dataRepresentationList.getObjects();
            regionOfInterestLists = {};
            
            for i = 1:numel(dataRepresentations)
                res = kmeans(dataRepresentations{i}.data, this.k, 'distance', this.distanceMetric, 'start', ...
                    this.InitialClusterSelection, 'replicates', this.Replicates, 'onlinephase', this.OnlineUpdatePhase, ...
                    'emptyaction', this.EmptyClusterAction );
                 
                %                curPixels = dataRepresentations{i}.regionOfInterest.pixelSelection;
                kmeansImage = zeros(dataRepresentation.height, dataRepresentation.width); %size(curPixels));
                
                pixels = dataRepresentations{i}.regionOfInterest.getPixelList();
                
                if(dataRepresentations{i}.isRowMajor)
                    % Sort by y column, then by x column
                    pixels = sortrows(pixels, [2 1]);
                else
                    % Sort by x column, then by y column
                    pixels = sortrows(pixels, [1 2]);
                end
                
                for j = 1:length(pixels)
                    kmeansImage(pixels(j, 2), pixels(j, 1)) = res(j);
                end
                
                %                 figure, imagesc(kmeansImage);
                
                %                 kmeansImage = zeros(size(curPixels));
                %                 kmeansImage(curPixels == 1) = res;
                
                regionOfInterestLists{i} = RegionOfInterestList();
                
                for j = 1:this.k
                    roi = RegionOfInterest(size(kmeansImage, 2), size(kmeansImage, 1));
                    roi.addPixels(kmeansImage == j);
                    roi.setName(['k = ' num2str(j)]);
                    roi.setColour(Colour(round(rand*255), round(rand*255), round(rand*255)));
                    
                    %                     roi.cropTo(curPixels);
                    
                    regionOfInterestLists{i}.add(roi);
                    %                     curPixels(curPixels == 1) = res
                end
            end
            
            %             % Create projection data representation
            %             kmeansDataRepresentation = DataInMemory();
            %             kmeansDataRepresentation.setData(res, dataRepresentation.pixelSelection, dataRepresentation.isRowMajor, 0);
            %             dataRepresentation = kmeansDataRepresentation;
        end
    end
end