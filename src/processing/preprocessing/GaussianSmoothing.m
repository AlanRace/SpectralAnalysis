classdef GaussianSmoothing < SpectralSmoothing % TODO: Change SpectralSmoothing to appropriate parent class
    properties (Constant)
        Name = 'Gaussian'; % TODO: Provide a sensible name
        Description = '';
        
        % TODO: Fill in parameter definitions
        ParameterDefinitions = [ParameterDescription('Window Size', ParameterType.Integer, 5), ...
                        ParameterDescription('Sigma', ParameterType.Double, 2)]; 
    end
    
    properties
        windowSize;
        sigma;
        
        coeffs;
    end
    
    methods
        function this = GaussianSmoothing(windowSize, sigma)
            % Store the parameters for use in the smooth function
            this.windowSize = windowSize;
            this.sigma = sigma;
            
            N = (windowSize - 1) / 2;
            this.coeffs = (1 / (sqrt(2 * pi) * sigma)) * exp(-(-N:N).^2 / (2* sigma^2));
        end
        
        function [spectralChannels, intensities] = smooth(obj, spectralChannels, intensities)
            % TODO: Smooth the spectrum using any parameters required
            
            intensities = conv(intensities, obj.coeffs, 'same');
        end
    end
end