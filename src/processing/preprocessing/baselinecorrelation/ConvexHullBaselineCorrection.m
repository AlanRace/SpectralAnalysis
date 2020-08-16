classdef ConvexHullBaselineCorrection < SpectralBaselineCorrection
    properties (Constant)
        Name = 'Convex Hull';
        Description = '';
        
        ParameterDefinitions = [];
    end
    
    methods
        function obj = ConvexHullBaselineCorrection()
        end
        
        function [spectralChannels, intensities baseline] = baselineCorrect(obj, spectralChannels, intensities)
            k = convhull(spectralChannels, intensities);

            % Only need the values of k as they increase (below the spectrum) and not
            % the ones that touch the top of the peaks 
            currentVal = k(1);

            for i = 2:length(k)
                if(k(i) < currentVal)
                    break;
                end

                currentVal = k(i);
            end

            k = k(1:i-1);

            % Now need to generated an interpreted baseline between the points in k
            baseline = interp1(spectralChannels(k), intensities(k), spectralChannels);

            % Subtract the baseline
            intensities = intensities - baseline;
        end
    end
end