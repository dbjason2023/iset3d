function [thisR,skymapInfo] = piSkymapAdd(thisR,skyName)
% Choose a skymap, or random skybox, write this line to thisR.world.
%
% Synopsis
%   [thisR,skymapInfo] = piSkymapAdd(thisR,skyName)
%
% Brief Description
%   A skymap (either local or on Flywheel) is added to the recipe
%
% Inputs
%   thisR - A rendering recipe
%   skymap options:
%        'morning'
%        'day'
%        'dusk'
%        'sunset'
%        'night'
%        'cloudy'
%        'sunny_park'
%        'grass'
%        'city'
%        'cityscape'
%        'park'
%        'random'- pick a random skymap from skymaps folder
%
% Returns
%   none, but thisR.world is modified.
%
% Example: 
%    piAddSkymap(thisR,'day');
%
% Zhenyi,2018
%
% See also
%    

%% Choose the type of skymap

% Not yet using sunlights, but we will
sunlights = sprintf('# LightSource "distant" "point from" [ -30 100  100 ] "blackbody L" [6500 1.5]');

% 
skyName = lower(skyName);
if isequal(skyName,'random')
    index = randi(3,1);
    skynamelist = {'morning','noon','sunset'};
    skyName = skynamelist{index};
end

thisR.metadata.daytime = skyName;
switch skyName
    case 'morning'
        skyname = sprintf('morning_%03d.exr',randi(4,1));       
    case 'noon'
        skyname = sprintf('noon_%03d.exr',1); % favorate one, tmp
%         skyname = sprintf('noon_%03d.exr',randi(10,1));
    case 'sunset'
        skyname = sprintf('sunset_%03d.exr',randi(4,1)); 
    case 'cloudy'
%         skyname = sprintf('cloudy_%03d.exr',randi(2,1));
        skyname = sprintf('cloudy_%03d.exr',2);
end
skylights = sprintf('LightSource "infinite" "string mapname" "%s"',skyname);

%% Find the location where we will add the skymap attribute

% We want the skymap to be included before we include the materials
index_m = find(piContains(thisR.world,'_materials.pbrt'));

% skyview = randi(360,1);
skyview = randi(45,1)+45;% tmp
world(1,:) = thisR.world(1);
world(2,:) = cellstr(sprintf('AttributeBegin'));
world(3,:) = cellstr(sprintf('Rotate %d 0 1 0',skyview));
world(4,:) = cellstr(sprintf('Rotate -90 1 0 0'));
world(5,:) = cellstr(sprintf('Scale 1 1 1'));
world(6,:) = cellstr(skylights);
world(7,:) = cellstr(sprintf('AttributeEnd'));
jj=1;% skip materials and lightsource which are exported from C4D.
for ii=index_m:length(thisR.world)
    world(jj+7,:)=thisR.world(ii);
    jj=jj+1;
end
thisR.world = world;

%% Get the skymap information from Flywheel

% Open up the flywheel
st = scitran('stanfordlabs');
thisVersion = stFlywheelSDK('installed version');
if thisVersion <= 413
    error('Please update your Flywheel Add-On Toolbox.');
end

% Prior to 4.1.3, lookup did not exist
try
    acquisition = st.fw.lookup('wandell/Graphics assets/data/skymaps');
    dataId      = acquisition.id;
catch
    % We had trouble making lookup work with some Add-On toolbox
    % versions.  So we have this
    warning('Using piSkymapAdd search, not lookup')
    acquisition = st.search('acquisitions',...
        'project label exact','Graphics assets',...
        'session label exact','data',...
        'acquisition label exact','skymaps');
    dataId = st.objectParse(acquisition{1});
end

% What we wanted!
skymapInfo = [dataId,' ',skyname];

end
