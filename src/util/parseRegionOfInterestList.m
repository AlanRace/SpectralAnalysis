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
            regionOfInterestList.add(parseRegionOfInterest(element));
        end
    end
    
function regionOfInterest = parseRegionOfInterest(regionOfInterestNode)
    width = str2num(regionOfInterestNode.getAttributes().getNamedItem('width').getValue());
    height = str2num(regionOfInterestNode.getAttributes().getNamedItem('height').getValue());

    regionOfInterest = RegionOfInterest(width, height);
    
    childrenNodes = regionOfInterestNode.getChildNodes();
    
    for i = 1:childrenNodes.getLength()
        element = childrenNodes.item(i-1);
        
        nodeName = element.getNodeName();
        
        if(strcmp(nodeName, 'name'))
            regionOfInterest.setName(char(element.getTextContent()));
        elseif(strcmp(nodeName, 'colour'))
            r = str2num(element.getAttributes().getNamedItem('red').getValue());
            g = str2num(element.getAttributes().getNamedItem('green').getValue());
            b = str2num(element.getAttributes().getNamedItem('blue').getValue());
            
            regionOfInterest.setColour(Colour(r, g, b));
        elseif(strcmp(nodeName, 'pixelList'))
            parsePixelList(regionOfInterest, element);
        end
    end
    
function parsePixelList(regionOfInterest, pixelListElement)
    childrenNodes = pixelListElement.getChildNodes();
    
    for i = 1:childrenNodes.getLength()
        element = childrenNodes.item(i-1);
        
        nodeName = element.getNodeName();
        
        if(strcmp(nodeName, 'pixel'))
            x = str2num(element.getAttributes().getNamedItem('x').getValue());
            y = str2num(element.getAttributes().getNamedItem('y').getValue());
            
            regionOfInterest.addPixel(x, y);
        end
    end