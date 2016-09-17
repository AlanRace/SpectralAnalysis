% colourScale 'r' (red), 'g' (green), 'b' (blue), 'y' (yellow), 'm'
% (magenta), 'c' (cyan), 'h' hot, 'p' pink

function [image, maxValue, minValue] = colouriseData(data, positiveScaleColour, negativeScaleColour, quant)

numBits = 2^16;
image = zeros(size(data, 1), size(data, 2), 3, 'uint16');

if(nargin < 4)
    minValue = min(data(:));
    maxValue = max(data(:));
else
    minValue = -1*quantile(-1*data(:), quant);
    maxValue = quantile(data(:), quant);
end

% Ensure that the data starts at 0
if(nargin < 3)
    data = data - min(data(:));
end

positiveData = data;
positiveData(data < 0) = 0;
positiveData(positiveData > maxValue) = maxValue;
positiveData = (positiveData./maxValue) * numBits;

switch(positiveScaleColour)
    case 'r'
        image(:, :, 1) = positiveData;
    case 'g'
        image(:, :, 2) = positiveData;
    case 'b'
        image(:, :, 3) = positiveData;
    case 'y'
        image(:, :, 1) = positiveData;
        image(:, :, 2) = positiveData;
    case 'm'
        image(:, :, 1) = positiveData;
        image(:, :, 3) = positiveData;
    case 'c'
        image(:, :, 2) = positiveData;
        image(:, :, 3) = positiveData;
    case 'h'
        n = 3/8;
        
        positiveDataR = (positiveData./max(positiveData(:))) / n;
        positiveDataR(positiveDataR > 1) = 1;
        
        positiveDataG = (positiveData./max(positiveData(:))) - n;
        positiveDataG(positiveDataG < 0) = 0;
        positiveDataG = (positiveDataG / n);
        positiveDataG(positiveDataG > 1) = 1;
        
        positiveDataB = (positiveData./max(positiveData(:))) - (2*n);
        positiveDataB(positiveDataB < 0) = 0;
        positiveDataB = (positiveDataB / (1-(2*n)));
        
        image(:, :, 1) = positiveDataR * numBits;
        image(:, :, 2) = positiveDataG * numBits;
        image(:, :, 3) = positiveDataB * numBits;
    case 'p'
        n = 3/8;
        
        positiveDataR = (positiveData./max(positiveData(:))) / n;
        positiveDataR(positiveDataR > 1) = 1;
        
        positiveDataG = (positiveData./max(positiveData(:))) - n;
        positiveDataG(positiveDataG < 0) = 0;
        positiveDataG = (positiveDataG / n);
        positiveDataG(positiveDataG > 1) = 1;
        
        positiveDataB = (positiveData./max(positiveData(:))) - (2*n);
        positiveDataB(positiveDataB < 0) = 0;
        positiveDataB = (positiveDataB / (1-(2*n)));
        
        image(:, :, 1) = (sqrt(((2*(positiveData/max(positiveData(:)))) + (positiveDataR)) / 3)) * numBits;
        image(:, :, 2) = (sqrt(((2*(positiveData/max(positiveData(:)))) + (positiveDataG)) / 3)) * numBits;
        image(:, :, 3) = (sqrt(((2*(positiveData/max(positiveData(:)))) + (positiveDataB)) / 3)) * numBits;
    case 'j'
        m = 64;
        n = ceil(m/4);
        u = [(1:1:n)/n ones(1,n-1) (n:-1:1)/n]';
        g = ceil(n/2) - (mod(m,4)==1) + (1:length(u))';
        r = g + n;
        b = g - n;
        g(g>m) = [];
        r(r>m) = [];
        b(b<1) = [];
%         J = zeros(m,3);
%         J(r,1) = u(1:length(r));
%         J(g,2) = u(1:length(g));
%         J(b,3) = u(end-length(b)+1:end);

        positiveDataR = round((positiveData./max(positiveData(:))) * m);
        tempData = positiveDataR;
        positiveDataR = zeros(size(positiveDataR));
        min(r)
        for i = min(r):length(r)
            positiveDataR(tempData == r(i)) = r(i);
        end
        imagesc(positiveDataR);figure;
        positiveDataG = round((positiveData./max(positiveData(:))) * m);
        tempData = positiveDataG;
        positiveDataG = zeros(size(positiveDataG));
        
        for i = min(g):length(g)
            positiveDataG(tempData == g(i)) = g(i);
        end
        
        positiveDataB = round((positiveData./max(positiveData(:))) * m);
        tempData = positiveDataB;
        positiveDataB = zeros(size(positiveDataB));
        
        for i = min(b):length(b)
            positiveDataB(tempData == b(i)) = b(i);
        end
        
         positiveDataR = positiveDataR ./ m;
         positiveDataG = positiveDataG ./ m;
         positiveDataB = positiveDataB ./ m;
%         u = [(1:1:n)/n ones(1,n-1) (n:-1:1)/n]';
% g = ceil(n/2) - 1 + (1:length(u))';
% r = g + n;
% b = g - n;
% g(g>1) = [];
% r(r>1) = [];
% b(b<1) = [];
% J = zeros(1,3);
% J(r,1) = u(1:length(r));
% J(g,2) = u(1:length(g));
% J(b,3) = u(end-length(b)+1:end);

        image(:, :, 1) = positiveDataR * numBits;
        image(:, :, 2) = positiveDataG * numBits;
        image(:, :, 3) = positiveDataB * numBits;
end

if(nargin > 2)
    negativeData = data;
    negativeData(data > 0) = 0;
    negativeData(negativeData < minValue) = minValue;
    negativeData = (negativeData./minValue) * numBits;
    
    switch(negativeScaleColour)
        case 'r'
            image(:, :, 1) = negativeData;
        case 'g'
            image(:, :, 2) = negativeData;
        case 'b'
            image(:, :, 3) = negativeData;
        case 'y'
            image(:, :, 1) = negativeData;
            image(:, :, 2) = negativeData;
        case 'm'
            image(:, :, 1) = negativeData;
            image(:, :, 3) = negativeData;
        case 'c'
            image(:, :, 2) = negativeData;
            image(:, :, 3) = negativeData;
    end
end


        

% pca5 = positivePCA5 + negativePCA5;
% 
% h = figure('PaperPosition', [0, 0, 4, 10]); 
% imagesc(pca5);
% axis image, axis off
% 
% sizeOfMap = 100;
% numOfTicksPos = (floor(sizeOfMap*(thresh/(thresh+threshMin)))-1);
% numOfTicksNeg = (floor(sizeOfMap*(threshMin/(thresh+threshMin)))-1);
% 
% map = zeros(numOfTicksPos+numOfTicksNeg+1, 3);
% map(1:numOfTicksNeg+1, 1) = 1:-1*(1/numOfTicksNeg):0;
% map(1:numOfTicksNeg+1, 3) = 1:-1*(1/numOfTicksNeg):0;
% map(numOfTicksNeg+1:end, 2) = 0:(1/numOfTicksPos):1;
