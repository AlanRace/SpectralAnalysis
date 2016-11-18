% Function that estimates the noise in the data by first smoothing the data
% (spatially) and then taking the median of the residual sum of squares
%
% input
%
% X                 SxC matrix with C variables (channels) and S
%                   observations (spectra), i.e. each row consists of 
%                   one observation
% mzVector          vector with m/z-positions (of dimension Cx1)
% xyPos             vector with x- and y-positions corresponding to the 
%                   spectra in X (of dimension Sx2)
%
% output
%
% noiseVarEstimate  an estimate of the noise variance in the data (scalar)
%
%
% (C)2008 Michael Hanselmann
%
function noiseVarEstimate = mip_simpleNoiseEstimation(X, mzVector, xyPos)
    
    % make cube
    spectra = X;
    minX = min(xyPos(:,1));
    maxX = max(xyPos(:,1));
    minY = min(xyPos(:,2));
    maxY = max(xyPos(:,2));    
    dimensions = [maxY-minY+1, maxX-minX+1];
    cube = reshape(double(spectra), dimensions(1), dimensions(2), length(mzVector)); 

    % average spectrum at each position by averaging over the area given by
    % steps: (2*steps+1)^2-box function
    steps = 1;
    cubeAv = double(zeros(size(cube)));
    for i=1+steps:dimensions(1)-steps
        for j=1+steps:dimensions(2)-steps
            for k=i-steps:i+steps
                for l=j-steps:j+steps
                    cubeAv(i, j, :) = cubeAv(i, j, :) + 1/(2*steps+1)^2 * cube(k, l, :);
                end
            end
        end
    end

    % calculate median RSS, omit border area
    cubeRSS = (cube(1+steps:dimensions(1)-steps,1+steps:dimensions(2)-steps, :) - cubeAv(1+steps:dimensions(1)-steps,1+steps:dimensions(2)-steps, :)).^2;
    noiseVarEstimate = median(cubeRSS(:)); % mean also possible but less robust

end