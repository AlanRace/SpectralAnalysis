function found = checkJAROnPath(jarName)
    if(isdeployed())
        found = 1;
        return;
    end

    dpath = javaclasspath();
    strResults = strfind(dpath, jarName);

    found = 0;

    for i = 1:length(strResults)
        if(~isempty(strResults{i}))
            found = 1;
            break;
        end
    end