classdef InterpolationRebinZeroFilling < SpectralZeroFilling
    properties (Constant)
        Name = 'Interpolation Rebin';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Min Spectral Channel', ParameterType.Double, 50), ...
                    ParameterDescription('Max Spectral Channel', ParameterType.Double, 1000), ...
                    ParameterDescription('Bin Size', ParameterType.Double, 0.1)];
    end
    
    methods
        function obj = InterpolationRebinZeroFilling(minSpectralChannel, maxSpectralChannel, binSize)
            obj.Parameters = Parameter(InterpolationRebinZeroFilling.ParameterDefinitions(1), minSpectralChannel);
            obj.Parameters(2) = Parameter(InterpolationRebinZeroFilling.ParameterDefinitions(2), maxSpectralChannel);
            obj.Parameters(3) = Parameter(InterpolationRebinZeroFilling.ParameterDefinitions(3), binSize);
        end
        
        function [spectralChannels, intensities] = zeroFill(obj, spectralChannels, intensities)
            sChannels = obj.Parameters(1).value:obj.Parameters(3).value:obj.Parameters(2).value;

            intensities = interp1(spectralChannels, intensities, sChannels);
            spectralChannels = sChannels;
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