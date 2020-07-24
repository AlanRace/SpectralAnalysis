classdef PixelSelection < Copyable
    properties (Access = protected)
        % PixelSelection is a 2D array of size height x width, where 1
        % indicates that a pixel is selected and 0 indicates unselected
        pixelSelection;
    end
    
    events
        PixelSelectionChanged
    end
    
    methods
        function this = PixelSelection(width, height)
            error('PixelSelection:Deprecated', 'DEPRECATED: replace with RegionOfInterest');
            if(~isnumeric(width) || ~isnumeric(height))
                exception = MException('PixelSelection:InvalidArgument', 'Must supply width and height as integers.');
                throw(exception);
            end
            
            this.pixelSelection = zeros(width, height);
        end
        
        function image = getImage(this)
            image = this.pixelSelection;
        end
        
        
    end
    
    methods (Access = protected)
        function cpObj = copyElement(this)
            % Make a shallow copy 
            cpObj = copyElement@Copyable(this);
            
            cpObj.pixelSelection = this.pixelSelection;
        end
    end
end