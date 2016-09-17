% function that performs a probabilistic latent semantic analysis of the
% input data matrix with preprocessing (baseline correction, feature
% extraction) and a AICc model selection criterion
%
% input
%
% X                 SxC matrix with C variables (channels) and S
%                   observations (spectra), i.e. each row consists of 
%                   one observation
% mzVector          vector with m/z-positions (of dimension Cx1)
% xyPos             vector with x- and y-positions corresponding to the 
%                   spectra in X (of dimension Sx2)
% relativeChange    stopping criterion, terminated if relative change in
%                   fit falls below that threshold
% ppThreshold       peak picking threshold, description see
%                   mip_pickPeaksSimple
% maxIter           maximum number of iterations, default is 500
% plotResults       plot results 0/1
%
% output
%
% ct                CxT matrix of characteristic spectra
% ts                TxS matrix of mixture vectors
%
% (C)2008 Michael Hanselmann
%
function [ts, ct] = mip_processData(X, mzVector, xyPos, relativeChange, ppThreshold, maxIter, plotResults)

    % do preprocessing, i.e. baseline correction and peak picking
%     X = single(X);
    disp(['Preprocessing the data containing ', num2str(size(X, 1)), ' spectra à ', num2str(size(X, 2)), ' channels (baseline correction, peak picking)']);
    baseLine = min(X);
    for j=1:size(X, 1)
        X(j, :) = X(j, :) - baseLine;
    end
    [X2, mzVector2, featureMask] = mip_pickPeaksSimple(X, mzVector, ppThreshold);

    % do pLSA for various settings of numComponents
    numComponents = 2;  % a decomposition with one component is not interesting
    minFound = 0;       % minimum reached?
    cts = [];           % stores solutions for ct
    tss = [];           % stores solutions for ts
    logliks = [];       % stores data log likelihoods
    boundNumber = 0;   % stores the number of bounds calculated for stopping criterion
    
    % search optimum value for numComponents
    while(~minFound)
        disp(['Performing pLSA with ', num2str(numComponents), ' components (', num2str(size(X2, 1)), ' spectra à ', num2str(size(X2, 2)), ' channels):']);
        [ct, ts, loglik] = mip_plsa(X2, numComponents, relativeChange, maxIter);
        % save log-likelihoods and decomposition results
        cts{numComponents} = ct;
        tss{numComponents} = ts;
        logliks(numComponents) = loglik;
        numComponents = numComponents + 1;
        % calculate AICc-trace
        [AICc, lastPenalty] = mip_calculateAICcTrace(X2, mzVector2, xyPos, logliks);
        
        % check stopping criterion

%        % 1. possibility: stop after a certain number of iterations
%        if(numComponents == 10)        
%        % 2. possibility: stop if AICc-curve has increased for several  
%        % steps in a row
%        steps = length(AICc);
%        while(steps > 1)
%            if(AICc(steps) <= AICc(steps-1))
%                break;
%            end
%            steps = steps - 1;
%        end
%        inARow = length(AICc) - steps;
%        if(inARow >= 5)    

        % 3. possibility: stop if theoretical optimum reached
        % theoretical optimum of loglik part is zero, therefore if one
        % point in the AICc trace curve is below the current penalty
        % function value we can stop the iterations, this bound is not
        % very tight though; as the -2*loglik/N is monotonously decreasing
        % and the penalty term is strictly increasing, we calculate the 
        % loglik value corresponding to an upper bound that exceeds the number 
        % of components in the tissue (like 100)
        if(numComponents == 3)
            bound = 30;
            disp(['Searching for upper bound with ', num2str(bound), ' components:']);
            [ct2, ts2, loglik] = mip_plsa(X2, bound, relativeChange, 10*maxIter); 
            maxloglik = 2*loglik/(size(X2, 1) * size(X2, 2));
        end
        penaltyBound = lastPenalty - maxloglik;
        disp(['Penalty bound vs. minimum previous AICc value: ', num2str(penaltyBound), '<=', num2str(min(AICc(2:length(AICc))))]);
        if(penaltyBound > min(AICc(2:length(AICc))))
            disp('Iterations aborted as penalty bound higher than previous AICc value'); 

            minFound = 1;
        end
    end
    
    % plot results
    if(plotResults == 1)
        % plot pLSA decomposition results (abundance maps + spectra)
        [minVal, minIdx] = min(AICc(2:length(AICc)));
        mip_showPLSAResults(tss{minIdx+1}, cts{minIdx+1}, xyPos, mzVector2);
        title(['pLSA result for ', num2str(minIdx+1), ' components']);
        % plot AICc trace
        figure; plot(2:length(logliks), AICc(2:length(logliks))); title('AICc trace');
        % plot sparsity
        mip_plotSparsity(X2, mzVector, mzVector2, featureMask, cts{minIdx+1});        
    end

end

