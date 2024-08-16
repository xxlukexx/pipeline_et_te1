function valid = PIPELINE_ET_deleteEmptySessions(path_ses)

    % if a cell array of mutiple paths is passed, function calls itself on
    % each element
    if iscell(path_ses)
        valid = cellfun(@PIPELINE_ET_deleteEmptySessions, path_ses);
        return
    end

    path_gaze = fullfile(path_ses, 'gaze');
    hasGazeFolder = exist(path_gaze, 'dir');
    if hasGazeFolder
        file_eb = teFindFile(path_gaze, 'eventBuffer*.mat');
    else
        file_eb = [];
    end
    hasEventBuffer = hasGazeFolder && ~isempty(file_eb);
    if hasEventBuffer
        d = dir(file_eb);
        validBufferSize = d.bytes > 200;
    else
        validBufferSize = false;
    end
    valid = hasGazeFolder && hasEventBuffer && validBufferSize;
    
    if ~valid
        rmdir(path_ses, 's')
        fprintf('Deleted %s\n', path_ses)
    end
    
end