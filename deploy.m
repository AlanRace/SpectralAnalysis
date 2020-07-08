disp(['This script compiles SpectralAnalysis, if you instead intended to start SpectralAnalysis, please use the command runSpectralAnalysis']);

path = fileparts(mfilename('fullpath'));

srcPath = [path filesep 'src'];

% Ensure all folders are on the path
addpath(genpath(srcPath));

% Compile preprocessing methods
cd([srcPath filesep 'processing' filesep 'preprocessing']);

mex -largeArrayDims rebin.c
mex -largeArrayDims synaptReplaceZeros.c

cd '../../../'

% Compile MEPCA methods
cd([srcPath filesep 'processing' filesep 'postprocessing' filesep 'mepca'])
compileMEPCA

cd(path)

mcc -v -m SpectralAnalysis.m -a lib/ -a src/ -a *.m -a *.mex*