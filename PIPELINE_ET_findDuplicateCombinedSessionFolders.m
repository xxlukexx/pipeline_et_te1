function [idx_isTarget, oc, toDelete] = PIPELINE_ET_findDuplicateCombinedSessionFolders(path_sub)

    oc = 'unknown error';
    idx_isTarget = [];
    toDelete = {};
    
    % ensure that there is a _precombine folder in the subject folder
    path_pc = fullfile(path_sub, '_precombine');
    if ~exist(path_pc, 'dir')
        oc = 'No _precombine folder: not a candidate.';
        return
    end
    
    % find all session folders in this path
    ses = recSessionFolders(path_sub);
    
    % remove any with _precombine in the path -- these are expanded zip
    % files, the copy of the original session folders before they were
    % orignally combined
    pattern = sprintf('%s_precombine%s', filesep, filesep);
    idx_containsPreCombine = cellfun(@(x) contains(x, pattern), ses);
    ses(idx_containsPreCombine) = [];
    if isempty(ses)
        oc = 'All sessions contained ''precombine''.';
        return
    elseif length(ses) == 1
        oc = 'Only one session remained after removing ''precombine'' folders.';
        return
    end        
    
    numSes = length(ses);
%     % find the size of the tempData.mat file in each session -- target
%     % session should be the largest
%     numSes = length(ses);
%     d = cell(numSes, 1);
%     for s = 1:numSes
%         path_td = fullfile(ses{s}, 'tempData.mat');
%         if exist(path_td, 'file')
%             d{s} = dir(path_td);
%         end
%     end
%     idx_emptySession = cellfun(@isempty, d);
%     toDelete = [toDelete, ses{idx_emptySession}];
%     d(idx_emptySession) = [];
%     ses(idx_emptySession) = [];
%     numSes = length(ses);
%     md_tempData = teLogExtract(d);
%     idx_largestTempData = md_tempData.bytes == max(md_tempData.bytes);
%     if ~any(idx_largestTempData)
%         oc = 'No largest tempData.mat file could be found.';
%         return
%     elseif sum(idx_largestTempData) > 1
%         oc = 'Multiple tempData.mat files were largest of all sessions.';
%         return
%     end
    
%     % all folders other than the target should be newer than the target
%     targDate = md_tempData.datenum(idx_largestTempData);
%     otherDates = md_tempData.datenum(~idx_largestTempData);
%     targetHasEarliestData = all(otherDates > targDate);
%     if ~targetHasEarliestData
%         oc = 'Target folder did not have earliest time/data stamp.';
%         return
%     end
    
    
    % target should have duplicated buffers in /gaze folder
    hasDupBuffers = false(numSes, 1);
    path_mb = cell(numSes, 1);
    path_tb = cell(numSes, 1);
    path_eb = cell(numSes, 1);
    parfor s = 1:numSes
        path_mb{s} = teFindFile(fullfile(ses{s}, 'gaze'), '*mainBuffer*.mat');
        dup_mb = iscell(path_mb{s}) && length(path_mb{s}) > 1;
        path_tb{s} = teFindFile(fullfile(ses{s}, 'gaze'), '*timeBuffer*.mat');
        dup_tb = iscell(path_tb{s}) && length(path_tb{s}) > 1;
        path_eb{s} = teFindFile(fullfile(ses{s}, 'gaze'), '*eventBuffer*.mat');    
        dup_eb = iscell(path_eb{s}) && length(path_eb{s}) > 1;
        hasDupBuffers(s) = dup_mb && dup_tb && dup_eb;
    end
    
    % determine whether we have a target
%     idx_isTarget = idx_largestTempData & hasDupBuffers;
    idx_isTarget = hasDupBuffers;
    if ~any(idx_isTarget)
        oc = 'Target not found.';
        return
    end
    
    % find which duplicated buffers to delete -- this will be the largest
    % and the earliest

    
    % build list of files to delete
    
        % 1. non-target session folders
        toDelete = [toDelete; ses(~idx_isTarget)];
        
        % 2. duplicated buffer files
        path_mb = path_mb{idx_isTarget};
        idx_wanted_mb = findLargestAndEarliest(path_mb);
        path_tb = path_tb{idx_isTarget};
        idx_wanted_tb = findLargestAndEarliest(path_tb);
        path_eb = path_eb{idx_isTarget};
        idx_wanted_eb = findLargestAndEarliest(path_eb);
        if ~isequal(idx_wanted_mb, idx_wanted_tb, idx_wanted_eb)
            oc = 'Largest and earliest duplicate buffers were not consistant across main/time/event.';
            return
        end
        toDelete{end + 1, 1} = path_mb{~idx_wanted_mb};
        toDelete{end + 1, 1} = path_tb{~idx_wanted_tb};
        toDelete{end + 1, 1} = path_eb{~idx_wanted_eb};
        
    oc = 'Candidate';

end

function idx = findLargestAndEarliest(path_search)

    numPaths = length(path_search);
    sz = nan(numPaths, 1);
    dt = nan(numPaths, 1);
    for i = 1:numPaths
        d = dir(path_search{i});
        sz(i) = d.bytes;
        dt(i) = d.datenum;
    end
        
    idx_largest = sz == max(sz);
    idx_earliest = dt == min(dt);
    idx = idx_largest & idx_earliest;

end