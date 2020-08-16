classdef ProgressBar < handle
    
    properties (SetAccess = private)
        axisHandle;
    end
    
    properties (Access = private)
        lastUpdate;
        updateInterval = 0.25;
        previousPercentage = 0;
        minimalPercentageDisplay = 5;
        
        progressDescriptionText;
        progressText;
        
        progressBar;
        xData;
    end
    
    methods
        function obj = ProgressBar(axisHandle)
            if(~(ishandle(axisHandle) && strcmp(get(axisHandle, 'Type'), 'axes')))
                exception = MException('ProgressBar:invalidArgument', '''axisHandle'' must be a valid axes handle');
                throw(exception);
            end
            
            obj.axisHandle = axisHandle;
            
            set(obj.axisHandle, 'XLim', [0 1], 'YLim', [0 1], 'Box', 'on', 'yTick', [], 'xTick', []);
        end
        
        function updateProgress(obj, progressEventData)
            if(isa(progressEventData, 'event.EventData') && ~isa(progressEventData, 'ProgressEventData'))
                return;
            end
            
            if(~isa(progressEventData, 'ProgressEventData'))
                
                exception = MException('ProgressBar:invalidArgument', '''progressEventData'' must be of type ProgressEventData');
                throw(exception);
            end
            
            currentTime = clock;
            
            if(isempty(obj.lastUpdate) || (abs(currentTime(6) - obj.lastUpdate(6)) > obj.updateInterval) || progressEventData.progress == 1)
                progressPercentage = progressEventData.progress * 100;
                
                progressString = [num2str(progressPercentage, '% 10.2f') '%'];
                
                if(isempty(obj.progressBar))
                    obj.xData = [0 0 0 0];
                    yData = [0 0 1 1];
                    
                    obj.progressBar = patch('Parent', obj.axisHandle, 'XData', obj.xData, 'YData', yData, 'FaceColor', [0 0.76 0]);
                elseif((progressPercentage - obj.previousPercentage) > obj.minimalPercentageDisplay || obj.previousPercentage > progressPercentage ...
                        || progressEventData.progress == 1)
                    set(obj.progressBar, 'XData', [0 progressEventData.progress progressEventData.progress 0]);
                    
                    obj.previousPercentage = progressPercentage;
                end
                
                if(isempty(obj.progressDescriptionText))
                    obj.progressDescriptionText = text(0.01, 0.5, progressEventData.event, 'Parent', obj.axisHandle);
                elseif(~strcmp(get(obj.progressDescriptionText, 'String'), progressEventData.event))
                    set(obj.progressDescriptionText, 'String', progressEventData.event);
                end
                
                if(isempty(obj.progressText))
                    obj.progressText = text(0.99, 0.5, progressString, 'Parent', obj.axisHandle, 'HorizontalAlignment', 'Right');
                else
                    set(obj.progressText, 'String', progressString);
                end
                
                drawnow;
                
                obj.lastUpdate = currentTime;
            end
        end
    end
end