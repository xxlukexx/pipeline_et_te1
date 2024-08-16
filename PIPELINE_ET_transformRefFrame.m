function [data, success, outcome, windowSize, monitorSize] =...
    PIPELINE_ET_transformRefFrame(data, windowSize, monitorSize)

    success = false;
    outcome = 'UNKNOWN ERROR';

    % back-up original main buffer
    data.ExtraData.MainBuffer_PreTransform =...
        data.MainBuffer;

    % transform
    data.MainBuffer = etScaleBySize(...
        data.MainBuffer, monitorSize, windowSize);

    % record on/offscreen gaze
    data.ExtraData.OnOffScreenGaze =...
        etCharacteriseDataLoss(data.MainBuffer);

    % remove offscreen gaze
    data.MainBuffer = etFilterGazeOnscreen(data.MainBuffer);

    % record outcome and monitor/window sizes
    success = true;
    outcome = ['Transformed gaze data',...
        num2cell([windowSize, monitorSize])];

end