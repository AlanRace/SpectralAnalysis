#include "mex.h"

/*   Eigen decomposition for a symmetric matrix stored in upper  
 *   packed format                                               
 */

/*   Alan Race <amr665@bham.ac.uk>  */
/*   University of Birmingham      */
/*   July 2012                     */

#define DEBUG 0

void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray*prhs[] )
{
    double *AP, *D, *E, *tau, *Q, *work;
    mwSignedIndex n, info;
    char buffer[256];
    
    /* Create the vectors required as output and intermediate variables */
    mxArray *DArray, *EArray, *TAUArray, *QArray, *workArray;

    if (nrhs!=2)
        mexErrMsgTxt("Must have exactly two input arguments.");
    if (nlhs>2)
        mexErrMsgTxt("Too many output arguments.");
    if (!mxIsDouble(prhs[0]) || !mxIsDouble(prhs[1]))
        mexErrMsgTxt("Both inputs must be double arrays.");
    if (mxIsComplex(prhs[0]) || mxIsComplex(prhs[1]))
        mexErrMsgTxt("Both inputs must be real.");
    if (mxGetM(prhs[0])!=1 && mxGetN(prhs[0])!=1)
        mexErrMsgTxt("First input must be a vector.");
    if (mxGetM(prhs[1]) == 1 && mxGetN(prhs[1]) == 0)
        mexErrMsgTxt("Second input must be a scalar.");
  
#if DEBUG
    mexPrintf("Symmeig.c...\n");
#endif
    
    /*  */
    n = mxGetPr(prhs[1])[0];
  
    if(mxGetNumberOfElements(prhs[0]) != (n*(n+1)/2))
        mexErrMsgTxt("The vector is the wrong size for the N specified");

#if DEBUG
    mexPrintf("Creating matricies...\n");
#endif
    
    DArray = mxCreateDoubleMatrix(n, 1, mxREAL);
    EArray = mxCreateDoubleMatrix(n-1, 1, mxREAL); /* USED TO BE n-1 */
    TAUArray = mxCreateDoubleMatrix(n-1, 1, mxREAL);
    QArray = mxCreateDoubleMatrix(n, n, mxREAL);
    workArray = mxCreateDoubleMatrix(2*n-2, 1, mxREAL);
      
    if(!DArray)
        mexErrMsgTxt("Failed creating D");
    if(!EArray)
        mexErrMsgTxt("Failed creating E");
    if(!TAUArray)
        mexErrMsgTxt("Failed creating tau");
    if(!QArray)
        mexErrMsgTxt("Failed creating Q");
    if(!workArray)
        mexErrMsgTxt("Failed creating work");
    
#if DEBUG
    mexPrintf("Assigning matrices to pointers...\n");
#endif
    
    D = mxGetPr(DArray);
    E = mxGetPr(EArray);
    tau = mxGetPr(TAUArray);
    Q = mxGetPr(QArray);
    work = mxGetPr(workArray);
    
    if(!D)
        mexErrMsgTxt("Failed getting pointer for D");
    if(!E)
        mexErrMsgTxt("Failed getting pointer for E");
    if(!tau)
        mexErrMsgTxt("Failed getting pointer for tau");
    if(!Q)
        mexErrMsgTxt("Failed getting pointer for Q");
    if(!work)
        mexErrMsgTxt("Failed getting pointer for work");
  
#if DEBUG    
    mexPrintf("Set return arrays...\n");
#endif
    
    /* Return D (eigenvalues) and Q (eigenvectors) */
    plhs[0] = DArray;
    plhs[1] = QArray;
    
#if DEBUG    
    mexPrintf("Get input vector...\n");
#endif
    
    /* Assign the input vector to AP */
    AP = mxGetPr(prhs[0]);

#if DEBUG    
    mexPrintf("Reduce symmetric matrix to tridiagonal form...\n");
#endif

    if(!AP)
        mexErrMsgTxt("AP is null!\n");
    
    /* Reduce symmetric matrix to tridiagonal form */
#if defined _WIN32 || defined _WIN64
    dsptrd("U", &n, AP, D, E, tau, &info);
#else
    dsptrd_("U", &n, AP, D, E, tau, &info);
#endif
  
    if (info < 0) {
        sprintf(buffer, "Error using DSPTRD with input: %d", -1*info);
      
        /* Cleanup */
        mxDestroyArray(TAUArray);
        TAUArray = NULL;
        mxDestroyArray(EArray);
        EArray = NULL;
        mxDestroyArray(workArray);
        workArray = NULL;
      
        mexErrMsgTxt(buffer);
    }
    
    if(!AP)
        mexErrMsgTxt("AP is null!\n");
    if(!tau)
        mexErrMsgTxt("tau is null!\n");
    if(!Q)
        mexErrMsgTxt("Q is null!\n");
    if(!work)
        mexErrMsgTxt("work is null!\n");
    
#if DEBUG   
    mexPrintf("Generate orthogonal matrix Q...\n");

    mexPrintf("n = %d\n", n);
    if(AP)
        mexPrintf("AP[0] = %f\n", AP[0]);
    if(tau)
        mexPrintf("tau[0] = %f\n", tau[0]);
    if(Q)
        mexPrintf("Q[0] = %f\n", Q[0]);
    if(work)
        mexPrintf("work[0] = %f\n", work[0]);

    mexPrintf("Starting dopgtr...\n");    
#endif
    
    /* Generate orthogonal matrix Q */
#if defined _WIN32 || defined _WIN64   
    dopgtr("U", &n, AP, tau, Q, &n, work, &info);
#else
    dopgtr_("U", &n, AP, tau, Q, &n, work, &info);
#endif
        
#if DEBUG    
    mexPrintf("Free up tau...\n");
#endif
    
    /* Free up the unneeded vector */
    mxDestroyArray(TAUArray);
    
    if (info < 0) {
        sprintf(buffer, "Error using DOPGTR with input: %d", -1*info);      
        
        /* Cleanup */
        mxDestroyArray(EArray);
        EArray = NULL;
        mxDestroyArray(workArray);
        workArray = NULL;
        
        mexErrMsgTxt(buffer);
    }

    if(!D)
        mexErrMsgTxt("D is null!\n");
    if(!E)
        mexErrMsgTxt("E is null!\n");
    if(!Q)
        mexErrMsgTxt("Q is null!\n");
    if(!work)
        mexErrMsgTxt("work is null!\n");
    
#if DEBUG    
    mexPrintf("Compute eigenvalues and eigenvectors...\n");

    mexPrintf("n = %d\n", n);
    if(D)
        mexPrintf("D[0] = %f\n", D[0]);
    if(E)
        mexPrintf("E[0] = %f\n", E[0]);
    if(Q)
        mexPrintf("Q[0] = %f\n", Q[0]);
    if(work)
        mexPrintf("work[0] = %f\n", work[0]);
    
    mexPrintf("Starting dsteqr...\n");   
#endif
    
    /* Compute all eigenvalues and eigenvectors using implicit QL or QR method. */
#if defined _WIN32 || defined _WIN64 
    dsteqr("V", &n, D, E, Q, &n, work, &info);
#else
    dsteqr_("V", &n, D, E, Q, &n, work, &info);
#endif
  
#if DEBUG    
    mexPrintf("Free up unneeded vectors...\n");
#endif
    
    /* Free up unneeded vectors */
    if(EArray) {
        mxDestroyArray(EArray);
        EArray = NULL;
    }
    if(workArray) {
        mxDestroyArray(workArray);
        workArray = NULL;
    }
    
#if DEBUG    
    mexPrintf("Destroyed unneeded vectors.\n");
#endif
    
    if (info < 0) {
        sprintf(buffer, "Error using DSTEQR with input: %d", -1*info); 
        
        mexErrMsgTxt(buffer);
    } else if(info > 0) {
        sprintf(buffer, "Error using DSTEQR: failed to find all eigenvalues in a total of %d iterations. %d elements of E have not converged to zero.", 30*n, info); 
        
        mexErrMsgTxt(buffer);
    }
}
