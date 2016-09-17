% In an ideal world this would extend TotalSpectrum, but with the Name
% being constant this prevents this being possible in this design.
%
% Instead the TotalSpectrum code is still used, but an additional object is
% created
classdef MeanSpectrum < SpectralRepresentation
    properties (Constant)
        Name = 'Mean Spectrum';
        Description = '';
        
        ParameterDefinitions = [];
    end
    
%     methods (Static)
%         function name = getName()
%             name = 'Mean Spectrum';
%         end
%         
%         function numParams = getNumberOfParameters()
%             numParams = 0;
%         end
%         
%         function param = getParameterType(parameterNumber)
%         end
%     end
    
    methods
        function spectrumList = process(this, dataRepresentation)
            % Set up TotalSpectrum with same arguments as MeanSpectrum
            ts = TotalSpectrum();
            ts.setPreprocessingWorkflow(this.preprocessingWorkflow);
            ts.applyPreprocessingToEverySpectrum(this.preprocessEverySpectrum);
            ts.postProcessEntireDataset(this.processEntireDataset);
            ts.setRegionOfInterestList(this.regionOfInterestList);
            
            % Make sure that we have a progress bar
            addlistener(ts, 'ProcessingProgress', @(src, evnt) notify(this, 'ProcessingProgress', evnt));
            spectrumList = ts.process(dataRepresentation);
            
            curIndex = 1;
            
            if(this.processEntireDataset)
                spectrum = spectrumList.get(curIndex);
                spectrum.setDescription('Mean Spectrum (Entire Dataset)');
                
                spectrum.setData(spectrum.spectralChannels, spectrum.intensities ./ size(dataRepresentation.pixels, 1));
                
                curIndex = curIndex + 1;
            end
            
            rois = this.regionOfInterestList.getObjects();
            
            if(numel(rois) > 0)
                for i = 1:numel(rois)
                    pixels = rois{i}.getPixelList();
                    
                    spectrum = spectrumList.get(curIndex);
                    spectrum.setDescription(['Mean Spectrum (' rois{i}.getName() ')']);
                    
                    spectrum.setData(spectrum.spectralChannels, spectrum.intensities ./ size(pixels, 1));
                    
                    curIndex = curIndex + 1;
                end
            end
        end
    end
end