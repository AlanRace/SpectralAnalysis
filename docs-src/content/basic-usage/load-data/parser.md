+++
title = "Parser"
weight = 1
+++

A parser is something that understands a specific file format and enables the translation and loading of data. Currently supported data formats are

* [imzML](http://imzml.org/wp/imzml/) the open mass spectrometry imaging format (.imzML)


---

#### Advanced

Currently supported parsers are

* ImzMLParser (Mass spectrometry imaging data, .imzML)
* SIMSParser (SIMS data, .tof or .grd)
* 

To create a parser for a currently unsupported file type or style of data, extend the `Parser` class and add the new class into the same folder.
