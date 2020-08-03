spectralAnalysisPath = '/home/alan/Documents/GitProjects/SpectralAnalysis/';

inputFolder = [spectralAnalysisPath '/example-data/mouse-brain']; %location of imzML files to process
outputFoler = [spectralAnalysisPath '/example-data/mouse-brain'];
filesToProcess = dir([inputFolder filesep '*.imzML']); %gets all imzML files in folder

% Set up datacube generation variables
preprocessingWorkflowFile = [spectralAnalysisPath '/example-data/mouse-brain/mouse-brain-preprocessingWorkflow.sap']; %location of preprocessing file
nzm_multiple = 3; % multiple of non zero median

% Add SpectralAnalysis to the path - this only needs to be done once per MATLAB session
disp('Setting up ');
addpath(genpath(spectralAnalysisPath));
addJARsToClassPath();

% Generate preprocessing workflow
preprocessing = PreprocessingWorkflow();
preprocessing.loadWorkflow(preprocessingWorkflowFile);

peakPicking = GradientPeakDetection();
medianPeakFilter = PeakThresholdFilterMedian(1, nzm_multiple);
peakPicking.addPeakFilter(medianPeakFilter);

%%
for i = 1:length(filesToProcess)
    disp(['Processing ' filesToProcess(i).name]);

    input_file = [filesToProcess(i).folder filesep filesToProcess(i).name];

    %% Get the filename from the path
    [~, filename, ~] = fileparts(input_file);

    %% make datacubes from each dataset

    % obtain total spectrum
    disp(['Generating Total Spectrum for ' ,input_file]);
    parser = ImzMLParser(input_file);
    parser.parse;
    data = DataOnDisk(parser);

    spectrumGeneration = TotalSpectrum();
    spectrumGeneration.setPreprocessingWorkflow(preprocessing);

    totalSpectrum = spectrumGeneration.process(data);
    totalSpectrum = totalSpectrum.get(1);

    %% Peak picking
    disp('Peak picking ');
    peaks = peakPicking.process(totalSpectrum);
    
    spectralChannels_all = totalSpectrum.spectralChannels;
    spectralChannels = [peaks.centroid];

    %% Make datacube old
    disp(['! Generating data cube with ' num2str(length(peaks)) ' peaks...'])

    peakTolerance = -1;

    reduction = DatacubeReduction(peakTolerance);
    reduction.setPeakList(peaks);

    addlistener(reduction, 'FastMethods', @(src, canUseFastMethods)disp(['! Using fast Methods?   ' num2str(canUseFastMethods.bool)]));
    
    dataRepresentation = reduction.process(data);
    dataRepresentation = dataRepresentation.get(1);
    dataRepresentation_struct = dataRepresentation.saveobj();

    datacube = dataRepresentation.data;
    pixels = dataRepresentation.pixels;

    %% K means clustering
    disp('Performing k-means clustering on top 1000 peaks with k = 2 and cosine distance')

    [~, top1000idx] = maxk([peaks.intensity], 1000);
    datacube_small = datacube(:,top1000idx);

    [kmeans_idx, kmeans_c, ~, ~ ] = kmeans(datacube_small, 2, 'distance', 'cosine');

    %% Make mean spectrum
    disp('Saving cluster mean spectra')

    datacube_clust1 = datacube(kmeans_idx == 1,:);
    datacube_clust2 = datacube(kmeans_idx == 2,:);

    mean_intensity_clust1 = mean(datacube_clust1);
    mean_intensity_clust2 = mean(datacube_clust2);
    mean_intensity_all = mean(datacube);

    %% Save all
    disp('Saving files')

    save([outputFoler filesep filename '.mat'], '-struct', 'dataRepresentation_struct', '-v7.3')
    save([outputFoler filesep filename '.mat'], ...
    'peaks', 'spectralChannels_all', 'spectralChannels', ...
    'kmeans_idx', 'kmeans_c', ...
    'mean_intensity_clust1', 'mean_intensity_clust2', 'mean_intensity_all',...
    'top1000idx',...
    '-append')

    disp([input_file ' complete']);
end