classdef LineProfile < Tools
    properties (Constant)
        Name = 'Line profile';
        Description = '';
        
        ParameterDefinitions = [];
        
    end
    
    properties
        
    end
    
    methods
        function this = LineProfile()
            shg;
            curFigure = gcf;
            for i = 1:length(curFigure.Children)
                temp = curFigure.Children(i);
                if isa(temp, 'matlab.graphics.axis.Axes')
                    axisTitleInfo = get(curFigure.Children(i), 'title');
                    axisTitle = axisTitleInfo.String;
                    if ~strcmp(axisTitle, '')
                        set(curFigure,'CurrentAxes',curFigure.Children(i))
                        improfile
                    end
                end
            end
        end
        
        function process(this)
        end
    end
end