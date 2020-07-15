classdef RebinZeroFilling < SpectralZeroFilling
    properties (Constant)
        Name = 'Rebin';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Min Spectral Channel', ParameterType.Double, 50), ...
                    ParameterDescription('Max Spectral Channel', ParameterType.Double, 1000), ...
                    ParameterDescription('Bin Size', ParameterType.Double, 0.1)];
    end
    
    methods
        function obj = RebinZeroFilling(minSpectralChannel, maxSpectralChannel, binSize)
            obj.Parameters = Parameter(RebinZeroFilling.ParameterDefinitions(1), minSpectralChannel);
            obj.Parameters(2) = Parameter(RebinZeroFilling.ParameterDefinitions(2), maxSpectralChannel);
            obj.Parameters(3) = Parameter(RebinZeroFilling.ParameterDefinitions(3), binSize);
        end
        
        function [spectralChannels, intensities] = zeroFill(obj, spectralChannels, intensities)
            [spectralChannels, intensities] = rebin(spectralChannels, intensities, [obj.Parameters(1).value obj.Parameters(2).value], obj.Parameters(3).value);
        end
    end
    
    methods (Static)
        function bool = defaultsRequireGenerating()
            bool = 1;
        end                
        
        function Parameters = generateDefaultsFromSpectrum(spectrum)
            Parameters = Parameter(RebinZeroFilling.ParameterDefinitions(1), min(spectrum.spectralChannels));
            Parameters(2) = Parameter(RebinZeroFilling.ParameterDefinitions(2), max(spectrum.spectralChannels));
            Parameters(3) = Parameter(RebinZeroFilling.ParameterDefinitions(3), RebinZeroFilling.ParameterDefinitions(3).defaultValue);
        end
    end
end