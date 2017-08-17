mex -largeArrayDims calculateE.c
mex -largeArrayDims updateQ.c

if(isunix)
    mex -largeArrayDims symmeig.c -lmwlapack
elseif(ispc)
    if strcmp(regexp(computer, '..$', 'match'), '64')
        arch = 'win64';
    else
        arch = 'win32';
    end
    
    lapacklib = fullfile(matlabroot, 'extern', 'lib', arch, 'microsoft', 'libmwlapack.lib');
    mex('-largeArrayDims', 'symmeig.c', lapacklib)
end