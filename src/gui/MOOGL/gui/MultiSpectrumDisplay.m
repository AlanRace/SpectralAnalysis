classdef MultiSpectrumDisplay < SpectrumDisplay
    
    properties (SetAccess = private)
        spectrumList;
        
        logDisplay = 0;
        
        peakDetectionMethodIndex = 1;
    end
    
    methods
        function obj = MultiSpectrumDisplay(parent, spectrum)
            obj = obj@SpectrumDisplay(parent, spectrum);
            
            obj.spectrumList = SpectrumList();
            obj.spectrumList.add(spectrum);
        end
        
        function updateDisplay(obj)
            obj.updateDisplay@SpectrumDisplay();
            
            % Set up callback functions such as button down functions
            set(obj.axisHandle, 'ButtonDownFcn', @(src, evnt)obj.buttonDownCallback());
            set(obj.axisHandle, 'UIContextMenu', obj.contextMenu);
        end
        
        function setSpectrum(obj, index, spectrum)
            if(~isa(spectrum, 'SpectralData'))
                exception = MException('MultiSpectrumDisplay:invalidArgument', 'Must provide an instance of a class that extends SpectralData');
                throw(exception);
            end
            if(index <= 0)
                exception = MException('MultiSpectrumDisplay:invalidArgument', 'Index must be a positive integer');
                throw(exception);
            end
            
            obj.spectrumList.set(index, spectrum);
            
            obj.labelPeaksWithMethod(obj.peakDetectionMethodIndex);
            
            % Reset the limits so that they are fixed with the new spectrum
            % when added
%             obj.xLimit = [];
%             obj.yLimit = [];
            
            % Force the x/y limit to be empty so that it fixes the limits
            % to the largest in each direction
            obj.xLimit = [];
            obj.yLimit = [];
            obj.fixLimits();
            obj.updateDisplay();
        end
        
        function labelPeaksWithMethod(obj, index)
            for i = 1:length(obj.peakDetectionMenuItem)
                set(obj.peakDetectionMenuItem(i), 'Checked', 'off');
            end
            
            if(index > 1)
                set(obj.peakDetectionMenuItem(index), 'Checked', 'on');
            
                obj.peakDetectionMethodIndex = index;
                
                spectrum = obj.spectrumList.get(obj.spectrumList.getSize());
                
                peakDetectionMethod = eval([obj.peakDetectionMethods{index} '()']);
                [obj.peakList, obj.peakHeight] = peakDetectionMethod.process(spectrum.spectralChannels, spectrum.intensities);
                size(obj.peakList)
            else
                obj.peakList = [];
            end
            
            obj.updateDisplay();
        end
        
        function setLogDisplay(this, logDisplay)
            this.logDisplay = logDisplay;
            this.logDisplay
            this.updateDisplay();
        end
    end
    
    methods (Access = protected)
        
        function plotSpectrum(this)
            if(isempty(this.spectrumList))
                return;
            end
            
            spectra = this.spectrumList.getObjects();
            
            hold(this.axisHandle, 'off');
            
            legends = {};
            
            for i = 1:numel(spectra)
                if(this.logDisplay)
                    semilogy(this.axisHandle, spectra{i}.spectralChannels, spectra{i}.intensities);
                else
                    plot(this.axisHandle, spectra{i}.spectralChannels, spectra{i}.intensities);
                end
                
                legends{i} = spectra{i}.getDescription();
                
                hold(this.axisHandle, 'all');
            end
            
            hold(this.axisHandle, 'off');
            
            legend(legends);
        end
        
        function fixLimits(this)
            if(isempty(this.spectrumList) || this.spectrumList.getSize() < 1)
                return;
            end
            
            spectra = this.spectrumList.getObjects();
            
            minxLimit = min(spectra{1}.spectralChannels);
            maxxLimit = max(spectra{1}.spectralChannels);
            
            if(isempty(this.xLimit))
                currentViewMask = true(1, length(spectra{1}.spectralChannels));
            else
                currentViewMask = this.data.spectralChannels >= this.xLimit(1) & this.data.spectralChannels <= this.xLimit(2);
            end
            
            minyLimit = min(spectra{1}.intensities(currentViewMask));
            maxyLimit = max(spectra{1}.intensities(currentViewMask));
            
            for i = 2:numel(spectra)
                specChannels = spectra{i}.spectralChannels;
                intensities = spectra{i}.intensities;
                
                if(isempty(this.xLimit))
                    currentViewMask = true(1, length(specChannels));
                else
                    currentViewMask = specChannels >= this.xLimit(1) & specChannels <= this.xLimit(2);
                end
                
                intensities = intensities(currentViewMask);
                
                newminxLimit = min(specChannels);
                newmaxxLimit = max(specChannels);
                
                newminyLimit = min(intensities);
                newmaxyLimit = max(intensities);
                
                if(newminxLimit < minxLimit)
                    minxLimit = newminxLimit;
                end
                if(newmaxxLimit > maxxLimit)
                    maxxLimit = newmaxxLimit;
                end
                if(newminyLimit < minyLimit)
                    minyLimit = newminyLimit;
                end
                if(newmaxyLimit > maxyLimit)
                    maxyLimit = newmaxyLimit;
                end
            end
            
            if(isempty(this.xLimit))
                this.xLimit = [minxLimit maxxLimit];
            end
            if(isempty(this.yLimit))
                this.yLimit = [minyLimit maxyLimit];
            end
        end
        
%         function buttonDownCallback(obj)
%             'hi'
%         end
    end
end