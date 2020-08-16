classdef ChromatogramDisplay  < SpectrumDisplay
    
    properties (Access = protected)
        chromatogramLine = [];
    end
    
    methods
        function obj = ChromatogramDisplay(axisHandle, chromatogram)
            obj = obj@SpectrumDisplay(axisHandle, chromatogram);
            
            if(~isa(chromatogram, 'Chromatogram'))
                exception = MException('ChromatogramDisplay:invalidArgument', 'Must provide an instance of a class that extends Chromatogram');
                throw(exception);
            end
        end
        
        function moveChromatogramLine(this, selectedTime)
            yLim = get(this.axisHandle, 'YLim');
            
            this.deleteChromtogramLine();
            
            axes(this.axisHandle);
            this.chromatogramLine = line([selectedTime selectedTime], [yLim(1) yLim(2)], 'Color', [0 1 0]);
        end
        
        function mouseButtonUpCallback(this)
            currentPoint = get(this.axisHandle, 'CurrentPoint');
            
            time = this.data.spectralChannels;
            [distance, idx] = min(abs(time - currentPoint(1)));
            
            selectedTime = time(idx);
            
            this.moveChromatogramLine(selectedTime);
            
            peakSelectionEvent = PeakSelectionEvent(PeakSelectionEvent.Exact, selectedTime); % currentPoint(1));
            notify(this, 'PeakSelected', peakSelectionEvent);
        end
        
        function chromatogramLinePos = getChromatogramLinePosition(this)
            if(~isempty(this.chromatogramLine))
                xPos = get(this.chromatogramLine, 'XData');
                chromatogramLinePos = xPos(1);
            else
                chromatogramLinePos = [];
            end
        end
    end
    
    methods (Access = protected)
        function mouseClickInsideAxis(this)
            'test'
            time = this.data.spectralChannels;
            [distance, idx] = min(abs(time - this.currentPoint(1)));
            
            selectedTime = time(idx);
            
            this.moveChromatogramLine(selectedTime);
            
            peakSelectionEvent = PeakSelectionEvent(PeakSelectionEvent.Exact, selectedTime); % currentPoint(1));
            notify(obj, 'PeakSelected', peakSelectionEvent);
        end
        
        function deleteChromtogramLine(obj)
            if(~isempty(obj.chromatogramLine))
                try
                    delete(obj.chromatogramLine);
                catch err
                    err
                    warning('TODO: Handle error')
                end
                    
                obj.chromatogramLine = [];    
            end
            
            obj.chromatogramLine = [];
        end
    end
end