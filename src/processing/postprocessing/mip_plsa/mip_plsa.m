% function that performs a probabilistic latent semantic analysis of the
% input data matrix
%
% input
%
% X                 SxC matrix with C variables (channels) and S
%                   observations (spectra), i.e. each row consists of 
%                   one observation
% numComponents     decompose the data into that many components (tissue
%                   types T)
% relativeChange    stopping criterion, terminated if relative change in
%                   fit falls below that threshold
% maxIter           maximum number of iterations, default is 500
%
% output
%
% ct                CxT matrix of characteristic spectra
% ts                TxS matrix of mixture vectors
% loglik            log-likelihood of the data
%
% for details see 
% 
% T. Hofmann. Probabilistic Latent Semantic Analysis, Uncertainty in Artificial Intelligence, 1999. 
% we use the matrix formulation to speed up the calculations in MATLAB (see also Kaban and Verbeek - http://www.cs.bham.ac.uk/~axk/ML_CODE/PLSA.m, http://lear.inrialpes.fr/~verbeek/software)
%
% (C)2008 Michael Hanselmann
%
function [ct, ts, loglik] = mip_plsa(X, numComponents, relativeChange, maxIter)

    % variable initialization
    Xt = X';
    [numChannels, numSpectra] = size(Xt);
    ct = mip_col_normalize(rand(numChannels, numComponents));
    ts = mip_col_normalize(ones(numComponents, numSpectra));
    if nargin < 4
        maxIter = 500; % default value
    end
    
    lastChange = 1/eps;
	err = 1e10;
    iter = 0;

    while(lastChange > relativeChange && iter < maxIter) 

        % update rules (EM algorithm as described by Hofmann99)
        ts = mip_col_normalize(ts .* (ct' * (Xt ./ (ct*ts + eps))));
        ct = mip_col_normalize(ct .* ((Xt ./ ( ct*ts + eps)) * ts'));

        % check model fit (here we use a least-squares fit, but this can 
        % easily be replaced by a KL-divergence fit);
        % we check for the RELATIVE change in fit
        model = (ones(numChannels, 1) * sum(Xt, 1))' .* (ct * ts)';
        errold = err;
        err = sum(sum((Xt - model').^2));
        lastChange = abs((err - errold)/err);
        iter = iter + 1;
        
        if(mod(iter, 25) == 0 || iter == 1)
            disp(['...iteration ', num2str(iter), ', relative change ', num2str(lastChange)]);
        end
        
    end
    
    % data log-likelihood
    loglik = sum(sum(Xt.*log(ct*ts + eps)));
   
end

function X = mip_col_normalize(X)
    % normalize column-wise
    sumX = sum(X);
    X = X ./ (ones(size(X, 1), 1) * (sumX + (sumX==0)));
end


