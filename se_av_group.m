function [avg_group, se_group] = se_av_group(groupdata, condition)
    unique_monkeys = unique(groupdata.monkey);
    lengthmonkeys = length(unique_monkeys);
    multicurves = NaN(18,lengthmonkeys);

    for mi = 1:lengthmonkeys
        actualmonkey = unique_monkeys(mi);
        singlemonkey = groupdata(groupdata.monkey == actualmonkey,:);
        singlecurve = average_monkey(singlemonkey,condition);
        multicurves(:,mi) = singlecurve;
    end
    [avg_group, se_group] = W.avse(multicurves');
end
