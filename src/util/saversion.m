function version = saversion(includeCommit)

if nargin == 0
    includeCommit = true;
end
    
version = '1.4.0';

if(isdeployed() || ~includeCommit)
    return
end

curdir = cd();

saFolder = getSpectralAnalysisFolder();

cd(saFolder)

[success, commit] = system('git rev-parse --short HEAD');
if success == 0
    commit = strtrim(commit);
    
    fid = fopen([saFolder filesep 'version.txt'], 'w');
    
    fprintf(fid, "%s-%s", version, commit);
    fclose(fid);
end

cd(curdir);

fid = fopen([saFolder filesep 'version.txt'], 'r');
if fid >= 0
    version = fread(fid, Inf, '*char')';
    fclose(fid);
end