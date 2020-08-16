+++
title = "Using SpectralAnalysis in python"
weight = 3
+++

1. Install MATLAB
2. Install Python version 3.7
3. Install [MATLAB Engine for Python](https://mathworks.com/help/matlab/matlab_external/install-the-matlab-engine-for-python.html)


```python
import matlab.engine

print("Starting MATLAB Engine. This may take a couple of seconds.");
eng = matlab.engine.start_matlab()
print("MATLAB Engine started.")

# Add SpectralAnalysis to MATLAB path
eng.addpath(eng.genpath(r"C:\\Path\\To\\SpectralAnalysis"))
# Add Java libraries to MATLAB path
eng.addJARsToClassPath(nargout=0)

# Load in the example data using ImzMLParser
mouseBrain = eng.ImzMLParser(r"C:\\Path\\To\\SpectralAnalysis\\example-data\\mouse-brain\\MouseBrainCerebellum.imzML")
eng.parse(mouseBrain, nargout=0)

# Get the image parameters
width = eng.getWidth(mouseBrain)
height = eng.getHeight(mouseBrain)

# Get the spectrum at position (1, 1)
firstSpectrum = eng.getSpectrum(mouseBrain, 1, 1)

# Get the spectralChannels array
spectralChannels = eng.getfield(firstSpectrum, 'spectralChannels')
spectralChannels = spectralChannels[0]

intensities = eng.getfield(firstSpectrum, 'intensities')
intensities = intensities[0]

print("Found spectrum with {0} values. First data point has spectral channel = {1} with intensity {2}".format(len(spectralChannels), spectralChannels[0], intensities[0]))
```