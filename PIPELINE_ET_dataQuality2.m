function PIPELINE_ET_dataQuality(path_preproc, screenSize)

    if ~exist(path_preproc, 'dir')
        error('Preproc folder not found at: %s', path_preproc)
    end

    % if screen size is not passed, assume 23" 16:9 (TX-300)
    if ~exist('screenSize', 'var') || isempty(screenSize)
        screenSize = [50.9, 28.6];
        warning('Screen size assumed to be 23" 16:9 (TX-300).')
    end
    
    % build path to sessions
    path_sesRoot = fullfile(path_preproc, '05_export', 'sessions', 'mat');
    if ~exist(path_sesRoot, 'dir')
        error('Session output folder not found at: %s', path_sesRoot)
    end
    d = dir(path_sesRoot);
    d([d.isdir] | ismember({d.name}, {'.', '..'})) = [];
    file_mat = cellfun(@(pth, fil) fullfile(pth, fil), {d.folder},...
        {d.name}, 'UniformOutput', false)';
    numSes = length(file_mat);    
    
    
    % task DQ
    la = {};
    for s = 1:numSes
            
            try
                
                % load data
                tmp = load(file_mat{s});
                if ~isfield(tmp, 'data')
                    la_tmp{f}.success = false;
                    la_tmp{f}.outcome = 'No .data variable in file';
                    continue
                end
                
                [dq, smry] = etDataQualityMetric3(tmp.data.MainBuffer,...
                    tmp.data.TimeBuffer, tmp.data.EventBuffer, screenSize)
                
                
                
            catch ERR
                la_tmp{f}.success = false;
                la_tmp{f}.outocme = sprintf('Error loading file: %s', ERR.message);
                continue
            end
            
            
            
            
        end
        
    end

    % session DQ
    







end