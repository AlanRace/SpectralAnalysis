classdef Processing < Copyable % & matlab.mixin.Heterogeneous
    properties (Abstract, Constant)
        Name;
        Description;
        
        ParameterDefinitions;
    end
    
    properties
        Parameters;
    end
    
    events
        ProcessingProgress
    end
    
    methods 
        function string = toString(obj)
            string = [obj.Name '('];
            
            for i = 1:length(obj.Parameters)
                if(i > 1)
                    string = [string ', '];
                end
                
                string = [string obj.Parameters(i).parameterDescription.name ': '];
                
                type = obj.Parameters(i).parameterDescription.type;
                
                if(type == ParameterType.Integer || type == ParameterType.Double || type == ParameterType.Boolean)
                    string = [string num2str(obj.Parameters(i).value)];
                end
            end
            
            string = [string ')'];
        end
    end
    
    methods (Access = protected)
        function cpObj = copyElement(obj)
            % Make a shallow copy 
            cpObj = copyElement@Copyable(obj);
            
            for i = 1:length(obj.Parameters)
                cpObj.Parameters(i) = obj.Parameters(i).copy();
            end
        end
    end
end