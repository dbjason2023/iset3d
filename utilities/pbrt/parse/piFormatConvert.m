function [newlines] = piFormatConvert(txtLines)
% Format txtlines into a standard format.
%
% Inputs
%   txtLines - Text lines read from a pbrt file
%
% Output
%   newlines - Formatted to be compliant with ISET3d needs
%
% See also
%

%%
nn=1;ii=1;

%% remove empty cells
txtLines = txtLines(~cellfun('isempty',txtLines));

%% remove lines start with '#' except '#ObjectName'
parseStrings = {'#ObjectName','#object name','#CollectionName','#Instance','#MeshName'};
txtLines = txtLines(or(~strncmp(txtLines,'#',1), contains(txtLines,parseStrings)));
tokenlist = {'A', 'C' , 'F', 'I', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T'};
txtLines = regexprep(txtLines, '\t', ' ');

%% deal with special case
idxList = find(strcmp(txtLines,']'));
for idx = 1:numel(idxList)
    txtLines{idxList(idx)-1} = strcat(txtLines{idxList(idx)-1},txtLines{idxList(idx)});
    txtLines{idxList(idx)} = [];
end
txtLines = txtLines(~cellfun('isempty',txtLines));
nLines = numel(txtLines);
newlines = cell(nLines, 1);

% Comments needed.
while ii <= nLines
    thisLine = txtLines{ii};
    if length(thisLine) >= length('Shape')
        if any(strncmp(thisLine, tokenlist, 1)) && ...
                ~strncmp(thisLine,'Include', length('Include')) && ...
                ~strncmp(thisLine,'Attribute', length('Attribute'))
            % It does, so this is the start
            blockBegin = ii;
            % Keep adding lines whose first symbol is a double quote (")
            if ii == nLines
                newlines{nn,1}=thisLine;
                break;
            end
            for jj=(ii+1):nLines+1
                if jj==nLines+1 || isempty(txtLines{jj}) || ~isequal(txtLines{jj}(1),'"')
                    if jj==nLines+1 || isempty(txtLines{jj}) || isempty(sscanf(txtLines{jj}(1:2), '%f')) ||...
                            any(strncmp(txtLines{jj}, tokenlist, 1))
                        blockEnd = jj;
                        blockLines = txtLines(blockBegin:(blockEnd-1));
                        texLines=blockLines{1};
                        for texI = 2:numel(blockLines)
                            if ~strcmp(texLines(end),' ')&&~strcmp(blockLines{texI}(1),' ')
                                texLines = [texLines,' ',blockLines{texI}];
                            else
                                texLines = [texLines,blockLines{texI}];
                            end
                        end
                        newlines{nn,1}=texLines;nn=nn+1;
                        ii = jj-1;
                        break;
                    end
                end
                
            end
        else
            newlines{nn,1}=thisLine; nn=nn+1;
        end
    end
    ii=ii+1;
end

%% Clear out junk
newlines(piContains(newlines,'Warning'))=[];
newlines = newlines(~cellfun('isempty', newlines));

end