classdef XMLHelper
    methods (Static)
        function indent(fileID, indent)
            if(~exist('indent', 'var'))
                indent = 0;
            end
            
            for i = 1:indent
                fprintf(fileID, '  '); %\t is too large a jump
            end
        end
        
        function string = ensureSafeXML(string)
        end
    end
end