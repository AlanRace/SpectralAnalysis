% Original source: http://stackoverflow.com/questions/1389042/how-do-i-create-enumerated-types-in-matlab
% Original author: Mason Freed 13/07/2010

classdef Enumeration
    
% ============================================================================
% Everything from here down is completely boilerplate - no need to change anything.
% ============================================================================
properties (SetAccess=protected) % All these properties are immutable.
    Code;
end
properties (Dependent, SetAccess=protected)
    Name;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
methods
    function out = eq(a, b) %EQ Basic "type-safe" eq
        check_type_safety(a, b);
        out = reshape([a.Code],size(a)) == reshape([b.Code],size(b));
    end
    function [tf,loc] = ismember(a, b)
        check_type_safety(a, b);
        [tf,loc] = ismember(reshape([a.Code],size(a)), [b.Code]);
    end
    function check_type_safety(varargin) %CHECK_TYPE_SAFETY Check that all inputs are of this enum type
        theClass = class(varargin{1});
        for ii = 2:nargin
            if ~isa(varargin{ii}, theClass)
                error('Non-typesafe comparison of %s vs. %s', theClass, class(varargin{ii}));
            end
        end
    end

    % Display stuff:
    function display(obj)
        disp([inputname(1) ' =']);
        disp(obj);
    end
    function disp(obj)
        if isscalar(obj)
            fprintf('%s: %s (%d)\n', class(obj), obj.Name, obj.Code);
        else
            fprintf('%s array: size %s\n', class(obj), mat2str(size(obj)));
        end
    end    
    function name=get.Name(obj)
        mc=metaclass(obj);
        mp=mc.Properties;
        for ii=1:length(mp)
            if (mp{ii}.Constant && isequal(obj.(mp{ii}.Name).Code,obj.Code))
                name = mp{ii}.Name;
                return;
            end;
        end;
        error('Unable to find a %s value of %d',class(obj),obj.Code);
    end;
end
end