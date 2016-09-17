function [v,d] = eigen2(a,b)

% function [v,d] = eigen2(a,b)
%
% sort eigenvalues and -vectors by eigenvalue size

% Allan Aasbjerg Nielsen
% aa@imm.dtu.dk

[v1,d1] = eig(a,b);
d2 = diag(d1);
[dum,idx] = sort(d2);
v = v1(:,idx);
d = diag(d2(idx));