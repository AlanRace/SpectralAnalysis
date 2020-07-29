classdef Peak < Data
    % Peak Class for storing peak data. 
    
    properties (SetAccess = private) 
        % Reference to SpectralData where the peak was detected
        spectralData;
        
        % Description of the peak itself
        centroid;
        intensity;
        
        minSpectralChannel;
        maxSpectralChannel;
        
        
%         sumIntensity;
    end
    
    methods
        function this = Peak(spectralData, centroid, intensity, minSpectralChannel, maxSpectralChannel)
            % Peak Constructor for Peak.
            %
            %   Peak(spectralData, centroid, minSpectralChannel, maxSpectralChannel)
            %       spectralData        - SpectralData instance where the
            %                           peak was detected
            %       centroid            - Centroid value for the peak
            %       intensity           - Peak intensity
            %       minSpectralChannel  - Minimum spectral channel for the
            %                           peak limits
            %       maxSpectralChannel  - Maximum spectral channel for the
            %                           peak limits
            
            this.spectralData = spectralData;
            
            this.centroid = centroid;
            this.intensity = intensity;
            
            if nargin > 3
                this.minSpectralChannel = minSpectralChannel;
                this.maxSpectralChannel = maxSpectralChannel;

                this.setDescription([num2str(this.centroid, '%.5f') ' (' num2str(this.minSpectralChannel, '%.5f') ' - ' num2str(this.maxSpectralChannel, '%.5f') ')']);
            else
                this.setDescription(num2str(this.centroid, '%.5f'));
            end
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