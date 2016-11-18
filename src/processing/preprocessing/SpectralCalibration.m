classdef SpectralCalibration < SpectralZeroFilling
    properties (Constant)
        Name = 'Calibration';
        Description = '';
        
        ParameterDefinitions = [ParameterDescription('Theoretical', ParameterType.String, ''), ...
                    ParameterDescription('Experimental', ParameterType.String, ''),...
                    ParameterDescription('Order', ParameterType.Integer, 1)];
    end
    
    properties (Access = private)
        fit;
    end
    
    methods
        function obj = SpectralCalibration(theoretical, experimental, order)
            obj.Parameters = Parameter(SpectralCalibration.ParameterDefinitions(1), theoretical);
            obj.Parameters(2) = Parameter(SpectralCalibration.ParameterDefinitions(2), experimental);
            obj.Parameters(3) = Parameter(SpectralCalibration.ParameterDefinitions(3), order);
            
            obj.fit = polyfit(str2double(strsplit(experimental, ',')), str2double(strsplit(theoretical, ',')), order);
        end
        
        function [spectralChannels, intensities] = zeroFill(obj, spectralChannels, intensities)
            spectralChannels = polyval(obj.fit, spectralChannels);
        end
    end
    
    methods (Static)
        function bool = defaultsRequireGenerating()
            bool = 0;
        end                
        
%         function Parameters = generateDefaultsFromSpectrum(spectrum)
%             Parameters = Parameter(QSTARZeroFilling.ParameterDefinitions(1), min(spectrum.spectralChannels));
%             Parameters(2) = Parameter(QSTARZeroFilling.ParameterDefinitions(2), max(spectrum.spectralChannels));
%             
%             time = sqrt(spectrum.spectralChannels);
%             
%             timeDiff = time(2:end) - time(1:end-1);
%     
%             if(min(timeDiff) < 0)
%                 timeDiff = timeDiff * -1;
%             end
% 
%             detectorBinSize = mode(timeDiff(timeDiff < 1.5*min(timeDiff)));
%             
%             Parameters(3) = Parameter(QSTARZeroFilling.ParameterDefinitions(3), detectorBinSize);
%         end
    end
end