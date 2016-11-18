classdef CombineBinsZeroFilling < SpectralZeroFilling
    properties (Constant)
        Name = 'Combine Bins';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Bin Size', ParameterType.Integer, 2)];
    end
    
    methods
        function obj = CombineBinsZeroFilling(numBins)
            obj.Parameters = Parameter(CombineBinsZeroFilling.ParameterDefinitions(1), numBins);
        end
        
        function [spectralChannels, intensities] = zeroFill(obj, spectralChannels, intensities)
            numBins = obj.Parameters(1).value;
            
            zerosToAdd = mod(length(spectralChannels), numBins);
            
            if(zerosToAdd > 0)
                spectralChannels(end:end+(numBins-zerosToAdd)) = spectralChannels(end);
                intensities(end+(numBins-zerosToAdd)) = 0;
            end
            
            spectralChannels = mean(reshape(spectralChannels, numBins, []), 1);
            intensities = sum(reshape(intensities, numBins, []), 1);
        end
    end
    
    methods (Static)
        function bool = defaultsRequireGenerating()
            bool = 0;
        end                
        
%         function Parameters = generateDefaultsFromSpectrum(spectrum)
%             Parameters = Parameter(CombineBinsZeroFilling.ParameterDefinitions(1), CombineBinsZeroFilling.ParameterDefinitions(1).defaultValue);
%         end
    end
end