function version = saversion()

version = '1.4.0';

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

fopen([saFolder filesep 'version.txt'], 'r');    
version = char(fread(fid, Inf, 'char'))';
fclose(fid);