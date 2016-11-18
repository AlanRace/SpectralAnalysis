classdef PreprocessingWorkflow < Copyable
    properties
        workflow
    end

    events
        WorkflowStepCompleted;
        WorkflowCompleted;
    end
    
    methods
        function obj = PreprocessingWorkflow(preprocessingMethod)
            if(nargin >= 1)
                obj = obj.addPreprocessingMethod(preprocessingMethod);
            end
        end
        
%         function pw = copy(obj)
%             pw = PreprocessingWorkflow();
%             
%             for i = 1:obj.numberOfMethods()
%                 pw.addPreprocessingMethod(obj.workflow(i).copy());
%             end
%         end
        
        function obj = addPreprocessingMethod(obj, preprocessingMethod)
            if(~isa(preprocessingMethod, 'SpectralPreprocessing'))
                exception = MException('PreprocessingWorkflow:invalidArgument', 'Must provide an instance of a class that extends SpectralPreprocessing');
                throw(exception);
            end
            
            if(isempty(obj.workflow))
                obj.workflow = {preprocessingMethod};
            else
                obj.workflow(obj.numberOfMethods() + 1) = {preprocessingMethod};
            end
        end
        
        function numMethods = numberOfMethods(obj)
            numMethods = length(obj.workflow);
        end
        
        function bool = containsPeakPicking(obj)
            bool = 0;
            
            for i = 1:obj.numberOfMethods()
                if(isa(obj.workflow(i), 'SpectralPeakDetection'))
                    bool = 1;                
                end
            end
        end
        
        function preprocessingMethod = getPreprocessingMethod(obj, index)
            if(index <= 0 || index > obj.numberOfMethods())
                exception = MException('PreprocessingWorkflow:invalidArgument', ['''index'' must be between 1 and ' num2str(obj.numberOfMethods())]);
                throw(exception);
            end
           
            preprocessingMethod = obj.workflow{index};
        end
        
        function swap(obj, index1, index2)
            if(~(index1 > 0 && index1 <= obj.numberOfMethods() && index2 > 0 && index2 <= obj.numberOfMethods()))
                exception = MException('PreprocessingWorkflow:invalidArgument', ['''index'' values must be between 1 and ' num2str(obj.numberOfMethods())]);
                throw(exception);
            end
            
            tmp = obj.workflow(index1);
            obj.workflow(index1) = obj.workflow(index2);
            obj.workflow(index2) = tmp;
        end
        
        function removePreprocessingMethod(obj, index)
            if(index <= 0 || index > obj.numberOfMethods())
                exception = MException('PreprocessingWorkflow:invalidArgument', ['''index'' must be between 1 and ' num2str(obj.numberOfMethods())]);
                throw(exception);
            end
            
            obj.workflow(index) = [];
        end
        
        function spectrum = performWorkflow(obj, spectrum)
            spectralChannels = spectrum.spectralChannels;
            intensities = spectrum.intensities;
            
            for i = 1:length(obj.workflow)
                [spectralChannels, intensities] = obj.workflow{i}.process(spectralChannels, intensities);
                notify(obj, 'WorkflowStepCompleted');
            end
            
            spectrum = SpectralData(spectralChannels, intensities);
            spectrum.setData(spectralChannels, intensities);
            
            if(obj.containsPeakPicking || ~spectrum.isContinuous)
                spectrum.setIsContinuous(false);
            else
                spectrum.setIsContinuous(true);
            end
            
            notify(obj, 'WorkflowCompleted');
        end
        
        function saveWorkflow(this, location)
            docNode = com.mathworks.xml.XMLUtils.createDocument('preprocessingWorkflow');
            docRootNode = docNode.getDocumentElement;
            docRootNode.setAttribute('version', '1.0');
            
            for i = 1:length(this.workflow)
                preprocessingMethod = this.workflow{i};
                
                methodElement = docNode.createElement('preprocessingMethod');
                methodElement.setAttribute('class', class(preprocessingMethod));
                
                params = preprocessingMethod.Parameters;
                
                for j = 1:length(params)
                    paramElement = docNode.createElement('parameter');
                    
                    paramElement.setAttribute('description', params(j).parameterDescription.name);
                    
                    switch(params(j).parameterDescription.type)
                        case {ParameterType.Integer, ParameterType.Boolean}
                            paramElement.setAttribute('value', num2str(params(j).value, '%d'));
                        case(ParameterType.Double)
                            paramElement.setAttribute('value', num2str(params(j).value, '%f'));
                        otherwise
                            paramElement.setAttribute('value', params(j).value);
                    end
                    
                    methodElement.appendChild(paramElement);
                end
                
                docRootNode.appendChild(methodElement);
            end
            
            xmlwrite(location, docNode);
        end
        
        function loadWorkflow(this, location)
            pw = PreprocessingWorkflow();
            
            xDoc = xmlread(location);
            xRoot = xDoc.getDocumentElement();
            
            childNodes = xRoot.getChildNodes();
            
            for i = 0:childNodes.getLength()-1
                preprocessingMethod = childNodes.item(i);
                
                if(strcmp(preprocessingMethod.getNodeName(), 'preprocessingMethod'))
                    className = char(preprocessingMethod.getAttribute('class'));
                    
                    functionCall = [className '('];
                    
                    methodChildren = preprocessingMethod.getChildNodes();
                    
                    paramIndex = 0;
                    
                    for j = 0:methodChildren.getLength()-1
                        parameter = methodChildren.item(j);
                        
                        if(strcmp(parameter.getNodeName(), 'parameter'))
                            paramIndex = paramIndex + 1;
                            value = char(parameter.getAttribute('value'));
                            
                            if(paramIndex > 1)
                                functionCall = [functionCall ', '];
                            end
                            
                            functionCall = [functionCall value];
                            
%                             type = eval([className '.ParameterDefinitions(paramIndex).type'])
%                             
%                             switch(type)
%                                 case {ParameterType.Integer, ParameterType.Boolean}
%                                     value = str2num(value);
%                                 case(ParameterType.Double)
%                                     value = str2double(value);
%                             end
%                             
%                             value
                        end
                    end
                    
                    functionCall = [functionCall ')'];
                    
                    pm = eval(functionCall);
                    pw.addPreprocessingMethod(pm);
                end
            end
            
            this.workflow = pw.workflow;
        end
        
        function strings = toCellArrayOfStrings(obj)
            strings = {};
            
            for i = 1:obj.numberOfMethods()
                strings{i} = obj.workflow{i}.toString();
            end
        end
        
        function exportToWorkspace(obj)
            variableName = inputdlg('Please specifiy a variable name:', 'Variable name', 1, {'workflow'});
            
            while(~isempty(variableName))
                if(isvarname(variableName{1}))
                    assignin('base', variableName{1}, obj);
                    break;
                else
                    variableName = inputdlg('Invalid variable name. Please specifiy a variable name:', 'Variable name', 1, variableName);
                end
            end
        end
    end
    
    methods (Access = protected)
        function cpObj = copyElement(obj)
            % Make a shallow copy 
            cpObj = copyElement@Copyable(obj);
        end
    end
end