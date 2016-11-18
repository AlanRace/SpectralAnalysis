% Function that calculates the AICc-trace from a given likelihood vector
% and the data
%
% input
%
% X                 SxC matrix with C variables (channels) and S
%                   observations (spectra), i.e. each row consists of 
%                   one observation
% mzVector          vector with m/z-positions (of dimension Cx1)
% xyPos             vector with x- and y-positions corresponding to the 
%                   spectra in X (of dimension Sx2)
% logliks           vector of data likelihoods
%
% output
%
% AICc              vector of AICc-values (of dimension equal to logliks)
% currPenalty       last value of penalty term
%
% (C)2008 Michael Hanselmann
%
function [AICc, currPenalty] = mip_calculateAICcTrace(X, mzVector, xyPos, logliks)

    % AICc criterion for optimal model selection
    noiseVar = mip_simpleNoiseEstimation(X, mzVector, xyPos);
    N = size(X, 1) * size(X, 2);
    for i=1:length(logliks)
        K = i*(size(X, 1) + size(X, 2));
        AICc(i) = -2*logliks(i)/N + 2*K/N*noiseVar + 1/N*2*K*(K+1)/(N-K-1); 
        currPenalty = 2*K*noiseVar/N + 1/N*2*K*(K+1)/(N-K-1);
    end

end