function can = canUseJSpectralAnalysis()
% Check if old versions of Java are used, and if so then we can't use the
% fast methods in JSpectralAnalysis (uses Java 7)
if(~isempty(strfind(version('-java'), '1.6')) || ...
    ~isempty(strfind(version('-java'), '1.5')) || ...
    ~isValidLicence())
    can = false;
else
    can = true;
end