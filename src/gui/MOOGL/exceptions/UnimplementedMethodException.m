classdef UnimplementedMethodException < MException
    
    
    methods
        function this = UnimplementedMethodException(methodName)
            this@MException('MOOGL:UnimplementedMethodException', ['Unimplemented method: ' methodName]);
        end
    end
end