function numPossibleAssignments = HMDBGetNumberAnnotations(peaks, adducts, ppmTolerance)

ppmTolerance = ppmTolerance/1e6;

dbconn = sqlite([getDatabasesPath() filesep 'hmdb.db']);

sqlQuery = 'select monoisotopicMolecularWeight, count(monoisotopicMolecularWeight) as "Count" from metabolites where monoisotopicMolecularWeight > 0 group by monoisotopicMolecularWeight';
results = fetch(dbconn, sqlQuery);

masses = [results{:, 1}];
resultsPerMass = [results{:, 2}];

numPossibleAssignments = zeros(1, length(peaks));

for peakID = 1:length(peaks)
    peak = peaks(peakID);
    
    numPossibleAssignments(peakID) = 0;
    
    for adductID = 1:length(adducts)
        curAdduct = adducts(adductID);
        
        centroid = peak.centroid - curAdduct.monoisotopicMass;
        deltamz = centroid * ppmTolerance;
        
        minmz = centroid - deltamz;
        maxmz = centroid + deltamz;

        numPossibleAssignments(peakID) = numPossibleAssignments(peakID) + sum(resultsPerMass(masses >= minmz & masses <= maxmz));
    end
end

close(dbconn);