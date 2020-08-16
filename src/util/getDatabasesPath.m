function pathstr = getDatabasesPath()
    if(isdeployed())
        pathstr = ctfroot();
    else
        pathstr = fileparts(mfilename('fullpath'));
        
        % files folder is ../../files compared to current location of ./util
        pathstr = [pathstr filesep '..' filesep '..'];
    end
    
    pathstr = [pathstr filesep 'files' filesep 'databases'];