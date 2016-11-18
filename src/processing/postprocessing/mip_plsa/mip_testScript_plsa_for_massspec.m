% test script that demonstrates the AICc-enhanced plsa for mass spectrometry
% imaging data on a simple simulated dataset
%
% (c)2008 Michael Hanselmann
%

testOnArtificialSet = 1;
if(testOnArtificialSet)
    % create three characteristic spectra; other than in the publication we use 
    % completely artificial, randomly generated spectra here (which is
    % sufficient for illustration purposes)
    pureSpectra = 1e6*rand(100, 3).^100;
    % the tissue mix consists of three tissue types and we have three different 
    % mixtures in stripe-shaped areas, the correct mixtures are (1/0/0), 
    % (0.33/0.33/0.33), (0/0/1) (from left to right, each has the size 30x10 pixels)
    pureAbundance = [[1;0;0] * ones(1, 300), [1/3;1/3;1/3] * ones(1,300), [0;0;1] * ones(1,300)];

    % create spectral datacube, m/z-vector and position vector
    spectra = (pureSpectra * pureAbundance)';
    for i=1:size(spectra, 1)
        % add some noise to make it more realistic 
        % makes use of image processing toolbox)
        spectra(i, :) = imnoise(uint16(spectra(i, :)),'poisson');    
%           % additive, intensity dependent noise
%           spectra(i, :) = spectra(i, :) + 0.1 * spectra(i, :) .* (rand(1, 100) - 0.5);          
    end
    i = 1;
    xyPos = [];
    for x=1:30
        for y=1:30
            xyPos(i, 2) = y; 
            xyPos(i, 1) = x;
            i = i+1;
        end        
    end
    mzVector = 1:100;

    % plot the ground truth
    figure;
    subplot(3,2,2);
    bar(mzVector, pureSpectra(:, 1));
    subplot(3,2,1);
    imshow(reshape(pureAbundance(1, :), 30, 30));
    subplot(3,2,4);
    bar(mzVector, pureSpectra(:, 2));
    subplot(3,2,3);
    imshow(reshape(pureAbundance(2, :), 30, 30));
    subplot(3,2,6);
    bar(mzVector, pureSpectra(:, 3));
    title('Ground truth - pure spectra and abundance maps');
    subplot(3,2,5);
    imshow(reshape(pureAbundance(3, :), 30, 30));
end

% process the data with AICc-enhanced pLSA
mip_processData(spectra, mzVector, xyPos, 1e-5, 0.005, 500, 1);