classdef Chromatogram < SpectralData
    % Chromatogram Class for storing chromatogram data.
    
    methods
        function obj = Chromatogram(time, intensities)
            obj = obj@SpectralData(time, intensities);
        end
    end
end