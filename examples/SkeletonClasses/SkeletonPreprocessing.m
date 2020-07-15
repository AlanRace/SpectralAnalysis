classdef SkeletonPreprocessing < SpectralSmoothing % TODO: Change SpectralSmoothing to appropriate parent class
    properties (Constant)
        Name = 'Skeleton Preprocessing'; % TODO: Provide a sensible name
        Description = 'This is just a template class';
        
        % TODO: Fill in parameter definitions
        ParameterDefinitions = [ParameterDescription('Skeleton Parameter 1', ParameterType.Integer, 5), ...
                        ParameterDescription('Skeleton Parameter 2', ParameterType.Double, 1.05)]; 
    end
    
    properties
        skeletonParameter1;
        skeletonParameter2;
    end
    
    methods
        function this = MovingAverageSmoothing(skeletonParameter1, skeletonParameter2)
            % Store the parameters for use in the smooth function
            this.skeletonParameter1 = skeletonParameter1;
            this.skeletonParameter2 = skeletonParameter2;
        end
        
        function [spectralChannels, intensities] = smooth(obj, spectralChannels, intensities)
            % TODO: Smooth the spectrum using any parameters required
            
%             intensities = ??;
        end
    end
end