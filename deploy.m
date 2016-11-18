disp(['This script compiles SpectralAnalysis, if you instead intended to start SpectralAnalysis, please use the command runSpectralAnalysis']);

path = [fileparts(mfilename('fullpath')) filesep 'src'];

% Ensure all folders are on the path
addpath(genpath(path));

mcc -v -m SpectralAnalysis.m -a lib/ -a src/ -a *.m