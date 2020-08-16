classdef RegionEditor < Editor
    
    properties (SetAccess = private)
        region;
    end
    
    properties (Access = private)
        nameLabel;
        nameEdit;
        
        colourPanel;
        colourChooser;
    end
    
    methods
        function this = RegionEditor(region)
            if(nargin >= 1)
                if(~isa(region, 'RegionOfInterest'))
                    exception = MException('RegionEditor:InvalidArgument', ...
                        'Must supply an argument that is an instance of the class RegionOfInterest');
                    throw(exception);
                end
            else
                region = RegionOfInterest();
            end
            
            this.createFigure();
            
            set(this.handle, 'Name', 'Region Editor');
            this.setRegionOfInterest(region);
        end
       
        
        
        function setRegionOfInterest(this, region)
            this.region = region;
            
            set(this.nameEdit, 'String', region.getName());
            colour = region.getColour();
            this.colourChooser.setColor(colour.getRed(), colour.getGreen(), colour.getBlue());
        end
        
        function regionOfInterest = getRegionOfInterest(this)
            regionOfInterest = this.region;
        end
    end
        
    methods (Access = protected)
        function createFigure(this)
            createFigure@Editor(this);
            
            set(this.handle, 'Units', 'pixels');
            figureHandlePosition = get(this.handle, 'Position');
            figureHandlePosition(3) = 700;
            figureHandlePosition(4) = figureHandlePosition(4) + 30;
            set(this.handle, 'Position', figureHandlePosition);
            set(this.handle, 'Units', 'normalized');
            
            %             this.nameLabel = uicontrol('Parent', this.handle, 'Style', 'text', 'String', 'Region Name', ...
            %                 'Units', 'normalized', 'Position', [0.05 0.9 0.4 0.05]);
            this.nameEdit = uicontrol('Parent', this.handle, 'Style', 'edit', ...
                'Units', 'normalized', 'Position', [0.05 0.9 0.9 0.05]);
            
            this.colourPanel = uipanel('Parent', this.handle, ...
                'Units', 'normalized', 'Position', [0.05 0.125 0.9 0.75]);
            
            colourChooser = javax.swing.JColorChooser();
            [this.colourChooser, container] = javacomponent(colourChooser, [1,1,625,325], this.colourPanel);
        end
        
        function okButtonCallback(this)
            % Check that a name has been entered
            if(isempty(get(this.nameEdit, 'String')))
                errordlg('Please enter a name for the region', 'Missing field');
            else
                this.region.setName(get(this.nameEdit, 'String'));
                
                colour = this.colourChooser.getColor();
                this.region.setColour(Colour(colour.getRed(), colour.getGreen(), colour.getBlue()));
                
                okButtonCallback@Editor(this);
            end
        end
    end
end