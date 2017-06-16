classdef OrbitrapZeroFilling < SpectralZeroFilling
    properties (Constant)
        Name = 'Orbitrap';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Min Spectral Channel', ParameterType.Double, 50), ...
                    ParameterDescription('Max Spectral Channel', ParameterType.Double, 1000), ...
                    ParameterDescription('Detector Bin Size', ParameterType.Double, 0.1)];
    end
    
    properties (Access = private)
        mzsFull;
    end
    
    methods
        function obj = OrbitrapZeroFilling(minSpectralChannel, maxSpectralChannel, detectorBinSize)
            obj.Parameters = Parameter(OrbitrapZeroFilling.ParameterDefinitions(1), minSpectralChannel);
            obj.Parameters(2) = Parameter(OrbitrapZeroFilling.ParameterDefinitions(2), maxSpectralChannel);
            obj.Parameters(3) = Parameter(OrbitrapZeroFilling.ParameterDefinitions(3), detectorBinSize);
            
            obj.mzsFull = 1/sqrt(minSpectralChannel) :detectorBinSize : 1/sqrt(maxSpectralChannel)+detectorBinSize;
            obj.mzsFull = ones(size(obj.mzsFull))./(obj.mzsFull.^2);
        end
        
        function [mzsFull, countsFull] = zeroFill(obj, spectralChannels, intensities)
            if(isempty(spectralChannels))
                mzsFull = obj.mzsFull;
                counts = zeros(size(mzsFull));
                
                return;
            end
            
            minMZ = obj.Parameters(1).value;
            detectorBinSize = obj.Parameters(3).value;
            
            frequency = ones(size(spectralChannels))./sqrt(spectralChannels);
            
            index = ceil(frequency / detectorBinSize) - floor(1/sqrt(minMZ) / detectorBinSize);

            mzsFull = obj.mzsFull;
            
%             % Remove any negative indicies (occurs when minMZ is supplied and it is
%             % greater than the minimum m/z in the data) and any that are above the
%             % maximum m/z
%             intensities = intensities(index > 0 & index <= size(mzsFull, 2));
%             index = index(index > 0 & index <= size(mzsFull, 2));
% 
%             countsFull = zeros(size(mzsFull));
%             countsFull(index) = intensities;

            mzsFull = mzsFull';
%             countsFull = countsFull';

%             assignin('base', 'o_sc', spectralChannels);
%             assignin('base', 'o_in', intensities);
%             assignin('base', 'o_mf', mzsFull);

            % Ensure that the data can be successfully interpolated and
            % that values do not fall outside of the full m/z list
            % generated
            intensities(spectralChannels > max(mzsFull)) = [];
            spectralChannels(spectralChannels > max(mzsFull)) = [];
            
            intensities(spectralChannels < min(mzsFull)) = [];
            spectralChannels(spectralChannels < min(mzsFull)) = [];

            countsFull = interp1(spectralChannels, intensities, mzsFull, 'linear');
            countsFull(isnan(countsFull)) = 0;
            
%             countsFull = sparse(countsFull);
        end
    end
    
    methods (Static)
        function bool = defaultsRequireGenerating()
            bool = 1;
        end                
        
        function Parameters = generateDefaultsFromSpectrum(spectrum)
            Parameters = Parameter(OrbitrapZeroFilling.ParameterDefinitions(1), min(spectrum.spectralChannels));
            Parameters(2) = Parameter(OrbitrapZeroFilling.ParameterDefinitions(2), max(spectrum.spectralChannels));
            
            % Go from m/z axis to time axis
            frequency = ones(size(spectrum.spectralChannels))./sqrt(spectrum.spectralChannels);

            freqDiff = frequency(2:end) - frequency(1:end-1);
            detectorBinSize = mode(freqDiff(freqDiff > 1.5*max(freqDiff)));

            
%             figure, plot(spectrum.spectralChannels(1:end-1), freqDiff, '.')
%             detectorBinSize
%             mode(freqDiff)
%             max(freqDiff) ./ mode(freqDiff)
%             round(max(freqDiff) ./ mode(freqDiff)) - (max(freqDiff) ./ mode(freqDiff))

            if(isnan(detectorBinSize))
                detectorBinSize = mode(freqDiff);
            end
            
            Parameters(3) = Parameter(OrbitrapZeroFilling.ParameterDefinitions(3), detectorBinSize);
        end
    end
end