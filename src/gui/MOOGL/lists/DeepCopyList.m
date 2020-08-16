classdef DeepCopyList < List
    
    methods (Access = protected)
        function cpObj = copyElement(obj)
            cpObj = copyElement@Copyable(obj);
            
            for i = 1:length(obj.objects)
                cpObj.objects{i} = obj.objects{i}.copy();
            end
        end
    end
end