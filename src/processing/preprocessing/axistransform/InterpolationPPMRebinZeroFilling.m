classdef InterpolationPPMRebinZeroFilling < SpectralZeroFilling
    properties (Constant)
        Name = 'Interpolation PPM Rebin';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Min Spectral Channel', ParameterType.Double, 50), ...
                    ParameterDescription('Max Spectral Channel', ParameterType.Double, 1000), ...
                    ParameterDescription('PPM', ParameterType.Double, 1)];
    end
    
    properties (SetAccess = private)
        sChannels;
    end
    
    methods
        function obj = InterpolationPPMRebinZeroFilling(minSpectralChannel, maxSpectralChannel, binSize)
            obj.Parameters = Parameter(InterpolationRebinZeroFilling.ParameterDefinitions(1), minSpectralChannel);
            obj.Parameters(2) = Parameter(InterpolationRebinZeroFilling.ParameterDefinitions(2), maxSpectralChannel);
            obj.Parameters(3) = Parameter(InterpolationRebinZeroFilling.ParameterDefinitions(3), binSize);
            
            
            minmz = obj.Parameters(1).value;
            maxmz = obj.Parameters(2).value;
            
            tempArray = zeros(1, 10000);
            
            ppmValue = obj.Parameters(3).value / 1e6;
            
            tempArray(1) = minmz;
            lastValue = tempArray(1);
            currentIndex = 2;

            while(true)
                if currentIndex > length(tempArray)
                    obj.sChannels = [obj.sChannels tempArray];
                    currentIndex = 1;
                end
                
                newValue = lastValue + (lastValue * ppmValue);
                tempArray(currentIndex) = newValue;
                
                if newValue > maxmz
                    break
                end
                
                lastValue = newValue;
                currentIndex = currentIndex + 1;
            end
            
            obj.sChannels = [obj.sChannels tempArray(1:currentIndex)];
        end
        
        function [spectralChannels, intensities] = zeroFill(obj, spectralChannels, intensities)
            intensities = interp1(spectralChannels, intensities, obj.sChannels);
            intensities(isnan(intensities)) = 0;
            spectralChannels = obj.sChannels;
        end
    end
    
    methods (Static)
        function bool = defaultsRequireGenerating()
            bool = 1;
        end                
        
        function Parameters = generateDefaultsFromSpectrum(spectrum)
            Parameters = Parameter(InterpolationRebinZeroFilling.ParameterDefinitions(1), min(spectrum.spectralChannels));
            Parameters(2) = Parameter(InterpolationRebinZeroFilling.ParameterDefinitions(2), max(spectrum.spectralChannels));
            Parameters(3) = Parameter(InterpolationRebinZeroFilling.ParameterDefinitions(3), InterpolationRebinZeroFilling.ParameterDefinitions(3).defaultValue);
        end
    end
end