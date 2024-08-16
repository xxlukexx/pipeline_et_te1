function PIPELINE_ET_alignFrames(path_in, path_out)

    % set input and output paths
    if ~exist(path_out, 'dir'), mkdir(path_out); end

    % get filenames
    d = dir([path_in, filesep, '*.mat']);
    numData = length(d);

    % data loop
    parGUID = parProgress('INIT');
    parfor f = 1:numData

        parProgress(parGUID, f, numData);
        prog = parReadProgress(parGUID) * 100;
        fprintf('Dataset %d of %d (%.1f%%)...\n', f, numData, prog);

        tmp = load([path_data, filesep, d(f).name]); data = tmp.data;
        numSegs = length(data.Segments);
        trials = struct;
        trials(numSegs + 1).preallocate = 1;

        % segments loop
        for s = 1:numSegs

            % get buffers
            mb = data.Segments(s).MainBuffer;
            tb = data.Segments(s).TimeBuffer;
            eb = data.Segments(s).EventBuffer;

            % get movie name
            ebMov = etFilterEvents(eb, 'NATSCENES');
            if isempty(ebMov) || size(ebMov, 1) ~= 1 || size(ebMov, 2) ~= 4 ||...
                    size(ebMov{3}, 1) ~= 1 || size(ebMov{3}, 2) ~= 2
                trials(s).Movie = 'NOT FOUND';
            else
                trials(s).Movie = ebMov{3}{2};
            end

            % align
            [x, y, ft, fn] = salAlignFrames(mb, tb, eb);
            x = cellfun(@nanmean, x);
            y = cellfun(@nanmean, y);
            val = ~isnan(x) & ~isnan(y);
            trials(s).AlignedBuffer = [fn, ft, x, y, val];
            trials(s).ColumnHeaders =...
                {'FrameNo', 'FrameTime', 'X', 'Y', 'Valid'};
            trials(s).PropValid = sum(val) / length(val);

        end

        trials = rmfield(trials, 'preallocate');
        trials(numSegs + 1) = [];

        [~, fileName, fileExt] = fileparts(d(f).name);
        file_out = [path_out, filesep, fileName, '_frames', fileExt];
        parsave(file_out, trials, '-v6');

    end
    
end



