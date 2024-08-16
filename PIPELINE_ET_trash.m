function PIPELINE_ET_trash(path_delete, path_trash)

    if ~iscell(path_delete)
        path_delete = {path_delete};
    end
    numPaths = length(path_delete);
    
    for p = 1:numPaths
        
        src = path_delete{p};
        dest = fullfile(path_trash, src);
        
        if ~exist(src, 'dir') && ~exist(src, 'file')
            fprintf(2, 'Not found: %s\n\n', src);
            return
        end
    
        tryToMakePath(dest)
        [suc, msg] = movefile(src, dest);
        if contains(msg, 'Resource busy')
            fprintf(2, 'Couldn''t delete %s\n\n', src);
        end
        
        fprintf('\n\n%s\n\t -> %s', src, dest)
        
    end

end