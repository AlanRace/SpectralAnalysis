function savePeakList(peakList, location)
%SAVEPEAKLIST Save an array of Peak intances to specified location

docNode = com.mathworks.xml.XMLUtils.createDocument('peaks');

peaksElement = docNode.getDocumentElement();

for i = 1:length(peakList)
    peak = peakList(i);
    
    peakElement = docNode.createElement('peak');
    peaksElement.appendChild(peakElement);
    
    centroid = docNode.createElement('centroid');
    centroid.appendChild(docNode.createTextNode(num2str(peak.centroid, '%.8f')));
    peakElement.appendChild(centroid);
    
    intensity = docNode.createElement('intensity');
    intensity.appendChild(docNode.createTextNode(num2str(peak.intensity, '%.8f')));
    peakElement.appendChild(intensity);
    
    minSpectralChannel = docNode.createElement('minSpectralChannel');
    minSpectralChannel.appendChild(docNode.createTextNode(num2str(peak.minSpectralChannel, '%.8f')));
    peakElement.appendChild(minSpectralChannel);
    
    maxSpectralChannel = docNode.createElement('maxSpectralChannel');
    maxSpectralChannel.appendChild(docNode.createTextNode(num2str(peak.maxSpectralChannel, '%.8f')));
    peakElement.appendChild(maxSpectralChannel);
end

xmlwrite(location, docNode);

end

