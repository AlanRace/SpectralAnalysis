function valid = isValidLicence()

valid = false;

licenceJar = 'SpectralAnalysisLicence.jar';

found = checkJAROnPath(licenceJar);

pathstr = getLibraryPath();

if(~found)
    javaaddpath([pathstr 'licence' filesep licenceJar]);
    
    % Check that it has been added to the path now, and if not throw an
    % exception
    found = checkJAROnPath(licenceJar);
    
    if(~found)
        exception = MException('addJARsToClassPath:FailedToAddJAR', ...
            ['Failed to add JAR file '''  'licence/' licenceJar ''', please ensure that it exists.']);
        throw(exception);
    end
end

if(isdeployed())
    licenceFile = [ctfroot() filesep '..' filesep 'SpectralAnalysis.lic'];
else
    licenceFile = [pathstr 'licence' filesep 'SpectralAnalysis.lic'];
end

if(exist(licenceFile, 'file'))
    fid = fopen(licenceFile, 'r');
    signature = fread(fid, Inf, '*char');
    fclose(fid);
    
    licenceCheck = com.alanmrace.spectralanalysislicence.EncryptLibrary([pathstr 'licence' filesep 'public.key']);
    
    if(licenceCheck.checkLicence(signature))
        valid = true;
    end
end