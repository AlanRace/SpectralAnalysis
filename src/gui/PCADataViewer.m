classdef PCADataViewer < DimRedDataViewer
    properties(Access = protected)
        % TODO: Extend DataViewer for ProjectedDataViewer or PCADataViewer 
        % to allow for more specific control over 
        switchSpectrumViewButton;
    end
    
    methods
        function obj = PCADataViewer(dataRepresentation)
            obj@DimRedDataViewer(dataRepresentation)
            if(~isa(dataRepresentation, 'ProjectedDataRepresentation'))
                exception = MException('PCADataViewer:InvalidArgument', ...
                    'Must supply an instance of a subclass of ProjectedDataRepresentation to the PCADataViewer constructor');
                throw(exception);
            end
        end
                
        function switchSpectrumView(obj)
            f = PCAInfoFigure(obj.dataRepresentation, obj.regionOfInterestPanel.regionOfInterestList);
            
%             isVisible = strcmp(get(obj.previousCoefficientButton, 'Visible'), 'on');
            
%             obj.makeCoefficientControlsVisible(~isVisible);
        end
       
        function coefficientEditBoxCallback(obj)
            coefficientEditBoxCallback@DimRedDataViewer(obj);
%             % Set the diverging colourmap to be enabled
            obj.imageDisplay.setDivergingColourMap();
        end
    end
    
    methods (Access = protected)
        %% createFigure()
        function createFigure(obj) 
            if(isempty(obj.handle) || ~obj.handle)
                createFigure@DimRedDataViewer(obj);
            end
            
            obj.switchSpectrumViewButton = uicontrol('Parent', obj.handle, 'String', 'PCA Info', 'Callback', @(src, evnt)obj.switchSpectrumView(), ...
                        'Units', 'normalized', 'Position', [0.65 0.35 0.1 0.05], 'Visible', 'Off');
                
        end
        
        function showProjectedInterface(obj)
            showProjectedInterface@DimRedDataViewer(obj);
            
            set(obj.switchSpectrumViewButton, 'Visible', 'On');
        end
        
    end
end