classdef RegionOfInterest < Copyable
    
    properties (SetAccess = protected)
        width;
        height;
        
        name;
        colour;
        
        pixelSelection;
    end
    
    events
        NameChanged;
        ColourChanged;
        
        PixelSelectionChanged;
    end
    
    methods
        function this = RegionOfInterest(width, height)
            if(~isnumeric(width) || ~isnumeric(height))
                exception = MException('RegionOfInterest:InvalidArgument', 'Must supply width and height as integers.');
                throw(exception);
            end
            
            this.width = width;
            this.height = height;
            
            this.pixelSelection = false(height, width);
            
            % Provide a default name and colour
            this.name = 'Region of interest';
            this.colour = Colour(0, 0, 255);
        end
        
        function setName(this, name)
            this.name = name;
            
            notify(this, 'NameChanged');
        end
        
        function name = getName(this)
            name = this.name;
        end
        
        function setColour(this, colour)
            if(~isa(colour, 'Colour'))
                exception = MException('RegionOfInterst:InvalidArgument', 'Error calling setColour, must supply an instance of Colour as an argument');
                throw(exception);
            else
                this.colour = colour;
            end
        end
        
        function colour = getColour(this)
            colour = this.colour;
        end
        
        function addPixel(this, x, y)
            if(x > 0 && x <= this.width && y > 0 && y <= this.height)
                this.pixelSelection(y, x) = 1;
                
                this.notify('PixelSelectionChanged');
            else
                exception = MException('RegionOfInterest:InvalidArgument', ...
                    ['addPixel: x must be between 1 and ' num2str(this.width) '. y must be between 1 and ' num2str(this.height)]);
                throw(exception);
            end
        end
        
        function addPixels(this, binaryImage)
            if(isequal(size(this.pixelSelection), size(binaryImage)))
                if(islogical(binaryImage))
                    this.pixelSelection = this.pixelSelection | binaryImage;
                else
                    this.pixelSelection = this.pixelSelection | (binaryImage ~= 0);
                end
                
                this.notify('PixelSelectionChanged');
            else
                exception = MException('RegionOfInterest:InvalidArgument', 'addPixels: binaryImage must be same size as region of interest.');
                throw(exception);
            end
        end
        
        function removePixel(this, x, y)
            if(x > 0 && x <= this.width && y > 0 && y <= this.height)
                this.pixelSelection(y, x) = 0;
                
                this.notify('PixelSelectionChanged');
            else
                exception = MException('RegionOfInterest:InvalidArgument', ...
                    ['removePixel: x must be between 1 and ' num2str(this.width) '. y must be between 1 and ' num2str(this.height)]);
                throw(exception);
            end
        end
        
        function removePixels(this, binaryImage)
            if(isequal(size(this.pixelSelection), size(binaryImage)))
                if(islogical(binaryImage))
                    this.pixelSelection = this.pixelSelection & ~binaryImage;
                else
                    this.pixelSelection = this.pixelSelection & (binaryImage == 0);
                end
                
                this.notify('PixelSelectionChanged');
            else
                exception = MException('RegionOfInterest:InvalidArgument', ...
                    'removePixels: binaryImage must be same size as region of interest.');
                throw(exception);
            end
        end
        
        function invert(this)
            this.pixelSelection = ~this.pixelSelection;
            
            this.notify('PixelSelectionChanged');
        end
        
        function shiftLeft(this, distance)
            maxDistance = find(sum(this.pixelSelection, 1) > 0, 1, 'first');
            newPos = maxDistance - distance;
            
            if(newPos < 1)
                distance = maxDistance - 1;
            end
            
            if(distance > 0)
                newPixelSelection = zeros(size(this.pixelSelection));
                newPixelSelection(:, 1:end-distance) = this.pixelSelection(:, (distance+1):end);

                this.pixelSelection = newPixelSelection;

                this.notify('PixelSelectionChanged');
            end
        end
        
        function shiftRight(this, distance)
            maxDistance = find(sum(this.pixelSelection, 1) > 0, 1, 'last');
            newPos = maxDistance + distance;
            
            if(newPos > size(this.pixelSelection, 2))
                distance = size(this.pixelSelection, 2) - maxDistance;
            end
            
            if(distance > 0)
                newPixelSelection = zeros(size(this.pixelSelection));
                newPixelSelection(:, (distance+1):end) = this.pixelSelection(:, 1:end-distance);

                this.pixelSelection = newPixelSelection;

                this.notify('PixelSelectionChanged');
            end
        end
        
        function shiftUp(this, distance)
            maxDistance = find(sum(this.pixelSelection, 2) > 0, 1, 'first');
            newPos = maxDistance - distance;
            
            if(newPos < 1)
                distance = maxDistance - 1;
            end
            
            if(distance > 0)
                newPixelSelection = zeros(size(this.pixelSelection));
                newPixelSelection(1:end-distance) = this.pixelSelection((distance+1):end);

                this.pixelSelection = newPixelSelection;

                this.notify('PixelSelectionChanged');
            end
        end
        
        function shiftDown(this, distance)
            maxDistance = find(sum(this.pixelSelection, 2) > 0, 1, 'last');
            newPos = maxDistance + distance;
            
            if(newPos > size(this.pixelSelection, 1))
                distance = size(this.pixelSelection, 1) - maxDistance;
            end
            
            if(distance > 0)
                newPixelSelection = zeros(size(this.pixelSelection));
                newPixelSelection((distance+1):end, :) = this.pixelSelection(1:end-distance, :);

                this.pixelSelection = newPixelSelection;

                this.notify('PixelSelectionChanged');
            end
        end
        
        function bool = containsPixel(this, x, y)
            bool = this.pixelSelection(y, x);
        end
        
        function mask = getPixelMask(this)
            mask = this.pixelSelection;
        end
        
        function image = getImage(this)
            image = zeros(size(this.pixelSelection, 1), size(this.pixelSelection, 2), 3, 'uint8');
            image(:, :, 1) = this.pixelSelection * this.colour.getRed();
            image(:, :, 2) = this.pixelSelection * this.colour.getGreen();
            image(:, :, 3) = this.pixelSelection * this.colour.getBlue();
        end
        
        function pixels = getPixelList(this)
            numPixels = sum(this.pixelSelection(:));
            
            % If no pixels have been selected, assume we want everything
            if(numPixels == 0)
                this.pixelSelection = ones(size(this.pixelSelection));
            end
            
            [rows cols] = find(this.pixelSelection);
            
            if(size(this.pixelSelection, 1) == 1)
                pixels = [cols' rows'];
            else
                pixels = [cols rows];
            end
            
            pixels = sortrows(pixels, [2 1]);
        end
        
        function cropTo(this, pixels)
            this.pixelSelection(:, sum(pixels, 1) == 0) = [];
            this.pixelSelection(sum(pixels, 2) == 0, :) = [];
            
            this.width = size(this.pixelSelection, 2);
            this.height = size(this.pixelSelection, 1);
        end
        
        function outputXML(this, fileID, indent)
            XMLHelper.indent(fileID, indent);            
            fprintf(fileID, '<regionOfInterest width="%d" height="%d">\n', this.width, this.height);
            
            XMLHelper.indent(fileID, indent+1);
            fprintf(fileID, '<name>%s</name>\n', XMLHelper.ensureSafeXML(this.name));
            
            this.colour.outputXML(fileID, indent+1);
            
            pixels = this.getPixelList();
            XMLHelper.indent(fileID, indent+1);
            fprintf(fileID, '<pixelList>\n');
            
            for i = 1:size(pixels, 1)
                XMLHelper.indent(fileID, indent+2);
                fprintf(fileID, '<pixel x="%d" y="%d" />\n', pixels(i, 1), pixels(i, 2));
            end
            
            XMLHelper.indent(fileID, indent+1);
            fprintf(fileID, '</pixelList>\n');
            
            XMLHelper.indent(fileID, indent);            
            fprintf(fileID, '</regionOfInterest>\n');
        end
    end
    
    methods (Access = protected)        
        function cpObj = copyElement(this)
            % Make a shallow copy 
            cpObj = copyElement@Copyable(this, this.width, this.height);
            
%             cpObj.width = this.width;
%             cpObj.height = this.height;
            cpObj.name = this.name;
            cpObj.colour = this.colour;
            cpObj.pixelSelection = this.pixelSelection;
        end
    end
end