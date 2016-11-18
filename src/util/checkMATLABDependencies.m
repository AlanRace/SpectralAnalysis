function [files, fullfList, fullpList] = checkMATLABDependencies()

fileList = dir('*.m');

files = [];
fullfList = [];
fullpList = [];

for i = 1:length(fileList)
    [res1, res2] = matlab.codetools.requiredFilesAndProducts(fileList(i).name);
    
    files(i).name = fileList(i).name;
    files(i).fileDependencies = res1;
    files(i).pathDependencies = res2;
    
    fullfList = union(fullfList, fullfList);
    fullpList = union(fullpList, {res2.Name});
end
