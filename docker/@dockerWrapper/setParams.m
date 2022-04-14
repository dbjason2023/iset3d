function  setParams(options)
% setParams: Set remote docker rendering options
%
% Syntax
%    dockerWrapper.setParams(key/val pairs)
%
% Brief synopsis
%   Set docker parameters for remote rendering
%
% Inputs
%   N/A
%
% Key/Val pairs
%
% Return
%   N/A
%
% Description
% Underlying mechanism is setpref(), getpref() so changes are persistent
% across Matlab sessions. 
%
%   dockerWrapper.setParams('remoteUser',<remoteUser>);
%   dockerWrapper.setParams('remoteRoot',<remoteRoot>); % where we will put the iset tree
%   dockerWrapper.setParams('localRoot',<localRoot>); % only needed for WSL if not \mnt\c
%
% Other options you can specify:
% If you need to turn-off GPU Rendering set to false
%  dockerWrapper.setParams('gpuRendering',false);
%
% If you are having issues with :latest, you can go back to :stable
% dockerWrapper.setParams('remoteImageTag','stable');
%
% Change which gpu to use on a server
% dockerWrapper.setParams('whichGPU', <#>); % default is 0
%

arguments
    options.whichGPU {mustBeNumeric} = 0;
    options.gpuRendering = '';

    % these relate to remote/server rendering
    % they overlap while we learn the best way to organize them
    options.remoteMachine = ''; % for syncing the data
    options.remoteUser = ''; % use for rsync & ssh/docker

    options.remoteImage = '';
    options.remoteImageTag = '';
    options.remoteRoot = ''; % we need to know where to map on the remote system
    options.localRoot = ''; % for the Windows/wsl case (sigh)
    options.forceLocal = false;

end

if ~isempty(options.forceLocal)
    setpref('docker','forceLocal', options.forceLocal);
end

setpref('docker','whichGPU', options.whichGPU);

if ~isempty(options.gpuRendering)
    setpref('docker','gpuRendering', options.gpuRendering);
end
if ~isempty(options.remoteUser)
    setpref('docker', 'remoteUser', options.remoteUser);
end
if ~isempty(options.remoteImage)
    setpref('docker', 'remoteImage', options.remoteImage);
end
if ~isempty(options.remoteImageTag)
    setpref('docker', 'remoteImageTag', options.remoteImageTag);
end
if ~isempty(options.remoteRoot)
    setpref('docker', 'remoteRoot', options.remoteRoot);
end
if ~isempty(options.localRoot)
    setpref('docker', 'localRoot', options.localRoot);
end

dockerWrapper.reset;
end

