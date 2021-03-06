classdef SynaptZeroFilling < SpectralZeroFilling
    properties (Constant)
        Name = 'Synapt';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Full m/z List', ParameterType.Double, [0, 1000])];
    end
    
    properties (Access = public)
        mzsFull;
    end
    
    methods
        function obj = SynaptZeroFilling(fullmzList)
            obj.Parameters = Parameter(SynaptZeroFilling.ParameterDefinitions(1), fullmzList);
            
            %% Generate fullmzListFile using:
            % imzML = dataRepresentation.parser.imzML;
            % 
            % fullmzList = [];
            % 
            % tic;
            % for y = 1:imzML.getHeight()
            %     for x = 1:imzML.getWidth()
            %         spectrum = imzML.getSpectrum(x, y);
            %         
            %         if(isempty(spectrum))
            %             continue;
            %         end
            %         
            %         mzs = spectrum.getmzArray();
            %         
            %         fullmzList = union(fullmzList, mzs);
            %     end
            % end
            % toc;
            
%             a = load(fullmzListFile);
            
            obj.mzsFull = fullmzList;
        end
        
        function [mzsFull, countsFull] = zeroFill(obj, spectralChannels, intensities)
            [mzsFull, countsFull] = synaptReplaceZeros(obj.mzsFull, spectralChannels, intensities);
            
            mzsFull = obj.mzsFull;
        end
    end
    
    methods (Static)
        function bool = defaultsRequireGenerating()
            bool = 0;
        end 
    end
end
