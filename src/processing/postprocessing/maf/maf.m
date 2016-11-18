function [mafs,ac,v,d,sigmad,sigma] = maf(X, nrows, ncols, nvars, varargin)

% [mafs,ac,v,d,sigmad,sigma] = maf(fname,nrows,ncols,nvars,varargin)
%
% MAF - maximum autocorrelation factor analysis
%
% Input
% fname  - file name of multivariate band sequential byte, float32 or int16 input image
% nrows  - number of rows in input
% ncols  - number of columns in input
% nvars  - number of variables or bands or channels in input
% flag   - 0, 1 or 2 (optional, defaults to 1)
% fnameo - outout file name, BSQ float32 image (optional)
%
% flag = 0 - eigenvectors scaled as from eig
% flag = 1 - MAFs will be standardised to unit variance (default)
% flag = 2 - eigenvectors will be unit vectors
% flag = 3 - noise in model has unit variance
%
% Output
% mafs   - the factors stored in an ncols by nrows by nvars array
%          (each factor is transposed, see below)
% ac     - autocorrelation in each factor
% v      - the eigenvectors or weights to obtain the factors from the
%          original variables
% d      - the eigenvalues
% sigmad - variance-covariance matrix of difference between spatially
%          shifted and original images
% sigma  - variance-covariance matrix of input image
%
% Output array consists of transposed images must be viewed with e.g. 
%       imshow(reshape(mafs(:,:,1),ncols,nrows)',[-3 3])
%
% If disk output is requested a primitive .hdr file for the output file is written;
% (a  full ENVI or another header file must be constructed manually).

% (c) Copyright 2005
% Allan Aasbjerg Nielsen
% aa@imm.dtu.dk, www.imm.dtu.dk/~aa
% 25 Feb 2005

% Modified by Alan Race 27/07/2015

% if nargin<4, error('Not enough input arguments.'); end
% if nargin>6, error('Too many input arguments.'); end
% if ~ischar(fname), error('fname should be a char string'); end
% if nargin==6
%     fnameo = varargin{end};
%     if ~ischar(fnameo), error('fnameo should be a char string'); end
% end

flag = 1;
if nargin>4
    flag = varargin{1};
end

% % open as byte (uint8) image, if unsuccesful open as float32 or int16
% fid = fopen(fname,'r');
% if fid==-1, error(strcat(fname,' not found')); end
% [x,count] = fread(fid,'uint8');
% fclose(fid);
% if count~=(nrows*ncols*nvars)
%     warning('data in fname do not match nrows, ncols, nvars for uint8, try float32');
%     fid = fopen(fname,'r');
%     if fid==-1, error(strcat(fname,' not found')); end
%     [x,count] = fread(fid,'float32');
%     fclose(fid);
%     if count~=(nrows*ncols*nvars)
%         warning('data in fname do not match nrows, ncols, nvars for float32, try int16');
%         fid = fopen(fname,'r');
%         if fid==-1, error(strcat(fname,' not found')); end
%         [x,count] = fread(fid,'int16');
%         fclose(fid);
%         if count~=(nrows*ncols*nvars)
%             error('data in fname do not match nrows, ncols, nvars for int16 either');
%         end
%     end
% end
% 
% X = reshape(x,nrows*ncols,nvars);
sigma = cov(X);
sigmad = pool(X, nrows, ncols,nvars);

[v,d] = eigen2(sigmad,sigma);
d=diag(d)';
ac = 1-0.5*d; % autocorrelation

% sum of correlations between X and MAFs positive
invstderr = diag(1./std(X));
invstderrmaf = diag(1./sqrt(diag(v'*sigma*v)));
sgn = diag(sign(sum(invstderr*sigma*v*invstderrmaf)));
v = v*sgn;

N = nrows*ncols;
X = X-repmat(mean(X),N,1);
if flag==1 % unit variance
    % scale v to give MAFs with unit variance
    aux1 = v'*sigma*v; % dispersion of MAFs
    aux2 = 1./sqrt(diag(aux1));
    aux3 = repmat(aux2',nvars,1);
    v = v.*aux3; % now dispersion is unit matrix
    %v'*sigma*v
elseif flag==2 % v unit vector
    aux1 = v'*v;
    aux2 = 1./sqrt(diag(aux1));
    aux3 = repmat(aux2',nvars,1);
    v = v.*aux3; % now v contains unit vectors in columns
    %v'*v
elseif flag==3 % noise part has unit variance (SMAF)
    aux1 = 0.5*v'*sigmad*v; % sigma_n = sigma_d/2
    aux2 = 1./sqrt(diag(aux1));
    aux3 = repmat(aux2',nvars,1);
    v = v.*aux3; % now noise dispersion is unit matrix
    %0.5*v'*sigmad*v
end
mafs = X*v;
%cov(mafs)

% output array mafs consists of transposed images
% mafs = reshape(mafs,ncols,nrows,nvars);
% if nargin==6
%     fid = fopen(fnameo,'w');
%     fwrite(fid,mafs,'float32');
%     fclose(fid);
%     fid = fopen(strcat(fnameo,'.hdr'),'w'); % write primitive header file
%     fprintf(fid,'samples = %d\n',ncols);
%     fprintf(fid,'lines   = %d\n',nrows);
%     fprintf(fid,'bands   = %d\n',nvars);
%     fprintf(fid,'data type = 4\n');
%     fclose(fid);
% end
