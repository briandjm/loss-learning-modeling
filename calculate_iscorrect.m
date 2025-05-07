function is_correct = calculate_iscorrect(data)     
    idx_chosen = data.cue_side == data.saccade_direction; % checks if cue_side matches saccade_direction
    chosen_image = idx_chosen * [1 2 3 4]';
    data.unchosen_direction = 3 - data.saccade_direction;
    idx_unchosen = data.cue_side == 3 - data.saccade_direction;
    unchosen_image = idx_unchosen * [1 2 3 4]';
    
    % calculate choice correctness
    values = [1, 2, -1, -2];
    value_chosen = values(chosen_image);
    value_unchosen = values(unchosen_image);
    is_correct = (value_chosen > value_unchosen)' + 0;
end