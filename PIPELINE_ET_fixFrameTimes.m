function [data, suc, oc, ftCorr, rtCorr] =...
    PIPELINE_ET_fixFrameTimes(data, ftfix)

    numTasks = size(ftfix, 1);
    suc = false(numTasks, 1);
    oc = cellstr(repmat('UNKNOWN ERROR', numTasks, 1));
    ftCorr = nan(numTasks, 1);
    rtCorr = nan(numTasks, 1);

    for t = 1:numTasks
        [data.EventBuffer, ftCorr(t), rtCorr(t), oc{t}] =...
            etFixFrameTimes(data.EventBuffer, data.TimeBuffer, ftfix{t, :});
        suc(t) = true;
    end

end