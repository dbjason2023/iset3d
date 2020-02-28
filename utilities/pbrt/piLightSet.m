function thisR = piLightSet(thisR, lightIdx, param, val, varargin)
% Set a light source struct parameter
%
%
% Inputs
%   thisR
%   lightIdx
%   param
%   val
%
% Optional key/val pairs
%   print:   Printout the list of lights
%
% Returns
%   lightSource:  Modified light source
%
% Zheng,BW, SCIEN, 2020
%
% TODO
%   Build a switch statement for the param value, checking it is a
%   legitimate part of the light source structure
%
% See also
%   piLightDelete, piLightAdd, piLightGet
%

% Examples
%{
    thisR = piRecipeDefault;
    thisR = piLightDelete(thisR, 'all');
    thisR = piLightAdd(thisR, 'type', 'spot', 'cameracoordinate', true);
    
    piLightGet(thisR);
    lightNumber = 1;
    [~, lightNumber] = piLightSet(thisR, lightNumber, 'light spectrum', 'D50')
    [~, lightNumber] = piLightSet(thisR, lightNumber, 'coneAngle', 5);

    thisR = piLightAdd(thisR, 'type', 'spot',...
                        'light spectrum', 'blueLEDFlood',...
                        'spectrumscale', 10000,...
                        'cameracoordinate', true);
    lightNumber = 2;
    thisR = piLightSet(thisR, lightNumber, 'coneAngle', 20);
    piWrite(thisR, 'overwritematerials', true);

    % Render
    [scene, result] = piRender(thisR, 'render type','radiance');
    sceneWindow(scene);
%}

%{
    % Apply translation and rotation on light
    thisR = piRecipeDefault;
    thisR = piLightDelete(thisR, 'all');
    thisR = piLightAdd(thisR, 'type', 'spot', 'cameracoordinate', true);
    
    piLightGet(thisR);
    lightNumber = 1;
    piLightSet(thisR, lightNumber, 'spectrum', 'D50')
    piLightSet(thisR, lightNumber, 'coneAngle', 10);
    [~, lightNumber] = piLightRotate(thisR, lightNumber, 'x rot', 7);
    [~, lightNumber] = piLightTranslate(thisR, lightNumber, 'x shift', 1.2);

    thisR = piLightAdd(thisR, 'type', 'spot',...
                        'light spectrum', 'blueLEDFlood',...
                        'spectrumscale', 10000,...
                        'cameracoordinate', true);
    lightNumber = 2;
    thisR = piLightSet(thisR, lightNumber, 'coneAngle', 20);
    piWrite(thisR, 'overwritematerials', true);

    % Render
    [scene, result] = piRender(thisR, 'render type','radiance');
    sceneWindow(scene);
%}

%% Parse inputs
param = ieParamFormat(param);
varargin = ieParamFormat(varargin);

p  = inputParser;
p.addRequired('recipe', @(x)(isa(x, 'recipe')));
p.addRequired('lightIdx');
p.addRequired('param', @ischar);
p.addRequired('val');

p.parse(thisR, lightIdx, param, val, varargin{:});
idx = p.Results.lightIdx;

%%
% lightSources = thisR.lights;

%{
if isnumeric(lightIdx)
    % Record the light
    thisLight = lightSources{lightIdx};
    idx = lightIdx;
elseif ischar(lightIdx)
    lightSourcesStruct = cell2mat(lightSources);
    find(lightSourcesStruct.name == lightIdx);
else
    error('Unknown lightName. It must be an integer or a char.');
end
%}

% if strcmp(param, 'from')
%     param = 'position';
% elseif strcmp(param, 'to')
%     % As direction is easier to consider compare directly change the "to"
%     % vector, light only contains direction, so we change "to" if user
%     % insists providing "to" values.
%     param = 'direction';
%     if ~isfield(thisLight, 'position')
%         position = 0;
%     end
%     val = val - position;
% end
% 
% thisLight.(param) = val;
thisR.lights{idx}.(param) = val;

%%
