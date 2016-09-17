#include "mex.h"

/*                                                  
 */

/*   Alan Race <amr665@bham.ac.uk>  */
/*   University of Birmingham      */
/*   July 2012                     */

void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray*prhs[] )
{
    double *Q, *L;
    
    int i, j, index;
    
    double nSpectra = mxGetPr(prhs[2])[0];
    int lSize = mxGetNumberOfElements(prhs[1]);
    
    int qSize = mxGetNumberOfElements(prhs[0]);
    
    double factor = nSpectra * (nSpectra - 1);

    /* Use Q as the output for E = (Q./(nSpectra - 1)) - ((L*L')./(nSpectra * (nSpectra - 1))); */
    /* plhs[0] = prhs[0];*/
    
    Q = mxGetPr(prhs[0]);
    L = mxGetPr(prhs[1]);
    
    for(j = 0; j < lSize; j++) {
        for(i = 0; i <= j; i++) {
            index = (i+j*(j+1)/2);
            
            if(index >= qSize)
                mexErrMsgTxt("Invalid index generated. x has too many elements to update Q.");
            
            Q[index] /= (nSpectra - 1);
            Q[index] -= (L[i] * L[j]) / factor;            
        }
    }        
}
