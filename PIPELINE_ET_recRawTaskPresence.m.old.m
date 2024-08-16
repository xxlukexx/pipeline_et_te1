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
                
        % num trials scheduled per task
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
            m_sched = accumarray(task_s, taskList.NumTrials, [], @sum);
            numTasks = length(task_u);
        catch ERR
            oc{s} = ERR.message;
            continue
        end
        
        % num trials presented per task
        try
            
            % filter task list to remove non-presented items
            idx = true(size(taskList, 1), 1);
            s1 = length(idx) - tracker.ListRemainingSamples(idx_taskList) + 2;
            s2 = length(idx);
            idx(s1:s2) = false;
            taskList.NumTrials(~idx) = zeros(sum(~idx), 1);
            
%             % if num trials col is not numeric, remove non-numeric entries
%             % then convert to num
%             if iscell(taskList.NumTrials)
%                 idx_notNumeric = cellfun(@(x) isempty(x) ||...
%                     ~isnumeric(x) || ~isscalar(x), taskList.NumTrials);
%                 taskList(idx_notNumeric, :) = [];
%                 taskList.NumTrials = cell2mat(taskList.NumTrials);
%             end
            
            m_pres = accumarray(task_s, taskList.NumTrials, [], @sum);
            
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
            la{s}{t}.sched = m_sched(t);
            la{s}{t}.trials = m_pres(t);
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
    m_sched = accumarray([sig_s, task_s], tab_tall.trials, [], @sum);
    m_pres = accumarray([sig_s, task_s], tab_tall.sched, [], @sum);
    varNames_sched = cellfun(@(x) sprintf('%s_sched', x), task_u,...
        'UniformOutput', false);
    varNames_pres = cellfun(@(x) sprintf('%s', x), task_u,...
        'UniformOutput', false);    
    tab_sched =...
        array2table(m_sched, 'VariableNames', fixTableVariableNames(varNames_sched));
    tab_pres =...
        array2table(m_pres, 'VariableNames', fixTableVariableNames(varNames_pres)); 
    tab_wide = [tab_sched, tab_pres];
    parts = cellfun(@(x) strsplit(x, '#'), sig(sig_i), 'UniformOutput', false);
    tab_wide.id = cellfun(@(x) x{1}, parts, 'UniformOutput', false);
    tab_wide.wave = cellfun(@(x) x{2}, parts, 'UniformOutput', false);
    tab_wide.Properties.VariableNames(3:end) = sort(tab_wide.Properties.VariableNames(3:end));
    
    % append wave to tall and wide tables
    tab_tall.wave = repmat({wave}, size(tab_tall, 1), 1);
    tab_wide.wave = repmat({wave}, size(tab_wide, 1), 1);
    
    tab_wide = movevars(tab_wide, {'id', 'wave'}, 'before', tab_wide.Properties.VariableNames{1});
    
%     file_out_tall = sprintf('RawTaskPresence_tall_%s.xlsx', datestr(now, 30));
%     file_out_wide = sprintf('RawTaskPresence_wide_%s.xlsx', datestr(now, 30));
%     writetable(tab, file_out_tall)
%     writetable(tab_wide, file_out_wide)
    

end