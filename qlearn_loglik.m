function nll = qlearn_loglik(params, choices, outcomes)

alpha = params(1);  % learning rate
beta  = params(2);  % inverse temperature

cue_ids = unique(choices);
n_cues = max(cue_ids);  % assumes cue IDs are 1–4
Q = zeros(1, n_cues);   % initial Q-values

logp = zeros(length(choices), 1);

for t = 1:length(choices)
    ch = choices(t);
    r  = outcomes(t);

    % Softmax over cues
    expQ = exp(beta * Q);
    p = expQ(ch) / sum(expQ);

    % Avoid log(0)
    p = max(p, 1e-5);
    logp(t) = log(p);

    % Q-learning update
    Q(ch) = Q(ch) + alpha * (r - Q(ch));
end

nll = -sum(logp);  % negative log-likelihood
