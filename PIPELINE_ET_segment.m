function [data, tasks, success, outcome] =...
    PIPELINE_ET_segment(data, taskSegmentEvents, trf)
  
    numTasks = size(taskSegmentEvents, 1);
    data = checkDataIn(data);
    
    success = false(numTasks, 1);
    outcome = repmat({data.Data{1}.ParticipantID, 'ERROR', false,...
        false, 'UNKNOWN ERROR'}, [numTasks, 1]);
    tasks = cellstr(repmat('ERROR', [numTasks, 1]));
    summaries = cell(numTasks, 1);
    
    % check for per-task ref frame transform
    if ~exist('trf', 'var') || isempty(trf)
        trf.transformRefFrame = false;
    elseif ~isfield(trf, 'perTask')
        trf.perTask = false;
    end
    
    % loop through task definitions
    for t = 1:numTasks
        
        tasks{t} = taskSegmentEvents{t, 1};

        try
            
            % get task name, and trial on/offset events
            jobLabel = taskSegmentEvents{t, 1};
            task = taskSegmentEvents{t, 2};
            onset = taskSegmentEvents{t, 3};
            offset = taskSegmentEvents{t, 4};

            cfg = struct;
            cfg.type = 'labelpairs';
            cfg.outputtype = 'inline';
            cfg.onsetlabel = onset;
            cfg.onsetlabelexactmatch = taskSegmentEvents{t, 5};
            cfg.offsetlabel = offset;
            cfg.offsetlabelexactmatch = taskSegmentEvents{t, 6};
            cfg.takefirstoffset = taskSegmentEvents{t, 6};
%             cfg.droporphanedonsets = true;
            cfg.matchneighbours = true;
            cfg.label = strrep(task, '_trial', '');
            cfg.joblabel = jobLabel;
            cfg.task = task;
%             cfg.task = strrep(task, '_trial', '');
            if trf.perTask
                cfg.trf = trf;
            end
            [data, summary] = etSegment(data, cfg);
            
            % remove summary header
            summary = summary(2:end, :);
            
            % store success/results
            success(t) = all(cell2mat(summary(:, 3)));
            outcome(t, :) = {tasks{t}, summary{1, 2}, success(t),...
                sum(cell2mat(summary(:, 4))), ''};
            
        catch ERR

            success(t) = false;
            outcome{t} = ERR.message;
            
        end

    end

end