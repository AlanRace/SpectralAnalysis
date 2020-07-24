classdef ChromatogramSegment < Copyable
    
    properties (Access = protected)
        startTime;
        endTime;
        zeroFilling;
        combination;
    end
    
    
    methods
        function this = ChromatogramSegment(startTime, endTime, zeroFilling, combination)
            if(~isnumeric(startTime) || ~isnumeric(endTime))
                exception = MException('ChromatogramSegment:InvalidArgument', 'Must supply start time and end time as numbers.');
                throw(exception);
            end
            
            this.startTime = startTime;
            this.endTime = endTime;
            
            this.zeroFilling = zeroFilling;
            this.combination = combination;
        end
        
        function startTime = getStartTime(this) 
            startTime = this.startTime;
        end
        
        function endTime = getEndTime(this)
            endTime = this.endTime;
        end
        
        function zeroFilling = getZeroFilling(this)
            zeroFilling = this.zeroFilling;
        end
        
        function combination = getCombination(this)
            combination = this.combination;
        end
        
        function string = toString(this)
            if(this.combination == 1)
                combination = 'Mean';
            else
                combination = 'Sum';
            end
            
            if(isempty(this.zeroFilling))
                zeroFilling = 'None';
            else
                zeroFilling = this.zeroFilling.toString();
            end
            
            string = ['Time: ' num2str(this.startTime) ' - ' num2str(this.endTime) ', ' zeroFilling ', ' combination];
        end
    end
end