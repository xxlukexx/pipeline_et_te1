function [tasks, results, path_res] = PIPELINE_ET_findExportedTaskData(path_preproc)

    tasks = teCollection('char');
    results = teCollection('char');
    
    % check path exists
    if ~exist(path_preproc, 'dir')
        error('Path not found: %s', path_preproc)
    end
    
    % look for export folder
    path_export = fullfile(path_preproc, '05_export');
    if ~exist(path_export, 'dir')
        error('Export path not found in preproc folder: %s', path_export)
    end
    
    % look for results folder
    path_res = fullfile(path_preproc, '06_results');
    tryToMakePath(path_res);
    
    % look for tasks folder
    path_tasks = fullfile(path_export, 'tasks');
    if ~exist(path_tasks, 'dir')
        error('''tasks'' folder not found in export folder: %s', path_tasks)
    end
    
    % find individual tasks
    allTasks = dir(path_tasks);
    allTasks(~[allTasks.isdir]) = [];
    idx_crap = ismember({allTasks.name}, {'.', '..'});
    allTasks(idx_crap) = [];
    
    for t = 1:length(allTasks)
        
        % strip _trial off task name
        taskName = strrep(allTasks(t).name, '_trial', '');

        % find task folder
        taskFolder = fullfile(path_tasks, allTasks(t).name);
    
        % look for mat folder
        path_mat = fullfile(taskFolder, 'mat');
        if ~exist(path_mat, 'dir')
            error('''mat'' folder not found: %s', path_mat)
        end
        
        % store task path
        tasks(taskName) = path_mat;
        
        % make results folder
        path_task_res = fullfile(path_res, taskName);
        tryToMakePath(path_task_res);
        results(taskName) = path_task_res;
        
    end

end