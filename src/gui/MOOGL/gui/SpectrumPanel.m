classdef SpectrumPanel < Panel
    
    properties (SetAccess = protected)        
        spectrumDisplay;
    end
    
    methods
        function this = SpectrumPanel(parent, spectrum)
            this = this@Panel(parent);
            
            this.spectrumDisplay = SpectrumDisplay(this, spectrum);
            addlistener(this.spectrumDisplay, 'DisplayChanged', @(src, evnt) this.sizeChanged());
        end
    end
    
    methods(Access = protected)       
        function createPanel(this)
            createPanel@Panel(this);
        end
        
        function sizeChanged(this)
            % Ensure that the spectrum and axes labels fit nicely within
            % the panel
            if(~isempty(this.spectrumDisplay) && ~isempty(this.spectrumDisplay.axisHandle))
                
                if this.isUIFigure
                    margin = this.defaultMargin;
                    
                    curPosition = get(this.handle, 'Position');
                    set(this.spectrumDisplay.axisHandle,'Position', [margin margin curPosition(3)-margin*2 curPosition(4)-margin*2]);
                else
                    T = get(this.spectrumDisplay.axisHandle, 'TightInset');
                    set(this.spectrumDisplay.axisHandle,'Position',[0.01+T(1) 0.01+T(2) 0.98-T(1)-T(3) 0.98-T(2)-T(4)*2]);
                end
            end
        end
    end
end