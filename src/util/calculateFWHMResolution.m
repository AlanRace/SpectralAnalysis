function [massResolvingPower, deltamz, halfmaxleftmz, halfmaxrightmz] = calculateFWHMResolution(mzs, counts, peakmz)

% TODO: Check that the peak given is the maximum

peakLoc = find(mzs == peakmz);

if(isempty(peakLoc))
%     massResolvingPower = 0;
%     halfmaxleftloc = 0;
%     halfmaxrightloc = 0;
%     deltamz = 0;
%     return;
    
    error(['Can''t find the peak specified: ' num2str(peakmz)]);
end

halfmax = counts(peakLoc)/2;

halfmaxleftloc = 0;
halfmaxrightloc = 0;

for i = peakLoc:-1:2
    if(counts(i) > halfmax && counts(i-1) < halfmax)
        % Found the half max crossing point
        halfmaxleftloc = i;
        break;
    end
end

for i = peakLoc:length(counts)-1
    if(counts(i) > halfmax && counts(i+1) < halfmax)
        % Found the half max crossing point
        halfmaxrightloc = i;
        break;
    end
end

% Failed to find the peak boundaries
if(halfmaxleftloc == 0 || halfmaxrightloc == 0)
    massResolvingPower = 0;
    deltamz = 0;
    return;
end

deltamzleft = mzs(halfmaxleftloc)-mzs(halfmaxleftloc-1);
numbins = 1000;

halfmaxleftmzs = mzs(halfmaxleftloc-1):(deltamzleft/numbins):mzs(halfmaxleftloc);
halfmaxleft = interp1([mzs(halfmaxleftloc-1) mzs(halfmaxleftloc)], [counts(halfmaxleftloc-1) counts(halfmaxleftloc)], halfmaxleftmzs);
[~, halfmaxleftloc] = min(abs(halfmaxleft - halfmax));
halfmaxleftmz = halfmaxleftmzs(halfmaxleftloc);

deltamzright = mzs(halfmaxrightloc+1)-mzs(halfmaxrightloc);
halfmaxrightmzs = mzs(halfmaxrightloc):(deltamzright/numbins):mzs(halfmaxrightloc+1);
halfmaxright = interp1([mzs(halfmaxrightloc) mzs(halfmaxrightloc+1)], [counts(halfmaxrightloc) counts(halfmaxrightloc+1)], halfmaxrightmzs);
[~, halfmaxrightloc] = min(abs(halfmaxright - halfmax));
halfmaxrightmz = halfmaxrightmzs(halfmaxrightloc);

deltamz = halfmaxrightmz - halfmaxleftmz;
massResolvingPower = round(peakmz / deltamz);