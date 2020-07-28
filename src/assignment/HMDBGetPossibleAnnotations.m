function possibleAssignments = HMDBGetPossibleAnnotations(peak, adducts, ppmTolerance)

ppmTolerance = ppmTolerance/1e6;

dbconn = sqlite([getDatabasesPath() filesep 'hmdb.db']);

sqlquery = 'SELECT accession, name, chemicalFormula, monoisotopicMolecularWeight FROM metabolites where monoisotopicMolecularWeight >= %f and monoisotopicMolecularWeight <= %f';

possibleAssignments = [];
numAssignments = 0;

for adductID = 1:length(adducts)
    adduct = adducts(adductID);
    
    centroid = peak.centroid - adduct.monoisotopicMass;
    deltamz = centroid * ppmTolerance;
    
    minmz = centroid - deltamz;
    maxmz = centroid + deltamz;
    
    query = sprintf(sqlquery, minmz, maxmz);
    
    results = fetch(dbconn, query);
    
    for i = 1:size(results, 1)
        annotation = HMDBPeakAnnotation(results{i, 1}, results{i, 2}, adduct, results{i, 3}, results{i, 4});
    
        if numAssignments == 0
            possibleAssignments = annotation;
        else
            possibleAssignments(numAssignments+1) = annotation;
        end
        
        numAssignments = numAssignments + 1;
    end
end

close(dbconn);