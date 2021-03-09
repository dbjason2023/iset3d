% t_material_wavelength - Control wavelength samples
%
% The purpose of this tutorial is to explore the properties of 4 commonly 
% used materials: matte, glass, plastic, and uber. It uses asset functions 
% to set up a scene in which multiple materials and properties can be
% viewed simultaneously. Lastly, this tutorial demonstrated how spectral
% properties of materials can be changed in three different ways:
% 1) RGB values
% 2) Data from a reflectance file
% 3) Making a reflectance array
%
% See also
%   t_materials.m, tls_materials.mlx, t_assets, t_piIntro*,
%   piMaterialCreate.m
%
%% Initialize
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Create recipe

thisR = piRecipeDefault('scene name', 'sphere');
thisR.set('light', 'delete', 'all');

% Distant Light
distLight = piLightCreate('new dist',...
                           'type', 'distant', ...
                           'spd', [1 1 1],...
                           'specscale float', 10,...
                           'cameracoordinate', true);
thisR.set('light', 'add', distLight);                       

% Environmental Light
% An environmental light starts from an image, in this case pngExample.png
% The image is then mapped on the inside surface of a sphere. So if you
% were standing inside this sphere, you would see a stretched out version
% of the image all around you. Every point in this space is a pixel, so we
% can construct a scene by tracing the light from the image map to every
% pixel. Then when an object is placed inside of the image map, pbrt knows
% how the light from the image map affects the object.
fileName = 'pngExample.png';
exampleEnvLight = piLightCreate('field light','type', 'infinite',...
    'mapname', fileName);
exampleEnvLight = piLightSet(exampleEnvLight, 'rotation val', {[0 0 1 0], [-90 1 0 0]});
thisR.set('lights', 'add', exampleEnvLight); 
thisR.get('lights print');

% A low resolution rendering for speed
thisR.set('film resolution',[200 150]);
thisR.set('rays per pixel',48);
thisR.set('fov',60);
thisR.set('nbounces',5); 

piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance');
scene = sceneSet(scene, 'name', 'reference scene');
sceneWindow(scene);
sceneSet(scene, 'render flag', 'rgb');

%% Change Matte properties
% The material type 'matte' has two main properties: the diffuse
% reflectivity (kd) and the sigma parameter (sigma) of the Oren-Nayar model

% We'll start by getting the current the kd value
matte_kd_orig = thisR.get('material', 'white', 'kd value');

% Change value of kd to reflect a green color using RGB values
thisR.set('material', 'white', 'kd value', [0 0.4 0]);

% Set value of signma to 0, surface will have pure Lambertian reflection
thisR.set('material', 'white', 'sigma value', 0);

piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance', 'meanluminance', -1);
scene = sceneSet(scene, 'name', 'Matte: kd = green, sigma=0');
sceneWindow(scene);

% Get the radiance of an inner and outer section
% Center section
% [~,rect_1] = ieROISelect(scene);
% roi_1 = uint64(rect_1.Position);
roi_1 = [94,71,14,13];
roiMean_1 = sceneGet(scene, 'roimeanenergy', roi_1);

% Fringe (outer) section
% [~, rect_2] = ieROISelect(scene);
% roi_2 = uint64(rect_2.Position);
roi_2 = [50,74,6,10];
roiMean_2 = sceneGet(scene, 'roimeanenergy', roi_2);

ieNewGraphWin;
hold on;
plot(wave, roiMean_1); 
plot(wave, roiMean_2);
grid on;
title('Matte - Sigma = 0');
legend('Center', 'Fringe');
hold off;

% Set value of signma to 100, surface will have pure Lambertian reflection
thisR.set('material', 'white', 'sigma value', 100);

piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance', 'meanluminance', -1);
scene = sceneSet(scene, 'name', 'Matte: kd = green, sigma=100');
sceneWindow(scene);

% Plot the inner and outer regions
roiMean_1 = sceneGet(scene, 'roimeanenergy', roi_1);
roiMean_2 = sceneGet(scene, 'roimeanenergy', roi_2);

ieNewGraphWin; hold on; grid on;
plot(wave, roiMean_1); plot(wave, roiMean_2);
title('Matte - Sigma = 100'); ylim([0, 70]);
legend('Center', 'Fringe'); hold off;


%% Set sphere to Uber
% Now we'll explore the properties of uber. 
% Run this section 4 times, each time uncommenting the next block of code 

% Creating the uber material
uberName = 'uber';
uber = piMaterialCreate(uberName, 'type', 'uber');
thisR.set('material', 'add', uber);

% Assigning the uber material to the sphere
assetName = '005ID_Sphere_O';
thisR.set('asset', assetName, 'material name', uberName);

%% Uber properties: Diffuse reflectivity 
wave = 400:10:700;
reflectance = 0.1*ones(1,length(wave));
reflectance(11:end)=0;
spd = piMaterialCreateSPD(wave, reflectance);
thisR.set('material', uberName, 'kd value', spd);

piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance','meanluminance',-1);
scene = sceneSet(scene, 'name', 'Uber - kd');
sceneWindow(scene);

% Plot the inner and outer regions
roiMean_1 = sceneGet(scene, 'roimeanenergy', roi_1);
roiMean_2 = sceneGet(scene, 'roimeanenergy', roi_2);
ieNewGraphWin; hold on; grid on;
plot(wave, roiMean_1); plot(wave, roiMean_2);
title('Uber - kd'); ylim([0 20]);
legend('Center', 'Fringe'); hold off;

%% Uber Properties: Glossy Reflection
% midway between kd and kr, distribution at angle
ref_pass = zeros(1, length(wave));
ref_pass(wave>500 & wave<600) = 1;
spd = piMaterialCreateSPD(wave, ref_pass);
thisR.set('material', uberName, 'ks value', spd);

piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance','meanluminance',-1);
scene = sceneSet(scene, 'name', 'Uber - kd,ks');
sceneWindow(scene);

% Plot the inner and outer regions
roiMean_1 = sceneGet(scene, 'roimeanenergy', roi_1);
roiMean_2 = sceneGet(scene, 'roimeanenergy', roi_2);
ieNewGraphWin; hold on; grid on;
plot(wave, roiMean_1); plot(wave, roiMean_2);
title('Uber - kd, ks'); ylim([0 20]);
legend('Center', 'Fringe'); hold off;

% Roughness Parameter: run this line 2 times, once with the value =0 and
% once with the value =0.01
%thisR.set('material', uberName, 'roughness value', []);

%% Uber Properties: Specular Reflection
% like mirror reflection
ref_kr = zeros(1, length(wave));
ref_kr(wave>600) = 1;
spd = piMaterialCreateSPD(wave, ref_kr);
thisR.set('material', uberName, 'kr value', spd);

piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance','meanluminance',-1);
scene = sceneSet(scene, 'name', 'sphere to uber - kd');
sceneWindow(scene);

% Plot the inner and outer regions
roiMean_1 = sceneGet(scene, 'roimeanenergy', roi_1);
roiMean_2 = sceneGet(scene, 'roimeanenergy', roi_2);
ieNewGraphWin; hold on; grid on;
plot(wave, roiMean_1); plot(wave, roiMean_2);
title('Uber - kd,ks,kr'); ylim([0 20]);
legend('Center', 'Fringe'); hold off;

%% Set sphere to plastic
% 'plastic' materials have 2 spectral properties: diffuse reflectivity
% ('kd') and specular reflectivity ('ks')

% Create plastic material
plasticName = 'plastic';
plastic = piMaterialCreate(plasticName, 'type', 'plastic');
thisR.set('material', 'add', plastic);
thisR.set('asset', assetName, 'material name', plasticName);

%% Plastic Properties: diffuse relectivity

% Change kd value using RGB to tongue color
tongueRefs = ieReadSpectra('tongue', wave);
% The tongue data has reflectances for 12 subjects, we'll just use subject
% 7's data
thisRef = tongueRefs(:, 7);
spdRef = piMaterialCreateSPD(wave, thisRef);
thisR.set('material', plasticName, 'kd value', spdRef);

% Plot the radiance of the tongue data to compare to our results
ieNewGraphWin;
plotReflectance(wave,thisRef);
title('Tongue data');

piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance', 'meanluminance',-1);
scene = sceneSet(scene, 'name', 'Plastic - kd');
sceneWindow(scene);

% Plot the inner and outer regions
roiMean_1 = sceneGet(scene, 'roimeanenergy', roi_1);
roiMean_2 = sceneGet(scene, 'roimeanenergy', roi_2);
ieNewGraphWin; hold on; grid on;
plot(wave, roiMean_1); plot(wave, roiMean_2);
title('Plastic - kd'); ylim([0 70]);
legend('Center', 'Fringe'); hold off;

%% Plastic Properties: Spectral Reflectance
% Change ks value by making own spectral array to get green-blue color
reflectance = ones(size(wave));
reflectance(wave>550) = 0;
spdRef = piMaterialCreateSPD(wave, reflectance);

% Store the reflectance as the specular reflectance of the material
thisR.set('material', plasticName, 'ks value', spdRef);

% see the change
piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance', 'meanluminance',-1);
scene = sceneSet(scene, 'name', 'Plastic - kd,ks');
sceneWindow(scene);

% Plot the inner and outer regions
roiMean_1 = sceneGet(scene, 'roimeanenergy', roi_1);
roiMean_2 = sceneGet(scene, 'roimeanenergy', roi_2);
ieNewGraphWin; hold on; grid on;
plot(wave, roiMean_1); plot(wave, roiMean_2);
title('Plastic - kd,ks'); ylim([0 70]);
legend('Center', 'Fringe'); hold off;


%% Glass 

% 2 spheres (1 matte material, 1 glass with transmissivity) with sky map,
% have light go through glass sphere and reflect on one side of matte
% sphere
% tune parameters, keep matte reflection in the middle, glass
% transmissivity high
glassName = 'glass';
glass = piMaterialCreate(glassName, 'type', 'glass');
thisR.set('material', 'add', glass);
thisR.set('asset', assetName, 'material name', glassName);

piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance', 'meanluminance', -1);
scene = sceneSet(scene, 'name', 'Glass - kt,kr');
sceneWindow(scene);
sceneSet(scene, 'render flag', 'rgb');

wave = 400:10:700;
reflectance = 0.8*ones(1,length(wave));
reflectance(wave<500)=0;
spd = piMaterialCreateSPD(wave, reflectance);
thisR.set('material', glassName, 'kt value', spd);

piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance', 'meanluminance', -1);
scene = sceneSet(scene, 'name', 'Glass - kt');
sceneWindow(scene);
sceneSet(scene, 'render flag', 'rgb');

ref_2 = 1-reflectance;
% ref_2 = zeros(1, length(wave));
% ref_2(wave<500) = 1;
spd = piMaterialCreateSPD(wave, ref_2);
thisR.set('material', glassName, 'kr value', spd);

piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance', 'meanluminance', -1);
scene = sceneSet(scene, 'name', 'Glass - kt,kr');
sceneWindow(scene);
sceneSet(scene, 'render flag', 'rgb');

%% Mirror
mirrorName = 'mirror';
mirror = piMaterialCreate(mirrorName, 'type', 'mirror');
thisR.set('material', 'add', mirror);
thisR.set('asset', assetName, 'material name', mirrorName);

piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance', 'meanluminance', -1);
scene = sceneSet(scene, 'name', 'Mirror');
sceneWindow(scene);
sceneSet(scene, 'render flag', 'rgb');

thisR.get('to')
thisR.set('to',[0 0 500])


%% Add a matte sphere

thisAsset = thisR.get('asset', assetName);
% duplicating the original asset
newAsset2 = thisAsset;
newAsset2.name = 'Sphere2';
parent = thisR.get('asset parent', thisAsset);
thisR.set('asset',parent.name,'add',newAsset2);
thisR.assets.print;

% change material of second sphere
thisR.set('asset', newAsset2.name, 'material name', 'white');

% change fov to see both spheres
thisR.set('fov',90);

% translate spheres
% translate translates from object space, if rotate sphere the xyz axis
% change; world translate makes the new branch higher so when a rotation is
% added, the translation is taken into account
[~,translateBranch] = thisR.set('asset', thisAsset.name, 'world translate', [-300, 0, 0]); % top left
[~,translateBranch] = thisR.set('asset', newAsset2.name, 'world translate', [300, 0, 0]);

thisR.assets.print;

piWrite(thisR);

scene = piRender(thisR, 'render type', 'radiance','meanluminance', -1);
scene = sceneSet(scene, 'name', 'Translation');
sceneWindow(scene);