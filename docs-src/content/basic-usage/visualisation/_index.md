+++
title = "Data visualisation"
weight = 2
+++

### Feature List
* [View spectrum](#view-spectrum)
* [Generate ion image](#image-generation)
* Generate images from list
* Save image list
* Generate RGB composite
* View spectrum
* Overlay spectra

### Interface Overview

{{% notice note %}}
The interface has changed appearance in the latest version, but the information on this page is still accurate. 
{{% /notice %}}

![Data Visualisation Interface](/images/SpectralAnalysis-interface-labelled.png)


1. Generate a [spectral representation]({{< ref "spectral-representation.md" >}})
2. Perform [data reduction]({{< ref "data-reduction.md" >}})
3. Perform [clustering]({{< ref "clustering.md" >}})
4. Image List panel
5. Selected image display
6. Region of Interest panel
7. Spectrum List panel
8. Selected spectrum display
9. Spectral Preprocessing panel

### View Spectrum{#view-spectrum}
To view the spectrum associated with a single pixel, simply click on the desired pixel and the spectrum will be displayed in the spectrum display panel.

* Zooming into a spectrum is performed by click-and-drag below the spectrum axis (see below)
* Zooming out is performed by double clicking below the spectrum axis

![Spectral Zooming](/images/SpectralAnalysis-interface-zooming.gif)

### Image Generation{#image-generation}

{{% notice info %}}
This section is written to describe generation of images in mass spectrometry imaging (i.e. ion images, where the spectral channels are _m/z_ values), but the same process applies for any spectral imaging data. 
{{% /notice %}}

Generation of ion images is performed by selecting one or more _m/z_ limit pairs

Ion images that have been previously generated are marked by a tick (✓) in the 'Generated' column in the `Image List` panel.


{{% notice note %}}
When a dataset is loaded as ['Data On Disk'](/basic-usage/load-data/data-representation), ion images are not automatically generated. As the generation of 10, 20, or even 100 ion images takes approximately the same amount of time when data is on disk, the generation process is only triggered when the user clicks the `G` button in the `Image List` panel. Once this button is clicked, all images that have not been previously generated (which do not have a tick (✓) next to them) in the image list will be generated.
{{% /notice %}}

Various methods of generation ion images are discussed in the following sections.

#### Visually select ion image limits
Select the range by clicking and dragging above the axis in the spectrum.

![Image Generation](/images/SpectralAnalysis-interface-imageGeneration.gif)

#### Manually select ion image limits 
1. Type the range manually into the `Image List`, with the minimum and maximum value separated by a hypen (-).
2. Type a centroid value only into the `Image List`. When the images are generated, SpectralAnalysis will then automatically apply the range (+/-) with the units chosen (either PPM or Da) defined above the `Image List`.
