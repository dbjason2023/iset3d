function expanded = expanduser(p)
% expanded = expanduser(path)
%
%   expands tilde ~ into user home directory
%
%   Useful for Matlab functions like h5read() and some Computer Vision toolbox functions
%   that can't handle ~ and Matlab does not consider it a bug per conversations with
%   Mathworks staff
%
%  Benchmark: on laptop and Matlab R2020a
%
%   about 200 microseconds
%   f = @() expanduser('~/foo');
%   timeit(f)
%
%   about 2 microseconds:
%   f = @() expanduser('foo');
%   timeit(f)
%
%   See also absolute_path
arguments
  p string
end

expanded = p;

if ispc
  home = getenv('USERPROFILE');
else
  home = getenv('HOME');
end

if ~isempty(home)
  i = startsWith(expanded, "~");
  expanded(i) = fullfile(home, extractAfter(expanded(i), 1));
end

end %function