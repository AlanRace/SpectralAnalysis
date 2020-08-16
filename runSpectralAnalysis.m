% Get location of current m-file
path = [fileparts(mfilename('fullpath')) filesep 'src'];

% Ensure all folders are on the path
addpath(fileparts(mfilename('fullpath')));
addpath(genpath(path));

SpectralAnalysis