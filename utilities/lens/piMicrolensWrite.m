function fname = piMicrolensWrite(fname,cLens)
% Write out a JSON file with a combined microlens and main lens
%
% Synopsis
%   fname = piMicrolensWrite(fname,cLens)
%
% Inputs
%   fname - file name of the output json file
%   cLens - Matlab struct in a compatible JSON format 
%
% Optional key/val
%   N/A
%
% Output
%   fname - full path to the output file name
%
% Description
%   This is designed to replace the old lenstool code in the PBRT
%   docker container. The format of the JSON file is this:
%
% cLens = jsonread('dgauss.22deg.3.0mm+microlens.json');
% cLens = 
%
%  struct with fields:
%
%    description: ' Description: multi element lens Focal length (mm) '
%      microlens: [1×1 struct]
%           name: 'dgauss.22deg.3.0mm w/ microlens microlens'
%       surfaces: [11×1 struct]
%           type: 'multi element lens'
%
% The imaging lens information is stored in the usual way within the
% 'surfaces' slot.  The microlens slot is quite large.  It contains
% these several slots.  
% 
%   dimensions - the number of microlenses.
%   surfaces - the data for the microlens surfaces
%   offsets  - there is 2-vector offset for every one of the
%              microlenses
%
%  cLens.microlens
%
% ans = 
%
%  struct with fields:
%
%    dimensions: [2×1 double]
%       offsets: [262144×2 double]
%      surfaces: [3×1 struct]
%
% See also
%   piCameraInsertMicrolens, lensCombine


if exist(fname,'file')
end

jsonwrite(fname,cLens);

end
