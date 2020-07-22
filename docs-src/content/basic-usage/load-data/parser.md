+++
title = "Parser"
weight = 1
+++

A parser is something that understands a specific file format and enables the translation and loading of data. 


---

#### Advanced

Currently supported parsers are

* ImzMLParser (Mass spectrometry imaging data, .imzML)
* SIMSParser (SIMS data, .tof or .grd)
* 

To create a parser for a currently unsupported file type or style of data, extend the `Parser` class and add the new class into the same folder.
