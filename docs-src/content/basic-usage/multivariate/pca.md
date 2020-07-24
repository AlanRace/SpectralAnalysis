+++
title = "Principal Component Analysis (PCA)"
weight = 1
+++

Principal component analysis (PCA) is a statistical technique that can be used for data exploration. It is not necessary to understand the details of PCA to be able to successfully use it to find patterns within your data, but they can help interpret how significant such a pattern is. The screenshot below shows SpectralAnalysis' interface for exploring PCA results.

![PCA Interface](/images/SpectralAnalysis-PCAInterface.png?width=45pc)

##### Performing PCA
There are two methods for performing PCA included within SpectralAnalysis. These can be found in the  `Data Reduction` dropdown menu, as shown below.

![PCA Interface](/images/SpectralAnalysis-MVADropdown.png?width=45pc)

The fastest method (`PCA`) requires the data to be in memory (see [data representation](/basic-usage/load-data/data-representation)), whereas `Memory Efficient PCA` only loads in the bare minimum amount of data at any one time and can therefore be performed on datasets much larger than the available RAM. See Race *et al.* (https://pubs.acs.org/doi/10.1021/ac302528v) for more details on this method.



##### PCA Details 
The data is projected into a new space, such the the first dimension (principal component) captures the largest amount of variance within the data. Each subsequent principal component captures the largest amount of remaining variance, with the constraint that it must be orthogonal to all previous principal components.

