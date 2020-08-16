disp(['This script compiles SpectralAnalysis, if you instead intended to start SpectralAnalysis, please use the command runSpectralAnalysis']);

curDir = pwd;

path = [curDir filesep '..'];

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

if ispc
    wOption = "'WinMain:SpectralAnalysis,version=1.4'";
    osText = 'win';
    defaultInstallDir = 'C:\Program Files\SpectralAnalysis';
elseif isunix
    defaultInstallDir = '/usr/local/SpectralAnalysis';
end

saFolder = [getSpectralAnalysisFolder() filesep];
deployFolder = [saFolder filesep 'deploy'];


mccCommand = "mcc -o SpectralAnalysis -W %s -T link:exe -v SpectralAnalysis.m -d %s -a files -a lib -a src -a version.txt -r '%s'";
mccCommand = sprintf(mccCommand, wOption, deployFolder, [saFolder 'files' filesep 'SA_icon_256.ico']) %'C:\Program Files\MATLAB\R2020a\toolbox\compiler\resources\default_icon.ico')%

cd(saFolder);
eval(mccCommand);
cd(curDir);

matlabVersion = version('-release');
matlabYear = str2num(matlabVersion(1:end-1));

if matlabYear >= 2020
    installerOpts = compiler.package.InstallerOptions('ApplicationName', 'SpectralAnalysis',...
        'Version', saversion(false), ...
        'AuthorCompany', 'Alan Race',...
        'AuthorName', 'Alan Race',...
        'AuthorEmail', 'alan.race@uni-marburg.de',...
        'InstallerName', 'SpectralAnalysis_Installer',...
        'InstallerIcon', [deployFolder filesep 'SpectralAnalysis_resources' filesep 'icon_48.png'], ...
        'InstallerLogo', [deployFolder filesep 'SpectralAnalysis_resources' filesep 'installerLogo.png'], ...
        'InstallerSplash', [deployFolder filesep 'SpectralAnalysis_resources' filesep 'installerSplash.png'], ...
        'OutputDir', deployFolder, ...
        'DefaultInstallationDir', defaultInstallDir, ...
        'Summary', 'Software for the analysis and interactive exploration of spectral imaging data.', ...
        'Description', 'Software for the analysis and interactive exploration of spectral imaging data (such as mass spectrometry imaging and Raman spectroscopy mapping), including visualisation of both images and spectra, preprocessing, multivariate analysis and machine learning.');

    compiler.package.installer([deployFolder filesep 'SpectralAnalysis.exe'], [deployFolder filesep 'requiredMCRProducts.txt'], 'Options', installerOpts);
end


if ispc
    movefile([deployFolder filesep 'SpectralAnalysis.exe'], [deployFolder filesep 'SpectralAnalysis-' saversion(false) '-' osText '.exe']);
    
    if matlabYear >= 2020
         movefile([deployFolder filesep 'SpectralAnalysis_Installer.exe'], [deployFolder filesep 'SpectralAnalysis-' saversion(false) '-' osText '-installer-web.exe']);
    end
end