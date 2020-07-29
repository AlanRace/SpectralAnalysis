classdef PeakAnnotation < handle
    properties
        name
        baseMonoisotopicMass
        chemicalFormula
        adduct
    end
    
    methods
        function mass = getMonoisotopicMass(this)
            mass = this.baseMonoisotopicMass + this.adduct.monoisotopicMass;
        end
    end
end