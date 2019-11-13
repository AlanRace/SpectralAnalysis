classdef DimRedDataViewer < DataViewer
    properties(Access = protected)
        % TODO: Extend DataViewer for ProjectedDataViewer or PCADataViewer 
        % to allow for more specific control over 
        previousCoefficientButton;
        nextCoefficientButton;
        coefficientEditBox;
        coefficientLabel;
    end
    
    methods
        function obj = DimRedDataViewer(dataRepresentation)
            obj@DataViewer(dataRepresentation)
            if(~isa(dataRepresentation, 'ProjectedDataRepresentation'))
                exception = MException('DimRedDataViewer:InvalidArgument', ...
                    'Must supply an instance of a subclass of ProjectedDataRepresentation to the DimRedDataViewer constructor');
                throw(exception);
            end
            
            obj.showProjectedInterface();
                
            obj.coefficientEditBoxCallback();
        end
        
        function makeCoefficientControlsVisible(obj, isVisible)
            if(isVisible)
                set(obj.previousCoefficientButton, 'Visible', 'on');
                set(obj.nextCoefficientButton, 'Visible', 'on');
                set(obj.coefficientEditBox, 'Visible', 'on');
                set(obj.coefficientLabel, 'Visible', 'on');
            else
                set(obj.previousCoefficientButton, 'Visible', 'off');
                set(obj.nextCoefficientButton, 'Visible', 'off');
                set(obj.coefficientEditBox, 'Visible', 'off');
                set(obj.coefficientLabel, 'Visible', 'off');
            end
        end
        
        function previousCoefficientPlotCallback(obj)
            newValue = str2num(get(obj.coefficientEditBox, 'String')) - 1;
            
            if(newValue <= 0)
                newValue = 1;
            end
            
            set(obj.coefficientEditBox, 'String', num2str(newValue));
            obj.coefficientEditBoxCallback();
        end
        
        function nextCoefficientPlotCallback(obj)
            newValue = str2num(get(obj.coefficientEditBox, 'String')) + 1;
            
            if(newValue > size(obj.dataRepresentation.projectionMatrix, 2))
                newValue = size(obj.dataRepresentation.projectionMatrix, 2);
            end
            
            set(obj.coefficientEditBox, 'String', num2str(newValue));
            obj.coefficientEditBoxCallback();
        end
        
        function coefficientEditBoxCallback(obj)
            coeffString = get(obj.coefficientEditBox, 'String');
            
            value = str2num(coeffString);
            
            if(isempty(value) || value <= 0 || isinf(value) || isnan(value))
                value = 1;
                
                set(obj.coefficientEditBox, 'String', num2str(value));
            end
            
            if(value > obj.dataRepresentation.getNumberOfDimensions())
                value = obj.dataRepresentation.getNumberOfDimensions();
                
                set(obj.coefficientEditBox, 'String', num2str(value));
            end
            
            imageData = obj.dataRepresentation.getProjectedImage(value);
            obj.imageDisplay.setData(Image(imageData));
            obj.regionOfInterestPanel.setImageForEditor(Image(imageData));
                        
            spectrum = SpectralData(obj.dataRepresentation.spectralChannels, obj.dataRepresentation.projectionMatrix(:, value));
            spectrum.setIsContinuous(0);
            
            spectrum.setDescription(['Coefficient ' num2str(value) ' (Out of ' num2str(size(obj.dataRepresentation.projectionMatrix, 2)) ')']);
            obj.spectrumList.set(1, spectrum);
            obj.updateSpectrumSelectionPopup();
            set(obj.spectrumSelectionPopup, 'Value', 1);
            
            obj.spectrumDisplay.setData(spectrum);
        end
    end
    
    methods (Access = protected)
        %% createFigure()
        function createFigure(obj) 
            if(isempty(obj.handle) || ~obj.handle)
                createFigure@DataViewer(obj);
            end
                                
                    obj.previousCoefficientButton = uicontrol('Parent', obj.handle, 'String', '<', 'Callback', @(src, evnt)obj.previousCoefficientPlotCallback(), ...
                        'Units', 'normalized', 'Position', [0.1 0.55 0.05 0.05], 'Visible', 'Off');
                    obj.nextCoefficientButton = uicontrol('Parent', obj.handle, 'String', '>', 'Callback', @(src, evnt)obj.nextCoefficientPlotCallback(), ...
                        'Units', 'normalized', 'Position', [0.8 0.55 0.05 0.05], 'Visible', 'Off');
                    obj.coefficientEditBox = uicontrol('Parent', obj.handle, 'Style', 'edit', 'Callback', @(src, evnt)obj.coefficientEditBoxCallback(), ...
                        'Units', 'normalized', 'Position', [0.15 0.55 0.05 0.05], 'String', '1', 'Visible', 'Off');
                    obj.coefficientLabel = uicontrol('Parent', obj.handle, 'Style', 'text', 'String', [''], ...
                        'Units', 'normalized', 'Position', [0.49 0.56 0.1 0.05], 'HorizontalAlignment', 'left');
                
        end
        
        function showProjectedInterface(obj)
            set(obj.previousCoefficientButton, 'Visible', 'On');
            set(obj.nextCoefficientButton, 'Visible', 'On');
            set(obj.coefficientEditBox, 'Visible', 'On');
            set(obj.coefficientLabel, 'Visible', 'On');
            
            set(obj.coefficientLabel, 'String', [' / ' num2str(obj.dataRepresentation.getNumberOfDimensions())]);
        end
        
        function sizeChanged(obj)
            sizeChanged@DataViewer(obj);
            
            if(obj.handle ~= 0)
                % Get the new position of the figure in pixels
                newPosition = Figure.getPositionInPixels(obj.handle);
                
                margin = 5;
                
                colourBarSize = 80;
                spectrumExtraSize = 30;
                spectrumExtraSize = 0;
                buttonHeight = 25;
                
                widthForImage = newPosition(3) - margin*2 - colourBarSize;
                widthForSpectrum = newPosition(3) - margin*2 - spectrumExtraSize;
                
                xPositionForImage = margin;
                xPositionForSpectrum = margin + spectrumExtraSize;
                
                spectrumRegionY = 50;
                spectrumRegionHeight = newPosition(4) * (1-(obj.percentageImage/100)) - 50;
                                
                imageRegionY = (spectrumRegionHeight + spectrumRegionY) + 25;
                imageRegionHeight = newPosition(4) * (obj.percentageImage/100) - 50;
                
                progressBarHeight = 15;
                
                                
                xPositionForImage = margin;
                xPositionForCoeffs = xPositionForImage+widthForImage/2 - 90;
                
                Figure.setObjectPositionInPixels(obj.previousCoefficientButton, [xPositionForCoeffs, imageRegionY-20, 50, 30]);
                Figure.setObjectPositionInPixels(obj.coefficientEditBox, [xPositionForCoeffs+60, imageRegionY-20, 50, 30]);
                Figure.setObjectPositionInPixels(obj.coefficientLabel, [xPositionForCoeffs+120, imageRegionY-20, 50, 20]);
                Figure.setObjectPositionInPixels(obj.nextCoefficientButton, [xPositionForCoeffs + 180, imageRegionY-20, 50, 30]);
%                 get(obj.coefficientLabel)
            end
        end
    end
end