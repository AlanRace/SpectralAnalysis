function regionOfInterest = parseRegionOfInterest(filename) 
% parseClusterGroupList Convert XML file to a MATLAB structure.
try
   tree = xmlread(filename);
catch
   error('Failed to read XML file %s.',filename);
end

% Recurse over child nodes. This could run into problems 
% with very deeply nested trees.
try
   regionOfInterest = parseRegionOfInterestElement(tree.getChildNodes().item(0));
catch err
    err
   error('Unable to parse XML file %s.',filename);
end
