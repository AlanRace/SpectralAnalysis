function [mads,rho,v1,v2,s11,s22,s12,prob,chi2] = mad(fname1,fname2, ...
    nrows,ncols,nvar1,nvar2,varargin)

% [mads,rho,v1,v2,s11,s22,s12] = mad(fname1,fname2, ...
%   nrows,ncols,nvar1,nvar2,varargin)
%
% MAD - multivariate alteration detection
%
% Input
% fname1 - file name of multivariate band sequential byte, float32 or int16 input image
%           number one
% fname2 - file name of multivariate band sequential byte, float32 or int16 input image
%           number two
% nrows  - number of rows in input image number one
% ncols  - number of columns in input image number one
% nvars1 - number of variables or bands or channels in input image number one
% nvars2 - number of variables or bands or channels in input image number two
% fnameo - outout file name, BSQ float32 image (optional)
% 
% Output
% the MAD variates (mads),
% the canonical correlations (rho),
% the eigenvectors (v1 and v2) normed to give CVs unit variance,
% the relevant (variance-)covariance matrices, and
% if desired, the probability of no-change and the approximate chi-squared quantity. 

% Output array mads consists of transposed images must be viewed with e.g.
%       imshow(reshape(mads(:,:,1),ncols,nrows)',[-3 3])
%
% If disk output is requested a primitive .hdr file for the output file is written;
% (a  full ENVI or another header file must be constructed manually).

% (c) Copyright 2005
% Allan Aasbjerg Nielsen
% aa@imm.dtu.dk, www.imm.dtu.dk/~aa
% 21 Feb 2005

if nargin<6, error('Not enough input arguments.'); end
if nargin>7, error('Too many input arguments.'); end
if ~ischar(fname1), error('fname1 should be a char string'); end
if ~ischar(fname2), error('fname2 should be a char string'); end
if nargin==7
    fnameo = varargin{1};
    if ~ischar(fnameo), error('fnameo should be a char string'); end
end
if nvar2>nvar1
    error('input with highest number of variables must be first set');
end

% open as byte (uint8) image, if unsuccesful open as float32 or int16
fid1 = fopen(fname1,'r');
if fid1==-1, error(strcat(fname1,' not found')); end
[x,count1] = fread(fid1,'uint8');
fclose(fid1);
if count1~=(nrows*ncols*nvar1)
    warning('data in fname1 do not match nrows, ncols, nvars for uint8, try float32');
    fid1 = fopen(fname1,'r');
    if fid1==-1, error(strcat(fname1,' not found')); end
    [x,count1] = fread(fid1,'float32');
    fclose(fid1);
    if count1~=(nrows*ncols*nvar1)
        warning('data in fname1 do not match nrows, ncols, nvars for float32, try int16');
        fid1 = fopen(fname1,'r');
        if fid1==-1, error(strcat(fname1,' not found')); end
        [x,count1] = fread(fid1,'int16');
        fclose(fid1);
        if count1~=(nrows*ncols*nvar1)
            error('data in fname1 do not match nrows, ncols, nvars for int16 either');
        end
    end
end

fid2 = fopen(fname2,'r');
if fid2==-1, error(strcat(fname2,' not found')); end
[y,count2] = fread(fid2,'uint8');
fclose(fid2);
if count2~=(nrows*ncols*nvar2)
    warning('data in fname2 do not match nrows, ncols, nvars for uint8, try float32');
    fid2 = fopen(fname2,'r');
    if fid2==-1, error(strcat(fname2,' not found')); end
    [y,count2] = fread(fid2,'float32');
    fclose(fid2);
    if count2~=(nrows*ncols*nvar2)
        warning('data in fname2 do not match nrows, ncols, nvars for float32, try int16');
        fid2 = fopen(fname2,'r');
        if fid2==-1, error(strcat(fname2,' not found')); end
        [y,count2] = fread(fid2,'int16');
        fclose(fid2);
        if count2~=(nrows*ncols*nvar2)
            error('data in fname2 do not match nrows, ncols, nvars for int16 either');
        end
    end
end

if (count1/nvar1)~=(count2/nvar2)
    error('data in fname1 and fname2 do not match');
end

N = nrows*ncols;
X = reshape(x,N,nvar1);
Y = reshape(y,N,nvar2);

covxy = cov([X Y]);
s11 = covxy(1:nvar1,1:nvar1);
s22 = covxy(nvar1+1:end,nvar1+1:end);
s12 = covxy(1:nvar1,nvar1+1:end);
s21 = s12';

if nvar2==nvar1 % solve smallest eigenproblem

%[v1,d1] = eigen2(s12*(s22^(-1))*s21,s11);
invs22 = inv(s22);
[v1,d1] = eigen2(s12*invs22*s21,s11);
rho = diag(sqrt(d1))'; % lowest canonical correlation first

% scale v1 to give CVs with unit variance
aux1 = v1'*s11*v1; % dispersion of CVs
aux2 = 1./sqrt(diag(aux1));
aux3 = repmat(aux2',nvar1,1);
v1 = v1.*aux3; % now dispersion is unit matrix
%v1'*s11*v1

% sum of correlations between X and CV(X) positive
invstderr = diag(1./std(X));
%invstderrcv = diag(1./sqrt(diag(v1'*s11*v1)));
%sgn = diag(sign(sum(invstderr*s11*v1*invstderrcv)));
sgn = diag(sign(sum(invstderr*s11*v1)));
v1 = v1*sgn;
%figure; bar(sum(invstderr*s11*v1))

%%[v2,d2] = eigen2(s21*(s11^(-1))*s12,s22);
%[v2,d2] = eigen2(s21*inv(s11)*s12,s22);
%v2 = v2*diag(sign(diag(v1'*s12*v2)));
v2 = invs22*s21*v1; %./repmat(rho,nvar1,1); % scaling doesn't matter

% scale v2 to give CVs with unit variance
aux1 = v2'*s22*v2; % dispersion of CVs
aux2 = 1./sqrt(diag(aux1));
aux3 = repmat(aux2',nvar2,1);
v2 = v2.*aux3; % now dispersion is unit matrix
%v2'*s22*v2
%invstderr = diag(1./std(Y)); figure; bar(sum(invstderr*s22*v2))

mads = (X-repmat(mean(X),N,1))*v1 - (Y-repmat(mean(Y),N,1))*v2;

else % nvar1>nvar2: solve big, joint eigenproblem
    
Sleft  = [zeros(nvar1,nvar1) s12; s21 zeros(nvar2,nvar2)];
Sright = [s11 zeros(nvar1,nvar2); zeros(nvar2,nvar1) s22];
[v,d] = eigen2(Sleft,Sright);
v = fliplr(v);
v1 = v(1:nvar1,1:nvar1);
v2 = v(nvar1+1:end,1:nvar2);   
rho = fliplr(diag(d)'); % highest canonical correlation first
rho(:,nvar2+1:end) = 0;
rho = rho(:,1:nvar1);
    
% scale v1 to give CVs with unit variance
aux1 = v1'*s11*v1; % dispersion of CVs
aux2 = 1./sqrt(diag(aux1));
aux3 = repmat(aux2',nvar1,1);
v1 = v1.*aux3; % now dispersion is unit matrix
%v1'*s11*v1

% sum of correlations between X and CV(X) positive
invstderr = diag(1./std(X));
%invstderrcv = diag(1./sqrt(diag(v1'*s11*v1)));
%sgn = diag(sign(sum(invstderr*s11*v1*invstderrcv)));
sgn = diag(sign(sum(invstderr*s11*v1)));
v1 = v1*sgn;
%figure; bar(sum(invstderr*s11*v1))

% scale v2 to give CVs with unit variance
aux1 = v2'*s22*v2; % dispersion of CVs
aux2 = 1./sqrt(diag(aux1));
aux3 = repmat(aux2',nvar2,1);
v2 = v2.*aux3; % now dispersion is unit matrix
%v2'*s22*v2

% correlations between CV(X) and CV(Y) positive
sgn = diag(sign(diag(v1'*s12*v2)'));
v2 = v2*sgn;
%invstderr = diag(1./std(Y)); figure; bar(sum(invstderr*s22*v2))
%v1'*s12*v2

mads = (X-repmat(mean(X),N,1))*v1 - ...
    [(Y-repmat(mean(Y),N,1))*v2 zeros(N,nvar1-nvar2)];
mads = fliplr(mads);
mads(:,1:nvar1-nvar2) = sqrt(2)*mads(:,1:nvar1-nvar2); % variance = 2
rho = fliplr(rho);

end

%cov(mads)

if nargout>7
    chi2 = sum((mads./repmat(sqrt(2*(1-rho)),N,1)).^2,2); % should be no-change std only
    %chi2 = sum((mads./repmat(std(mads),N,1)).^2,2); % should be no-change std only
    %prob = tanh(1./chi2); % sensible measure but ad hoc
    prob = 1-gammainc(0.5*chi2,0.5*nvar1); % probability of finding larger chi2
end

% output array mads consists of transposed images
mads = reshape(mads,ncols,nrows,nvar1);
if nargin==7
    fid = fopen(fnameo,'w');
    fwrite(fid,mads,'float32');
    fclose(fid);
    fid = fopen(strcat(fnameo,'.hdr'),'w'); % write primitive header file
    fprintf(fid,'samples = %d\n',ncols);
    fprintf(fid,'lines   = %d\n',nrows);
    fprintf(fid,'bands   = %d\n',nvar1);
    fprintf(fid,'data type = 4\n');
    fprintf(fid,'rho = {\n'); fprintf(fid,' %g',rho); fprintf(fid,'}\n');
    fclose(fid);
end
