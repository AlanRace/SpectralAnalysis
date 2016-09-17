function mfileList = getmFilesFromAllFolders(path)

mfileList = dir([path filesep '*.m']);

listing = dir(path);

for i = 1:length(listing)
    if(strcmp(listing(i).name, '.') || strcmp(listing(i).name, '..'))
        continue;
    end
    
    if(listing(i).isdir)
        mfileList = [mfileList; getmFilesFromAllFolders([path filesep listing(i).name])];
    end
end