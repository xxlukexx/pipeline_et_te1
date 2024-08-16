function [op, dataKey] = PIPELINE_ET_doPreProc(path_main, data, dataKey,...
    tse, trf, ftfix, doSave, customEditFcn)

    % default to not custom edit function
    if ~exist('customEditFcn', 'var') 
        customEditFcn = [];
    end
   
    % make output paths
    path_raw                = [path_main, filesep, '01_raw'];
    path_frametimes         = [path_main, filesep, '03_frametimes'];
    path_segment            = [path_main, filesep, '04_segment'];
    path_export             = [path_main, filesep, '05_export'];
    path_sessions           = [path_export, filesep, 'sessions'];
    path_tasks              = [path_export, filesep, 'tasks'];
    path_summary            = [path_main, filesep, '99_summary'];
    path_summary_seg        = [path_summary, filesep, 'seg'];
    path_export_breakdown   = [path_summary, filesep, 'export'];
    tryToMakePath(path_raw);
    tryToMakePath(path_frametimes);
    tryToMakePath(path_segment);
    tryToMakePath(path_export);
    tryToMakePath(path_export_breakdown);
    tryToMakePath(path_sessions);
    tryToMakePath(path_tasks);
    tryToMakePath(path_summary);
    tryToMakePath(path_summary_seg);
    % get path, id, site, wave vars
    pth                     = data.path;
    id                      = data.id;
    site                    = data.site; 
    wave                    = data.wave;
    % operation counter
    opIdx                   = 1; 

    try

        % load
        if isfield(data, 'raw') && isa(data.raw, 'ECKData')
            if ~data.raw.Loaded
                data.raw.Load(data.path);
            end
            data_orig = data.raw;
        else
            data_orig = ECKData;
            data_orig.Load(data.path);
        end
        
        % extract ID/timepoint/site form data if requested (otherwise use
        % the passed values)
        if ischar(id) && strcmp(id, '<FROMDATA>')
            id = data_orig.ParticipantID;
        else
            data_orig.ParticipantID = id;
        end
        if ischar(wave) && strcmp(wave, '<FROMDATA>')
            wave = data_orig.TimePoint;
        else
            data_orig.TimePoint = wave;
        end
        if ischar(site) && strcmp(site, '<FROMDATA>')
            site = data_orig.Site;
        else 
            data_orig.Site = site;
        end
        
    % optioanlly call a custom edit function to do pre-pre-processing on
    % the data. This might include eg editing event labels to make them
    % suitable for segmentation. This function can do anything to the
    % loaded data, and returns the data it is passed in its edited state
    
        if ~isempty(customEditFcn)
            data_orig = feval(customEditFcn, data_orig);
        end
        
    % transform ref frame. This can be done (or not done) globally (for
    % all datasets), or it can be set on a per-task or per-site basis.
    % These latter options operate via trf.adb_idx. This is a vector of
    % indices, each being a data key in the analysis database (adb). If
    % a datakey (adb index) is found in trf.adb_idx then the reference
    % frame is transformed, otherwise it is not. In practice, the
    % trf.perTask and trf.perSite fields do not in themselves do
    % anything - trf.adb_idx can flag datasets that need a transform by
    % site of by task. However, these .perTask and .perSite fields are
    % kept because they made the code more readable.
    
        if isfield(trf, 'perSubject') && trf.perSubject &&...
                isfield(trf, 'adb_idx')
            % if a per-subject setting is in effect, compare the datakey of
            % the current dataset with the index and apply transform
            % accordingly
            if dataKey <= length(trf.adb_idx)
                transformRefFrame = trf.adb_idx(dataKey);
                
            else
                % datakey not found in index - throw warning and default to
                % not transforming
                warning('Datakey not found in trf.adb_idx - trf DEFAULTS TO FALSE.')
                transformRefFrame = false;
                
            end
        else
            % no per-subject setting, so use the global flag set in the trf
            % structure
            transformRefFrame = trf.transformRefFrame;
            
        end
                    
    % if we are transforming ref frame on a per-session or per-dataset
    % (but for the entire session) basis, then do this here. If we are
    % doing it on a per-task basis, it needs to get done during
    % segmentation (below)
    
        try
            if transformRefFrame && ~trf.perTask
                % transform
                [...
                    data_refframe,...
                    tfSuc,...
                    tfOc,...
                    tfWindowSize,...
                    tfMonitorSize,...
                ] =...
                    PIPELINE_ET_transformRefFrame(data_orig,...
                        trf.windowSize, trf.monitorSize);
                % log operation
                op{opIdx}.Operation                 = 'TransformRefFrame';
                op{opIdx}.Success                   = tfSuc;
                op{opIdx}.Outcome                   = tfOc;
                op{opIdx}.ExtraData.windowSize      = tfWindowSize;
                op{opIdx}.ExtraData.monitorSize     = tfMonitorSize;
                opIdx                               = opIdx + 1;
                
            else
                % copy data to new variable
                data_refframe                       = data_orig;
                
            end
            
        catch ERR
            % log error
            data_refframe                           = data_orig;
            op{opIdx}.Operation                     = 'TransformRefFrame_ERROR';
            op{opIdx}.Success                       = false;
            op{opIdx}.Outcome                       = ERR.message;
            opIdx                                   = opIdx + 1;  
            
        end

    % fix frame times
        if ~isempty(ftfix)
            try
                [...
                    data_ft,...
                    ftSuc,...
                    ftOc,...
                    ftCorr,...
                    rtCorr,...
                ] =...
                    PIPELINE_ET_fixFrameTimes(data_refframe, ftfix);
                % put frame time results in separate op for each video
                numOps = length(ftSuc);
                for o = 1:numOps
                    op{opIdx}.Operation = ['FixFrameTimes_', ftfix{o, 3}];
                    op{opIdx}.Success = ftSuc(o);
                    op{opIdx}.Outcome = ftOc{o};
                    op{opIdx}.ExtraData.ftCorr = ftCorr(o);
                    op{opIdx}.ExtraData.rtCorr = rtCorr(o);
                    opIdx = opIdx + 1;
                end

            catch ERR
                op{opIdx}.Operation = 'FixFrameTimes_ERROR';
                op{opIdx}.Success = false;
                op{opIdx}.Outcome = ERR.message;
                opIdx = opIdx + 1;
                data_ft = data_orig;

            end
        else
            data_ft = data_orig;
        end
        
        % segment
        try
            [...
                tmp,...
                ~,...
                smry_seg_suc,...
                smry_seg_oc...
            ] =...
                PIPELINE_ET_segment(data_ft, tse.taskSegmentEvents, trf);
                data_seg = tmp.Data{1};
            % record operations
            numOps = size(smry_seg_oc, 1);
            for o = 1:numOps
                op{opIdx}.Operation = ['Segment_', smry_seg_oc{o, 1}];
                op{opIdx}.Success = smry_seg_suc(o);
                op{opIdx}.Outcome = 'Success';
                opIdx = opIdx + 1;
            end
            
        catch ERR
            op{opIdx}.Operation = 'Segment_ERROR';
            op{opIdx}.Success = false;
            op{opIdx}.Outcome = ERR.message;
            opIdx = opIdx + 1;
            
        end
        
        % save 
        if doSave
%             file_frametimes = fullfile(path_frametimes, [id, '_', wave, '.frametimes.mat']);
%             parsave(file_frametimes, data_ft, '-v6');  

%             file_seg = fullfile(path_segment, [id, '_', wave, '.seg.mat']);
%             parsave(file_seg, data_seg, '-v6'); 

            % export
            try
                % produce summary reports 
                [summary_exports, smry_export_suc, smry_export_oc] =...
                    etExport(data_seg, path_sessions, path_tasks, [], id, wave);       
                % make filenames
                file_seg_detail = [path_summary_seg, filesep,...
                    id, '_', wave, '_segdetail.csv'];
                file_export_breakdown = [path_export_breakdown, filesep,...
                    id, '_', wave, '_export.csv'];
                % write
                csvwritecell(file_seg_detail, smry_seg_oc, false);
                csvwritecell(file_export_breakdown, [summary_exports,...
                    num2cell(smry_export_suc)', smry_export_oc'], false);
                
            catch ERR
                op{opIdx}.Operation = 'Save_ERROR';
                op{opIdx}.Success = false;
                op{opIdx}.Outcome = ERR.message;
                opIdx = opIdx + 1;
            end
            
        else
            % if save was disabled, log this
            op{opIdx}.Operation = 'Save_ERROR';
            op{opIdx}.Success = false;
            op{opIdx}.Outcome = 'Save was disabled in script.';
            opIdx = opIdx + 1;
            
        end
        
        op{opIdx}.Operation = 'PIPELINE_ET_doPreProc';
        op{opIdx}.Success = true;
        op{opIdx}.Outcome = 'Success';
        opIdx = opIdx + 1;

    catch ERR

        op{opIdx}.Operation = 'PIPELINE_ET_doPreProc';
        op{opIdx}.Success = false;
        op{opIdx}.Outcome = [ERR.message,...
            cell2char(reshape(struct2cell(ERR.stack), 1, []))];
        opIdx = opIdx + 1;
        return

    end

end

