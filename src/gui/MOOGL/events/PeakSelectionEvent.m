classdef PeakSelectionEvent < event.EventData
    properties (Constant)
        Exact = 1;
        Range = 2;
    end
    
    properties (SetAccess = protected)
        selectionType;
        peakDetails;
    end
    
    methods
        function data = PeakSelectionEvent(selectionType, peakDetails)
            % Check mouse event inputs
            if(~isnumeric(selectionType))
                exception = MException('PeakSelectionEvent:invalidArgument', ['Invalid selectionType specified: ' selectionType]);
                throw(exception);
            else
                switch selectionType
                    case PeakSelectionEvent.Exact
                        if(~isnumeric(peakDetails) || length(peakDetails) ~= 1)
                            exception = MException('PeakSelectionEvent:invalidArgument', ['Invalid peakDetails specified for ''Exact'', must be numeric and a single value']);
                            throw(exception);
                        end
                    case PeakSelectionEvent.Range
                        if(~isnumeric(peakDetails) || length(peakDetails) ~= 2)
                            exception = MException('PeakSelectionEvent:invalidArgument', ['Invalid peakDetails specified for ''Range'', must be numeric and two values']);
                            throw(exception);
                        end
                    otherwise
                        % Not a recognised mouse event
                        exception = MException('PeakSelectionEvent:invalidArgument', ['Invalid selectionType specified: ' num2str(selectionType)]);
                        throw(exception);
                end
            end
            
            data.selectionType = selectionType;
            data.peakDetails = peakDetails;
        end
    end
end