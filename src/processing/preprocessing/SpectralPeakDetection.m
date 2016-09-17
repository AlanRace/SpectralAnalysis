classdef SpectralPeakDetection < SpectralPreprocessing
    properties
        peakFilters
    end
    
    methods (Abstract)
        [spectralChannels, intensities, peakDetails] = detectPeaks(spectralChannels, intensities);     
    end
    
    methods
        function [spectralChannels, intensities, peakDetails] = process(this, spectralChannels, intensities)
            [spectralChannels, intensities, peakDetails] = this.detectPeaks(spectralChannels, intensities);
            
            % Filter the results of the peak detection
            [spectralChannels, intensities, peakDetails] = this.applyFilters(spectralChannels, intensities, peakDetails);
        end
        
        function this = addPeakFilter(this, peakFilter)
            if(~isa(peakFilter, 'PeakFilter'))
                exception = MException('SpectralPeakDetection:invalidArgument', 'Must provide an instance of a class that extends PeakFilter');
                throw(exception);
            end
            
            if(isempty(this.peakFilters))
                this.peakFilters = {peakFilter};
            else
                this.peakFilters(this.numberOfFilters() + 1) = {peakFilter};
            end
        end
        
        function numFilters = numberOfFilters(this)
            numFilters = length(this.peakFilters);
        end
        
        function peakFilter = getPeakFilter(obj, index)
            if(index <= 0 || index > obj.numberOfFilters())
                exception = MException('SpectralPeakDetection:invalidArgument', ['''index'' must be between 1 and ' num2str(obj.numberOfFilters())]);
                throw(exception);
            end
           
            peakFilter = obj.peakFilters{index};
        end
        
        function swap(obj, index1, index2)
            if(~(index1 > 0 && index1 <= obj.numberOfFilters() && index2 > 0 && index2 <= obj.numberOfFilters()))
                exception = MException('SpectralPeakDetection:invalidArgument', ['''index'' values must be between 1 and ' num2str(obj.numberOfFilters())]);
                throw(exception);
            end
            
            tmp = obj.peakFilters(index1);
            obj.peakFilters(index1) = obj.peakFilters(index2);
            obj.peakFilters(index2) = tmp;
        end
        
        function removePeakFilter(obj, index)
            if(index <= 0 || index > obj.numberOfFilters())
                exception = MException('SpectralPeakDetection:invalidArgument', ['''index'' must be between 1 and ' num2str(obj.numberOfFilters())]);
                throw(exception);
            end
            
            obj.peakFilters(index) = [];
        end
        
        function [spectralChannels, intensities, peakDetails] = applyFilters(this, spectralChannels, intensities, peakDetails)
            for i = 1:this.numberOfFilters()
                [spectralChannels, intensities, peakDetails] = this.peakFilters{i}.applyFilter(spectralChannels, intensities, peakDetails);
            end
        end
    end
end