classdef KMeansClustering < Clustering
    properties (Constant)
        Name = 'k-means';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('k (Number of clusters)', ParameterType.Integer, 5)];
    end
    
    methods
        function obj = KMeansClustering(k)
                obj.Parameters = Parameter(KMeansClustering.ParameterDefinitions(1), k);
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
            
            k = this.Parameters(1).value;
            
            dataRepresentations = dataRepresentationList.getObjects();
            this.regionOfInterestLists = {};
            
            for i = 1:numel(dataRepresentations)
                res = kmeans(dataRepresentations{i}.data, k);
                
%                curPixels = dataRepresentations{i}.regionOfInterest.pixelSelection;
                kmeansImage = zeros(dataRepresentation.height, dataRepresentation.width); %size(curPixels));
                
                pixels = dataRepresentations{i}.getDataOrderedPixelList();
                
                for j = 1:length(pixels)
                    kmeansImage(pixels(j, 2), pixels(j, 1)) = res(j);
                end
                
%                 figure, imagesc(kmeansImage);
                
%                 kmeansImage = zeros(size(curPixels));
%                 kmeansImage(curPixels == 1) = res;
                
                this.regionOfInterestLists{i} = RegionOfInterestList();
                
                for j = 1:k
                    roi = RegionOfInterest(size(kmeansImage, 2), size(kmeansImage, 1));
                    roi.addPixels(kmeansImage == j);
                    roi.setName(['k = ' num2str(j)]);
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