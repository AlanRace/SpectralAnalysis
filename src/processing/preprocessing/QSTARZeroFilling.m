classdef QSTARZeroFilling < SpectralZeroFilling
    properties (Constant)
        Name = 'QSTAR';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Min Spectral Channel', ParameterType.Double, 50), ...
                    ParameterDescription('Max Spectral Channel', ParameterType.Double, 1000), ...
                    ParameterDescription('Detector Bin Size', ParameterType.Double, 0.1)];
    end
    
    properties (Access = private)
        mzsFull;
    end
    
    methods
        function obj = QSTARZeroFilling(minSpectralChannel, maxSpectralChannel, detectorBinSize)
            obj.Parameters = Parameter(QSTARZeroFilling.ParameterDefinitions(1), minSpectralChannel);
            obj.Parameters(2) = Parameter(QSTARZeroFilling.ParameterDefinitions(2), maxSpectralChannel);
            obj.Parameters(3) = Parameter(QSTARZeroFilling.ParameterDefinitions(3), detectorBinSize);
            
            obj.mzsFull = (sqrt(minSpectralChannel):detectorBinSize:sqrt(maxSpectralChannel)+detectorBinSize).^2;
        end
        
        function [mzsFull, countsFull] = zeroFill(obj, spectralChannels, intensities)
            minMZ = obj.Parameters(1).value;
            detectorBinSize = obj.Parameters(3).value;
            
            time = sqrt(spectralChannels);
            
            index = ceil(time / detectorBinSize) - floor(sqrt(minMZ) / detectorBinSize);

            mzsFull = obj.mzsFull;

            % Remove any negative indicies (occurs when minMZ is supplied and it is
            % greater than the minimum m/z in the data) and any that are above the
            % maximum m/z
            intensities = intensities(index > 0 & index <= size(mzsFull, 2));
            index = index(index > 0 & index <= size(mzsFull, 2));

            countsFull = zeros(size(mzsFull));
            countsFull(index) = intensities;
        end
    end
    
    methods (Static)
        function bool = defaultsRequireGenerating()
            bool = 1;
        end                
        
        function Parameters = generateDefaultsFromSpectrum(spectrum)
            Parameters = Parameter(QSTARZeroFilling.ParameterDefinitions(1), min(spectrum.spectralChannels));
            Parameters(2) = Parameter(QSTARZeroFilling.ParameterDefinitions(2), max(spectrum.spectralChannels));
            
            time = sqrt(spectrum.spectralChannels);
            
            timeDiff = time(2:end) - time(1:end-1);
    
            if(min(timeDiff) < 0)
                timeDiff = timeDiff * -1;
            end

            detectorBinSize = mode(timeDiff(timeDiff < 1.5*min(timeDiff)));
            
            Parameters(3) = Parameter(QSTARZeroFilling.ParameterDefinitions(3), detectorBinSize);
        end
    end
end