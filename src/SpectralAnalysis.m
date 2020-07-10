%% SpectralAnalysis
% Spectral Imaging analysis software

% Get location of current m-file
if(isdeployed())
    disp('Initialising MATLAB, please wait...');
    path = ctfroot();
    disp(path);
else
    path = fileparts(mfilename('fullpath'));
    
    % Ensure all folders are on the path
    addpath(genpath(path));
end

% Ensure libraries are on the path
addJARsToClassPath();

% Check if SpectralAnalysis folder exists
spectralAnalysisHome = [homepath filesep '.SpectralAnalysis'];

% TODO: Check last version and if newer then copy over
if ~exist(spectralAnalysisHome, 'file')
    mkdir(spectralAnalysisHome);
    
    copyfile([path filesep '..' filesep 'files' filesep 'profiles'], [spectralAnalysisHome filesep 'profiles'])
end

% TODO: Check version on github to see if update available

% Launch spectral analysis interface
try 
    spectralAnalysis = SpectralAnalysisInterface();
catch err
    if((strcmp(err.identifier, 'MATLAB:class:undefinedMethod') || strcmp(err.identifier, 'MATLAB:class:InvalidSuperClass')) ...
            && ~isempty(strfind(err.message, 'Figure')))
        disp('ERROR: Missing MOOGL. Download from https://github.com/AlanRace/MOOGL and place in src/gui/MOOGL folder');
        
        return;
    else
        throw(err);
    end
end


% Check that a valid licence exists, otherwise show the 
if(~isValidLicence())
    MissingLicenceFigure();
end