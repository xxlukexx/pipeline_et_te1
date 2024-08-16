function PIPELINE_writeSummaries(adb, path_out)

    if ~exist(path_out, 'dir')
        error('Output path ''%s'' not found.', path_out)
    end
    
    file_wide = fullfile(path_out, sprintf('pipeline_summary_wide_%s.xlsx',...
        datestr(now, 30)));
    file_smry = fullfile(path_out, sprintf('pipeline_summary_%s.xlsx',...
        datestr(now, 30)));

    writetable(adb.WideTable, file_wide)
    fprintf('Wrote wide table to %s\n', file_wide)
    
    writetable(adb.WideSummaryTable, file_smry, 'WriteRowNames', true)
    fprintf('Wrote wide table to %s\n', file_smry)
    
end