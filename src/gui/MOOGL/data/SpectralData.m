classdef SpectralData < Data
    % SpectralData Class for storing spectral data. Can't use the name 'Spectrum' as it
    % is used by MATLAB, so can cause confusion / unexpected behaviour
    
    properties (SetObservable) 
        % Array of values representing the channels for the spectral data
        % e.g. m/z in mass spectrometry, wavenumbers in Raman, etc.
        spectralChannels;
        % Array of intensities in the spectrum
        intensities;
    end
       
    properties (SetObservable, SetAccess = private)
        % Is the spectrum continuous? i.e. should the spectrum be plotted with 
        % interpolation or as individual bars
        isContinuous = true;
    end
    
    methods (Static)
        function vector = ensureColumnVector(vector)
            % ensureColumnVector Return array in column form
            %
            %   vector = ensureColumnVector(vector)
            %       vector - 1D array 
            if(size(vector, 2) == 1)
                vector = vector';
            end
        end
    end
    
    methods
        function this = SpectralData(spectralChannels, intensities)
            % SpectralData Constructor for SpectralData.
            %
            %   SpectralData(spectralChannels, intensities)
            %       spectralChannels    - Array of values representing the channels for the spectral data
            %       intensities         - Array of intensities for the spectral data
            
            this.spectralChannels = SpectralData.ensureColumnVector(spectralChannels);
            this.intensities = SpectralData.ensureColumnVector(intensities);
            
            addlistener(this, 'spectralChannels', 'PostSet', @(src, evnt) notify(this, 'DataChanged'));
            addlistener(this, 'intensities', 'PostSet', @(src, evnt) notify(this, 'DataChanged'));
            addlistener(this, 'isContinuous', 'PostSet', @(src, evnt) notify(this, 'DataChanged'));
        end
        
        function setIsContinuous(obj, bool)
            % setIsContinuous Set whether the spectrum is continuous
            %
            %   setIsContinuous(bool)
            %       bool - true if spectrum is series of continuous values
            %           (should be plotted with interpolation) false if not
            
            obj.isContinuous = bool;
        end
        
        function setData(this, spectralChannels, intensities)
            % setData Set the spectral data and trigger DataChanged event.
            %
            %   setData(spectralChannels, intensities)
            %       spectralChannels    - Array of values representing the channels for the spectral data
            %       intensities         - Array of intensities for the spectral data
            
            this.spectralChannels = SpectralData.ensureColumnVector(spectralChannels);
            this.intensities = SpectralData.ensureColumnVector(intensities);
        end
        
        function exportToImage(this)
            % exportToImage Export this object to an image file.
            %
            %   exportToImage()
            
            throw(UnimplementedMethodException('SpectralData.exportToImage()'));
        end
        
        function exportToLaTeX(this)
            % exportToLaTeX Export this object to a LaTeX compatible file.
            %
            %   exportToLaTeX()
            
            throw(UnimplementedMethodException('SpectralData.exportToLaTeX()'));
        end
    end
end