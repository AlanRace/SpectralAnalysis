classdef Adduct < handle

    properties
        description;
        chemicalFormula;
        
        monoisotopicMass;
    end
    
    methods
        function adduct = Adduct(description, chemicalFormula, monoisotopicMass)
            adduct.description = description;
            adduct.chemicalFormula = chemicalFormula;
            adduct.monoisotopicMass = monoisotopicMass;
        end
    end
end