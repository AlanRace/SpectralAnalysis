#include "mex.h"
#include <math.h>

/*  Replace zeros for Synapt G2 data
 *                                               
 */

/*   Alan Race <amr665@bham.ac.uk>  */
/*   University of Birmingham      */
/*   July 2013                     */

#define totalSpectralChannels_IN    prhs[0]
#define spectralChannels_IN         prhs[1]
#define intensities_IN              prhs[2]

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
    size_t totalSpectralChannels_m, totalSpectralChannels_n,
            spectralChannels_m, spectralChannels_n,
            intensities_m, intensities_n;
    
    double *totalSpectralChannels, *totalIntensities, 
            *spectralChannels, *intensities;
    
    int numBins, i, j, totalVectorLength, vectorLength;
    
    double temp, temp2;
    
    if(nrhs != 3)
        mexErrMsgIdAndTxt("SynaptReplaceZeros:InvalidInput", "Invalid input. Requires: totalSpectralChannels, spectralChannels, intensities");
    if(nlhs > 2)
        mexErrMsgIdAndTxt("SynaptReplaceZeros:InvalidOutput", "Too many output arguments.");
    
    totalSpectralChannels_m = mxGetM(totalSpectralChannels_IN);
    totalSpectralChannels_n = mxGetN(totalSpectralChannels_IN);
    spectralChannels_m = mxGetM(spectralChannels_IN);
    spectralChannels_n = mxGetN(spectralChannels_IN);
    intensities_m = mxGetM(intensities_IN);
    intensities_n = mxGetN(intensities_IN);
    
    /* Check */
    if(!mxIsDouble(totalSpectralChannels_IN))
        mexErrMsgIdAndTxt("SynaptReplaceZeros:InvalidInput", "totalSpectralChannels must be double."); 
    
    /* Check the dimensions of spectralChannels  and intensities */
    if(!mxIsDouble(spectralChannels_IN) || !mxIsDouble(intensities_IN) || 
            MAX(spectralChannels_m, spectralChannels_n) != MAX(intensities_m, intensities_n))
        mexErrMsgIdAndTxt("SynaptReplaceZeros:InvalidInput", "spectralChannels and intensities must be the same length vectors."); 
    
    vectorLength = MAX(spectralChannels_m, spectralChannels_n);
    totalVectorLength = MAX(totalSpectralChannels_m, totalSpectralChannels_n);
        
    spectralChannels_OUT = totalSpectralChannels_IN;
    intensities_OUT = mxCreateDoubleMatrix(1, totalVectorLength, mxREAL);
    
    totalSpectralChannels = mxGetPr(totalSpectralChannels_IN);
    totalIntensities = mxGetPr(intensities_OUT);
        
    spectralChannels = mxGetPr(spectralChannels_IN);
    intensities = mxGetPr(intensities_IN);
    
    j = 0;
    
    for(i = 0; i < vectorLength; i++) {
        while(j < totalVectorLength && spectralChannels[i] != totalSpectralChannels[j])
            j++;
        
        if(j < totalVectorLength && spectralChannels[i] == totalSpectralChannels[j])
            totalIntensities[j] += intensities[i];
    }
}