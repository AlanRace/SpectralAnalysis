classdef List < Copyable
    
    properties (Access = protected)
        objects = {};
    end
    
    methods (Abstract, Static)
        listClass = getListClass();
    end
    
    events
        ListChanged;
    end
    
    methods 
        function add(obj, objectToAdd)
            if(isa(objectToAdd, obj.getListClass()))
                if(isempty(obj.objects) || isempty(obj.objects{1}))
                    obj.objects{1} = objectToAdd;
                else
                    obj.objects{end+1} = objectToAdd;
                end
                
                notify(obj, 'ListChanged');
            else
                exception = MException([class(obj) ':InvalidClass'], ['Cannot add class of type ' class(objectToAdd) ' to a list of type ' obj.getListClass()]);
                throw(exception);
            end
        end
        
        function addAll(obj, listToAdd)
            objects = listToAdd.getObjects();
            
            for i = 1:length(objects)
                objectToAdd = objects{i};
                
                % TODO: Avoid duplication of code?
                if(isempty(obj.objects) || isempty(obj.objects{1}))
                    obj.objects{1} = objectToAdd;
                else
                    obj.objects{end+1} = objectToAdd;
                end
            end
            
            notify(obj, 'ListChanged');
        end
        
        % Can't call this 'size' as it would interfere with MATLAB
        function numElements = getSize(obj)
            numElements = numel(obj.objects);
        end
        
        function object = get(obj, index)
            object = {};
            
            if(isnumeric(index) == 1 && index > 0 && index <= obj.getSize())
                object = obj.objects{index};
            else
                if(isnumeric(index))
                    exception = MException([class(obj) ':InvalidIndex'], ['Cannot get index ' num2str(index) '. Must be an integer, greater than 0 and less than or equal to ' num2str(obj.getSize()) '.']);
                else
                    exception = MException([class(obj) ':InvalidIndex'], ['Cannot get index ' index '. Must be an integer, greater than 0 and less than or equal to ' num2str(obj.getSize()) '.']);
                end
                throw(exception);
            end
        end
        
        function set(this, index, object)
            this.objects{index} = object;
        end
        
        function remove(obj, objectToRemove)
            if(isa(objectToRemove, obj.getListClass()))
                % There is no easy way to remove from cells without leaving
                % spaces as far as I can tell. To avoid sorting, simply
                % create a new list to contain the references that aren't
                % equal to the object to be removed
                newList = {};
                
                for i = 1:numel(obj.objects)
                    if(obj.objects{i} ~= objectToRemove)
                        newList{end+1} = obj.objects{i};
                    end
                end
                
                obj.objects = newList;
                
                notify(obj, 'ListChanged');
            else
                exception = MException([class(obj) ':InvalidClass'], ['Cannot remove class of type ' class(objectToRemove) ' to a list of type ' class(obj)]);
                throw(exception);
            end
        end
        
        function removeAll(obj)
            obj.objects = {};
            
            notify(obj, 'ListChanged');
        end
        
        function objects = getObjects(obj)
            objects = obj.objects;
        end
    end
    
    methods (Access = protected)
        function cpObj = copyElement(obj)
            % Make a shallow copy 
            cpObj = copyElement@Copyable(obj);
            
            cpObj.objects = obj.objects;
        end
    end
end