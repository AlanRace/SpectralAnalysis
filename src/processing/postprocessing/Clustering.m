classdef Clustering < PostProcessing
    properties (Access = protected)
        regionOfInterestLists;
    end
    
    methods
        function dataViewer = displayResults(this, dataViewer)
            for i = 1:numel(this.regionOfInterestLists)
                dataViewer.addRegionOfInterestList(this.regionOfInterestLists{i});
            end
        end
    end
end