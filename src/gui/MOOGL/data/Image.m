classdef Image < Data
    % Image Class for storing image data.
    
    properties (SetObservable) 
        % 2D matrix for image data
        imageData;
    end
    
    methods
        function this = Image(imageData)
            % SpectralData Constructor for Image.
            %
            %   Image(imageData)
            %       imageData    - 2D matrix for image data.
            
            this.imageData = imageData;
            
            addlistener(this, 'imageData', 'PostSet', @(src, evnt) notify(this, 'DataChanged'));
        end
        
        function width = getWidth(this)
            % getWidth Get width of image in pixels.
            %
            %   width = getWidth()
            %       width - Width in pixels.
            
            width = size(this.imageData, 2);
        end
        
        function height = getHeight(this)
            % getHeight Get height of image in pixels.
            %
            %   height = getHeight()
            %       height - Height in pixels.
            
            height = size(this.imageData, 1);
        end
        
        function rescaleTo(this, value)
            % rescaleTo Rescale the image data to be between 0 and value.
            %
            %   rescaleTo(value)
            %       value - Maximum value to rescale to.
            
            this.imageData = (this.imageData ./ max(this.imageData(:))) * value;
        end
        
        function normalisedImage = normalisedTo(this, value)
            normalisedImage = Image(this.imageData ./ value);
        end
        
         function exportToImage(this)
            % exportToImage Export this object to an image file.
            %
            %   exportToImage()
            
            throw(UnimplementedMethodException('Image.exportToImage()'));
        end
        
        function exportToLaTeX(this)
            % exportToLaTeX Export this object to a LaTeX compatible file.
            %
            %   exportToLaTeX()
            
            throw(UnimplementedMethodException('Image.exportToLaTeX()'));
        end
    end
end