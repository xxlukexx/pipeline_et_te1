function [exports, success, outcome] =...
    etExport(data, path_sessions, path_tasks, prefix, id, wave)

    %% setup
    
    % flag to save CSVs (slow)
    
    
    % if not prefix given, use blank
    if ~exist('prefix', 'var') || isempty(prefix)
        prefix = '';
    else
        prefix = [prefix, '_'];
    end

    exports = {'UNKNOWN ERROR', 'NO FILE'};
    success = false;
    outcome = {'UNKNOWN ERROR'};

    % make paths
    try
        path_sessions_csv = [path_sessions, filesep, 'csv'];
        path_sessions_mat = [path_sessions, filesep, 'mat'];
        tryToMakePath(path_sessions_csv);
        tryToMakePath(path_sessions_mat);
    catch ERR
    end
    
    %% process 

    % get ID
%     id = data.ParticipantID;
%     wave = data.TimePoint;
%     if isnumeric(wave), wave = num2str(wave); end

    % get log data
    trialLog = data.Log;

    % get gaze data
    mb = data.MainBuffer;
    tb = data.TimeBuffer;
    eb = data.EventBuffer;

    % convert ECKData to structs
    [ses, seg] = ECKDataSegmentsToStruct(data);

    %% write session data

    % make path to log files
    path_sessions_logs = [path_sessions, filesep, 'logs', filesep,...
        id, '_', wave];
    tryToMakePath(path_sessions_logs);

    % make filenames
    try
        file_session = [path_sessions_mat, filesep, prefix,...
            id, '_', wave, '.mat'];
        file_session_csv_gaze = [path_sessions_csv,...
            filesep, prefix, id, '_', wave, '_GAZE.csv'];
        file_session_csv_events = [path_sessions_csv,...
            filesep, prefix, id, '_', wave, '_EVENTS.csv'];   
    catch ERR
    end
    
    % write mat data
    data = ses;
    save(file_session, 'data', '-v6');
    tmpSuccess = exist(file_session, 'file');
    tmpOutcome = '';
    updateExports('Session mat', file_session, tmpSuccess, tmpOutcome);

    % write csv data
    try
        ECKSaveETGazeTime(file_session_csv_gaze, mb, tb, false);
        tmpSuccess = exist(file_session_csv_gaze, 'file');
        tmpOutcome = '';
    catch ERR
        tmpSuccess = false;
        tmpOutcome = ERR.message;
    end
    updateExports('Session gaze', file_session_csv_gaze, tmpSuccess,...
        tmpOutcome);
    
    try
        ECKSaveETEvents(file_session_csv_events, eb);
        tmpSuccess = exist(file_session_csv_events, 'file');
        tmpOutcome = '';
    catch ERR
        tmpSuccess = false;
        tmpOutcome = ERR.message;
    end        
    updateExports('Session events', file_session_csv_events, tmpSuccess,...
        tmpOutcome);
    
    % write logs
    try
        tmpSuccess = ECKSaveLog(path_sessions_logs, trialLog, false);
        tmpOutcome = '';
    catch ERR
        tmpSuccess = false;
        tmpOutcome = ERR.message;
    end        
    updateExports('Session logs', path_sessions_logs, tmpSuccess,...
        tmpOutcome);
    
    %% write task data

    numTasks = length(seg);
    for t = 1:numTasks

        % flags recording whether we have made a folder for each task's csv
        % and mat files (saves calling exist on each iteration of the loop)
        path_task_log_set = false;
        path_task_mat_set = false;

        % get task name
        task = seg{t}.Task;
        jobLabel = seg{t}.JobLabel;

        % get number of segments for this task, for this id
        numTasks = length(seg{t}.Segments);

        % make paths
        path_task = [path_tasks, filesep, jobLabel];
        path_task_csv = [path_task, filesep, 'csv', filesep, id];
        path_task_mat = [path_task, filesep, 'mat'];
        path_task_log = [path_task, filesep, 'logs', filesep, id];

        tryToMakePath(path_task_csv);
        if ~path_task_mat_set
            tryToMakePath(path_task_mat);
            path_task_mat_set = true;
        end

        if ~path_task_log_set
            tryToMakePath(path_task_log);
            path_task_log_set = true;
        end

        % make filenames
        file_task_mat = [path_task_mat, filesep, prefix,...
            jobLabel, '_', id, '_', wave, '.mat'];

        % save mat file
        data = seg{t};
        try
            save(file_task_mat, 'data', '-v6');
            tmpSuccess = exist(file_task_mat, 'file');
            tmpOutcome = '';
        catch ERR
            tmpSuccess = false;
            tmpOutcome = ERR.message;
        end        
        updateExports('Task mat', file_task_mat, tmpSuccess,...
            tmpOutcome);
        
        % save logs
        try
            tmpSuccess = ECKSaveLog(path_task_log, seg{t}.Log, false);
            tmpOutcome = '';
        catch ERR
            tmpSuccess = false;
            tmpOutcome = ERR.message;
        end        
        updateExports('Session logs', path_task_log, tmpSuccess,...
            tmpOutcome);
    
        % loop through segments (trials)

        numSegs = length(seg{t}.Segments);
        for s = 1:numSegs

            mb_seg = seg{t}.Segments(s).MainBuffer;
            tb_seg = seg{t}.Segments(s).TimeBuffer;
            eb_seg = seg{t}.Segments(s).EventBuffer;

            % make filenames
            file_task_csv_gaze = [path_task_csv, filesep,...
                id, '_', jobLabel, '_segment',...
                LeadingString('0000', s), '_GAZE.csv'];
            file_task_csv_events = [path_task_csv, filesep,...
                id, '_', jobLabel, '_segment',...
                LeadingString('0000', s), '_EVENTS.csv'];   

            % save csvs
            try
                ECKSaveETGazeTime(file_task_csv_gaze, mb_seg, tb_seg, false);
                tmpSuccess = exist(file_task_csv_gaze, 'file');
                tmpOutcome = '';
            catch ERR
                tmpSuccess = false;
                tmpOutcome = ERR.message;
            end        
            updateExports(['Task gaze', LeadingString('000', s)],...
                file_task_csv_gaze, tmpSuccess, tmpOutcome);                
                
            try
                ECKSaveETEvents(file_task_csv_events, eb_seg, false);
                tmpSuccess = exist(file_task_csv_events, 'file');
                tmpOutcome = '';
            catch ERR
                tmpSuccess = false;
                tmpOutcome = ERR.message;
            end        
            updateExports(['Task events', LeadingString('000', s)],...
                file_task_csv_events, tmpSuccess, tmpOutcome); 
            
        end

    end
    
    % if there is valid summary data, remove the first line containing the
    % default error message
    if size(exports, 1) > 1 && strcmpi(exports{1, 1}, 'UNKNOWN ERROR')
        exports = exports(2:end, :);
        success = success(2:end);
        outcome = outcome(2:end);
    end
    
    function updateExports(updatedExport, updatedFilename,...
            updatedSuccess, updatedOutcome)
    
        exports(end + 1, :) = {updatedExport, updatedFilename};
        success(end + 1) = updatedSuccess;
        outcome{end + 1} = updatedOutcome;
    
    end

end