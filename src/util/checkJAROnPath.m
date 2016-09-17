function found = checkJAROnPath(jarName)
    dpath = javaclasspath;
    strResults = strfind(dpath, jarName);

    found = 0;

    for i = 1:length(strResults)
        if(~isempty(strResults{i}))
            found = 1;
            break;
        end
    end