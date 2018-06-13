% Returns empty variable if there is no fast preprocessing workflow
% available
function fastPreprocessingWorkflow = generateFastPreprocessingWorkflow(workflow)

if(~canUseJSpectralAnalysis())
    fastPreprocessingWorkflow = [];
    return;
end

fastPreprocessingWorkflow = com.alanmrace.JSpectralAnalysis.PreprocessingWorkflow();

numFastMethods = 0;

if(isa(workflow, 'PreprocessingWorkflow'))
    workflow = workflow.workflow;
end

for i = 1:length(workflow)
    if(isa(workflow{i}, 'QSTARZeroFilling'))
        params = workflow{i}.Parameters;
        
        fastPreprocessingWorkflow.addMethod(com.alanmrace.JSpectralAnalysis.zerofilling.QSTARZeroFilling(params(1).value, params(2).value, params(3).value));
        numFastMethods = numFastMethods + 1;
    elseif(isa(workflow{i}, 'SynaptZeroFilling'))
        fastPreprocessingWorkflow.addMethod(com.alanmrace.JSpectralAnalysis.zerofilling.FixedmzListReplaceZeros(workflow{i}.mzsFull));
        numFastMethods = numFastMethods + 1;
    elseif(isa(workflow{i}, 'RebinZeroFilling'))
        params = workflow{i}.Parameters;
        
        fastPreprocessingWorkflow.addMethod(com.alanmrace.JSpectralAnalysis.zerofilling.RebinZeroFilling(params(1).value, params(2).value, params(3).value));
        numFastMethods = numFastMethods + 1;
    elseif(isa(workflow{i}, 'RebinPPMZeroFilling'))
        params = workflow{i}.Parameters;
        
        fastPreprocessingWorkflow.addMethod(com.alanmrace.JSpectralAnalysis.zerofilling.PPMRebinZeroFilling(params(1).value, params(2).value, params(3).value));
        numFastMethods = numFastMethods + 1;    
    elseif(isa(workflow{i}, 'InterpolationRebinZeroFilling'))
        params = workflow{i}.Parameters;
        
        fastPreprocessingWorkflow.addMethod(com.alanmrace.JSpectralAnalysis.zerofilling.InterpolationRebinZeroFilling(params(1).value, params(2).value, params(3).value));
        numFastMethods = numFastMethods + 1;
    elseif(isa(workflow{i}, 'InterpolationPPMRebinZeroFilling'))
        params = workflow{i}.Parameters;
        
        fastPreprocessingWorkflow.addMethod(com.alanmrace.JSpectralAnalysis.zerofilling.InterpolationPPMRebinZeroFilling(params(1).value, params(2).value, params(3).value));
        numFastMethods = numFastMethods + 1;    
    elseif(isa(workflow{i}, 'GaussianSmoothing'))
        params = workflow{i}.Parameters;
        
        fastPreprocessingWorkflow.addMethod(com.alanmrace.JSpectralAnalysis.smoothing.GaussianSmoothing(params(1).value, params(2).value));
        numFastMethods = numFastMethods + 1;
    elseif(isa(workflow{i}, 'SavitzkyGolaySmoothing'))
        params = workflow{i}.Parameters;
        
        fastPreprocessingWorkflow.addMethod(com.alanmrace.JSpectralAnalysis.smoothing.SavitzkyGolaySmoothing(params(1).value, params(2).value));
        numFastMethods = numFastMethods + 1;
    elseif(isa(workflow{i}, 'TotalIntensitySpectralNormalisation'))
        fastPreprocessingWorkflow.addMethod(com.alanmrace.JSpectralAnalysis.normalisation.TICNormalisation());
        numFastMethods = numFastMethods + 1;
    elseif(isa(workflow{i}, 'RemoveNegativesBaselineCorrection'))
        fastPreprocessingWorkflow.addMethod(com.alanmrace.JSpectralAnalysis.baselinecorrection.RemoveNegativesBaselineCorrection());
        numFastMethods = numFastMethods + 1;
    end
end

if(numFastMethods ~= length(workflow))
    fastPreprocessingWorkflow = [];
end