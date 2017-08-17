disp(['This script compiles SpectralAnalysis, if you instead intended to start SpectralAnalysis, please use the command runSpectralAnalysis']);

path = [fileparts(mfilename('fullpath')) filesep 'src'];

% Ensure all folders are on the path
addpath(genpath(path));

% Compile preprocessing methods
cd 'src/processing/preprocessing/'

mex -largeArrayDims rebin.c
mex -largeArrayDims synaptReplaceZeros.c

cd '../../../'

% Compile MEPCA methods
cd 'src/processing/postprocessing/mepca'
compileMEPCA
cd '../../../../'

mcc -v -m SpectralAnalysis.m -a lib/ -a src/ -a *.m -a *.mex*