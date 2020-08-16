classdef Data < handle
    % Data Abstract base class for data.
    
    properties (SetAccess = protected)
        % Description of the data stored within class.
        description = 'Data';
        
        % Preprocessing workflow applied to generate the data
        preprocessingWorkflow;
    end
    
    events
        % Triggered when the data is changed.
        DataChanged;
    end
    
    methods
        function setDescription(this, description)
            % setDescription Set the description of the data.
            %
            %   setDescription(description)
            %       description - Description of the data
            this.description = description;
        end
        
        function description = getDescription(this)
            % getDescription Get the description of the data.
            %
            %   description = getDescription()
            %       description - Description of the data
            
            description = this.description;
        end
        
        function setPreprocessingWorkflow(this, preprocessingWorkflow)
            % setPreprocessingWorkflow Set the preprocessing workflow used to generate the datas.
            %
            %   setPreprocessingWorkflow(preprocessingWorkflow)
            %       preprocessingWorkflow - Preprocessing workflow
            this.preprocessingWorkflow = preprocessingWorkflow;
        end
        
        function exportToWorkspace(this)
            % exportToWorkspace Export this object to the MATLAB workspace.
            %
            %   exportToWorkspace()
            
            % Default variable name
            variableName = {'data'};
            
            errorMessage = '';
            
            % Check that the variable name is a valid one, otherwise
            % request again
            while(~isempty(variableName))
                % Request a variable name to export to
                variableName = inputdlg([errorMessage 'Please specifiy a variable name:'], 'Variable name', 1, variableName);
                
                % Check if the user selected cancel
                if(isempty(variableName))
                    break;
                end
                
                % Ensure that the user selected a valid variable name
                if(isvarname(variableName{1}))
                    % Export variable to workspace
                    assignin('base', variableName{1}, this);
                    
                    break;
                end
                
                % Add in an error message to the variable name request
                errorMessage = 'Invalid variable name. ';
            end
        end
        
    end
    
    methods (Abstract)
        % exportToImage Export this object to an image file.
        %
        %   exportToImage()
        exportToImage(obj);
        
        % exportToLaTeX Export this object to a LaTeX compatible file.
        %
        %   exportToLaTeX()
        exportToLaTeX(obj);
    end
end