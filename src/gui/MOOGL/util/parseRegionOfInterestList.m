function regionOfInterestList = parseRegionOfInterestList(filename) 
% parseClusterGroupList Convert XML file to a MATLAB structure.
try
   tree = xmlread(filename);
catch
   error('Failed to read XML file %s.',filename);
end

% Recurse over child nodes. This could run into problems 
% with very deeply nested trees.
try
   regionOfInterestList = parseRegionOfInterestListElement(tree.getChildNodes().item(0));
catch err
    err
   error('Unable to parse XML file %s.',filename);
end


function regionOfInterestList = parseRegionOfInterestListElement(regionOfInterestNode) 
    regionOfInterestList = RegionOfInterestList();

    childrenNodes = regionOfInterestNode.getChildNodes();

    for i = 1:childrenNodes.getLength()
        element = childrenNodes.item(i-1);
        
        nodeName = element.getNodeName();
        
        if(strcmp(nodeName, 'regionOfInterest'))
            regionOfInterestList.add(parseRegionOfInterestElement(element));
        end
    end
    
