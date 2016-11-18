classdef Colour < handle
    properties
        r
        g
        b
    end
    
    methods
        function this = Colour(r, g, b)
            this.r = r;
            this.g = g;
            this.b = b;
        end
        
        function red = getRed(this)
            red = this.r;
        end
        
        function green = getGreen(this)
            green = this.g;
        end
        
        function blue = getBlue(this)
            blue = this.b;
        end
        
        function hex = toHex(this)
            hex = ['#' dec2hex(this.r, 2) dec2hex(this.g, 2) dec2hex(this.b, 2)];
        end
        
        function outputXML(this, fileID, indent)
            XMLHelper.indent(fileID, indent);
            fprintf(fileID, '<colour red="%d" green="%d" blue="%d" />\n', this.r, this.g, this.b);
        end
    end
end