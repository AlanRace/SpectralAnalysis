function addJARsToClassPath()
    jimzMLParserVersion = '1.0-SNAPSHOT';
    jimzMLParserJar = ['jimzMLParser-' jimzMLParserVersion '.jar'];

    % Ensure that imzMLConverter is on the path
    found = checkJAROnPath(jimzMLParserJar);

    if(isdeployed())
        pathstr = ctfroot();
    else
        pathstr = fileparts(mfilename('fullpath'));
    end
    
    % lib folder is ../../lib compared to current location of ./util
    pathstr = [pathstr filesep '..' filesep '..' filesep 'lib' filesep];
    
    % If it's not already on the path then add it
    if(~found)
        javaaddpath([pathstr 'jimzMLParser' filesep jimzMLParserJar]);
        
        % Check that it has been added to the path now, and if not throw an
        % exception
        found = checkJAROnPath(jimzMLParserJar);
        
        if(~found)
            exception = MException('addJARsToClassPath:FailedToAddJAR', ...
       ['Failed to add JAR file ''' pathstr filesep 'jimzMLParser/' jimzMLParserJar ''', please ensure that it exists.']);
            throw(exception);
        end
    end
    
    found = checkJAROnPath('JSpectralAnalysis.jar');
    if(~found)
        javaaddpath(strrep([pathstr filesep 'JSpectralAnalysis' filesep 'commons-math3-3.2.jar'], '\', '\\'));
        javaaddpath(strrep([pathstr filesep 'JSpectralAnalysis' filesep 'jarhdf5-2.10.1.jar'], '\', '\\'));
        javaaddpath(strrep([pathstr filesep 'JSpectralAnalysis' filesep 'guava-18.0.jar'], '\', '\\'));
        javaaddpath(strrep([pathstr filesep 'JSpectralAnalysis' filesep 'JSIMS.jar'], '\', '\\'));
        javaaddpath(strrep([pathstr filesep 'JSpectralAnalysis' filesep 'JSpectralAnalysis.jar'], '\', '\\'));
        
        % Check that it has been added to the path now, and if not throw an
        % exception
        found = checkJAROnPath('JSpectralAnalysis.jar');
        
        if(~found)
            exception = MException('addJARsToClassPath:FailedToAddJAR', ...
       ['Failed to add JAR file ''' pathstr filesep 'JSpectralAnalysis/JSpectralAnalysis.jar' ''', please ensure that it exists.']);
            throw(exception);
        end
    end
    
    java.lang.System.setProperty('ncsa.hdf.hdf5lib.H5.hdf5lib', [pathstr filesep 'JSpectralAnalysis' filesep 'jhdf5.dll']);
%    [pathstr filesep 'JSpectralAnalysis' filesep 'jhdf5.dll']
end