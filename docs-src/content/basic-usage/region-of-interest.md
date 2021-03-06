+++
title = "Region of Interest"
weight = 3
+++

Regions of interest (ROIs) are areas of an image, which can be used as input into subsequent data analysis. ROIs can be defined manually, as explained in this page, or automatically through processing such as [clustering](/basic-usage/clustering).


### Feature List
* [Generate ROI](#generate-roi)
* [Calculate statistics on ROI](#calculate-statistics)
* [Export ROIs](#export-roi)

### Overview {#overview}
The ROI panel can be found on the right on the main interface (number 1 in the image below).

![Data Visualisation Interface](/images/SpectralAnalysis-ROI-labelled.png)

1. Region of interest list
2. Save region of interest list
3. Load region of interest list
4. [View statistics on ROI](#calculate-statistics)
5. [Add/edit/delete ROIs](#generate-roi)

### Generate ROI {#generate-roi}

To create an ROI manually, the `Edit` button on the main interface in the [ROI panel](#overview) must be clicked. This then opens the `ROI List Editor`, shown below, displaying the ion image which was previously active in the main interface. 

![Edit a region of interest](/images/SpectralAnalysis-ROIListEditor.png)

To create a new ROI, first click the `+` button, and then in the new window, select an ROI name and colour and then click `OK`. This then adds the new ROI to the list (bottom left in the interface). The highlighted ROI is then displayed on top of the image, and any selected tool (defined below) can then be applied directly to the image by clicking and/or dragging.

Pencil
: Assign individual pixels to the ROI.

Line
: Assign all pixels which fall along a line drawn by the user to the ROI.

Rectangle
: Assign all pixels which fall within a rectangle drawn by the user to the ROI.

Ellipse
: Assign all pixels which fall within an ellipse drawn by the user.

Poly
: Define an arbitrary shaped region of interest.

Eraser
: Toggle button. When active, use any shape to define an area to remove from the current region of interest. When deactivated, areas are added to the ROI.

Threshold
: Assign all pixels based on thresholds applied (see [Threshold](#threshold) for more details).

Move
: Allows dragging of the ROI to a new location.


#### Threshold {#threshold}
When selecting the `Threshold` button, the following window will be shown, with the fields automatically poplated with the minimim and maximum intensity of the displayed ion image.

![Threshold options](/images/roi/roiThreshold.png)

 

### Calculate statistics {#calculate-statistics}
Once one or more regions of interest have been defined, it is possible to investigate the differences between these regions further.

![](https://camo.githubusercontent.com/f8b3147640efc495e34d536ac2ddbb4c466e833f/68747470733a2f2f692e696d6775722e636f6d2f446742315553392e706e67)

### Export ROIs {#export-roi}

Selecting the 'save' button in the ROI panel will bring up a dialog box for selecting an output location for the .rois file.