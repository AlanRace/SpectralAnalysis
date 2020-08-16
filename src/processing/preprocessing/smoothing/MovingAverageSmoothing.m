classdef MovingAverageSmoothing < SpectralSmoothing
    properties (Constant)
        Name = 'Moving Average';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Window Size', ParameterType.Integer, 5)];
    end
    
    properties (SetAccess = private)
        coeffs;
    end
    
    methods (Access = protected)
        function obj = generateCoefficients(obj)
            % Generate the filter
            windowSize = obj.Parameters(1).value;

            % Create the Gaussian filter
            obj.coeffs = ones(1,windowSize) / windowSize;
        end
    end
    
    methods
        function obj = MovingAverageSmoothing(windowSize)
            obj.Parameters = Parameter(MovingAverageSmoothing.ParameterDefinitions(1), windowSize);
            
            obj = generateCoefficients(obj);            
        end
        
        function [spectralChannels, intensities] = smooth(obj, spectralChannels, intensities)
            intensities = conv(intensities, obj.coeffs, 'same');
        end
    end
end