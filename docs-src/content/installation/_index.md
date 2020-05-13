+++
title = "Installation"
weight = 1
+++

There are two means of installing SpectralAnalysis and you can choose the one that best fits your use case. The standalone version works without requiring a MATLAB licence, however this cannot be modified or make use of any of the ['advanced' functionality](/advanced-use/). The source code version requires a valid MATLAB licence, however can perform both [general](/basic-usage/) and [advanced](/advanced-use/) functionality.

## Standalone Version

Currently requires 64-bit Windows. If you are running 32-bit Windows and want a standalone version please [contact me](https://github.com/AlanRace/SpectralAnalysis/issues/new).

1. Download and extract the zip file of the [latest release](https://github.com/AlanRace/SpectralAnalysis/releases)
2. Download and install the [R2016b (9.1) MATLAB Runtime](https://uk.mathworks.com/products/compiler/mcr/)
3. Download and install the [Visual C++ Redistributable for Visual Studio 2015](https://www.microsoft.com/en-us/download/details.aspx?id=48145)
4. Run SpectralAnalysis.exe 

## Source code Version {#source-version}

The source code version requires a valid MATLAB licence.

### Increase Java Heap Space
Prior to running SpectralAnalysis, it is advisable to increase the 'Java Heap Size' allocated to MATLAB to the maximum available. This enables larger imzML files to be opened successfully.

* [MATLAB 2010a or later](http://uk.mathworks.com/help/matlab/matlab_external/java-heap-memory-preferences.html)
* [MATLAB 2009b or earlier](https://uk.mathworks.com/matlabcentral/answers/92813-how-do-i-increase-the-heap-space-for-the-java-vm-in-matlab-6-0-r12-and-later-versions)


### Installation with Git

     git clone https://github.com/AlanRace/SpectralAnalysis
     cd SpectralAnalysis
     git submodule update --init

### Installation without Git

1. Download the source code of the [latest release](https://github.com/AlanRace/SpectralAnalysis/releases)
2. Download the latest version of [MOOGL](https://github.com/AlanRace/MOOGL/tree/develop) and place in the `SpectralAnalysis\src\gui\MOOGL` folder
2. Open MATLAB and navigate to the folder containing the source code 
3. Run the command `runSpectralAnalysis`

### Compatible MATLAB Versions

If you use a currently untested version of MATLAB, please let me know any successes or issues you encounter ([submit issues](https://github.com/AlanRace/SpectralAnalysis/issues)).

| MATLAB Version | Compatibility        | Notes  |
| -------------- |-------------| -----|
| R2016b | Compatible |  |
| R2016a | Compatible |  |
| R2015b | Compatible |    |
| R2015a | Compatible |     |
| R2014b | Compatible |     |
| R2014a | Compatible |     |
| R2013b | Untested |     |
| R2013a | Untested |     |
| R2012b | Untested |     |
| R2012a | Untested |     |
| R2011b | Untested |     |
| R2011a | Untested |     |
| R2010b | Untested |     |
| R2010a | Untested |     |
| R2009b | Untested |     |
| R2009a | Untested |     |



