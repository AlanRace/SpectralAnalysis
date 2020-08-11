function pathstr = getSpectralAnalysisFolder()

if(isdeployed())
    pathstr = ctfroot();
else
    pathstr = fileparts(mfilename('fullpath'));
    
    % lib folder is ../../lib compared to current location of ./util
    pathstr = [pathstr filesep '..' filesep '..'];
end

