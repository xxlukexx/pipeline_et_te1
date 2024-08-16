function dq = PIPELINE_ET_dataQuality(path_session, screenSize)

    % check input arg
    if ~exist('path_session', 'var')
        error('Must specify an export session folder.')
    end
    
    % check session path
    if ~exist(path_session, 'dir')
        error('Export session folder not found.')
    end

    % if screen size is not passed, assume 23" 16:9 (TX-300)
    if ~exist('screenSize', 'var') || isempty(screenSize)
        screenSize = [50.9, 28.6];
        warning('Screen size assumed to be 23" 16:9 (TX-300).')
    end
   
    % find files
    stat = ECKStatus(sprintf('Finding files in %s...\n', path_session));
    d = dir([path_session, filesep, '*.mat']);
    if isempty(d) 
        error('No files found in: %s', path_session)
    end
    numFiles = length(d);
    
    for f = 1:numFiles
        
        clear datafile
        
        % get filename
        filename = fullfile(path_session, d(f).name);
        
        % send to worker
        fut(f) = parfeval(@PIPELINE_ET_doDataQuality, 3, filename, screenSize);
        stat.Status = sprintf('Sending jobs %d of %d to worker...\n',...
            f, numFiles);

%         [suc, oc, res] = PIPELINE_ET_doDataQuality(filename, screenSize);
        
    end

    % wait for jobs to finish, receive results
    suc = false(numFiles, 1);
    oc = cell(numFiles, 1);
    res = cell(numFiles, 1);
    for f = 1:length(fut)
        
        % get results from worker
        [idx, tmpSuc, tmpOC, tmpRes] = fetchNext(fut);
        suc(f) = tmpSuc;
        oc{f} = tmpOC;
        res{f} = tmpRes;
        res{f}.outcome = tmpOC;
        res{f}.success = tmpSuc;
        stat.Status = sprintf('Received job %d from worker (%.1f%%)...', idx,...
            (f / length(fut)) * 100);
        
    end
    
    % check success
    if ~all(suc)
        fprintf('%d of %d failed.\n', sum(~suc), length(suc));
    end
    
    % collate
%     dq = struct2table(vertcat(res{:}));
    dq = teLogExtract(res);
    
    dq(:, {'EyeValidity', 'EyeValidityLabels', 'EyeValidityTimeSeries',...
        'FlickerPairs', 'GapHist', 'SampleFrequencyTimeSeries',...
        'TimeVector'}) = [];
    
    % convert cell columns to numeric
    dq = tableCellColumns2Numeric(dq);
    
    
    
end