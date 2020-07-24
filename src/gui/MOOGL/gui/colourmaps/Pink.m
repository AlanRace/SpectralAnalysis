classdef Pink < Colourmap
    properties (Constant)
        Name = 'Pink';
    end
    
    methods (Static)        
        function colourMap = getColourMap(colourmapSize)
            if nargin < 1
                colourMap = pink;
            else
                colourMap = pink(colourmapSize);
            end
        end
    end
end