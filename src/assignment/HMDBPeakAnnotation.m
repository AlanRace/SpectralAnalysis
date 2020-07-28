classdef HMDBPeakAnnotation < PeakAnnotation
    properties
        hmdbID;
        status;
    end
    
    methods
        function annotation = HMDBPeakAnnotation(hmdbID, name, adduct, monoisotopicMass, chemicalFormula)
            annotation.hmdbID = hmdbID;
            annotation.name = name;
            annotation.adduct = adduct;
            annotation.monoisotopicMass = monoisotopicMass;
            annotation.chemicalFormula = chemicalFormula;
        end
    end
end