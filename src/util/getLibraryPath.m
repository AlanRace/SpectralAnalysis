function pathstr = getLibraryPath()
    if(isdeployed())
        pathstr = ctfroot();
    else
        pathstr = fileparts(mfilename('fullpath'));
        
        % lib folder is ../../lib compared to current location of ./util
        pathstr = [pathstr filesep '..' filesep '..'];
    end
    
    pathstr = [pathstr filesep 'lib' filesep];