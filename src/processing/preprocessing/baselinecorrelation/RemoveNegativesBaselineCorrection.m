classdef RemoveNegativesBaselineCorrection < SpectralBaselineCorrection
    properties (Constant)
        Name = 'Remove Negatives';
        Description = '';
        
        ParameterDefinitions = [];
    end
    
    methods
        function obj = RemoveNegativesBaselineCorrection()
        end
        
        function [spectralChannels, intensities baseline] = baselineCorrect(obj, spectralChannels, intensities)
            intensities(isnan(intensities)) = 0;
            intensities(intensities < 0) = 0;
        end
    end
end