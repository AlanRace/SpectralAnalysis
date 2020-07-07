+++
title = "Data visualisation"
weight = 2
+++

### Feature List
* Generate ion image
* Generate images from list
* Save image list
* Generate RGB composite
* View spectrum
* Overlay spectra

### Overview

![Data Visualisation Interface](/images/SpectralAnalysis-interface-labelled.png)

1. Generate a [spectral representation]({{< ref "spectral-representation.md" >}})
2. Perform [data reduction]({{< ref "data-reduction.md" >}})
3. Perform [clustering]({{< ref "clustering.md" >}})
4. [Image List]({{< ref "image-list.md" >}})
5. Selected image display

### Spectral Zooming
* Zooming into a spectrum is performed by click-and-drag below the spectrum axis (see below)
* Zooming out is performed by double clicking below the spectrum axis

![Spectral Zooming](/images/SpectralAnalysis-interface-zooming.gif)

### Image Generation
When the data is loaded as ['On Disk'](/basic-usage/load-data/data-representation), ion images are not automatically generated. As the generation of 10, 20, or even 100 ion images takes approximately the same amount of time when data is on disk, the generation process is only triggered when the user clicks the `G` button in the `Image List`, demonstrated in the image below. Once this button is clicked, all images that have not been previously generated (which do not have a tick next to them) in the image list will be generated.

There are four ways to add _m/z_ ranges to the `Image List`:

1. Select the range by clicking and dragging above the axis in the spectrum
2. Type the range manually into the `Image List`, with the minimum and maximum value separated by a hypen (-).
3. Type a centroid value only into the `Image List`. When the images are generated, SpectralAnalysis will then automatically apply the range (+/-) with the units chosen (either PPM or Da) defined above the `Image List`.
4. Load a previous list (of either centroid values, or ranges).

![Image Generation](/images/SpectralAnalysis-interface-imageGeneration.gif)
