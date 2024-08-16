function [suc, oc, res] = PIPELINE_ET_doDataQuality(filename, screenSize)

    if ~exist('screenSize', 'var')
        screenSize = [];
    end
    
    % check file
    res = struct;
    if ~exist(filename, 'var')
        suc = false;
        oc = 'File not found';
    end
    
    % load
    try
        tmp = load(filename);
    catch ERR
        suc = false;
        oc = sprintf('Load error: %s', ERR.message);
        return
    end
    
    % data quality
    try

        % calculate data quality from session
        res = etDataQualityMetric3(tmp.data.MainBuffer, tmp.data.TimeBuffer,...
            tmp.data.EventBuffer);

        % add metadata
        res.ID = tmp.data.ParticipantID;
        res.Wave = tmp.data.Schedule;
        res.Site = tmp.data.Site;

        % accuracy and precision from phc, fixation points and gap stimuli
        [~, phc] = phc_extract(tmp.data);
        [res.Accuracy, res.Precision] =...
            etCalculateDrift(phc.px, phc.py, phc.gx, phc.gy);

        % try to provice accuracy and precision in degrees, if screen size
        % has been passed
        if ~isempty(screenSize)
            [px_deg, py_deg] = norm2deg(phc.px, phc.py, screenSize(1),...
                screenSize(2), 60);
            [gx_deg, gy_deg] = norm2deg(phc.gx, phc.gy, screenSize(1),...
                screenSize(2), 60);
            [res.AccuracyDeg, res.PrecisionDeg] =...
                etCalculateDrift(px_deg, py_deg, gx_deg, gy_deg);
        else
            res.AccuracyDeg = nan;
            res.PrecisionDeg = nan;
    end


        suc = true;
        oc = '';
    catch ERR
        suc = false;
        oc = ERR.message;
    end
    
end