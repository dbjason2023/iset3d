function val = piMaterialGet(material, param, varargin)
% Read a material struct in the recipe
%
% Inputs
%   thisR:  Recipe
%
% Optional key/val pairs
%   idx:    Index of the material to address
%   param:  Parameter of the indexed material to return
%   print:  Print out the list of textures
%
% Returns:
%   val: Depending on the input arguments
%       - Cell array of material structures (idx and param both empty)
%       - One of materials (param empty)
%       - A parameter of one of the materials (idx and param both set)
%
% ZLY, SCIEN, 2020
%
% See also
%

% Examples:
%{
    mat = piMaterialCreate('new material');
    kdType = piMaterialGet(mat, 'kd type');
%}

%% Parse inputs

% check the parameter name and type/val flag
nameTypeVal = strsplit(param, ' ');
pName    = nameTypeVal{1};
if numel(nameTypeVal) > 1
    pTypeVal = nameTypeVal{2};
else
    pTypeVal = '';
end

p = inputParser;
p.addRequired('material', @isstruct);
p.addRequired('param', @ischar);

p.parse(material, param, varargin{:});

%%
val = [];

if isfield(material, pName)
    % If asking name or type, get the param and return.
    if isequal(pName, 'name') || isequal(pName, 'type')
        val = material.(pName);
        return;
    end
    
    % If type and val are both empty, return the parameter struct
    if isempty(pTypeVal)
        val = material.(pName);
    elseif isequal(pTypeVal, 'type')
        val = material.(pName).type;
    elseif isequal(pTypeVal, 'value') || isequal(pTypeVal, 'val')
        val = material.(pName).value;
    end    
else
    warning('Parameter: %s does not exist in material type: %s',...
            param, material.type);
end


%{
%% Return different values depending on inputs

if ~isempty(idx)
    % Just one of the textures
    thisMaterial = thisR.materials.list{idx};
    if ~isempty(param)
        % A parameter of that texture
        val = thisMaterial.(param);
    else
        val = thisMaterial;
    end
else
    % Return all textures
    if ~isfield(thisR.materials, 'list')
        val = {};
    else
        val = thisR.materials.list;
    end
end

%% Print all materials

if p.Results.print
   
end
%}
end