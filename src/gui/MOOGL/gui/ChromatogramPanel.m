classdef ChromatogramPanel < Panel
    
    properties (SetAccess = protected)        
        chromatogramDisplay;
    end
    
    methods
        function this = ChromatogramPanel(parent, spectrum)
            this = this@Panel(parent);
            
            this.chromatogramDisplay = ChromatogramDisplay(this, spectrum);
            addlistener(this.chromatogramDisplay, 'DisplayChanged', @(src, evnt) this.sizeChanged());
        end
    end
    
    methods(Access = protected)       
        function createPanel(this)
            createPanel@Panel(this);
        end
        
        function sizeChanged(this)
            % Ensure that the spectrum and axes labels fit nicely within
            % the panel
            if(~isempty(this.chromatogramDisplay) && ~isempty(this.chromatogramDisplay.axisHandle))
                T = get(this.chromatogramDisplay.axisHandle, 'TightInset');
                set(this.chromatogramDisplay.axisHandle,'Position',[0.01+T(1) 0.01+T(2) 0.98-T(1)-T(3) 0.98-T(2)-T(4)*2]);
            end
        end
    end
end