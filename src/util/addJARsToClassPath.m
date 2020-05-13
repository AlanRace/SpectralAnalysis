function addJARsToClassPath()

    jimzMLParserVersion = '1.0.8-jar-with-dependencies';
    jSpectralAnalysisVersion = '1.0.2';
    jSIMSVersion = '1.0.0';
    
    jimzMLParserJar = ['jimzmlparser-' jimzMLParserVersion '.jar'];
    jSpectralAnalysisJar = ['JSpectralAnalysis-' jSpectralAnalysisVersion '.jar'];
    jSIMSJar = ['JSIMS-' jSIMSVersion '.jar'];

    % Ensure that imzMLConverter is on the path
    found = checkJAROnPath(jimzMLParserJar);

    pathstr = getLibraryPath();
    
    % If it's not already on the path then add it
    if(~found)
        javaaddpath([pathstr 'jimzMLParser' filesep jimzMLParserJar]);
        
        % Check that it has been added to the path now, and if not throw an
        % exception
        found = checkJAROnPath(jimzMLParserJar);
        
        if(~found)
            exception = MException('addJARsToClassPath:FailedToAddJAR', ...
       ['Failed to add JAR file '''  'jimzMLParser/' jimzMLParserJar ''', please ensure that it exists.']);
            throw(exception);
        end
    end
    
    
    found = checkJAROnPath(jSpectralAnalysisJar);
    if(~found)
        javaaddpath([pathstr filesep 'JSpectralAnalysis' filesep 'commons-math3-3.3.jar']); %strrep([pathstr filesep 'JSpectralAnalysis' filesep 'commons-math3-3.3.jar'], '\', '\\'));
%         javaaddpath(strrep([pathstr filesep 'JSpectralAnalysis' filesep 'jarhdf5-2.10.1.jar'], '\', '\\'));
%         javaaddpath(strrep([pathstr filesep 'JSpectralAnalysis' filesep 'guava-18.0.jar'], '\', '\\'));
        javaaddpath([pathstr filesep 'JSpectralAnalysis' filesep jSIMSJar]); %strrep([pathstr filesep 'JSpectralAnalysis' filesep 'JSIMS.jar'], '\', '\\'));
        javaaddpath([pathstr filesep 'JSpectralAnalysis' filesep jSpectralAnalysisJar]); %strrep([pathstr filesep 'JSpectralAnalysis' filesep 'JSpectralAnalysis.jar'], '\', '\\'));

        % Check that it has been added to the path now, and if not throw an
        % exception
        found = checkJAROnPath(jSpectralAnalysisJar);
        
        if(~found)
            exception = MException('addJARsToClassPath:FailedToAddJAR', ...
       ['Failed to add JAR file ''' strrep([pathstr filesep], '\', '\\') 'JSpectralAnalysis/' jSpectralAnalysisJar '' ''', please ensure that it exists.']);
            throw(exception);
        end
    end
    
%     java.lang.System.setProperty('ncsa.hdf.hdf5lib.H5.hdf5lib', [pathstr filesep 'JSpectralAnalysis' filesep 'jhdf5.dll']);
%    [pathstr filesep 'JSpectralAnalysis' filesep 'jhdf5.dll']
end