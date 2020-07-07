+++
title = "Load data"
weight = 1
+++


![SpectralAnalysis Interface](/images/SpectralAnalysis-initialInterface-labelled.png)

1. [Open Data](#openData)
2. Convert data to SpectralAnalysis format
3. View memory usage interface
4. Progress bar
5. Log of activities that have been and are currently being performed

<a name="openData"></a>

## Opening Data

When selecting the 'Open' menu, the list of currently implemented [parsers]({{< ref "parser.md" >}}) will be shown, select the appropriate parser for the type of data to be opened.

![Select file type to open](/images/SpectralAnalysis-initialInterface-open.png)

After selecting the file to open, the 'Select Data Representation' interface will be shown. This enables loading all data in memory (most memory intensive, fastest processing), loading only a subset of the data (limited spectral range and/or a selected region of interest) into memory or leaving the data on the disk (very little memory consumed, slower processing).

![Select Data Representation interface](/images/SpectralAnalysis-dataRepresentation-select.png)

1. Select the [data representation]({{< ref "data-representation.md" >}}) to use to load the data (this interface is specific to Data In Memory).
2. Optional spectral channel range to impose when loading data.
3. Optionally select a [region of interest]({{< ref "region-of-interest.md" >}}) to load. Default is the entire dataset.
4. Optionally select a method for [ensuring a consistent spectral axis]({{< ref "ensure-consistent-mz-axis.md" >}}). If data is [not continuous]({{< ref "continuous-vs-profile.md" >}}) then a method must be selected or the data will not load.
5. Load data with selected options.

