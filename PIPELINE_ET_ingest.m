function adb = PIPELINE_ET_ingest(path_raw, site, wave, adb)

    % Finds raw ET data and ingests it into the pipeline. All data is
    % copied from path_raw to path_preproc for later preprocessing.
    %
    % path_raw          Input path. Will be searched recursively for
    %                   session folder
    % site              Optional site identifier.
    % wave              Optional wave identifier. E.g. timepoint/visit,
    %                   schedule, arm of study etc.
    
    % check site variable
    if ~exist('site', 'var'), site = []; end
    if ~iscell(site), site = {site}; end
    emptySite = cellfun(@isempty, site);
    if any(emptySite)
        site(emptySite) = repmat({'NONE'}, sum(emptySite), 1);
    end

    % check wave variable
    if ~exist('wave', 'var'), wave = []; end
    if ~iscell(wave), wave = {wave}; end
    emptyWave = cellfun(@isempty, wave);
    if any(emptyWave)
        site(emptyWave) = repmat({'NONE'}, sum(emptyWave), 1);
    end   
    
    % check for existing database having been passed
    if exist('adb', 'var') && ~isempty(adb)
        existingData = true;
    else
        existingData = false;
        adb = ECKAnalysisDB;
    end

    % check raw path    
    if ~exist('path_raw', 'var')
        error('Must supply an input path.')
    end
    
    % find data
    stat = ECKStatus(sprintf('<strong>Searching for valid sessions...</strong>\n'));
    ses = {};
    waveTmp = {};
    siteTmp = {};
    if ~iscell(path_raw), path_raw = {path_raw}; end
    numPaths = length(path_raw);
    sesTmp = cell(1, numPaths);
    parfor p = 1:numPaths
        fprintf('\nSearching path %d of %d: %s...\n', p, numPaths, path_raw{p});
        sesTmp{p} = recSessionFolders(path_raw{p});
    end
    
    fprintf('Ingesting %d sessions...\n', cellfun(@length, sesTmp))
    for p = 1:numPaths
        for s = 1:length(sesTmp{p})
            adb.Ingest(sesTmp{p}{s}, site{p}, wave{p});
        end    
    end
    nd = size(ses, 1);
    
    % check for dups
    if adb.HasDuplicates
        msg = [...
            '<strong>Duplicate IDs were found. Refer to DuplicateTable property\n',...
            'for a complete list. If you continue with preprocessing, each\n',...
            'duplicate will be treated as a unique dataset. Therefore you\n',...
            'should fix the duplicates first.\n\n\n</strong>'];
        fprintf(2, msg)
    end
  
end