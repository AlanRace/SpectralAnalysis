classdef Parameter < Copyable
    properties (SetAccess = private)
        parameterDescription;
        value;
    end
        
    methods
        function obj = Parameter(parameterDescription, value)
            if(nargin == 2)
                % Check that the type is a valid parameter type
                if(~isa(parameterDescription, 'ParameterDescription'))
                    exception = MException('Parameter:invalidArgument', '''parameterDescription'' must be a ParameterDescription');
                    throw(exception);
                end
                % Check if the value is correct for the specified type
                if(~parameterDescription.type.isTypeOf(value))
                    exception = MException('Parameter:invalidArgument', ['''value'' must be of type ' parameterDescription.type.Name]);
                    throw(exception);
                end

                obj.parameterDescription = parameterDescription;
                obj.value = value;
            end
        end
        
        function setValue(obj, value)
            % Check if the value is correct for the specified type
            if(~obj.parameterDescription.type.isTypeOf(value))
                exception = MException('Parameter:invalidArgument', ['''value'' must be of type ' obj.parameterDescription.type.Name]);
                throw(exception);
            end
            
            obj.value = value;
        end
    end
    
    methods (Access = protected)    
        function newObj = copyElement(obj)
            newObj = copyElement@Copyable(obj);
            
            newObj.parameterDescription = obj.parameterDescription;
            newObj.value = obj.value;
        end
    end
end