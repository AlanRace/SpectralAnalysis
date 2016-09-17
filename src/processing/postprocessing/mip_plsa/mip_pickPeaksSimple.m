% Function that performs feature extraction by peak-picking
%
% input
%
% X                 SxC matrix with C variables (channels) and S
%                   observations (spectra), i.e. each row consists of 
%                   one observation
% mzVector          vector with m/z-positions (of dimension Cx1)
% ppThreshold       value between 0 and 1, threshold for peak picking
% pp_ga_size        size of Gaussian filter for smoothing
% pp_ga_sigma       sigma for Gaussian filter
% plotResults       plot results 0/1
%
% output
%
% Xreduced          C'xS matrix of reduced data (with C' peaks)
% mzVectorReduced   vector with m/z-positions (of dimension C'x1)
% mask              0/1-mask of peak-positions and size C'x1
%
% (C)2008 Michael Hanselmann
%
function [Xreduced, mzVectorReduced, mask] = mip_pickPeaksSimple(X, mzVector, ppThreshold, pp_ga_size, pp_ga_sigma, plotResults)

    % default settings
    if nargin < 6
        plotResults = 0;
    end
    if nargin < 5
        pp_ga_sigma = 1;
    end
    if nargin < 4
        pp_ga_size = 4;
    end
    if nargin < 3
        ppThreshold = 0.0005;
    end    
    
    spectra = X;

    % calculate sum spectrum and put it in range [0, 1]
    spectraSum = sum(spectra, 1);
    spectraSum = (spectraSum-min(spectraSum));
    spectraSum = spectraSum/(max(spectraSum) + 1e-10);

    % peak picking
    % ...smoothing
    ga_x = -pp_ga_size:1:pp_ga_size;
    ga_f = exp( -(ga_x.^2)/(2*pp_ga_sigma^2) );
    ga_f = ga_f / sum(sum(ga_f));
    spectrumSmoothedShifted = conv(spectraSum, ga_f);
    spectrumSmoothed = zeros(1, size(spectraSum, 2));
    for i=1:(size(spectrumSmoothedShifted, 2)-2*pp_ga_size)
        spectrumSmoothed(1, i) = spectrumSmoothedShifted(1, i+pp_ga_size);
    end
    % ...detection of maxima/minima in smoothed sum spectrum
    [maxima, minima] = mip_peakdetect(spectrumSmoothed, ppThreshold);

    % now have a look at the unsmoothed data again
    % smoothing can cause peak shifts, so take the maximum in the
    % unsmoothed data by "hill-climbing", i.e. proceed to left and right as
    % long as the slope is positive and take the maximum
    for i=1:size(maxima, 1)
        % hill-climbing to left
        k = maxima(i, 1);
        while(k>1 && spectraSum(k-1)>spectraSum(k))
            k = k - 1;
        end
        % hill-climbing to right
        l = maxima(i, 1);
        while(l<length(spectraSum) && spectraSum(l+1)>spectraSum(l))
            l = l + 1;
        end
        if(spectraSum(k) > spectraSum(l))
            newMaxPos = k;
        else
            newMaxPos = l;
        end
        maxima(i, 1) = newMaxPos;
        maxima(i, 2) = spectraSum(newMaxPos);
    end
    for i=1:size(minima, 1)
        % down-climbing to left
        k = minima(i, 1);
        while(k>1 && spectraSum(k-1)<spectraSum(k))
            k = k - 1;
        end
        % down-climbing to right
        l = minima(i, 1);
        while(l<length(spectraSum) && spectraSum(l+1)<spectraSum(l))
            l = l + 1;
        end
        newMinPos = min(k, l);
        minima(i, 1) = newMinPos;
        minima(i, 2) = spectraSum(newMinPos);
    end
   
    % make mask to eliminate channels that are not picked by the peak
    % picker
    mask = zeros(size(spectra, 2), 1);
    for j=1:size(maxima, 1)
        mask(maxima(j, 1), 1) = 1;
    end

    % just take values at peak position (i.e. value for max channel for all
    % spatial locations)
    spectraReduced = spectra(:, mask>0);
    mzVectorReduced = mzVector(mask>0);

    % take sum over complete peak width (i.e. we sum over a
    % certain m/z range with regard to a spatial location)
    % basically go to left and right from peak position until spectrum
    % rises again
    minMask = zeros(size(spectra, 2), 1);
    for j=1:size(minima, 1)
        minMask(minima(j, 1), 1) = 1;
    end
    j = 1;
    numMax = 1;
    while(j < length(mask))
        % search next maximum    
        while(j < length(mask) && mask(j) == 0)
            j = j+1;
        end
        if(mask(j) == 1) % real maximum, i.e. not just last entry
            lastMax = j;
            % search next minimum (from maximum position)
            j = j+1;
            while(j < length(mask) && spectraSum(j) < spectraSum(j-1))
                j = j+1;
            end
            nextMin = j;        
            % search last minimum (from maximum position)
            j = lastMax - 1;
            while(j > 1 && spectraSum(j) < spectraSum(j+1))
                j = j-1;
            end        
            lastMin = j;
            j = lastMax + 1;
            lastMin = max(1, lastMin);
            nextMin = min(length(mask), nextMin);
            spectraReduced(:, numMax) = sum(spectra(:, lastMin:1:nextMin), 2);
            numMax = numMax+1;
        end
    end
    
    Xreduced = spectraReduced;
    
    % visualization of peak positions
    if(plotResults)
        figure;
        plot(mzVector, spectraSum); axis tight;
        hold on;
        plot(mzVector, spectrumSmoothed, 'm'); axis tight;
        hold on;
        if(size(maxima, 1) > 0 && size(minima, 1) > 0)
            plot(mzVector(maxima(:,1)), maxima(:,2), 'r*');
            hold on;
            plot(mzVector(minima(:,1)), minima(:,2), 'g*');
        end
        title('Picked peak positions (sum spectrum)');
        xlabel([num2str(mzVector(1)), ' to ', num2str(mzVector(length(mzVector))), ' (m/z, Da)']);
        ylabel('intensity');    
    end    
end