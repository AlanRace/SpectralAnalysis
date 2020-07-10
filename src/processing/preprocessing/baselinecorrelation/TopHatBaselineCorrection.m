classdef TopHatBaselineCorrection < SpectralBaselineCorrection
    properties (Constant)
        Name = 'Top-Hat';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Element Width', ParameterType.Integer, 5)];
    end
    
    properties (SetAccess = private)
        structuringElement;
    end
    
%     properties (SetAccess = private)
%         windowSize = 11;
%         structuringElement;
%     end
    
    methods
        function obj = TopHatBaselineCorrection(elementWidth)
            obj.Parameters = Parameter(TopHatBaselineCorrection.ParameterDefinitions(1), elementWidth);
            
            obj.structuringElement = strel('line', elementWidth, 0);
        end
        
        function [spectralChannels, intensities, baseline] = baselineCorrect(obj, spectralChannels, intensities)
            baseline = imopen(intensities, obj.structuringElement);

            % Subtract the baseline
            intensities = intensities - baseline;
        end
    end
end