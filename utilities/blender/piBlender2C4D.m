function fname = piBlender2C4D(fname)
% Converts the exported blender files into C4D format
%
% Synopsis
%    fname = piBlender2C4D(fname);
%
% Input:
%   fname - PBRT file exported by Blender
%
% Output
%   fnane - new filename for C4D compliant file
%
% Description
%   This function creates the material and geometry files from the exported
%   Blender PBRT file.  After this function has run, the format should
%   comply with the C4D exported format.  That way we can run the usual set
%   of functions.
% 
% See also
%   piRead
%

% Example:
%{
% See s_blenderTest   
%}

%% Copy the original Blender exported files to a new directory

[sourceDir,sceneName,ext] = fileparts(fname);
[~,destDirName] = fileparts(sourceDir);
destDir = fullfile(piRootPath,'local',[destDirName,'_C4D']);
copyfile(sourceDir,destDir);

%% We convert the files in the new directory to C4D format
fname = fullfile(destDir,[sceneName,ext]);
[txtLines, header] = piReadText(fname);

thisR = recipe;
thisR.exporter = 'Blender';
thisR.inputFile = fname;

%% Split text lines into pre-WorldBegin and WorldBegin sections
txtLines = piReadWorldText(thisR,txtLines);

%% Set flag indicating whether this is exported Cinema 4D file
% exporterFlag = piReadExporter(thisR,header);
piReadExporter(thisR,header);

%% If this is an exported Blender file:
% 1) rewrite 'txtLines' in C4D format
% 2) create materials and geometry files in C4D format
% 3) rewrite 'thisR.world' in C4D format
% 4) extract geometry information from .ply functions in the geometry file
% 5) convert the coordinate system from right-handed to left-handed
% 6) calculate 'Vector' information in the geometry file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: section added
% to rewrite a pbrt file exported from Blender into the format of pbrt
% files exported from C4D

% NOTE: this is a new helper function
% that rewrites 'txtLines' in C4D format
txtLines = piWriteC4Dformat_txt(txtLines);

% NOTE: this is a new helper function
% that creates materials and geometry files in C4D format
% (the Blender exporter does not create materials and geometry files)
piWriteC4Dformat_files(thisR);

% NOTE: this is a new helper function
% that rewrites 'thisR.world' in C4D format
thisR = piWriteC4Dformat_world(thisR);

% NOTE: this is a new helper function
% that extracts geometry information from .ply functions in the
% geometry file
% NOTE: this is currently called for Blender exports only
% but should be useful for converting any .ply functions
piWriteC4Dformat_ply(thisR);

% NOTE: this is a new helper function
% that converts a right-handed coordinate system into the left-handed
% pbrt system
% NOTE: this function should always be called once for Blender exports
% because Blender uses a right-handed coordinate system
piWriteC4Dformat_handedness(thisR);

% NOTE: this is a new helper function
% that calculate 'Vector' information in the geometry file
% NOTE: this function should always be called for Blender exports
% because the Blender exporter does not include vector information
% automatically, but should be useful for any pbrt files without Vector
% information included
piWriteC4Dformat_vector(thisR);

%% Set thisR.lookAt and determine if we need to flip the image
[flip, thisR] = piReadLookAt(thisR,txtLines);

% Sometimes the axis flip is "hidden" in the concatTransform matrix. In
% this case, the flip flag will be true. When the flip flag is true, we
% always output Scale -1 1 1.

% ZLY: when flip is not true, it means there is no need for flipping, we
% will get rid of the Scale -1 1 1 section
if ~flip
    scaleIdx = find(piContains(txtLines, 'Scale -1 1 1'));
    if ~isempty(scaleIdx)
        txtLines(scaleIdx) = [];
    end
end

% Override the original lookAt block with the look at in the PBRT
% coordinate.
lookAtIdx = find(piContains(txtLines, 'LookAt'));
if ~isempty(lookAtIdx)
from = thisR.get('from');
to   = thisR.get('to');
up   = thisR.get('up');

txtLines{lookAtIdx} = sprintf('LookAt %0.6f %0.6f %0.6f %0.6f %0.6f %0.6f %0.6f %0.6f %0.6f \n', ...
    [from(:); to(:); up(:)]);
end

% Erase Transform, ConcatTransform since all the transformations are included
% in lookAt
transformIdx = find(piContains(txtLines, 'Transform'));
if ~isempty(transformIdx)
    txtLines(transformIdx) = [];
end


%% Now we re-write the scene file

newSceneFile = txtLines;   % Lines before WorldBegin

newSceneFile{end+1} = 'WorldBegin';
newSceneFile{end+1} = sprintf('Include "%s_materials.pbrt"',sceneName);
newSceneFile{end+1} = sprintf('Include "%s_geometry.pbrt"',sceneName);
newSceneFile{end+1} = 'WorldEnd';

fid = fopen(fname,'w');
for ii=1:numel(newSceneFile)
    fprintf(fid,'%s\n',newSceneFile{ii});
end

fclose(fid);

end

function [txtLines, header] = piReadText(fname)
% Open, read, close excluding comment lines
fileID = fopen(fname);
tmp = textscan(fileID,'%s','Delimiter','\n','CommentStyle',{'#'});
txtLines = tmp{1};
fclose(fileID);

% Include comments so we can read only the first line, really
fileID = fopen(fname);
tmp = textscan(fileID,'%s','Delimiter','\n');
header = tmp{1};
fclose(fileID);
end

function txtLines = piReadWorldText(thisR,txtLines)
% txtLines are the lines before WorldBegin
% thisR.world contains the world text
%

worldBeginIndex = 0;
for ii = 1:length(txtLines)
    currLine = txtLines{ii};
    if(piContains(currLine,'WorldBegin'))
        worldBeginIndex = ii;
        break;
    end
end

% fprintf('Through the loop\n');
if(worldBeginIndex == 0)
    warning('Cannot find WorldBegin.');
    worldBeginIndex = ii;
end

% Store the text from WorldBegin to the end here
thisR.world = txtLines(worldBeginIndex:end);

% Store the text lines from before WorldBegin here
txtLines = txtLines(1:(worldBeginIndex-1));

end

function exporterFlag = piReadExporter(thisR,header)
%
% Read the first line of the scene file to see if it is a Cinema 4D file
% Also, check the materials file for consistency.
% Set the recipe accordingly and return a true/false flag
%

if piContains(header{1}, 'Exported by PBRT exporter for Cinema 4D')
    % Interprets the information and writes the _geometry.pbrt and
    % _materials.pbrt files to the rendering folder.
    exporterFlag   = true;
    thisR.exporter = 'C4D';
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % NOTE: below changed
    % to also set the exporterFlag to true if the exporter was Blender
    
elseif isequal(thisR.exporter,'Blender')
    % Interprets the information and writes the _geometry.pbrt and
    % _materials.pbrt files to the rendering folder.
    exporterFlag = true;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    % Copies the original _geometry.pbrt and _materials.pbrt to the
    % rendering folder.
    exporterFlag   = false;
    thisR.exporter = 'Copy';
end

% Check that the materials file export information matches the scene file
% export

% Read the materials file if it exists.
inputFile_materials = thisR.get('materials file');

if exist(inputFile_materials,'file')
    
    % Confirm that the material file matches the exporter of the main scene
    % file.
    fileID = fopen(inputFile_materials);
    tmp = textscan(fileID,'%s','Delimiter','\n');
    headerCheck_material = tmp{1};
    fclose(fileID);
    
    if ~piContains(headerCheck_material{1}, 'Exported by piMaterialWrite')
        if isequal(exporterFlag,true) && isequal(thisR.exporter,'C4D')
            % Everything is fine
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % NOTE: below added
            % to deal with the exporter being Blender
            
        elseif isequal(exporterFlag,true) && isequal(thisR.exporter,'Blender')
            % Everything is fine
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
        elseif isequal(thisR.exporter,'Copy')
            % Everything is still fine
        else
            warning('Puzzled about the materials file.');
        end
    else
        if isequal(exporterFlag,false)
            % Everything is fine
        else
            warning('Non-standard materials file. Export match not C4D like main file');
        end
    end
else
    % No material field.  If exporter is Cinema4D, that's not good. Check
    % that condition here
    if isequal(thisR.exporter,'C4D')
        warning('No materials file for a C4D export');
    end
end

end

function [flip,thisR] = piReadLookAt(thisR,txtLines)

% Reads multiple blocks to create the lookAt field and flip variable
%
% The lookAt is built up by reading from, to, up field and transform and
% concatTransform.
%
% Interpreting these variables from the text can be more complicated w.r.t.
% formatting.

% A flag for flipping from a RHS to a LHS.
flip = 0;

% Get the block
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: below changed
% as above

[s, lookAtBlock] = piBlockExtract_Blender(txtLines,'blockName','LookAt','exporter',thisR.exporter);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if(isempty(lookAtBlock))
    % If it is empty, use the default
    thisR.lookAt = struct('from',[0 0 0],'to',[0 1 0],'up',[0 0 1]);
else
    % We have values
    values = textscan(lookAtBlock{1}, '%s %f %f %f %f %f %f %f %f %f');
    from = [values{2} values{3} values{4}];
    to = [values{5} values{6} values{7}];
    up = [values{8} values{9} values{10}];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % NOTE: below added
    % to convert the right-handed coordinate system of the Blender export
    % into the left-handed pbrt system
    
    if isequal(thisR.exporter,'Blender')
        from = from([1 3 2]);
        to   =   to([1 3 2]);
        up   =   up([1 3 2]);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

% If there's a transform, we transform the LookAt.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: below changed
% as above

[~, transformBlock] = piBlockExtract_Blender(txtLines,'blockName','Transform','exporter',thisR.exporter);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(~isempty(transformBlock))
    values = textscan(transformBlock{1}, '%s [%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f]');
    values = cell2mat(values(2:end));
    transform = reshape(values,[4 4]);
    [from,to,up,flip] = piTransform2LookAt(transform);
end

% If there's a concat transform, we use it to update the current camera
% position.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: below changed
% as above

[~, concatTBlock] = piBlockExtract_Blender(txtLines,'blockName','ConcatTransform','exporter',thisR.exporter);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(~isempty(concatTBlock))
    values = textscan(concatTBlock{1}, '%s [%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f]');
    values = cell2mat(values(2:end));
    concatTransform = reshape(values,[4 4]);
    
    % Apply transform and update lookAt
    lookAtTransform = piLookat2Transform(from,to,up);
    [from,to,up,flip] = piTransform2LookAt(lookAtTransform*concatTransform);
end

% Warn the user if nothing was found
if(isempty(transformBlock) && isempty(lookAtBlock))
    warning('Cannot find "LookAt" or "Transform" in PBRT file. Returning default.');
end

thisR.lookAt = struct('from',from,'to',to,'up',up);

end

%% Rewrite txtLines in C4D format
function txtLines = piWriteC4Dformat_txt(txtLines)

% Remove a parameter that is not currently identified by piBlockExtractC4D.m
% as well as any empty lines
lineidx = cellfun('isempty',txtLines);
txtLines(lineidx) = [];
lineidx = piContains(txtLines,'bool');
txtLines(lineidx) = [];

% Rewrite each block's lines into a single line, including lines that begin
% with a double quote, as well as lines that begin with a +/- number (this
% is unique to Blender exports)
nLines = length(txtLines);
ii=1;
while ii<nLines
    % Append to the iith line any subsequent line/s whose first symbol is a
    % double quote ("), a number, or a negative sign (-) until the block ends
    for jj=(ii+1):nLines
        if isequal(txtLines{jj}(1),'"') || ...
                ~isnan(str2double(txtLines{jj}(1))) || isequal(txtLines{jj}(1),'-')
            txtLines{ii} = append(txtLines{ii},' ',txtLines{jj});
            txtLines{jj} = [];
            if jj==nLines
                ii = jj;
            end
        else
            ii = jj;
            break
        end
    end
end

% Remove empty lines
lineidx = cellfun('isempty',txtLines);
txtLines(lineidx) = [];
end

%% Create materials and geometry files in C4D format

function piWriteC4Dformat_files(thisR)

% Get materials and geometry file names
inputFile_materials = thisR.get('materials file');
[inFilepath,scene_fname] = fileparts(thisR.inputFile);
inputFile_geometry = fullfile(inFilepath,sprintf('%s_geometry.pbrt',scene_fname));

% If both files already exist, exit this function; otherwise, proceed
if exist(inputFile_materials,'file') && exist(inputFile_geometry,'file')
    fprintf('Materials and geometry files not created - they already exist.\n');
    return
end

% Since the materials and/or geometry files don't exist, start the process
% of creating them
allLines = thisR.world;

% Find how many objects need to be defined
beginLines    = find(piContains(allLines,'AttributeBegin'));
numbeginLines = numel(beginLines);

% Preallocate cell arrays for materials and geometry text
materials = cell(size(allLines));
geometry  = cell(size(allLines));

% Read out one object at a time
for ii = 1:numbeginLines
    
    % Start with the 'AttributeBegin' line
    startidx = beginLines(ii);
    
    % Find the index for the last line for this object
    endidx    = find(piContains(allLines(startidx+1:end),'AttributeEnd'),1,'first');
    endallidx = endidx + startidx;
    
    % Pull all of the lines for this object
    objectLines = allLines(startidx:endallidx);
    
    % For now, not reading out object light sources
    lightidx = piContains(objectLines,'LightSource');
    if any(lightidx)
        continue
    end
    
    % Preallocate cell array for object's geometry text
    geometryobj = cell(numel(objectLines)+6,1);
    
    % Add an 'AttributeBegin' line
    geometryobj{find(cellfun(@isempty,geometryobj),1)} = 'AttributeBegin';
    
    % Get object name (Blender files are not exported with object names)
    % If there is a .ply file associated with the object, use that file name
    plylineidx = piContains(objectLines,'.ply');
    if any(plylineidx)
        plyline = objectLines{plylineidx};
        [~,objectname] = fileparts(plyline);
        % Remove the '_mat0' that the Blender exporter adds automatically
        objectname = objectname(1:end-5);
        % If there is no .ply file, give the object a generic name
    else
        objectname = (['object' num2str(ii)]);
    end
    % Reformat the object name line in the same format as a C4D geometry file
    % (The 'Vector' parameter will be set later)
    nameline = append('#ObjectName ',objectname);
    geometryobj{find(cellfun(@isempty,geometryobj),1)} = nameline;
    
    %Add the transform line
    Tlineidx  = piContains(objectLines,'Transform');
    if any(Tlineidx)
        geometryobj{find(cellfun(@isempty,geometryobj),1)} = objectLines{Tlineidx};
    end
    
    % Add an 'AttributeBegin' line
    geometryobj{find(cellfun(@isempty,geometryobj),1)} = 'AttributeBegin';
    
    % Get material name and parameters
    Mlineidx = piContains(objectLines,'Material');
    if any(Mlineidx)
        Mline = objectLines{Mlineidx};
        % Get material name only
        Mname = textscan(Mline,'%q');
        Mname = Mname{1};
        Mname = Mname{2};
        % Start this part of the material line with the material name
        Mline = append('"',Mname,'"');
        % Append all material parameters to the material line started above
        nLines = endidx-1;
        for jj=find(Mlineidx)+1:nLines
            thisLine = objectLines{jj};
            
            % If the next line contains a double quote (") it gets appended
            if isequal(thisLine(1),'"')
                
                % The color parameters get special treatment because of how
                % they are exported from Blender
                if piContains(thisLine,'color')
                    
                    % The Blender exporter puts a space after the '['
                    % character for color parameters, which has to be
                    % removed to be compatible with piParseRGB.m later
                    thisLine = replace(thisLine,'[ ', '[');
                    
                    % Rename color parameters because the Blender exporter
                    % uses the 'color' synonym for 'rgb' and not all
                    % 'color' values are read out in piBlockExtractMaterial.m
                    thisLine = replace(thisLine,'color','rgb');
                end
                
                % Append the line
                Mline = append(Mline,' ',strtrim(thisLine));
                % If the next line does not contain a double quote, break
            else
                break
            end
        end
    else
        % If the object was exported from Blender without a pbrt material
        % assign a default material here (gray matte)
        Mline = '"matte" "float sigma" [0] "rgb Kd" [.9 .9 .9]';
    end
    % Assign material name (Blender files are not exported with
    % material names) based on the object name assigned above
    materialname = append(objectname,'_material');
    % Reformat the material line for this object's materials text
    Materialline = append('MakeNamedMaterial "',materialname,'" "string type" ',Mline);
    
    % Get texture parameters
    Tlineidx = piContains(objectLines,'Texture');
    if any(Tlineidx)
        Textureline = objectLines{Tlineidx};
        
        % Replace "color" with "spectrum" to match C4D format
        Textureline = strrep(Textureline,"color","spectrum");
        
        % The pbrt file exported from Blender refers to texture files in a
        % 'textures' folder, but any texture files were moved directly into
        % the scene folder for use in iset3d, so we need to remove any
        % references to a 'textures' folder
        Textureline = strrep(Textureline,"[""textures/","""");
        Textureline = strrep(Textureline,".exr""]",".exr""");
        
        % Add the texture line to this object's materials text
        materials{find(cellfun(@isempty,materials),1)} = Textureline;
    end
    
    % Add the material line to this object's materials text (it is added
    % after this object's texture line, if this object has a texture)
    materials{find(cellfun(@isempty,materials),1)} = Materialline;
    
    % Create a material line for this object's geometry text
    GMaterialline = append('NamedMaterial "',materialname,'"');
    geometryobj{find(cellfun(@isempty,geometryobj),1)} = GMaterialline;
    
    % Get shape parameters
    Slineidx = piContains(objectLines,'Shape');
    if any(Slineidx)
        % If the shape parameters are described by a .ply file, don't
        % reformat the shape line (the .ply file will be read out later)
        if piContains(objectLines{Slineidx},'.ply')
            Sline = objectLines{Slineidx};
            % But if not, reformat the shape parameters into a single line
        else
            objectLines(1:find(Slineidx)-1) = [];
            objectLines(end) = [];
            Sline = cellfun(@string,objectLines);
            Sline = join(Sline);
            % Remove an extra space after the '[' character
            Sline = replace(Sline,'[ ', '[');
            Sline = convertStringsToChars(Sline);
        end
        geometryobj{find(cellfun(@isempty,geometryobj),1)} = Sline;
    end
    
    % Complete this object description
    geometryobj{find(cellfun(@isempty,geometryobj),1)} = 'AttributeEnd';
    geometryobj{find(cellfun(@isempty,geometryobj),1)} = 'AttributeEnd';
    
    % Remove any empty cells
    lineidx = cellfun('isempty',geometryobj);
    geometryobj(lineidx) = [];
    
    % Add to geometry text
    Gstartidx = find(cellfun(@isempty,geometry),1);
    Gendidx   = Gstartidx + numel(geometryobj) - 1;
    try
        geometry(Gstartidx:Gendidx) = geometryobj;
    catch
        geometry = [geometry; geometryobj];
    end
end

% Complete materials text and geometry text
lineidx = cellfun('isempty',geometry);
geometry(lineidx) = [];
lineidx = cellfun('isempty',materials);
materials(lineidx) = [];

% If the materials file doesn't exist, create it in the same folder as the
% pbrt scene file
if ~exist(inputFile_materials,'file')
    % Open up a new materials file
    fileID = fopen(inputFile_materials,'w');
    % Write in a comment describing when this file was created
    fprintf(fileID,'# PBRT file created in C4D exporter format on %i/%i/%i %i:%i:%0.2f \n',clock);
    % Blank line
    fprintf(fileID,'\n');
    % Write in materials text
    materials = materials';
    fprintf(fileID,'%s\n',materials{:});
    % Close the materials file
    fclose(fileID);
    fprintf('A new materials file was created in %s\n', inFilepath);
end

% If the geometry file doesn't exist, create it in the same folder as the
% pbrt scene file
if ~exist(inputFile_geometry,'file')
    % Open up a new geometry file
    fileID = fopen(inputFile_geometry,'w');
    % Write in a comment describing when this file was created
    fprintf(fileID,'# PBRT file created in C4D exporter format on %i/%i/%i %i:%i:%0.2f \n',clock);
    % Blank line
    fprintf(fileID,'\n');
    % Write in geometry text
    geometry = geometry';
    fprintf(fileID,'%s\n',geometry{:});
    % Close the materials file
    fclose(fileID);
    fprintf('A new geometry file was created in %s\n', inFilepath);
end
end

function thisR = piWriteC4Dformat_world(thisR)

world{1,1} = 'WorldBegin';
% Include the materials file
[~,scene_fname] = fileparts(thisR.inputFile);
world{2,1} = append('Include "',scene_fname,'_materials.pbrt"');
% Include the geometry file
world{3,1} = append('Include "',scene_fname,'_geometry.pbrt"');
world{4,1} = 'WorldEnd';

% Update thisR.world
thisR.world = world;
end

function piWriteC4Dformat_ply(thisR)

% Get geometry file name
[inFilepath,scene_fname] = fileparts(thisR.inputFile);
inputFile_geometry = fullfile(inFilepath,sprintf('%s_geometry.pbrt',scene_fname));

% If the geometry file doesn't exist, give warning and exit this function
if ~exist(inputFile_geometry,'file')
    warning('Geometry file does not exist.');
    return
end

% Get text from geometry file
fileID = fopen(inputFile_geometry,'r');
tmp = textscan(fileID,'%s','Delimiter','\n');
txtLines = tmp{1};
fclose(fileID);

% Check for .ply files and exit this function if they do not exist
sLines = find(piContains(txtLines,'.ply'));
if ~any(sLines)
    return
end

% Replace text lines referencing .ply files with their geometry information
numsLines = numel(sLines);
for ii = 1:numsLines
    thisLine = txtLines{sLines(ii)};
    
    % Get the name of the .ply file
    plyLine = textscan(thisLine,'%q');
    plyLine = plyLine{1};
    plylineidx = piContains(plyLine,'.ply');
    plyLine = plyLine{plylineidx};
    [~,objectname] = fileparts(plyLine);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % NOTE: new function below
    % The function below is a modified version of pcread.m
    % that reads out the per-vertex texture coordinates (in addition to the
    % per-vertex locations and normals read out by pcread.m)from the .ply file
    
    [ptCloud,plyTexture] = pcread_Blender([objectname '.ply']);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Set up .ply file output in pbrt format
    plyLocation = ptCloud.Location;
    plyNormal   = ptCloud.Normal;
    %pcshow(ptCloud); %uncomment this line to plot points
    % NOTE: for now, assumes all exported objects are triangle mesh
    Shape = 'trianglemesh';
    % Align vertices with their corresponding normals and texture coordinates
    plyAll = [plyLocation plyNormal plyTexture];
    % Get the unique vertices/normals/texture coordinates
    uvertices = unique(plyAll,'rows');
    % Separate out the three parameters
    pointP  = uvertices(:,1:size(plyLocation,2));
    normalN = uvertices(:,size(plyLocation,2)+1:size(plyLocation,2)+size(plyNormal,2));
    floatuv = uvertices(:,size(plyLocation,2)+size(plyNormal,2)+1:end);
    % Calculate the integer indices
    [~,integerindices] = ismember(plyAll,uvertices,'rows');
    % Integers currently start at 1 but need to start at 0
    integerindices = integerindices - 1;
    % Reshape into pbrt format
    integerindices = integerindices';
    pointP  = reshape(pointP.',1,[]);
    normalN = reshape(normalN.',1,[]);
    floatuv = reshape(floatuv.',1,[]);
    % Convert to strings
    integerindices = mat2str(integerindices);
    pointP  = mat2str(pointP);
    normalN = mat2str(normalN);
    floatuv = mat2str(floatuv);
    
    % Rewrite 'Shape' line in pbrt format
    newLine = append('Shape "',Shape,'" "integer indices" ',integerindices, ...
        ' "point P" ',pointP);
    if ~isempty(plyNormal)
        newLine = append(newLine,' "normal N" ',normalN);
    end
    if ~isempty(plyTexture)
        newLine = append(newLine,' "float uv" ',floatuv);
    end
    
    % Replace the old 'Shape' line with the rewritten line
    txtLines{sLines(ii)} = newLine;
end

% Update geometry file text
fileID = fopen(inputFile_geometry,'w');
txtLines = txtLines';
fprintf(fileID,'%s\n',txtLines{:});
fclose(fileID);
fprintf('One or more .ply functions were parsed in the geometry file.\n');
end

%% Convert a right-handed coordinate system to the left-handed pbrt system
% (this function should always be called once for Blender exports, because
% Blender uses a right-handed coordinate system)

function piWriteC4Dformat_handedness(thisR)

% Get geometry file name
[inFilepath,scene_fname] = fileparts(thisR.inputFile);
inputFile_geometry = fullfile(inFilepath,sprintf('%s_geometry.pbrt',scene_fname));

% If the geometry file doesn't exist, give warning and exit this function
if ~exist(inputFile_geometry,'file')
    warning('Geometry file does not exist.');
    return
end

% Get text from geometry file
fileID = fopen(inputFile_geometry,'r');
tmp = textscan(fileID,'%s','Delimiter','\n');
txtLines = tmp{1};
fclose(fileID);

% If this conversion to a left-handed coordinate system has already
% occurred, exit this function (must only do this conversion once)
checkflg = piContains(txtLines,'Converted to a left-handed coordinate system');
if any(checkflg)
    return
end

% Switch y and z coordinates per vertex for vertex positions ('point P')
% and per-vertex normals ('normal N') in the 'Shape' line for each object
pLines = find(piContains(txtLines,'"point P"'));
numsLines = numel(pLines);
for ii = 1:numsLines
    Pline = txtLines{pLines(ii)};
    
    % Get 'point P' vector
    pidx = strfind(Pline,'"point P"');
    pPline = Pline(pidx:end);
    openidx  = strfind(pPline,'[');
    closeidx = strfind(pPline,']');
    pointP = pPline(openidx(1)+1:closeidx(1)-1);
    pointP = str2num(pointP);
    
    % Reshape points into three columns (three axes)
    numvertices = numel(pointP)/3;
    pointP = reshape(pointP,[3,numvertices]);
    pointP = pointP';
    
    % Switch y and z coordinates
    pointP = pointP(:,[1 3 2]);
    
    % Reshape points into vector
    pointP = reshape(pointP.',1,[]);
    
    % Convert to string
    pointP = mat2str(pointP);
    
    % Replace converted 'point P' in the 'Shape' line
    Pline = append(Pline(1:pidx+9),pointP,Pline(pidx+closeidx(1):end));
    
    % If the 'normal N' vector exists, switch y and z coordinates as above
    nidx = strfind(Pline,'"normal N"');
    if ~isempty(nidx)
        nPline = Pline(nidx:end);
        openidx  = strfind(nPline,'[');
        closeidx = strfind(nPline,']');
        normalN = nPline(openidx(1)+1:closeidx(1)-1);
        normalN = str2num(normalN);
        normalN = reshape(normalN,[3,numvertices]);
        normalN = normalN';
        normalN = normalN(:,[1 3 2]);
        normalN = reshape(normalN.',1,[]);
        normalN = mat2str(normalN);
        Pline = append(Pline(1:nidx+10),normalN,Pline(nidx+closeidx(1):end));
    end
    
    % Replace old 'Shape' text line with new text line
    txtLines{pLines(ii)} = Pline;
end

% Convert 'Transform' matrices into left-handed matrices for each object
tLines = find(piContains(txtLines,'Transform'));
numsLines = numel(tLines);
for ii = 1:numsLines
    Tline = txtLines{tLines(ii)};
    
    % Get 'Transform' vector
    openidx  = strfind(Tline,'[');
    closeidx = strfind(Tline,']');
    Transform = Tline(openidx(1)+1:closeidx-1);
    Transform = str2num(Transform);
    
    % Convert the right-handed matrix into a left-handed matrix
    Transform = reshape(Transform,[4,4]);
    Transform(:,[2 3]) = Transform(:,[3 2]);
    Transform([2 3],:) = Transform([3 2],:);
    
    % Reshape matrix into vector
    Transform = reshape(Transform,[1 16]);
    
    % Convert to string
    Transform = mat2str(Transform);
    
    % Replace converted 'Transform' vector
    Tline = append('Transform ',Transform);
    
    % Replace old 'Transform' text line with new text line
    txtLines{tLines(ii)} = Tline;
end

% Update geometry file text
fileID = fopen(inputFile_geometry,'w');
fprintf(fileID,'%s\n',txtLines{1});
% Write in a comment describing when the handedness was converted
% (this helper function will watch out for this comment in the future
% because you must only do this conversion once)
fprintf(fileID,'# Converted to a left-handed coordinate system on %i/%i/%i %i:%i:%0.2f \n',clock);
txtLines = txtLines(2:end);
txtLines = txtLines';
fprintf(fileID,'%s\n',txtLines{:});
fclose(fileID);
fprintf('Coordinate system was converted to left-handed pbrt system in the geometry file.\n');
end

%% Calculate vector information
function piWriteC4Dformat_vector(thisR)

% Get geometry file name
[inFilepath,scene_fname] = fileparts(thisR.inputFile);
inputFile_geometry = fullfile(inFilepath,sprintf('%s_geometry.pbrt',scene_fname));

% If the geometry file doesn't exist, give warning and exit this function
if ~exist(inputFile_geometry,'file')
    warning('Geometry file does not exist.');
    return
end

% Get text from geometry file
fileID = fopen(inputFile_geometry,'r');
tmp = textscan(fileID,'%s','Delimiter','\n');
txtLines = tmp{1};
fclose(fileID);

% Check for 'Vector' parameter and exit this function if it already exists
vLines = find(piContains(txtLines,':Vector('));
if any(vLines)
    return
end

% Add 'Vector' information to object name text lines
oLines = find(piContains(txtLines,'#ObjectName'));
numsLines = numel(oLines);
for ii = 1:numsLines
    thisLine = txtLines{oLines(ii)};
    
    % Find shape parameters for this object
    restoftxt = txtLines(oLines(ii)+1:numel(txtLines));
    endLine = find(piContains(restoftxt,'AttributeEnd'),1,'first');
    thistxt = restoftxt(1:endLine);
    lineidx = piContains(thistxt,'point P');
    
    % If shape parameters do not exist for this object, give default vector
    if ~any(lineidx)
        thisLine = append(thisLine,':Vector(0, 0, 0)');
    else
        % Get 'point P' vector
        Pline = thistxt{lineidx};
        pidx = strfind(Pline,'"point P"');
        Pline = Pline(pidx:end);
        openidx  = strfind(Pline,'[');
        closeidx = strfind(Pline,']');
        pointP = Pline(openidx(1)+1:closeidx(1)-1);
        pointP = str2num(pointP);
        
        % Reshape points into three columns (three axes)
        numvertices = numel(pointP)/3;
        pointP = reshape(pointP,[3,numvertices]);
        pointP = pointP';
        
        % Calculate vector parameter
        minpointP  = min(pointP);
        maxpointP  = max(pointP);
        diffpointP = abs(minpointP)+abs(maxpointP);
        v = diffpointP/2;
        
        % Add vector to object name line in pbrt format, which is
        % NAME:Vector(X, Z, Y)
        thisLine = append(thisLine,':Vector(',num2str(v(1)),', ',num2str(v(3)),', ',num2str(v(2)),')');
    end
    
    % Replace old object text line with new text line
    txtLines{oLines(ii)} = thisLine;
end

% Update geometry file text
fileID = fopen(inputFile_geometry,'w');
txtLines = txtLines';
fprintf(fileID,'%s\n',txtLines{:});
fclose(fileID);
fprintf('Vector information was updated in the geometry file.\n');
end

