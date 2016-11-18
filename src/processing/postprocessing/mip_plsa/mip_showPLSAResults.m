% function that plots the pLSA results
%
% input
%
% ts                TxS matrix with C variables (channels) and T
%                   tissue types - i.e. the matrix holding the abundance
%                   maps for the T tissue types
% ct                CxT matrix of pure, characteristic spectra
% xyPos             vector with x- and y-positions corresponding to the 
%                   spectra in X (of dimension Sx2)
% mzVector          vector with m/z-positions (of dimension Cx1)
% scale             rescale abundance maps to [0,1] 0/1
%
% output
%
% none
%
% (C)2008 Michael Hanselmann
%
function mip_showPLSAResults(ts, ct, xyPos, mzVector, scale) 

    % set defaults
    if(nargin < 5)
        scale = 1;
    end

    minX = min(xyPos(:,1));
    maxX = max(xyPos(:,1));
    minY = min(xyPos(:,2));
    maxY = max(xyPos(:,2));

    figure;
    subplot(size(ts, 1), 2, 1); 

    % write ts-entries to images
    for i=1:size(ts, 1)
        
        Img = zeros(maxY-minY+1, maxX-minX+1);
        
        for j=1:size(xyPos, 1)
            Img(xyPos(j, 2) - minY + 1, xyPos(j, 1) - minX + 1) = ts(i, j);
        end
        
        % abundance maps
        subplot(size(ts, 1), 2, 2*i-1); 
        imagesc(Img); 
        colormap gray;
        axis equal tight;      
        if(scale~=0)
            caxis([0, 1]);
        end
        colorbar;
        hold on;        
        
        % characteristic, "pure" spectra
        subplot(size(ts, 1), 2, 2*i); 
        bar(mzVector, ct(:, i)); axis tight;
    end
    
end