classdef RegionOfInterestList < DeepCopyList
    
    methods (Static)
        function listClass = getListClass()
            listClass = 'RegionOfInterest';
        end
    end    
    
    methods
        function add(this, objectToAdd)
            add@List(this, objectToAdd);
            
            addlistener(objectToAdd, 'NameChanged', @(src, event)notify(this, 'ListChanged', event));
            addlistener(objectToAdd, 'ColourChanged', @(src, event)notify(this, 'ListChanged', event));
            addlistener(objectToAdd, 'PixelSelectionChanged', @(src, event)notify(this, 'ListChanged', event));
        end
        
        function outputXML(this, fileID, indent)
            objects = this.getObjects();
            
            XMLHelper.indent(fileID, indent);
            fprintf(fileID, '<regionOfInterestList>\n');
            
            for i = 1:numel(objects)
                objects{i}.outputXML(fileID, indent+1);
            end
            
            XMLHelper.indent(fileID, indent);
            fprintf(fileID, '</regionOfInterestList>\n');
        end
    end
    
    
end