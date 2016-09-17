classdef DataViewerList < List
    methods (Static)
        function listClass = getListClass()
            listClass = 'DataViewer';
        end
    end   
    
    methods
        function closeAll(this)
            for i = 1:this.getSize()
                if(this.objects{i}.isvalid() && isa(this.objects{i}, 'DataViewer'))
                    this.objects{i}.delete();
                end
            end
            
            this.removeAll();
        end
    end
end