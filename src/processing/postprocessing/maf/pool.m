function [sigmad,sigmadh,sigmadv] = pool(in,r,c,p) 

% [sigmad,sigmadh,sigmadv] = pool(in,r,c,p) 
%
% r - number of rows
% c - number of columns
% p - number of variables

% Allan Aasbjerg Nielsen
% aa@imm.dtu.dk

r1 = r-1;
c1 = c-1;
for i = 1:p
    Z = in(:,i);
    A = reshape(Z,c,r)';
    Dh = A(1:r1,1:c1) - A(1:r1,2:c);
    H(:,i) = reshape(Dh,r1*c1,1);
    %imagesc(Dh);
    %colormap(gray);
    %axis image;
    %pause
    Dv = A(1:r1,1:c1) - A(2:r,1:c1);
    V(:,i) = reshape(Dv,r1*c1,1);
    %imagesc(Dv);
    %colormap(gray);
    %axis image;
    %pause
end

sigmadh = cov(H);
sigmadv = cov(V);

% simple pool
sigmad = 0.5*(sigmadh+sigmadv);