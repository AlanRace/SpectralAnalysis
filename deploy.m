path = [fileparts(mfilename('fullpath')) filesep 'src'];

% Ensure all folders are on the path
addpath(genpath(path));

mcc -v -m SpectralAnalysis.m -a lib/ -a src/ -a *.m