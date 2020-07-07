+++
title = "Data Representation"
+++

A data representation is a means of accessing data. Currently two general data representations are implemented `DataInMemory` and `DataOnDisk`. 

**DataInMemory** data is loaded into memory on initialisation, resulting in faster processing of data at the cost of RAM. 

**DataOnDisk** only the metadata is loaded into memory, with data being accessed from the disk only when needed. This is slower than `DataInMemory` but allows processing of datasets much larger than the available RAM.


---

#### Advanced

To create a data representation for a currently unsupported style of data access, the `DataRepresentation` class should be extended and the new class added into the same folder.
