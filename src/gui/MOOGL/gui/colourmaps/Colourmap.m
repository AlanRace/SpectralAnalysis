classdef Colourmap < handle
    methods (Abstract, Static)
        colourMap = getColourMap(size)
    end
end