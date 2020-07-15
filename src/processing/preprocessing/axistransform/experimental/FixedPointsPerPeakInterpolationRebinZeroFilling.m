classdef FixedPointsPerPeakInterpolationRebinZeroFilling < SpectralZeroFilling
    properties (Constant)
        Name = 'Fixed Points Per Peak Interpolation Rebin';
        Description = '';
        
        ParameterDefinitions = [];
    end
    
    properties
        newmzs
    end
    
    methods
        function obj = FixedPointsPerPeakInterpolationRebinZeroFilling()
            sPeakDiff = 104.11576-104.06217;
%             sPeakChan = 14;

            mPeakDiff = 739.4929-739.18681;
%             mPeakChan = 30;
            
            lPeak = 826.60032;
            lPeakDiff = lPeak - 826.26592;
%             lPeakChan = 31;

            % Synapt
            sPeak = 234.05577;
            sPeakDiff = sPeak - 233.97563;
            
            mPeak = 640.19574;
            mPeakDiff = mPeak - 639.97485;

            lPeak = 883.20056;
            lPeakDiff = lPeak - 882.91516;
            
            nPeakWidth = interp1([0, sPeak, mPeak, lPeak, 1201], [0, sPeakDiff, mPeakDiff, lPeakDiff, (lPeakDiff-mPeakDiff)+lPeakDiff], 50:1200) / 30;

            obj.newmzs = 50;

            for i = 1:length(nPeakWidth)
                nChans = floor(1/nPeakWidth(i));
                toAdd = obj.newmzs(end) + cumsum(ones(1, nChans) * nPeakWidth(i));
                obj.newmzs(end+1:end+length(toAdd)) = toAdd;
            end
        end
        
        function [spectralChannels, intensities] = zeroFill(obj, spectralChannels, intensities)
            intensities = interp1(spectralChannels, intensities, obj.newmzs);
            
%             if(sum(intensities) == 0)
%                 error('crap');
%             end
            
            spectralChannels = obj.newmzs;
        end
    end
    
    
end