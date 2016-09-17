% function that claculates the sparsity of the mixture vectors of the
% decomposition result
%
% input
%
% X                 SxC matrix with C variables (channels) and S
%                   observations (spectra), i.e. each row consists of 
%                   one observation
% mzVector          vector with m/z-positions (of dimension Cx1)
% mzVector2         peak-picked mzVector
% featureMask       indicator array with 0s and 1s indicating which peak
%                   positions have been selected
% ct                CxT matrix with characteristic spectra (see mip_plsa)
%
% output
%
% none
%
% this function uses Hoyer's spasity measure as described in "Non-negative Matrix Factorization with Sparseness Constraints" (2004)
%
% (C)2008 Michael Hanselmann
%
function mip_plotSparsity(X, mzVector, mzVector2, featureMask, ct)

    % sparsity calculations, see Hoyer01
    numComponents = size(ct, 2);
    sparseness = zeros(size(X, 2), 1);
    sqrtN = sqrt(numComponents);
    for i=1:size(X, 2);
        xVec = (ct(i, :)/norm(ct(i, :)))';
        sparseness(i) = ((sqrtN - sum(xVec, 1))/sqrt(sum(xVec.*xVec, 1)))/(sqrtN - 1); % normally we would have to use abs(xVec) in L1-norm, but all entries are positive anyway
    end
    j = 1;
    res = zeros(1, size(featureMask, 1));
    for i=1:size(featureMask, 1)
        if(featureMask(i)==1)
            res(i) = sparseness(j);
            j = j + 1;
        end
    end
    
    figure;
    % data plot
    ax(1) = subplot(2, 1, 1);
    bar(mzVector2, ct);
    title(['bar plot of the ', num2str(numComponents), ' component types (left to right)']);
    % sparsity plot
    ax(2) = subplot(2, 1, 2);
    bar(min(mzVector):(mzVector(2)-mzVector(1)):max(mzVector), res);
    title('sparsity indicating decisive m/z positions');
    
    linkaxes(ax, 'x');
    
end