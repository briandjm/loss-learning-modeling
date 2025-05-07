function curve_by_cond = curve_bycond(block_of_data, condition)
    idx_cond = block_of_data.condition == condition;
    data_bycond = block_of_data(idx_cond,:);
    curve_by_cond = data_bycond.is_correct;
end