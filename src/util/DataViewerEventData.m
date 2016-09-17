classdef (ConstructOnLoad) DataViewerEventData < event.EventData
   properties
      dataViewer
   end
   
   methods
      function data = DataViewerEventData(dataViewer)
          % TODO Add in checks to ensure correct type
          
         data.dataViewer = dataViewer;
      end
   end
end