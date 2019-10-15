sequence_dir = '/Users/h/Documents/projects_local/fractional_factorials/posner-AR/design/s01_cue-sequence';
for sub = 1:150
    n = 120;
    close all
    s = rng;
    R = noise_arp(n, [.7 0]);
%     R = (R - min(R)) ./ range(R);
    % https://stackoverflow.com/questions/5294955/how-to-scale-down-a-range-of-numbers-with-a-known-min-and-max-value
    newR = ((0.8-0.2)*(R - min(R)) ./ range(R)) + 0.2;
    % Generate an instance (sequence of valid/invalid)

    S = unifrnd(0, 1,n,1);
    trial_seq = S < newR;  % 1 = invalid, 0 = valid

    % Plot it create_figure('random walk');
    fig = plot(newR);
    hold on;
    hh = plot_onsets(trial_seq, 'r', 0, .2, .5);
    axis tight
    set(hh, 'EdgeColor', 'none');

    % save rng, plot, sequence
    filename_rng = fullfile(sequence_dir, ['sub-', sprintf('%03d',sub), '_randomseed.mat']);
    filename_sequence = fullfile(sequence_dir, ['sub-', sprintf('%03d',sub), '_cuesequence.csv']);
    filename_plot = fullfile(sequence_dir, ['sub-', sprintf('%03d',sub), '_plot.png']);
    save(filename_rng, 's');
    csvwrite(filename_sequence, trial_seq);
    saveas(fig, filename_plot);
end
