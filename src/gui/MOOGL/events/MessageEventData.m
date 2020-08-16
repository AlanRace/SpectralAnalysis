classdef (ConstructOnLoad) MessageEventData < event.EventData
   properties
      message
   end
   
   methods
      function data = MessageEventData(message)
          % TODO Add in checks to ensure correct type
          
         data.message = message;
      end
   end
end