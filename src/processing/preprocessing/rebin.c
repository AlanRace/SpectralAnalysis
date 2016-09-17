#include "mex.h"
#include <math.h>

/*  Rebin 1D data
 *                                               
 */

/*   Alan Race <amr665@bham.ac.uk>  */
/*   University of Birmingham      */
/*   July 2013                     */

#define spectralChannels_IN     prhs[0]
#define intensities_IN          prhs[1]
#define spectralRange_IN        prhs[2]
#define binSize_IN              prhs[3]

#define spectralChannels_OUT    plhs[0]
#define intensities_OUT         plhs[1]

#if !defined(MAX)
#define	MAX(A, B)	((A) > (B) ? (A) : (B))
#endif

#if !defined(MIN)
#define	MIN(A, B)	((A) < (B) ? (A) : (B))
#endif

void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray*prhs[] )
{
    size_t spectralChannels_m, spectralChannels_n,
            intensities_m, intensities_n,
            spectralRange_m, spectralRange_n;
    
    double *spectralChannels, *intensities, 
           *spectralChannelsBinned, *intensitiesBinned,
           *spectralRange;
    
    double minSpectralChannel, maxSpectralChannel, binSize;
    double halfBinSize;
    
    int numBins, i, j, vectorLength;
    
    double temp, temp2;
    
    if(nrhs != 4)
        mexErrMsgIdAndTxt("Rebin:InvalidInput", "Invalid input. Requires: spectralChannels, intensities, spectralRange, binSize");
    if(nlhs > 2)
        mexErrMsgIdAndTxt("Rebin:InvalidOutput", "Too many output arguments.");
    
    spectralChannels_m = mxGetM(spectralChannels_IN);
    spectralChannels_n = mxGetN(spectralChannels_IN);
    intensities_m = mxGetM(intensities_IN);
    intensities_n = mxGetN(intensities_IN);
    spectralRange_m = mxGetM(spectralRange_IN);
    spectralRange_n = mxGetN(spectralRange_IN);
    
    /* Check the dimensions of spectralChannels  and intensities */
    if(!mxIsDouble(spectralChannels_IN) || !mxIsDouble(intensities_IN) || 
            MAX(spectralChannels_m, spectralChannels_n) != MAX(intensities_m, intensities_n))
        mexErrMsgIdAndTxt( "Rebin:InvalidInput", "spectralChannels and intensities must be the same length vectors."); 
    
    vectorLength = MAX(spectralChannels_m, spectralChannels_n);
    
    /* Check the dimensions of spectralRange */
    if(!mxIsDouble(spectralRange_IN) || (MAX(spectralRange_m, spectralRange_n) != 2) || 
            (MIN(spectralRange_m, spectralRange_n) != 1))
        mexErrMsgIdAndTxt( "Rebin:InvalidInput", "spectralRange must be a 2 x 1 vector."); 
    
    /* TODO: Check binSize */
    
    spectralRange = mxGetPr(spectralRange_IN);
    minSpectralChannel = spectralRange[0];
    maxSpectralChannel = spectralRange[1];
    
    binSize = mxGetPr(binSize_IN)[0];
    halfBinSize = binSize / 2;
    
    numBins = floor(((maxSpectralChannel - minSpectralChannel) / binSize) + 0.5) + 1;
    
    spectralChannels_OUT = mxCreateDoubleMatrix(1, numBins, mxREAL);
    spectralChannelsBinned = mxGetPr(spectralChannels_OUT);
    
    intensities_OUT = mxCreateDoubleMatrix(1, numBins, mxREAL);
    intensitiesBinned = mxGetPr(intensities_OUT);
    
    temp = minSpectralChannel;
    
    for(i = 0; i < numBins; i++) {
        spectralChannelsBinned[i] = temp;
        intensitiesBinned[i] = 0;
        temp += binSize;
    }
    
    
    
    spectralChannels = mxGetPr(spectralChannels_IN);
    intensities = mxGetPr(intensities_IN);
    
    j = 0;
    
    for(i = 0; i < vectorLength; i++) {
        if(spectralChannels[i] < minSpectralChannel)
            continue;
        if(spectralChannels[i] > maxSpectralChannel)
            break;
        
        temp = spectralChannels[i] - halfBinSize;
        temp2 = spectralChannels[i] + halfBinSize;
        
        while(spectralChannelsBinned[j] < temp && j < numBins)
            j++;
        
        if(j < numBins && spectralChannelsBinned[j] < temp2)
            intensitiesBinned[j] += intensities[i];
    }
}