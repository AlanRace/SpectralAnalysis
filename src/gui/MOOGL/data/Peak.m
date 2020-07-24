classdef Peak < Data
    % Peak Class for storing peak data. 
    
    properties (SetAccess = private) 
        spectralChannels;
        intensities;
        
        peakCentroid;
        centroidIntensity;
    end
    
    methods
        function this = Peak(spectralChannels, intensities, peakCentroid, centroidIntensity)
            % Peak Constructor for Peak.
            %
            %   Peak(spectralChannels, intensities, peakCentroid, centroidIntensity)
            %       spectralChannels  - Array that describes the spectral channels for only the peak region
            %       intensities       - Array for the peak region
            %       peakCentroid      - Spectral channel for the peak centroid
            %       centroidIntensity - Intensity at the peak centroid channel
            
            this.spectralChannels = spectralChannels;
            this.intensities = intensities;
            
            this.peakCentroid = peakCentroid;
            this.centroidIntensity = centroidIntensity;
        end
        
        function ppmError = calculatePPMErrorTo(this, spectralChannel)
            % calculatePPMErrorTo Calculate the PPM error for a specified spectral channel
            %
            %   ppmError = calculatePPMErrorTo(spectralChannel)
            %       spectralChannel  - 
            %       ppmError         - 
            
            diff = abs(this.peakCentroid - spectralChannel);
            
            ppmError = (diff / spectralChannel) * 1e6;
        end
        
        function fwhmResolution = calculateFWHMResolution(this)
            % calculateFWHMResolution Calculate the resolution of the peak using FWHM 
            %
            %   fwhmResolution = calculateFWHMResolution()
            %       fwhmResolution - 
            
            throw(UnimplementedMethodException('Peak.calculateFWHMResolution()'));
        end
        
        function exportToImage(this)
            % exportToImage Export this object to an image file.
            %
            %   exportToImage()
            
            throw(UnimplementedMethodException('Peak.exportToImage()'));
        end
        
        function exportToLaTeX(this)
            % exportToLaTeX Export this object to a LaTeX compatible file.
            %
            %   exportToLaTeX()
            
            throw(UnimplementedMethodException('Peak.exportToLaTeX()'));
        end
    end
end