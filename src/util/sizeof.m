function numBytes = sizeof(dataType)

if(ischar(dataType))
    try
        val = zeros(1, dataType);
        
        details = whos('val');
        numBytes = details.bytes;
    catch err
        exception = MException('sizeof:InvalidString', ...
            ['Invalid data type: ''' dataType '''']);
        throw(exception);
    end
else
    details = whos('dataType');
        
    numBytes = details.bytes;
end
    