% test script that demonstrates the AICc-enhanced plsa for a simple simulated dataset
%
% (c)2008 Michael Hanselmann


% ----------------------------------------
% create a data matrix X for test purposes
% each row of X contains one observation
% just replace X with your data
% ----------------------------------------

% use three predefined pure spectra and mix them according to predefined
% pattern
data = load('data.mat', 'pureSpectra');
pureSpectra = data.pureSpectra;
% the three mixture patterns are (1/0/0), (0.33/0.33/0.33), (0/0/1) 
% (from left to right, each area has the size 30x10 pixels)
pureAbundance = [[1;0;0] * ones(1, 300), [1/3;1/3;1/3] * ones(1,300), [0;0;1] * ones(1,300)];
X = (pureSpectra * pureAbundance)';
rand('twister', 10);
for i=1:size(X, 1)
    % add some noise
    X(i, :) = X(i, :) + 0.25 * X(i, :) .* (rand(1, size(pureSpectra, 1)) - 0.5);
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
mzVector = 1:size(pureSpectra, 1);


% --------------------------
% process the data with pLSA
% --------------------------
numComponents = 3;
relativeChange = 1e-4;
maxIter = 1000;
[ct, ts, loglik] = mip_plsa(X, numComponents, relativeChange, maxIter);


% -------------------------
% plot results
% -------------------------
% plot the ground truth
figure;
subplot(3,2,2);
bar(mzVector, pureSpectra(:, 1));
axis tight;
subplot(3,2,1);
imshow(reshape(pureAbundance(1, :), 30, 30));
axis tight;
subplot(3,2,4);
bar(mzVector, pureSpectra(:, 2));
axis tight;
subplot(3,2,3);
imshow(reshape(pureAbundance(2, :), 30, 30));
axis tight;
subplot(3,2,6);
bar(mzVector, pureSpectra(:, 3));
title('Ground truth - pure spectra and abundance maps without noise');
axis tight;
subplot(3,2,5);
imshow(reshape(pureAbundance(3, :), 30, 30));

% plot pLSA results
mip_showPLSAResults(ts, ct, xyPos, mzVector);
title(['pLSA result for ', num2str(numComponents), ' components with noise (possibly perturbated)']);

