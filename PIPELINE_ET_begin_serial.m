function adb = PIPELINE_ET_begin_serial(adb, path_main, tse, trf, ftfix, doSave)
% PIPELINE_ET_begin(adb, path_main, tse, trf, ftfix, doSave) batch script
% to send data in an ECKAnalysisDB to parallel computing workers for
% processing. This function calls the generic PIPELINE_ET_doPreProc
% function for each raw dataset. 
%
% abd       - instance of ECKAnalysisDB containing data to be processed
% path_main - output path
% tse       - task segmentation definition
% trf       - reference frame transformation structure. Leave empty if not
%             required, or if reference frame is not being transformed
% ftfix     - frame time fix definition
% doSave    - flag to save output (set to false for faster testing)

% % check pool 
% p = gcp('nocreate');
% if isempty(p), p = parpool('imac', 16); end
% p.addAttachedFiles({'copyHandleClass.m', 'delta.m'});

% check whether we are transforming ref frame
if ~exist('trf', 'var') || isempty(trf)
    trf.transformRefFrame = false;
else
    % check for per-task transform option
    if ~isfield(trf, 'perTask')
        trf.perTask = false;
    end
    % check for per-site transform option
    if ~isfield(trf, 'perSite')
        trf.perSite = false;
    end
end

% send jobs to workers
stat = ECKStatus('Sending jobs to workers...');
clear fut

if adb.NumProcNeeded == 0
    return
end

d = 1;
while adb.NumProcNeeded > 0 
    
    clear data
    
    % get details of next dataset to process
    [~, data.path, data.id, data.site, data.wave, dataKey] = adb.GetNext;
    data.raw = [];
        
    adb.ProcFinished(dataKey)

%     profile on
    dbstop in PIPELINE_ET_begin_serial at 55
    [q, e] = PIPELINE_ET_doPreProc(path_main, data, dataKey, tse, trf, ftfix, doSave);
%     profile off
%     profile viewer
    
    d = d + 1;
end

% wait for jobs to finish, receive results
wb = waitbar(0, 'Waiting for first job to finish...');
for d = 1:length(fut)
    % get results from worker
    [idx, op, dataKey] = fetchNext(fut);
    % store operations
    if ~isempty(op)
        adb.AddOp(dataKey, op)
%         adb.ProcFinished(dataKey);
    end
    % save progress
    try
        save(fullfile(path_main, 'adb.mat'), 'adb')
    catch ERR_save
        warning('Error when saving adb: %s', ERR_save.message)
    end
    msg = sprintf('Received job %d from worker (%.1f%%)...', idx,...
        (d / length(fut)) * 100);
    stat.Status = msg;
    wb = waitbar(d / length(fut), wb, msg);
end

% make headers for frametime variables
parts = cellfun(@(x) strsplit(x, '_'), ftfix(:, 1), 'uniform', false);
ftLabs = cellfun(@(x) x{1}, parts, 'uniform', false);
numFt = size(ftfix, 1);
ftHdr = {...
    sprintf('frametimes_suc_%s', ftLabs{:}),...
    sprintf('frametimes_oc_%s', ftLabs{:}),...
    sprintf('frametimes_ftcorr_%s', ftLabs{:}),...
    sprintf('frametimes_rtcorr_%s', ftLabs{:}),...
    };

% make table headers
tasks = tse.taskSegmentEvents(:, 1);
hdr = [...
    'ID',...
    'frametimes_success',...
    ftHdr,...
    cellfun(@(x) ['seg_', x, '_success'], tasks, 'uniform', 0)',...
    cellfun(@(x) ['seg_', x, '_numSegs'], tasks, 'uniform', 0)',...
    cellfun(@(x) ['seg_', x, '_outcome'], tasks, 'uniform', 0)',...
    'dataset_success',...
    'dataset_outcome',...
    'GUID',...
];

% % strip ID from summary 
% summary = cell2table(vertcat(tmpSummary{:}));
% summary.Var1 = [];
% summary.Properties.VariableNames = hdr;
% dbtab = outerjoin(dbtab, summary, 'Keys', 'GUID');
% if isempty(tmpFailed)
%     failed = table({'NONE'}, {'NONE'});
% else
%     failed = cell2table(vertcat(tmpFailed{:}));
% end
% failed.Properties.VariableNames = ({'Path', 'Outcome'});

% write summary
% idx = summary.Dataset;
% summary.fullpath = sessions(idx);
% file_dataset = [path_summary, filesep, 'dataset.csv'];
% writetable(summary, file_dataset);
% file_failed = [path_summary, filesep, 'failed.csv'];
% writetable(failed, file_failed);

delete(wb)

end