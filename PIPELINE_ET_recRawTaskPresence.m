function [tab_tall, tab_wide] = PIPELINE_ET_recRawTaskPresence(path_raw, wave)
    
    allSes = recSessionFolders(path_raw);
    
    tic
    
    numSes = length(allSes);
    suc = false(numSes, 1);
    oc = cell(numSes, 1);
    la = cell(numSes, 1);
    parfor s = 1:numSes
        
        fprintf('Scanning %d of %d: %s\n', s, numSes, allSes{s});
        
        % find and load tracker
        file_tracker = teFindFile(allSes{s}, '*tracker.mat');
        if ~isempty(file_tracker)
            tmp = load(file_tracker);
            tracker = tmp.trackInfo;
        else
            oc{s} = 'tracker.mat not found';
            continue
        end
        
        % find task list
        idx_taskList = find(strcmpi(tracker.ListName, 'task list'), 1);
        if ~isempty(idx_taskList)
            taskList = ECKTrackerList2Table(tracker, idx_taskList);
        else
            oc{s} = 'task list not found';
            continue
        end
        
        % count trials per task
        try
            
            % if num trials col is not numeric, remove non-numeric entries
            % then convert to num
            if iscell(taskList.NumTrials)
                idx_notNumeric = cellfun(@(x) isempty(x) ||...
                    ~isnumeric(x) || ~isscalar(x), taskList.NumTrials);
                taskList(idx_notNumeric, :) = [];
                taskList.NumTrials = cell2mat(taskList.NumTrials);
            end
            
            [task_u, ~, task_s] = unique(taskList.TaskName);
            m = accumarray(task_s, taskList.NumTrials, [], @sum);
            numTasks = length(task_u);
        catch ERR
            oc{s} = ERR.message;
            continue
        end
        
        % find ID
        try
            if isfield(tracker, 'ParticipantID') && isfield(tracker, 'TimePoint')
                id = tracker.ParticipantID;
                tp = tracker.TimePoint;
            else
                % some (earlier?) trackers don't have ID/timepoint, so we have
                % to resort to loading an ECKData instance to get it
                data = ECKData;
                data.Load(allSes{s});
                id = data.ParticipantID;
                tp = data.TimePoint;
            end
        catch ERR
            oc{s} = ERR.message;
            continue
        end
        
        % store in log array
        la{s} = cell(numTasks, 1);
        for t = 1:numTasks
            la{s}{t} = struct;
            la{s}{t}.id = id;
            la{s}{t}.wave = tp;
            la{s}{t}.task = task_u{t};
            la{s}{t}.trials = m(t);
        end
        
        suc(s) = true;
        oc{s} = 'OK';

    end
    
    tab_tall = teLogExtract(vertcat(la{:}));
    if ~isnumeric(tab_tall.wave)
        tab_tall.wave = cell2mat(extractNumeric(tab_tall.wave));
    end
    
    
    [sig, sig_u, sig_i, sig_s] = makeSig(tab_tall, {'id', 'wave'});
    [task_u, ~, task_s] = unique(tab_tall.task);
    m = accumarray([sig_s, task_s], tab_tall.trials, [], @sum);
    tab_wide = array2table(m, 'VariableNames', fixTableVariableNames(task_u));
    parts = cellfun(@(x) strsplit(x, '#'), sig(sig_i), 'UniformOutput', false);
    tab_wide.id = cellfun(@(x) x{1}, parts, 'UniformOutput', false);
    tab_wide.wave = cellfun(@(x) x{2}, parts, 'UniformOutput', false);
    tab_wide = movevars(tab_wide, {'id', 'wave'}, 'before', tab_wide.Properties.VariableNames{1});
    
    % append wave to tall and wide tables
    tab_tall.wave = repmat({wave}, size(tab_tall, 1), 1);
    tab_wide.wave = repmat({wave}, size(tab_wide, 1), 1);
    
%     file_out_tall = sprintf('RawTaskPresence_tall_%s.xlsx', datestr(now, 30));
%     file_out_wide = sprintf('RawTaskPresence_wide_%s.xlsx', datestr(now, 30));
%     writetable(tab, file_out_tall)
%     writetable(tab_wide, file_out_wide)
    

end