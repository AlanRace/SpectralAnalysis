%% SpectralAnalysis
% Spectral Imaging analysis software

% Get location of current m-file
if(isdeployed())
    disp('Initialising MATLAB, please wait...');
    path = ctfroot();
else
    path = [fileparts(mfilename('fullpath'))];
end

% Ensure all folders are on the path
addpath(genpath(path));

% Ensure libraries are on the path
addJARsToClassPath();

% Launch spectral analysis interface
try 
    SpectralAnalysisInterface();
catch err
    if(strcmp(err.identifier, 'MATLAB:class:undefinedMethod') && ~isempty(strfind(err.message, 'Figure')))
        disp(['ERROR: Missing MOOGL. Download from https://github.com/AlanRace/MOOGL and place in src/gui folder']);
    else
        throw(err);
    end
end


% Check that a valid licence exists, otherwise show the 
if(~isValidLicence())
    MissingLicenceFigure();
end