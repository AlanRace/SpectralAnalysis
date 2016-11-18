classdef PreprocessingMethodEditor < Editor
    properties (SetAccess = private)
%         handle = 0;
        
        multiSpectrumDisplay;
        multiSpectrumPanel;
        
        preprocessingMethodName;
        preprocessingMethod;
        
        beforeSpectrum;
        afterSpectrum;
    end
    
    properties (Access = private)
        % Store handles of each child interface element
        spectrumAxis;
        
        parameterInterfaceHandles;
        parameterDefinitions;
        parameters;
        
%         okButton;
    end
    
%     events
%         FinishedEditingPreprocessingMethod;
%     end
    
    methods
        function obj = PreprocessingMethodEditor(spectrum, preprocessingMethod)
            if(~isa(spectrum, 'SpectralData'))
                exception = MException('PreprocessingWorkflowEditor:invalidArgument', 'Must provide an instance of SpectralData');
                throw(exception);
            end
            
            % TODO: if preprocessingMethod is an instance of a class then
            % get the class name 
            
            if(~exist(preprocessingMethod, 'class') || ~ismember('SpectralPreprocessing', superclasses(preprocessingMethod)))
                exception = MException('PreprocessingMethodEditor:invalidArgument', 'Must provide an instance of a class that extends SpectralPreprocessing');
                throw(exception);
            end
            
            obj.preprocessingMethodName = preprocessingMethod;
            
            obj.setTitle(['Edit Preprocessing Method: ' obj.preprocessingMethodName ]);
            
            obj.beforeSpectrum = spectrum;
            obj.beforeSpectrum.setDescription('Before');
            
%             obj.createFigure();
                        
            obj.afterSpectrum = SpectralData(obj.beforeSpectrum.spectralChannels, obj.beforeSpectrum.intensities);
            obj.afterSpectrum.setDescription('After');
            
%             obj.multiSpectrumDisplay = MultiSpectrumDisplay(obj, obj.beforeSpectrum);
            obj.multiSpectrumPanel = MultiSpectrumPanel(obj, obj.beforeSpectrum);
            obj.multiSpectrumDisplay = obj.multiSpectrumPanel.spectrumDisplay;
            
            obj.createParameterInterface();
            
            
            %TODO: Update the parameters if an instance of the class was
            % passed in
            
%            warning('TODO: add listener to PreprocessingMethodChanged');
            % TODO: Use listeners for checking parameters changed
            
            obj.parameterChanged();
            
            % Ensure that all proportions are correct
            obj.sizeChanged();
        end
       
        
        
        function preprocessingMethod = getPreprocessingMethod(obj)
            preprocessingMethod = obj.preprocessingMethod;
        end
        
        function afterSpectrum = getAfterSpectrum(obj)
            afterSpectrum = obj.afterSpectrum;
        end
        
%         function delete(obj)
%             delete(obj.handle);
%             obj.handle = 0;
%         end
        
        
    end
    
    methods (Access = private)
        function parameterChanged(obj)
            parameterString = ['obj.preprocessingMethod = ' obj.preprocessingMethodName '('];
            
            % Create a preprocessing method instance
            for i = 1:length(obj.parameterInterfaceHandles)
                type = obj.parameterDefinitions(i).type;
                
                value = get(obj.parameterInterfaceHandles(i), 'String');
                
                if(type == ParameterType.String)
                    value = ['''' value ''''];
                end
                
                parameterString = [parameterString value ', '];
            end
            
            if(length(parameterString) > 2 && length(obj.parameterInterfaceHandles) >= 1)
                parameterString = parameterString(1:end-2); % Strip off the last ', '
            end
            
            parameterString = [parameterString ');'];
            
            eval(parameterString);
            
            try
                [spectralChannels, intensities] = obj.preprocessingMethod.process(obj.beforeSpectrum.spectralChannels, obj.beforeSpectrum.intensities);
                
                xLimit = obj.multiSpectrumDisplay.getXLimit();
                yLimit = obj.multiSpectrumDisplay.getYLimit();
                
                % Update the multi spectrum display
                obj.afterSpectrum = SpectralData(spectralChannels, intensities);
                obj.afterSpectrum.setDescription('After');
                obj.multiSpectrumDisplay.setSpectrum(2, obj.afterSpectrum);
                
                if(isa(obj.preprocessingMethod, 'SpectralNormalisation'))
                    obj.multiSpectrumDisplay.setLogDisplay(1);
                end
                
                obj.multiSpectrumDisplay.setXLimit(xLimit);
                obj.multiSpectrumDisplay.setYLimit(yLimit);
            catch err
                if(~isempty(strfind(err.identifier, 'InvalidArgument')))
                    errordlg(err.message, 'Invalid argument');
                else
                    rethrow(err);
                end
            end
        end
        
        function reduceParameter(obj, index)
            type = obj.parameterDefinitions(index).type;
            
            if(type == ParameterType.Integer)
%                 obj.parameters(index).setValue(obj.parameters(index).value - 1);
                currentValue = str2num(get(obj.parameterInterfaceHandles(index), 'String'));
                set(obj.parameterInterfaceHandles(index), 'String', num2str(currentValue - 1));
            end
            
            obj.parameterChanged();
        end
        
        function increaseParameter(obj, index)
            type = obj.parameterDefinitions(index).type;
            
            if(type == ParameterType.Integer)
%                 obj.parameters(index).setValue(obj.parameters(index).value + 1);
                currentValue = str2num(get(obj.parameterInterfaceHandles(index), 'String'));
                set(obj.parameterInterfaceHandles(index), 'String', num2str(currentValue + 1));
            end
            
            obj.parameterChanged();
        end
        
%         function okButtonCallback(obj)
%             % Make sure any last updates are performed
%             obj.parameterChanged();
%             
%             notify(obj, 'FinishedEditingPreprocessingMethod'); %, obj.preprocessingMethod);
%             
%             obj.delete();
%         end
    end    
    
    methods (Access = protected)
        function createFigure(obj)
%             if(~obj.handle)
%                 preProcessingName = eval([obj.preprocessingMethodName '.Name']);
%                 
%                 obj.handle = figure(...
%                     'Name', ['Preprocessing Method Editor: ' preProcessingName], 'NumberTitle','off',...
%                     'Units','characters',...
%                     'MenuBar','none',...
%                     'Toolbar','none', ...
%                     'CloseRequestFcn', @(src, evnt)obj.closeRequest());
%                 
%                 if(strcmp(version('-release'), '2014b'))
%                     set(obj.handle, 'SizeChangedFcn', @(src, evnt)obj.sizeChanged());
%                 end

            if(isempty(obj.handle) || ~obj.handle)
                createFigure@Editor(obj);
                
%                 obj.spectrumAxis = axes('Parent', obj.handle, 'Position', [.1 .55 .8 .35]);
            end
        end
           
        function createParameterInterface(obj)
                % Create appropriate interface elements for the parameters
                % of the preprocessing method
                generate = eval([obj.preprocessingMethodName '.defaultsRequireGenerating()']);
                
                if(generate)
                    parameters = eval([obj.preprocessingMethodName '.generateDefaultsFromSpectrum(obj.beforeSpectrum)']);
                else
                    parameters = [];
                end
                
                obj.parameterDefinitions = eval([obj.preprocessingMethodName '.ParameterDefinitions']);
                
                for i = 1:length(obj.parameterDefinitions)
                    type = obj.parameterDefinitions(i).type;
                    
                    uicontrol(obj.handle, 'Style', 'text', 'String', obj.parameterDefinitions(i).name, 'HorizontalAlignment', 'left', ...
                        'Units', 'normalized', 'Position', [.25 .40-((i-1)*0.05) .25 .04]);
                    
                    if(isempty(parameters))
                        defaultValue = obj.parameterDefinitions(i).defaultValue;
                    else
                        defaultValue = parameters(i).value;
                    end
                    
                    if(isa(defaultValue, 'double'))
                        defaultValue = num2str(defaultValue, '%0.20f');
                        
                        decimalPointLoc = strfind(defaultValue, '.');
                        
                        if(~isempty(decimalPointLoc))
                            finalZeroVal = regexp(defaultValue(decimalPointLoc:end), '0+$', 'once');
                        
                            if(~isempty(finalZeroVal))
                                defaultValue = defaultValue(1:finalZeroVal+decimalPointLoc-2);
                            end
                        end
                    end
                    
                    if(type == ParameterType.Integer || type == ParameterType.Double || type == ParameterType.String)
%                         defaultValue
                        
                        obj.parameterInterfaceHandles(i) = uicontrol(obj.handle, 'Style', 'edit', 'String', defaultValue, ...
                            'Units', 'normalized', 'Position', [.55 .40-((i-1)*0.05) .2 .04], 'Callback', @(src, evnt)obj.parameterChanged());
                        
                        if(type == ParameterType.Integer)
                            uicontrol(obj.handle, 'Style', 'pushbutton', 'String', '-', ...
                                'Units', 'normalized', 'Position', [.5 .40-((i-1)*0.05) .04 .04], 'Callback', @(src, evnt)obj.reduceParameter(i));
                            uicontrol(obj.handle, 'Style', 'pushbutton', 'String', '+', ...
                                'Units', 'normalized', 'Position', [.75 .40-((i-1)*0.05) .04 .04], 'Callback', @(src, evnt)obj.increaseParameter(i));
                        end
                    end
                end
                
%                 obj.okButton = uicontrol(obj.handle, 'String', 'OK', ...
%                     'Units', 'normalized', 'Position', [0.8 0.05 0.15 0.05], 'Callback', @(src, evnt)obj.okButtonCallback());
            
        end
        
        function sizeChanged(obj, src, evnt)
            oldUnits = get(obj.handle, 'Units');
            set(obj.handle, 'Units', 'pixels');
            newPosition = get(obj.handle, 'Position');
            
            Figure.setObjectPositionInPixels(obj.multiSpectrumPanel.handle, [50 newPosition(4)/2 newPosition(3)-80 newPosition(4)/2-30]);
            
%             axisOldUnits = get(obj.spectrumAxis, 'Units');
%             set(obj.spectrumAxis, 'Units', 'pixels');
%             set(obj.spectrumAxis, 'Position', [50 newPosition(4)/2 newPosition(3)-80 newPosition(4)/2-30]);
%             set(obj.spectrumAxis, 'Units', axisOldUnits);
            
            set(obj.handle, 'Units', oldUnits);
            
            sizeChanged@Figure(obj);
        end
        
%         function closeRequest(obj)
%             obj.delete();
%         end
    end
end