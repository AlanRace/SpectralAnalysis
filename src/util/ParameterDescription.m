classdef ParameterDescription < handle
    properties (SetAccess = private)
        name;
        type;
        defaultValue;
    end
        
    methods
        function obj = ParameterDescription(name, type, defaultValue)
            % Check that the type is a valid parameter type
            if(~isa(type, 'ParameterType'))
                exception = MException('Parameter:invalidArgument', '''type'' must be a ParameterType');
                throw(exception);
            end
            % Check if the value is correct for the specified type
            if(~type.isTypeOf(defaultValue))
                exception = MException('Parameter:invalidArgument', ['''defaultValue'' must be of type ' type.Name]);
                throw(exception);
            end
            % Check that the name is a string
            if(~ischar(name))
                exception = MException('Parameter:invalidArgument', '''name'' must be a string');
                throw(exception);
            end
            
            obj.name = name;
            obj.type = type;
            obj.defaultValue = defaultValue;
        end
        
        
    end
end