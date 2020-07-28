%% SpectralAnalysis
% Spectral Imaging analysis software
function spectralAnalysis = SpectralAnalysis()

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
    
    copyfile([path filesep 'files' filesep 'profiles'], [spectralAnalysisHome filesep 'profiles'])
end

% TODO: Check version on github to see if update available

% Launch spectral analysis interface
spectralAnalysis = SpectralAnalysisInterface();

