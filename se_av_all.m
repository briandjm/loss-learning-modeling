function [avg_group_experiment_condition,se_group_experiment_condition] = se_av_all(alldata)
    unique_groups = unique(alldata.group);
    unique_experiments = unique(alldata.experimentID);
    unique_conditions = unique(alldata.condition);
    
    num_groups = length(unique_groups);
    num_experiments = length(unique_experiments);
    num_conditions = length(unique_conditions);
    
    avg_group_experiment_condition = cell(num_groups, num_experiments);
    se_group_experiment_condition = cell(num_groups, num_experiments);

    for gi = 1:num_groups
        actual_group = unique_groups(gi);
        
        for ei = 1:num_experiments
            actual_experiment = unique_experiments(ei);
            
            tab18by6AV = nan(18,6);
            tab18by6SE = nan(18,6);

            for ci = 1:num_conditions                
                matchdata = alldata(alldata.group == actual_group & alldata.experimentID == actual_experiment, :);
                
                [singlecurveAV,singlecurveSE] = se_av_group(matchdata,ci);

                tab18by6AV(:,ci) = singlecurveAV;
                tab18by6SE(:,ci) = singlecurveSE;

            end

            avg_group_experiment_condition{gi, ei} = tab18by6AV;
            se_group_experiment_condition{gi, ei} = tab18by6SE;
        end
    end
end