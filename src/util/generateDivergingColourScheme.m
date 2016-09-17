function diverging = generateDivergingColourScheme(imageData, scaleSize)

minVal = min(imageData(:));
maxVal = max(imageData(:));

% scaleSize = 256;
zeroLoc = round((abs(minVal) / (maxVal - minVal)) * scaleSize);

if(zeroLoc <= 0)
    zeroLoc = 1;
elseif(zeroLoc >= scaleSize)
    zeroLoc = scaleSize;
end

diverging = zeros(scaleSize, 3);

for i = 1:zeroLoc
    diverging(i, 2) = ((zeroLoc - (i - 1)) / zeroLoc);
end

for i = zeroLoc:scaleSize
    diverging(i, [1 3]) = (i - zeroLoc) / (scaleSize - zeroLoc);
end

diverging(zeroLoc, :) = [0 0 0];