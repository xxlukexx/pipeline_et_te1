function aligned = PIPELINE_ET_combineAlignedFrames(path_in)

    d = dir([path_in, filesep, '*.mat']);
    numData = length(d);
    
    aligned = table;
    for f = 1:numData
        
        % load
        tmp = load([path_in, filesep, d(f).name]);
        
        % check for aligned data
        if ~isfield(tmp.data, 'AlignedBuffer')
            continue
        end
        
        % remove col headers field
        tmp.data = rmfield(tmp.data, 'ColumnHeaders');
        
        % get id
        parts = strsplit(d(f).name, '_');
        id = parts{5};
        
        % put buffer in cell
        for i = 1:length(tmp.data)
            tmp.data(i).AlignedBuffer = {tmp.data(i).AlignedBuffer};
        end
        
        % convert to table
        tmpTab = struct2table(tmp.data);
        tmpTab = [cell2table(repmat({id}, size(tmpTab, 1), 1),...
            'variablenames', {'ID'}), tmpTab];
        
        % store
        aligned = [aligned; tmpTab];
        
    end

end