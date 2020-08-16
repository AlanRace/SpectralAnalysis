classdef Copyable < hgsetget
    
    methods
        function obj = Copyable()
        end
        
        function newObj = copy(obj)
            newObj = copyElement(obj);
        end
    end
    
    
    methods (Access = protected)    
        function newObj = copyElement(obj, varargin)
            fh = str2func(class(obj));
            
            if(~isempty(varargin))
                newObj = fh(varargin{:});
            else
                newObj = fh();
            end
%             newObj = eval(class(obj));
            
            props = properties(obj);
            
            for i = 1:length(props)
                try
                    set(newObj, props{i}, get(obj, props{i}));
                catch err
                    if(~strcmp(err.identifier, 'MATLAB:class:SetProhibited'))
                        rethrow(err);
                    end
                end
            end
        end
    end
end