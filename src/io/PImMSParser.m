classdef PImMSParser < Parser
    properties (Constant)
        Name = 'PImMS Binary';
    end

    properties (SetAccess = protected)
        % Time-of-flight properties
        tof_start;
        tof_end;
        tof_range;

        % Image data variable
        image_data;
    end

    methods (Static)
        function filterSpec = getFilterSpec()
            filterSpec = {'*.bin', 'PImMS Binary (*.bin)'};
        end
    end

    methods
        function this = PImMSParser(filename)
            this.filename = filename;

            % Check that the filename ends in .bin
            [pathstr,name,ext] = fileparts(filename);

            if(~strcmpi(ext, '.bin'))
                exception = MException('PImMSParser:FailedToParse', ...
                    ['Must supply a BIN (*.bin) file']);
                throw(exception);
            end

        end


        function parse(this)
            % Display a message to the user that parsing has started
            notify(this, 'ParsingStarted');

            % Assume data is PImMS2 (324x324)
            % TODO: Perform any parsing of the data here. Making sure that width and height are filled in
            this.width = 324;
            this.height = 324;

            % Set limits on how much of the time-of-flight to read
            this.tof_start = 0;
            this.tof_end = 4095;

            % Check the tof start and end falls within the timestamp range of PImMS
            if(this.tof_start < 0)
                this.tof_start = 0;
            end
            if(this.tof_end > 4095)
                this.tof_end = 4095;
            end

            this.tof_range = this.tof_end - this.tof_start + 1;

            % Read the PImMS file into an array
            % Initialise array
            this.image_data = zeros(this.height,this.width,this.tof_range);

            % Open the file
            fileID = fopen(this.filename, 'r');

            if(this.tof_range == 4096)
                % Loop through each frame and read the data with no need to account for different array sizes
                while 1
                    try
                        m = fread(fileID, 1, 'int32');
                        n = fread(fileID, 1, 'int32');
                        data = transpose(reshape(fread(fileID, m*n, 'uint16'),[n,m]) + 1);
                    catch err
                        break
                    end

                    % Add one to the image for each ion hit
                    for i = 1:size(data,1)
                        this.image_data(data(i,1),data(i,2),data(i,3)) = this.image_data(data(i,1),data(i,2),data(i,3)) + 1;
                    end
                end
            else
                % Loop through each frame and read the data
                while 1
                    try
                        m = fread(fileID, 1, 'int32');
                        n = fread(fileID, 1, 'int32');
                        if(m==0)
                          continue;
                        end
                        data = transpose(reshape(fread(fileID, m*n, 'uint16'),[n,m]) + 1);
                    catch err
                        break
                    end
                    % Make sure the indexing is correct and find valid
                    % indexes
                    data(:,3) = data(:,3) - this.tof_start;
                    data = data(data(:,3) > 0 & data(:,3) < this.tof_range + 1,:);

                    % Add one to the image for each ion hit
                    for i = 1:size(data,1)
                        this.image_data(data(i,1),data(i,2),data(i,3)) = this.image_data(data(i,1),data(i,2),data(i,3)) + 1;
                    end
                end

            end

            % Close the file
            fclose(fileID);

            % Close the message and notify the user that parsing is complete
            notify(this, 'ParsingComplete');
        end

        function spectrum = getSpectrum(this, x, y)
            % Read in the data for the spectrum at location (x, y). If one doesn't exist then set spectralChannels and intensities to be empty

            spectralChannels = transpose(this.tof_start:this.tof_end);
            intensities = reshape(this.image_data(x,y,:),[],1);

            spectrum = SpectralData(spectralChannels, intensities);
        end

        function image = getImage(this, spectralChannel, channelWidth)
            % Create an image for a defined timestamp range
            image = Image(sum(this.image_data(:,:,spectralChannel:SpectralChannel + channelWidth - 1),3));
        end

        function image = getOverviewImage(this)
            % Create an overview image by summing over the time axis
            image = Image(sum(this.image_data,3));
        end

        function spectrum = getOverviewSpectrum(this)
            % Create an overview tof by summing over the image for each timestamp
            spectralChannels = transpose(this.tof_start:this.tof_end);
            intensities = reshape(sum(this.image_data,[1,2]),[],1);

            spectrum = SpectralData(spectralChannels, intensities);
        end
                
        function dataRepresentation = getDefaultDataRepresentation(this)
            dataRepresentation = DataInMemory();
            
            obj.dataRepresentation.loadData(this, this.getAnalysedRegion(), [], []);
        end
        
        function workflow = getDefaultPreprocessingWorkflow(obj)
            workflow = PreprocessingWorkflow();
        end
    end
end
