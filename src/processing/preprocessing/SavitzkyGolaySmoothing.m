classdef SavitzkyGolaySmoothing < SpectralSmoothing
    properties (Constant)
        Name = 'Savitzky-Golay';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Window Size', ParameterType.Integer, 5), ...
                    ParameterDescription('Polynomial Order', ParameterType.Integer, 2)];
    end
    
    properties (SetAccess = private)
%         windowSize;
%         polynomialOrder;
        coeffs;
    end
    
    methods (Access = protected)
        function generateCoefficients(obj)
            % Generate the filter
            windowSize = obj.Parameters(1).value;
            polynomialOrder = obj.Parameters(2).value;
            
            A = ones(windowSize, polynomialOrder + 1);
            N = (windowSize - 1)/2;
            window = (-N:N)';

            for k = 1:polynomialOrder
                A(:, k+1) = window.^k;
            end

            h = (A'*A)\A';
            
            obj.coeffs = h(1, :);
        end
    end
    
    methods
        function SGS = SavitzkyGolaySmoothing(windowSize, polynomialOrder)
            if(nargin == 2)
                SGS.Parameters = Parameter(SavitzkyGolaySmoothing.ParameterDefinitions(1), windowSize);
                SGS.Parameters(2) = Parameter(SavitzkyGolaySmoothing.ParameterDefinitions(2), polynomialOrder);

                SGS.generateCoefficients();            
            end
        end
        
        function vargout = set(obj, varargin)
            varargout = set@hgsetget(obj, varargin{:});
            
            if(strcmp(varargin{1}, 'Parameters'))
                obj.generateCoefficients();
            end
        end
        
        function [spectralChannels, intensities] = smooth(obj, spectralChannels, intensities)
            intensities = conv(intensities, obj.coeffs, 'same');
        end
    end
end