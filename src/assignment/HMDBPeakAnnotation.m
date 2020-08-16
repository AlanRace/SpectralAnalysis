classdef HMDBPeakAnnotation < PeakAnnotation
    properties
        hmdbID;
        status;
        smiles;
        
        kingdom;
        superClass;
        class;
        subClass;
        directParent;
    end
    
    methods
        function annotation = HMDBPeakAnnotation(hmdbID, name, adduct, monoisotopicMass, chemicalFormula)
            annotation.hmdbID = hmdbID;
            annotation.name = name;
            annotation.adduct = adduct;
            annotation.baseMonoisotopicMass = monoisotopicMass;
            annotation.chemicalFormula = chemicalFormula;
        end
        
        function setSMILES(this, smiles)
            this.smiles = smiles;
        end
           
        function setTaxinomy(this, kingdom, superClass, class, subClass, directParent)
            this.kingdom = kingdom;
            this.superClass = superClass;
            this.class = class;
            this.subClass = subClass;
            this.directParent = directParent;
        end
    end
end