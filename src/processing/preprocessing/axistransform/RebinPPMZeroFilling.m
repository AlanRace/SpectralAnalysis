classdef RebinPPMZeroFilling < SpectralZeroFilling
    properties (Constant)
        Name = 'PPM Rebin';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Min Spectral Channel', ParameterType.Double, 50), ...
                    ParameterDescription('Max Spectral Channel', ParameterType.Double, 1000), ...
                    ParameterDescription('PPM', ParameterType.Double, 1)];
    end
    
    properties (SetAccess = private)
        sChannels;
    end
    
    methods
        function obj = RebinPPMZeroFilling(minSpectralChannel, maxSpectralChannel, binSize)
            obj.Parameters = Parameter(RebinPPMZeroFilling.ParameterDefinitions(1), minSpectralChannel);
            obj.Parameters(2) = Parameter(RebinPPMZeroFilling.ParameterDefinitions(2), maxSpectralChannel);
            obj.Parameters(3) = Parameter(RebinPPMZeroFilling.ParameterDefinitions(3), binSize);
            
            minmz = obj.Parameters(1).value;
            maxmz = obj.Parameters(2).value;
            
            obj.sChannels = minmz;

            while(obj.sChannels(end) < maxmz)
                obj.sChannels(end+1) = obj.sChannels(end) + ((obj.sChannels(end) * obj.Parameters(3).value) / 1e6);
            end
        end
        
        function [spectralChannels, intensities] = zeroFill(obj, spectralChannels, intensities)
            %[spectralChannels, intensities] = rebin(spectralChannels, intensities, [obj.Parameters(1).value obj.Parameters(2).value], obj.Parameters(3).value);
            y = discretize(spectralChannels, obj.sChannels);

            intensities(isnan(y)) = [];
            y(isnan(y)) = [];
            
            newintensities = zeros(size(obj.sChannels));
            newintensities(y) = newintensities(y) + intensities;

            spectralChannels = obj.sChannels;
            intensities = newintensities;
        end
    end
    
    methods (Static)
        function bool = defaultsRequireGenerating()
            bool = 1;
        end                
        
        function Parameters = generateDefaultsFromSpectrum(spectrum)
            Parameters = Parameter(RebinPPMZeroFilling.ParameterDefinitions(1), min(spectrum.spectralChannels));
            Parameters(2) = Parameter(RebinPPMZeroFilling.ParameterDefinitions(2), max(spectrum.spectralChannels));
            Parameters(3) = Parameter(RebinPPMZeroFilling.ParameterDefinitions(3), RebinPPMZeroFilling.ParameterDefinitions(3).defaultValue);
        end
    end
end