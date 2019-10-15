% Generate probability values between 0 and 1
% Generative process. This determines P(invalid) on each trial.

n = 36 * 6;

% this is an example. we really want a Gaussian random walk with bounds at
% .2 and .8. This means:
% 1 - use normrnd
% 2 - We want to constrain the random walk to be reflected at .2 and .8, so that it
% never generates an illegal probability value. and we don't need to
% rescale it later.


R = binornd(1,.5,n,1);
R = R - 0.5;
R = cumsum(R);
R = (R - min(R)) ./ range(R);
%figure; plot(R)

% Generate an instance (sequence of valid/invalid)

S = unifrnd(0, 1,n,1);

trial_seq = S < R;  % 1 = invalid, 0 = valid

% Plot it

create_figure('random walk'); plot(R);
hold on;
hh = plot_onsets(trial_seq, 'r', 0, .2, .5);
axis tight
set(hh, 'EdgeColor', 'none');

%% 
% 3 - We don't want linear 'drift' - we want it to oscillate slowly.
%  (could use autocorrelated vector instead).


R = noise_arp(n, [.7 0]);
R = (R - min(R)) ./ range(R);

% Generate an instance (sequence of valid/invalid)

S = unifrnd(0, 1,n,1);

trial_seq = S < R;  % 1 = invalid, 0 = valid

% Plot it

create_figure('random walk'); plot(R);
hold on;
hh = plot_onsets(trial_seq, 'r', 0, .2, .5);
axis tight
set(hh, 'EdgeColor', 'none');
