classdef SkeletonParser < Parser
    methods (Static) 
        function filterSpec = getFilterSpec() 
            % TODO: Fill in this method by returning 
        end
    end
    
    methods
        function this = SkeletonParser(filename)
            this.filename = filename;
            
            % TODO: Any other set up details here
        end
        
        
        function parse(this)
            % Display a message to the user that parsing has started
            notify(this, 'ParsingStarted');
            
            % TODO: Perform any parsing of the data here. Making sure that width and height are filled in
            this.width = ??;
            this.height = ??;
            
            % Close the message and notify the user that parsing is complete
            notify(this, 'ParsingComplete');
        end
        
        function [spectralChannels, intensities] = getSpectrum(this, x, y)
            % TODO: Read in the data for the spectrum at location (x, y). If one doesn't exist then set spectralChannels and intensities to be empty
            
            spectralChannels = ??;
            intensities = ??;
        end
        
        function image = getOverviewImage(this)
            imageData = zeros(this.height, this.width);        
        
            % TODO: Create an image that describes the dataset. This is displayed in the `Select Data Representation' interface when loading a dataset
            
            image = Image(imageData);
        end        
    end
end