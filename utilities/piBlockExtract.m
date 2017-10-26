function blockLines = piBlockExtract(txtLines,varargin)
% piBlockExtract - Given a series of text lines in cell format (e.g. output of piRead),
% extract a block that corresponds to the given keyword.

% Example
% txtLines = piRead('/home/wandell/pbrt-v2-spectral/pbrt-scenes/sanmiguel.pbrt');
% cameraBlock = piExtractBlock(txtLines,'blockName','camera')

% TL Scienstanford 2017


%%
p = inputParser;
p.addRequired('txtLines',@(x)(iscell(txtLines) && ~isempty(txtLines)));
addParameter(p,'blockName','Camera',@ischar);
p.parse(txtLines,varargin{:});

blockName = p.Results.blockName;

%% Extract lines that correspond to specified keyword

blockBegin = []; blockEnd = [];
nLines = length(txtLines);
for ii=1:nLines
    thisLine = txtLines{ii};
    if length(thisLine) >= length(blockName)
        if strncmp(thisLine,blockName,length(blockName))
            blockBegin = ii;
            for jj=(ii+1):nLines
                if isempty(txtLines{jj})
                    blockEnd = jj;
                    break;
                end
            end
        end
    end
end

% If the blockName is not found, then blockBegin and blockEnd will be
% empty.
if(~isempty('blockBegin') && ~isempty('blockEnd'))
    blockLines = txtLines(blockBegin:(blockEnd-1));
else
    blockLines = [];
end


end
