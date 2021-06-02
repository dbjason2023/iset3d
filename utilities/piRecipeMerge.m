function sceneR = piRecipeMerge(sceneR, objectRs, varargin)
% Add objects information to scene recipe
%
% Synopsis:
%   sceneR = piRecipeMerge(sceneR, objects, varargin)
% 
% Brief description:
%   Add objects information (material, texture, assets) to a scene recipe.
%
% Inputs:
%   sceneR   - scene recipe
%   objectRs  - object recipe/ recipe list
%   
% Returns:
%   sceneR   - scene recipe with added objects.
%
%% Parse input
p = inputParser;
p.addRequired('sceneR', @(x)isequal(class(x),'recipe'));
p.addParameter('material',true);
p.addParameter('texture',true);
p.addParameter('asset',true);

p.parse(sceneR, varargin{:});

sceneR        = p.Results.sceneR;
materialFlag = p.Results.material;
textureFlag  = p.Results.texture;
assetFlag    = p.Results.asset;

%%
if ~iscell(objectRs)
    recipelist{1} = objectRs;
else
    recipelist = objectRs;
end
for ii = 1:length(recipelist)
    thisR = recipelist{ii};
    if assetFlag
        names = thisR.get('assetnames');
        thisOBJsubtree = thisR.get('asset', names{2}, 'subtree');
        sceneR.set('asset', 'root', 'graft', thisOBJsubtree);
        % copy meshes from objects folder to scene folder here
        [sourceDir, ~, ~] = fileparts(thisR.inputFile);
        [dstDir, ~, ~]    = fileparts(sceneR.outputFile);
        
        sourceAssets = fullfile(sourceDir, 'scene/PBRT/pbrt-geometry');
        if exist(sourceAssets, 'dir')&& ~isempty(dir(fullfile(sourceAssets,'*.pbrt')))
            dstAssets = fullfile(dstDir,    'scene/PBRT/pbrt-geometry');
            copyfile(sourceAssets, dstAssets);
        else
            copyfile(sourceDir, dstDir);
        end
    end
    
    if materialFlag
        if ~isempty(sceneR.materials)
            sceneR.materials.list = [sceneR.materials.list; thisR.materials.list];
        else
            sceneR.materials = thisR.materials;
        end
    end
    
    if textureFlag
        if ~isempty(sceneR.textures)
            sceneR.textures.list = [sceneR.textures.list; thisR.textures.list];
        else
            sceneR.textures = thisR.textures;
        end
        [sourceDir, ~, ~]=fileparts(thisR.outputFile);
        [dstDir, ~, ~]=fileparts(sceneR.outputFile);
        sourceTexures = fullfile(sourceDir, 'textures');
        if exist(sourceTexures,'dir')
            copyfile(sourceTexures, dstDir);
        end
    end
end
end

