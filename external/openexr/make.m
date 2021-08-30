clc;
verbose = false;


% -----------------------------------------------
if ispc
    build_files = { 'exrinfo.cpp', ...
        'exrread.cpp', ...
        'exrreadchannels.cpp', ...
        'exrwritechannels.cpp', ...
        'exrwrite.cpp'};
else
    build_files = { 'exrinfo.cpp', ...
        'exrread.cpp', ...
        'exrreadchannels.cpp', ...
        'exrwrite.cpp', ...
        'exrwritechannels.cpp'};
end

companion_files = { 'utilities.cpp', ...
    'ImfToMatlab.cpp', ...
    'MatlabToImf.cpp'};

additionals = {};
if(verbose == true)
    additionals = [additionals, {'-v'}];
end

for n = 1:size(build_files, 2)
    if(verbose == true)
        clc;
    end
    
    file = cell2mat(build_files(n));
    
    disp(['Building ', file]);
    
    if ispc
        % So far, with 2.5 the MEX DLLs build, but MATLAB
        % crashes when the tutorials are run
        
        % SO this isn't a working code path (at least yet), more of a place
        % to start for anyone brave enough to help get this running on
        % Windows
        
        % should use symbolic links to versions, once we get something
        % running
        % Also, I've had to comment out lines 296 and 297 from half.h to
        % stop it from causing an error by trying to use the old way to
        % convert numbers. No clue if that broke something else:(
        % added -g for debug
        openexr3 = false; % Can't quite get it to work
        if openexr3
            mex(file, companion_files{:}, ...
                '-g', '-DOPENEXR_DLL','-UHALF_EXPORT',... % to fix _toFloat link issue and _eLut link issue
                '-IC:\Program Files (x86)\OpenEXR\include\OpenEXR', ...
                '-IC:\Program Files (x86)\OpenEXR\include\Imath', ...
                '-LC:\Program Files (x86)\OpenEXR\lib', ...
                '-lIex-3_1', ...
                '-lImath-3_2', ...
                '-lIlmThread-3_1', ...
                '-lOpenEXR-3_1', ...
                '-lOpenEXRCore-3_1', ...
                '-lOpenEXRUtil-3_1', ...
                '-largeArrayDims', ...
                additionals{:});
        else
            mex(file, companion_files{:}, ...
                '-g', '-v', '-DOPENEXR_DLL', '-UHALF_EXPORT',... % to fix _toFloat link issue and _eLut link issue
                '-Ic:\ProgramData\Anaconda3\Library\include\OpenEXR',...  OpenEXR include
                '-Ic:\ProgramData\Anaconda3\Library\include\OpenEXR',...  Ilmbase include
                '-Lc:\ProgramData\Anaconda3\Library\lib\', '-lIlmImf',... %path to IlmImf.lib
                '-Lc:\ProgramData\Anaconda3\Library\lib\','-lIex',... %path to Iex.lib
                '-Lc:\ProgramData\Anaconda3\Library\lib','-lImath',... %path to Imath.lib
                '-Lc:\ProgramData\Anaconda3\Library\lib','-lHalf',... %path to Half.lib
                '-Lc:\ProgramData\Anaconda3\Library\lib','-lIlmThread',... %path to IlmThread.lib
                '-largeArrayDims', ...
                additionals{:});
        end    
        else
            mex(file, companion_files{:}, ...
                '-I/usr/local/include/OpenEXR', ...
                '-L/usr/local/lib', ...
                '-lIlmImf', ...
                '-lIex', ...
                '-lImath', ...
                '-lHalf', ...
                '-lIlmThread', ...
                '-largeArrayDims', ...
                additionals{:});
        end
    end
    
    clear;
    disp('Finished building OpenEXR for Matlab');