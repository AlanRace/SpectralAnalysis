classdef MedianBaselineCorrection < SpectralBaselineCorrection
    properties (Constant)
        Name = 'Median';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Window Size', ParameterType.Integer, 5)];
    end
    
    methods
        function obj = MedianBaselineCorrection(windowSize)
            obj.Parameters = Parameter(MedianBaselineCorrection.ParameterDefinitions(1), windowSize);
        end
        
        function [spectralChannels, intensities baseline] = baselineCorrect(obj, spectralChannels, intensities)
            windowSize = obj.Parameters(1).value;
            
            try
                intensities = intensities - medfilt2(intensities, [1 windowSize]);
            catch err
                len1 = mod (windowSize, 2);
                if isequal (len1, 0)
                    exception = MException('MedianBaselineCorrection:InvalidArgument', ...
                        'Cannot use even number for the window size of this filter. Please choose odd number for window size');
                    throw(exception);
                end

                Siz_In = length(intensities);

    %             temp = zeros(1, windowSize);
                index = ceil(windowSize / 2);

                baseline = zeros(size(intensities));

                for i = 1:(Siz_In - (windowSize - 1))  
                    temp = intensities(i:i+windowSize-1);

                    temp = sort(temp);
                    baseline(i+index-1) = temp (index);
                end

                for i = (Siz_In - (windowSize - 2)):Siz_In
                    baseline(i) = intensities(i);
                end

                intensities = intensities - baseline;
            end
        end
    end
end