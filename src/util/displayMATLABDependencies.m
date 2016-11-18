[files fullpList] = checkMATLABDependencies();

%%
str = [];

% 'Simulink Verification and Validation' toolbox is used for calling
% superclass functions

for i = 1:length(files)
    if(length(files(i).pathDependencies) > 1 && ...
            (length(files(i).pathDependencies) > 2 || isempty(cell2mat(strfind({files(i).pathDependencies.Name}, 'Simulink Verification and Validation')))))
        str = [str files(i).name '\n'];
        
        for j = 2:length(files(i).pathDependencies)
            str = [str '\t' files(i).pathDependencies(j).Name '\n'];
        end
        
        for j = 1:length(files(i).fileDependencies)
            if(isempty(strfind(files(i).fileDependencies{j}, 'SpectralAnalysis')))
                str = [str '\t' strrep(files(i).fileDependencies{j}, '\', '\\') '\n'];
            end
        end
    end
end

str = sprintf(str)