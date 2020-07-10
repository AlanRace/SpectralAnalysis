disp(['This script compiles SpectralAnalysis, if you instead intended to start SpectralAnalysis, please use the command runSpectralAnalysis']);

path = fileparts(mfilename('fullpath'));

srcPath = [path filesep 'src'];

% Ensure all folders are on the path
addpath(genpath(srcPath));

% Compile preprocessing methods
cd([srcPath filesep 'processing' filesep 'preprocessing' filesep 'axistransform']);
mex -largeArrayDims rebin.c

cd([srcPath filesep 'processing' filesep 'preprocessing' filesep 'axistransform' filesep 'experimental']);
mex -largeArrayDims synaptReplaceZeros.c

% Compile MEPCA methods
cd([srcPath filesep 'processing' filesep 'postprocessing' filesep 'mepca'])
compileMEPCA

cd(path)

mcc -v -m SpectralAnalysis.m -a lib/ -a src/ -a *.m -a *.mex*