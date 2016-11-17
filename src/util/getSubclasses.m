function [classFiles classNames] = getSubclasses(superclass, includeNone)
    % Get the location of the m file to instigate the search for subclasses
    if(isdeployed())
        spectralAnalysisPath = [ctfroot() filesep 'SpectralAnal'];
    else
        spectralAnalysisPath = [fileparts(mfilename('fullpath'))];
    end
    
    spectralAnalysisPath = [spectralAnalysisPath filesep '..' filesep];
    
    % Limit the locations to speed up the search when looking for specific
    % types
    if(strcmp(superclass, 'Parser') || strcmp(superclass, 'ToBinaryConverter'))
        spectralAnalysisPath = [spectralAnalysisPath 'io' filesep];
    elseif(strcmp(superclass, 'SpectralZeroFilling'))    
        spectralAnalysisPath = [spectralAnalysisPath 'processing' filesep 'preprocessing' filesep];
    end
    
    % This file is located within ./util folder so go to parent directory
    % and start the search
    fileList = getmFilesFromAllFolders(spectralAnalysisPath);
    
    % Check if we are including the option of 'None' for a class name -
    % used in some preprocessing lists
    if(includeNone)
        classNames = {'None'};
        classFiles = {'None'};
    else
        classNames = {};
        classFiles = {};
    end

    % Extract the name of each .m file that has been found
    for i = 1:length(fileList)
        filename = fileList(i).name(1:end-2); % Strip off the .m

        % Ensure that we are only looking at classes
        if(exist(filename, 'class'))
            try
                % Check whether the class is a subclass of the specified
                % super class
                if(ismember(superclass, superclasses(filename)))
                    % Select a name to use to describe the class found 
                    try
                        className = eval([filename '.Name']);
                    catch err
                        % If the class doesn't have a Name field then just use
                        % the class name
                        if(strcmp(err.identifier, 'MATLAB:subscripting:classHasNoPropertyOrMethod') || ... % For MATLAB R2010a and later
                                strcmp(err.identifier, 'MATLAB:noSuchMethodOrField')) % For MATLAB R2009a
                            className = filename;
                        else
                            rethrow(err)
                        end
                    end

                    classFile = filename;

                    if(isempty(classNames))
                        classNames{1} = className;
                        classFiles{1} = classFile;
                    else
                        classNames{end+1} = className;
                        classFiles{end+1} = classFile;
                    end
                end
            catch err
                filename
                rethrow(err)
            end
        end
    end
end