function adb = PIPELINE_ET_begin(adb, path_main, tse, trf, ftfix, doSave, doSerial, customEditFcn)
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
% doSerial  - flag to instruct the pipeline to operate in serial, not
%             parellel mode

% % check pool 
% p = gcp('nocreate');
% if isempty(p), p = parpool('imac', 16); end
% p.addAttachedFiles({'copyHandleClass.m', 'delta.m'});

if ~exist('doSerial', 'var')
    doSerial = false;
end

% default is not custom edit function
if ~exist('customEditFcn', 'var')
    customEditFcn = [];
end

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

% check whether we are fixing frametimes
if ~exist('ftfix', 'var') 
    ftfix = [];
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
        
    switch doSerial
        
        case false

            % send to worker
            fut(d) = parfeval(@PIPELINE_ET_doPreProc, 2, path_main,...
                data, dataKey, tse, trf, ftfix, doSave, customEditFcn);
            % save progress
            save(fullfile(path_main, 'adb.mat'), 'adb')
            stat.Status = sprintf('Sending jobs to workers...%d remaining...',...
                adb.NumProcNeeded);

            % random wait
%             if d > 1 && d < 12
%                 pauseDur = 7 + (rand * 7);
%                 stat.Status = sprintf('Pausing for %.1fsecs before sending %0d...',...
%                     pauseDur, d);        
%                 pause(pauseDur);
%             end

            adb.ProcFinished(dataKey)
            
        case true

%             profile on
            [q, e] = PIPELINE_ET_doPreProc(path_main, data, dataKey, tse, trf, ftfix, doSave, customEditFcn);
            adb.ProcFinished(dataKey)
%             profile off
%             profile viewer
            
    end
    
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
if ~isempty(ftfix)
    parts = cellfun(@(x) strsplit(x, '_'), ftfix(:, 1), 'uniform', false);
    ftLabs = cellfun(@(x) x{1}, parts, 'uniform', false);
    numFt = size(ftfix, 1);
    ftHdr = {...
        sprintf('frametimes_suc_%s', ftLabs{:}),...
        sprintf('frametimes_oc_%s', ftLabs{:}),...
        sprintf('frametimes_ftcorr_%s', ftLabs{:}),...
        sprintf('frametimes_rtcorr_%s', ftLabs{:}),...
        };
else
    ftHdr = [];
end

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