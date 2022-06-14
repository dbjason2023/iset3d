function  setPrefs(varargin)
% Set the Matlab prefs (getpref('docker')) variables.
%
% Syntax
%    dockerWrapper.setPrefs(key/val pairs)
%
% Brief synopsis
%  Interface to setpref(), getpref().  The Matlab prefs are persistent
%    across Matlab sessions.  When these parameters are changed,
%    dockerWrapper.reset() is called.
%
% Inputs
%   N/A
%
% Key/Val pairs - hopefully meaning is clear (see examples below)
%
%   verbosity
%   whichGPU
%   gpuRendering
%
%   remoteMachine
%   remoteUser
%   remoteRoot
%   remoteImage
%   remoteImageTag
%
%   localRoot
%   localRender
%   localVolumePath
%
% Return
%   N/A
%
% Examples:
%
%   dockerWrapper.setParams('remoteUser',<remoteUser>);
%   dockerWrapper.setParams('remoteRoot',<remoteRoot>); % where we will put the iset tree
%
%  Used on Windows
%   dockerWrapper.setParams('localRoot',<localRoot>); % only needed for WSL if not \mnt\c
%
% Other p.Results:
%

p = inputParser;
p.addParameter('verbosity','',@islogical);
p.addParameter('whichGPU','',@isnumeric);
p.addParameter('gpuRendering','',@islogical);
p.addParameter('gpuRender','',@islogical);
p.addParameter('remoteMachine','',@ischar);
p.addParameter('remoteUser','',@ischar);
p.addParameter('remoteImage','',@ischar);
p.addParameter('remoteImageTag','',@ischar);
p.addParameter('remoteRoot','',@ischar);
p.addParameter('remoteRender','',@islogical);  % Inverted form of localRender

p.addParameter('localRoot','',@ischar);
p.addParameter('localRender','',@islogical);
p.addParameter('localImageTag','',@ischar);
p.addParameter('localVolumePath','',@ischar);
p.parse(varargin{:});

% % The options slots 
% arguments
%     options.verbosity {mustBeNumeric} = [];
%     options.whichGPU {mustBeNumeric} = [];
%     options.gpuRendering = [];
% 
%     % Remote options
%     % these relate to remote/server rendering
%     % they overlap while we learn the best way to organize them
%     options.remoteMachine = ''; % for syncing the data
%     options.remoteUser = ''; % use for rsync & ssh/docker
% 
%     options.remoteImage = '';
%     options.remoteImageTag = '';
%     options.remoteRoot = ''; % we need to know where to map on the remote system
% 
%     % When we run on the user's computer
%     options.localRoot = ''; % for the Windows/wsl case (sigh)
%     options.localRender   = '';
%     options.localImageTag = '';
%     options.localVolumePath = '';
% end

% Interface
if ~isempty(p.Results.verbosity)
    setpref('docker','verbosity', p.Results.verbosity);
end

% GPU related parameters
if ~isempty(p.Results.whichGPU)
    setpref('docker','whichGPU', p.Results.whichGPU);
end
if ~isempty(p.Results.gpuRendering)
    setpref('docker','gpuRendering', p.Results.gpuRendering);
end

% An alias for gpuRendering, because I often forget which string is
% right.
if ~isempty(p.Results.gpuRender)
    setpref('docker','gpuRendering', p.Results.gpuRender);
end

% Remote rendering parameters
if ~isempty(p.Results.remoteUser)
    setpref('docker', 'remoteUser', p.Results.remoteUser);
end
if ~isempty(p.Results.remoteImage)
    setpref('docker', 'remoteImage', p.Results.remoteImage);
end
if ~isempty(p.Results.remoteImageTag)
    setpref('docker', 'remoteImageTag', p.Results.remoteImageTag);
end
if ~isempty(p.Results.remoteRoot)
    setpref('docker', 'remoteRoot', p.Results.remoteRoot);
end

% Local rendering parameters
if ~isempty(p.Results.localRoot)
    % We think this is the local root on either the remote machine or
    % the local machine.  It is local w.r.t. the container.
    setpref('docker', 'localRoot', p.Results.localRoot);
end

% Some people want to set remote render true/false.  So we flip the
% sign for them and call the localRender set.
if ~isempty(p.Results.remoteRender)
    dockerWrapper.setPrefs('localRender',~p.Results.remoteRender);
end
if ~isempty(p.Results.localRender)
    % Run the container on the user's local machine.  This is a
    % logical variables, default's to false.
    setpref('docker', 'localRender', p.Results.localRender);
    if p.Results.localRender
        if getpref('docker','gpuRendering')
            disp('Set for local GPU rendering.')
        else
            disp('Set for local CPU rendering.');
        end
    end
end
if ~isempty(p.Results.localImageTag)
    % By default this will be 'latest'
    setpref('docker', 'localImageTag', p.Results.localImageTag);
end
if ~isempty(p.Results.localVolumePath)
    % By default this will be 'latest'
    setpref('docker', 'localImageTag', p.Results.localVolumePath);
end
% If you change these parameters, we need to reset the dockerWrapper.
% Not sure I understand this (BW).
dockerWrapper.reset;

end

