function avg_monkey = average_monkey(monkeydata, condition)
    unique_sessions = unique(monkeydata.sessionID);
    lengthsessions = length(unique_sessions);
    multicurves = NaN(18,lengthsessions);

    for si = 1:lengthsessions
        actualsession = unique_sessions(si);
        singlesession = monkeydata(monkeydata.sessionID == actualsession,:);
        singlecurve = average_session(singlesession,condition);
        multicurves(:,si) = singlecurve;
    end
    avg_monkey = mean(multicurves, 2);
end
