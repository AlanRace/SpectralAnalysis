+++
title = "Normalisation"
+++

### Background

The goal of normalisation is to scale the intensities of each pixel to remove systematic artefacts that affect intensity. For further reading on normalisation methods there are a number of articles that discuss this further

* [Normalization in MALDI-TOF imaging datasets of proteins: practical considerations](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3124646/)
* [Robust data processing and normalization strategy for MALDI mass spectrometric imaging](https://www.ncbi.nlm.nih.gov/pubmed/22148759)
* [Exploring Ion Suppression in Mass Spectrometry Imaging of a Heterogeneous Tissue](https://pubs.acs.org/doi/abs/10.1021/acs.analchem.7b05005)

### Applying a method in SpectralAnalysis

1. Select a spectrum by clicking on a pixel in the image.
2. Open `Preprocessing Workflow Editor` by selecting `Edit` button in `Spectral Preprocessing` panel.
3. Select most appropriate `Normalisation` method (see **Choosing the most appropriate method** section below) and click the adjacent `+` button.
4. Enter desired parameters for the chosen method (if appropriate, and applicable), optionally checking the effect of the zero filling method by zooming into the spectrum and observing the 'before' and 'after' spectra.
5. Click `OK` to close the `Edit Preprocesing Method` window and then `OK` again to close the `Preprocessing Workflow Editor`.  The chosen method(s) will now be automatically applied to any viewed spectrum.


   
### Choosing the most appropriate method

Choosing an appropriate normalisation method is challenging and depends on the artefacts that need to be removed. The methods included in SpectralAnalysis are described below.


* l<sup>2</sup> normalisation
* Median intensity normalisation
* Noise level normalisation
* p-norm normalisation
* Root mean square normalisation
* TIC normalisation


##### l<sup>2</sup> normalisation

This method normalises the data such that the sum of the squares of each spectrum will always be add up to 1 

##### Median intensity normalisation

This normalises by dividing the intensities of each spectrum by the median intensity for that spectrum. In some datasets (particularly protein imaging) this is an estimation of the baseline of the data.

##### Noise level normalisation

This method aims to estimate the noise level in the dataset using the method described by [Deininger *et al.*](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3124646/) and normalises to this. This assumes that the noise in the data should be constant.

##### p-norm normalisation

p-norm is a generalisable variation on the l<sup>2</sup> normalisation where the sum of the power `p` specified by the user adds up to 1. In the case where p = 2, this is equivalent to the l<sup>2</sup> norm, and p=1 is equivalent to the TIC norm 

##### Root mean square normalisation

Root mean square normalisation scales the intensities to the square root of the the arithmetic mean of the squares of the intensities for each spectrum.

##### TIC normalisation

This method scales the intensities of each spectrum such that they sum to 1. This method assumes that each spectrum should have the same total number of ion present.

##### 

##### 



#### 
