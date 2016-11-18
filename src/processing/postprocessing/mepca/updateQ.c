#include "mex.h"

/*                                                  
 */

/*   Alan Race <amr665@bham.ac.uk>  */
/*   University of Birmingham      */
/*   July 2012                     */

void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray*prhs[] )
{
    double *Q, *x;
    
    int i, j, index;
    
    int xSize = mxGetNumberOfElements(prhs[1]);
    int qSize = mxGetNumberOfElements(prhs[0]);
    
    /* Output the updated Q */    
    Q = mxGetPr(prhs[0]);
    x = mxGetPr(prhs[1]);
    
    for(j = 0; j < xSize; j++) {
        for(i = 0; i <= j; i++) {
            index = (i+j*(j+1)/2);
            
            if(index >= qSize)
                mexErrMsgTxt("Invalid index generated. x has too many elements to update Q.");
            
            Q[index] += x[i] * x[j];
        }
    }        
}
