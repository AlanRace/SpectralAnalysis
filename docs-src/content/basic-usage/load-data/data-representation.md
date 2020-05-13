+++
title = "Data Representation"
+++

A data representation is a means of accessing data.

* DataInMemory - data is loaded into memory and stored within this class. 
* DataOnDisk - not data is loaded into memory and each access to any portion of the data results in a disk read.

To create a data representation for a currently unsupported style of data access, extend the `DataRepresentation` class and add the new class into the same folder.
