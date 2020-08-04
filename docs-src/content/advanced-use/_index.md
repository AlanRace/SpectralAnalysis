+++
title = "Advanced Use"
weight = 3
+++

SpectralAnalysis was designed in such a way to enable rapid development and integration of new algorithms (such as preprocessing, multivariate analysis or clustering methods). To facilitate this, it is possible to freely transfer data to a MATLAB workspace and back again. This provides MATLAB proficient users with the option of exporting their data to the workspace and visualisating and further processing in any way they desire. 


### Integration with MATLAB
To take advantage of the transfer of data between the MATLAB workspace and SpectralAnalysis, the [source code version](/installation/#source-version) of SpectralAnalysis must be used.

Extracting data from the interface to MATLAB is then as simple as right clicking on the data that you want to export and selecting `Export > To Workspace` from the context menu.



### Extending SpectralAnalysis

All functions can be extended within SpectralAnalysis. Examples on how to include new preprocessing and processing algorithms can be found in the `examples/SkeletonClasses` folder within the main SpectralAnalysis folder.