classdef KMeansClustering < Clustering
    properties (Constant)
        Name = 'k-means';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('k (Number of clusters)', ParameterType.Integer, 5), ...
            ParameterDescription('Number of replicates', ParameterType.Integer, 5), ...
            ParameterDescription('Distance metric', ParameterType.Selection, {'cosine', 'sqeuclidean', 'cityblock', 'correlation', 'hamming'}), ...
            ParameterDescription('Minimum features size', ParameterType.Integer, 0)];
    end
    
    properties
        k;
        distanceMetric;
        replicates;
        minFeatureSize;
    end
    
    methods
        function this = KMeansClustering(k, replicates, distanceMetric, minFeatureSize)
            if nargin < 4
                minFeatureSize = 0;
            end
            if nargin < 3
                distanceMetric = 'cosine';
            end
            if nargin < 2
                replicates = 5;
            end
            
            this.k = k;
            this.replicates = replicates;
            this.distanceMetric = distanceMetric;
            this.minFeatureSize = minFeatureSize;
            
%                 obj.Parameters = [Parameter(KMeansClustering.ParameterDefinitions(1), k), ...
%                     Parameter(KMeansClustering.ParameterDefinitions(2), replicates), ...
%                     Parameter(KMeansClustering.ParameterDefinitions(3), distance)];
        end
        
        function [dataRepresentationList, regionOfInterestLists] = process(this, dataRepresentation)
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
            
%             k = this.Parameters(1).value;
%             replicates = this.Parameters(2).value;
%             distance = this.Parameters(3).value;
            
            dataRepresentations = dataRepresentationList.getObjects();
            this.regionOfInterestLists = {};
            
            for i = 1:numel(dataRepresentations)
                res = kmeans(dataRepresentations{i}.data, this.k, 'replicates', this.replicates, 'distance', this.distanceMetric);
                
%                curPixels = dataRepresentations{i}.regionOfInterest.pixelSelection;
                kmeansImage = zeros(dataRepresentation.height, dataRepresentation.width); %size(curPixels));
                
                pixels = dataRepresentations{i}.getDataOrderedPixelList();
                
                for j = 1:length(pixels)
                    kmeansImage(pixels(j, 2), pixels(j, 1)) = res(j);
                end
                
                newkmeansImage = kmeansImage;

                % Remove features that are smaller than the set size,
                % replacing them with the largest neighbouring cluster
                for j = 1:this.k
                    stats = regionprops(kmeansImage == j, 'PixelList', 'Area');

                    for a = 1:length(stats)
                        if stats(a).Area < this.minFeatureSize
                            for pixInx = 1:size(stats(a).PixelList, 1)
                                pix = stats(a).PixelList(pixInx, :);

                                minX = max(1, pix(1)-1);
                                maxX = min(size(kmeansImage, 2), pix(1)+1);
                                minY = max(1, pix(2)-1);
                                maxY = min(size(kmeansImage, 1), pix(2)+1);

                                neighbourhood = kmeansImage(minY:maxY, minX:maxX);

                                newkmeansImage(pix(2), pix(1)) = mode(neighbourhood(:));
                            end
                        end
                    end
                end
                
                kmeansImage = newkmeansImage;
                
                this.regionOfInterestLists{i} = RegionOfInterestList();
                
                for j = 1:this.k
                    roi = RegionOfInterest(size(kmeansImage, 2), size(kmeansImage, 1));
                    roi.addPixels(kmeansImage == j);
                    roi.setName(['k = ' num2str(j) ' (out of ' num2str(this.k) ')']);
                    roi.setColour(Colour(round(rand*255), round(rand*255), round(rand*255)));
                    
%                     roi.cropTo(curPixels);
                    
                    this.regionOfInterestLists{i}.add(roi);
%                     curPixels(curPixels == 1) = res
                end
            end
            
            regionOfInterestLists = this.regionOfInterestLists;
            
%             % Create projection data representation
%             kmeansDataRepresentation = DataInMemory();
%             kmeansDataRepresentation.setData(res, dataRepresentation.pixelSelection, dataRepresentation.isRowMajor, 0);
%             dataRepresentation = kmeansDataRepresentation;
        end
    end
end