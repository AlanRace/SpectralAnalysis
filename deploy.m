path = [fileparts(mfilename('fullpath')) filesep 'src'];

mcc -v -m SpectralAnalysis.m -a lib/ -a src/ -a *.m