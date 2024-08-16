function summary = etSegMakeSummary(segdet)

    numData = length(segdet);
    uHdr = {};

    % get all task names
    for d = 1:numData
        
        tasks = segdet{d}(:, 1);
        numTasks = length(tasks);
        uHdr = unique([uHdr; tasks]);

    end
    
    % transpose
    uHdr = uHdr';
    summary = cell(numData + 1, length(uHdr) + 1);
    summary(1, :) = ['ID', uHdr];

    % place data in summary
    for d = 1:numData
        
        tasks = segdet{d}(:, 1);
        numTasks = length(tasks);
        id = segdet{d}{1, 2};
        
        for t = 1:numTasks
            
            task = segdet{d}{t, 1};
            success = segdet{d}{t, 2};
            numSegs = segdet{d}{t, 3};
            outcome = segdet{d}{t, 4};
            
            col = find(strcmpi(uHdr, task), 1, 'first');
            summary{d + 1, 1} = id;
            summary{d + 1, col + 1} = numSegs;
            
        end

    end

end