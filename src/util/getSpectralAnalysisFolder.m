function pathstr = getSpectralAnalysisFolder()

if(isdeployed())
    pathstr = ctfroot();
else
    pathstr = fileparts(mfilename('fullpath'));
    
    curFolder = pwd;
    
    % lib folder is ../../lib compared to current location of ./util
    pathstr = [pathstr filesep '..' filesep '..'];
    
    cd(pathstr);
    pathstr = pwd;
    cd(curFolder);
end

