classdef SynaptZeroFilling < SpectralZeroFilling
    properties (Constant)
        Name = 'Synapt';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Full m/z List File', ParameterType.String, 'D:/Birmingham/DataDrive/2014_02_17_MALDI.PRO/Data/mTOR_Full_mz_List.mat')];
    end
    
    properties (Access = public)
        mzsFull;
    end
    
    methods
        function obj = SynaptZeroFilling(fullmzListFile)
            obj.Parameters = Parameter(SynaptZeroFilling.ParameterDefinitions(1), fullmzListFile);
            
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
            a = load(fullmzListFile);
            
            obj.mzsFull = a.fullmzList;
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
