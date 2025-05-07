function group_avg_curve = average_by_start_tokens(sessiondata, condition)
    % Define the possible starting token amounts
    start_tokens = [0, 1, 2, 3, 4, 5, 6, 7, 8];
    
    % Initialize a cell array to store average curves for each group
    group_avg_curve = cell(length(start_tokens), 1);

    for ti = 1:length(start_tokens)
        start_token = start_tokens(ti);
        
        % Filter the data for the current starting token amount
        token_data = sessiondata(sessiondata.tokens_before == start_token, :);

        allblocks = unique(token_data.blockID);
        lengthblocks = length(allblocks);
        multicurves = NaN(18, lengthblocks);

        for bi = 1:lengthblocks
            actualblockID = allblocks(bi);
            singleblock = token_data(token_data.blockID == actualblockID, :);
            singlecurve = curve_bycond(singleblock, condition);
            singlecurve = W.extend(singlecurve', 18)';
            multicurves(:, bi) = singlecurve;
        end

        % Compute the average curve for the current starting token amount
        avg_curve = mean(multicurves, 2);
        
        % Store the average curve in the cell array
        group_avg_curve{ti} = avg_curve;
    end
end

