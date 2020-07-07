+++
title = "Continuous vs Profile"
+++

The _continuous_ and _profile_ terminology are taken from [imzML](http://imzml.org/wp/imzml/) and are therefore primarily used in reference to mass spectrometry imaging data. Despite the nomenculature, _continuous_ data does not necessarily mean that the data points are a continuum and _profile_ data may be used to store peak picked data.

**Continuous** data points are consistent for all spectra within the dataset. A single, global, array of spectral channels is stored once in the dataset. Each spectrum then simply stores the corresponding intensity array

**Profile**  data stored as \[spectral channel, intensity\] pairs per spectrum. Each spectrum can therefore have a different length.
