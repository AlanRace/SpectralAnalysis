classdef ParameterType < Enumeration
    properties (Constant)
        Integer = ParameterType(1);
        Double = ParameterType(2);
        Boolean = ParameterType(3);
        String = ParameterType(4);
        List = ParameterType(5);
        Selection = ParameterType(6);
    end
    
    methods
        function bool = isTypeOf(obj, value)
            if(obj == ParameterType.Integer && isnumeric(value) && value == floor(value))
                bool = 1;
                return;
            elseif(obj == ParameterType.Double && isnumeric(value))
                bool = 1;
                return;
            elseif(obj == ParameterType.Selection && iscell(value))
                bool = 1;
                return;
            elseif(obj == ParameterType.List && isa(value, 'ParameterDescription'))
                bool = 1;
                return;  
            elseif(obj == ParameterType.Boolean && isnumeric(value) && (value == 0 || value == 1))
                bool = 1;
                return;
            elseif(obj == ParameterType.String && ischar(value))
                bool = 1;
                return;
            end
            
            bool = 0;
        end
    end
    
    methods (Access = private) 
        function obj = ParameterType(code)
            obj.Code = code;
        end       
    end
end