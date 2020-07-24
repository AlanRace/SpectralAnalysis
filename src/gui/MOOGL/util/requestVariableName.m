function variableName = requestVariableName(prompt, title)

variableName = [];

answer = inputdlg(prompt, title);

while(~isempty(answer))
    variableName = answer{1};
    
    if(~isvarname(variableName))
        f = errordlg(['The entered variable name was not valid. A valid variable name valid variable name ' ...
            'begins with a letter and contains only letters, digits, and underscores.'], ...
            'Invalid variable name');
        
        waitfor(f);
        
        answer = inputdlg(prompt, title);
        continue;
    else
        break;
    end
end