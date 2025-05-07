function avg_session = average_session(sessiondata, condition)
    allblocks = unique(sessiondata.blockID);
    lengthblocks = length(allblocks);
    multicurves = NaN(18,lengthblocks);

       for bi = 1:lengthblocks
           actualblockID = allblocks(bi);
           singleblock = sessiondata(sessiondata.blockID == actualblockID,:);
           singlecurve = curve_bycond(singleblock,condition);
           singlecurve = W.extend(singlecurve',18)';
           multicurves(:,bi) = singlecurve;
       end

       avg_session = mean(multicurves, 2);
end

% multisize = size(multicurves,1);
       % added_columns = zeros(multisize,1);
       %      for i = 1:size(multicurves,2)
       %          added_columns = multicurves(:,i) + added_columns;
       %      end
       % av_columns = added_columns/6;