+++
title = "Load data"
weight = 1
+++


![SpectralAnalysis Interface](/images/SpectralAnalysis-initialInterface-labelled.png)

1. [Load Dataset (Open)](#openData)
2. Convert data to SpectralAnalysis format
3. View memory usage interface
4. Progress bar
5. Log of activities that have been and are currently being performed

<a name="openData"></a>

### Load Dataset (Open)

When selecting the 'Open' menu, the list of currently implemented [parsers]({{< ref "parser.md" >}}) (data types) will be shown, select the appropriate parser for the type of data to be opened.

![Select file type to open](/images/SpectralAnalysis-initialInterface-open.png)

After selecting the file to open, the `DataViewer` interface will be shown. Futher details on the functionality of this interface can be found [here](/basic-usage/visualisation). The parser (data type) determines the [DataRepresentation](/basic-usage/load-data/data-representation) (whether the data is to be loaded into memory for fast access, or whether the data is too large and will therefore be accessed on demand on disk) and default spectral preprocessing workflow automatically. The data can be reloaded with a different `DataRepresentation` in the `Tools` menu. The preprocessing workflow can be altered through the [preprocessing editor](/basic-usage/preprocessing).

![SpectralAnalysis interface](/images/SpectralAnalysis-interface-1.3.0.png?width=60pc)

<!--After selecting the file to open, the 'Select Data Representation' interface will be shown. This enables loading all data in memory (most memory intensive, fastest processing), loading only a subset of the data (limited spectral range and/or a selected region of interest) into memory or leaving the data on the disk (very little memory consumed, slower processing).

![Select Data Representation interface](/images/SpectralAnalysis-dataRepresentation-select.png)

1. Select the [data representation]({{< ref "data-representation.md" >}}) to use to load the data (this interface is specific to Data In Memory).
2. Optional spectral channel range to impose when loading data.
3. Optionally select a [region of interest]({{< ref "region-of-interest.md" >}}) to load. Default is the entire dataset.
4. Optionally select a method for [ensuring a consistent spectral axis]({{< ref "ensure-consistent-mz-axis.md" >}}). If data is [not continuous]({{< ref "continuous-vs-profile.md" >}}) then a method must be selected or the data will not load.
5. Load data with selected options.
-->
