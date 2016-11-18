function displayREADME()
    if(isdeployed())
        path = ctfroot();
    else
        path = [fileparts(mfilename('fullpath'))];
    end
    
    filepath = [path filesep 'files' filesep 'README'];
    
    fid = fopen(filepath);
    readme = fread(fid, Inf, '*char');
    fclose(fid);
    
    disp(readme');