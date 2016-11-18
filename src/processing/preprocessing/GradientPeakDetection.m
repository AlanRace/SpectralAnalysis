classdef GradientPeakDetection < SpectralPeakDetection
    properties (Constant)
        Name = 'Gradient';
        Description = '';
        
        ParameterDefinitions = [];
    end
    
    methods        
        function [spectralChannels, intensities, peakDetails] = detectPeaks(obj, spectralChannels, intensities)
            % Ensure that the intensities are oriented as a row
            if(size(intensities, 2) == 1)
                intensities = intensities';
            end
            
            % Calculate first differential
            firstDerivative = gradient(intensities);

            % Calculate second differential
            secondDerivative = gradient(firstDerivative);

            % Look for zero crossings between data points
            indicies = find((firstDerivative(1:end-1) .* firstDerivative(2:end)) <= 0);

            % Pull out maxima
            indicies = indicies(secondDerivative(indicies) < 0);

            % It could either be the left or the right index so check which is the
            % actual maximum value
            indiciesRight = indicies + 1;
        %     indiciesRight = indiciesRight(indiciesRight < length(counts));
            indiciesLeft = indicies - 1;
        %     indiciesLeft = indiciesLeft(indiciesLeft > 0);

            toRemove = indiciesRight > length(intensities);

            indicies(toRemove) = [];
            indiciesRight(toRemove) = [];
            indiciesLeft(toRemove) = [];

            toRemove = indiciesLeft <= 0;

            indicies(toRemove) = [];
            indiciesRight(toRemove) = [];
            indiciesLeft(toRemove) = [];
            
            [temp, collected] = max([intensities(indicies); intensities(indiciesRight); intensities(indiciesLeft)], [], 1);

            indicies = unique(sort([indicies(collected == 1) indiciesRight(collected == 2) indiciesLeft(collected == 3)]));

            % Remove any 'peaks' that aren't real
            indicies(intensities(indicies) <= 0) = [];

            % Determine the peak details
            if(nargout > 2)
                peakDetails = zeros(length(indicies), 7);
                
                for i = 1:length(indicies)
                    ind = indicies(i);
                    
                    left = ind-1;
                    
                    while(left > 0 && firstDerivative(left) > 0)
                        left = left - 1;
                    end
                    
                    if(left == 0)
                        left = 1;
                    end
                    
                    right = ind+1;
                    
                    while(right < length(firstDerivative) && firstDerivative(right) < 0)
                        right = right + 1;
                    end
                    
                    peakDetails(i, :) = [spectralChannels(left) spectralChannels(ind) spectralChannels(right) intensities(ind) right-left left right];                    
                end
            end
            
            % Select the peaks
            spectralChannels = spectralChannels(indicies);
            intensities = intensities(indicies);
        end
    end
end