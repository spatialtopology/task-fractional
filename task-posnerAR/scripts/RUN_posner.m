function RUN_posner(sub_num, run_num, biopac, session, fMRI)

% created by Heejung Jung
% 2019.11.15

%--------------------------------------------------------------------------
%                          Experiment parameters
%--------------------------------------------------------------------------

% if fMRI
%     [keyboard_id, keyboard_name] = GetKeyboardIndices;
%     trigger_inputDevice = keyboard_id(find(contains(keyboard_name, 'Current Designs')));
%     stim_PC = keyboard_id(find(contains(keyboard_name, 'AT Translated')));
% else
%     trigger_inputDevice = -3;
%     stim_PC = -3;
% end

trigger_inputDevice = -3;
stim_PC = -3;

%% 0. Biopac parameters _________________________________________________
script_dir = pwd;
% biopac channel
channel = struct;
channel.trigger          = 0;
channel.fixation         = 1;
channel.cue              = 2;
channel.target           = 3;
channel.target_remainder = 4;
% channel.fixation_2       = 5;



%% 0. Biopac parameters _________________________________________________
if biopac == 1
    script_dir = pwd;
    cd('/home/spacetop/repos/labjackpython');
    pe = pyenv;
    try
        py.importlib.import_module('u3');
    catch
        warning("u3 already imported!");
    end
    % Check to see if u3 was imported correctly
    % py.help('u3')
    channel.d = py.u3.U3();
    % set every channel to 0
    channel.d.configIO(pyargs('FIOAnalog', int64(0), 'EIOAnalog', int64(0)));
    for FIONUM = 0:7
        channel.d.setFIOState(pyargs('fioNum', int64(FIONUM), 'state', int64(0)));
    end
    cd(script_dir);
end

% A. psychtoolbox parameters _____________________________________________
global p

Screen('Preference', 'SkipSyncTests', 0);
PsychDefaultSetup(2);
screens                        = Screen('Screens'); % Get the screen numbers
p.ptb.screenNumber             = max(screens); % Draw to the external screen if avaliable
p.ptb.white                    = WhiteIndex(p.ptb.screenNumber); % Define black and white
p.ptb.black                    = BlackIndex(p.ptb.screenNumber);
p.ptb.green                    = [0 1 0];
[p.ptb.window, p.ptb.rect]     = PsychImaging('OpenWindow',p.ptb.screenNumber,p.ptb.black);
[p.ptb.screenXpixels, p.ptb.screenYpixels] = Screen('WindowSize',p.ptb.window);
p.ptb.ifi                      = Screen('GetFlipInterval',p.ptb.window);
Screen('BlendFunction', p.ptb.window,'GL_SRC_ALPHA','GL_ONE_MINUS_SRC_ALPHA'); % Set up alpha-blending for smooth (anti-aliased) lines
Screen('TextFont', p.ptb.window, 'Arial');
Screen('TextSize', p.ptb.window, 36);
[p.ptb.xCenter, p.ptb.yCenter] = RectCenter(p.ptb.rect);
p.fix.sizePix                  = 40; % size of the arms of our fixation cross
p.fix.lineWidthPix             = 4; % Set the line width for our fixation cross
p.fix.xCoords                  = [-p.fix.sizePix p.fix.sizePix 0 0];
p.fix.yCoords                  = [0 0 -p.fix.sizePix p.fix.sizePix];
p.fix.allCoords                = [p.fix.xCoords; p.fix.yCoords];

% building shapes ______________________________________________________________
p.rect.baseRect                = [0 0 p.ptb.screenYpixels*2/9 p.ptb.screenYpixels*2/9];
p.rect.squareXpos              = [p.ptb.screenXpixels * 0.30 p.ptb.screenXpixels * 0.70];
numSquares                     = length(p.rect.squareXpos);
p.rect.allRects                = nan(4, 3);
for i = 1:numSquares
    p.rect.allRects(:, i)      = CenterRectOnPointd(p.rect.baseRect, p.rect.squareXpos(i), p.ptb.yCenter);
end
p.rect.leftRects = CenterRectOnPointd(p.rect.baseRect, p.ptb.screenXpixels * 0.30, p.ptb.yCenter);
p.rect.rightRects = CenterRectOnPointd(p.rect.baseRect, p.ptb.screenXpixels * 0.70, p.ptb.yCenter);
p.rect.penWidthPixels          = 6;

p.target.dotSizePix            = 20;
p.target.leftXpos              = p.ptb.screenXpixels * 0.30;
p.target.rightXpos             = p.ptb.screenXpixels * 0.70;

p.rect.LcenteredRect           = CenterRectOnPointd(p.rect.baseRect, -100, p.ptb.yCenter);
p.rect.RcenteredRect           = CenterRectOnPointd(p.rect.baseRect, 100, p.ptb.yCenter);

% B. Directories _________________________________________________________
task_dir                       = pwd;
main_dir                       = fileparts(task_dir); % ~/repos/fractional/task-posnerAR
repo_dir                       = fileparts(fileparts(fileparts((task_dir)))); % ~/repos/
payment_dir                    = fullfile(repo_dir, 'fractional', 'payment', strcat('sub-', sprintf('%04d', sub_num)));
taskname                       = 'posner';
% bids_string
% example: sub-0001_ses-04_task-fractional_run-posner-01
bids_string                         = [strcat('sub-', sprintf('%04d', sub_num)), ...
    strcat('_ses-',sprintf('%02d', session)),...
    strcat('_task-fractional'),...
    strcat('_run-', sprintf('%02d', run_num),'-', taskname )];
sub_save_dir = fullfile(main_dir, 'data', strcat('sub-', sprintf('%04d', sub_num)), 'beh'  );
repo_save_dir = fullfile(repo_dir, 'data', strcat('sub-', sprintf('%04d', sub_num)),...
    'task-fractional');
if ~exist(sub_save_dir, 'dir');     mkdir(sub_save_dir);     end
if ~exist(repo_save_dir, 'dir');    mkdir(repo_save_dir);   end
if ~exist(payment_dir, 'dir');      mkdir(payment_dir);   end

% load counterbalancefile
counterbalancefile             = fullfile(main_dir,'design', 's04_counterbalance', ...
    [strcat('sub-', sprintf('%04d', sub_num)),'_task-', taskname '_counterbalance.csv']);
countBalMat                    = readtable(counterbalancefile);

% C. experiment parameters _______________________________________________
% cue to target duration: 200ms
% response: give 2s
trial_duration                 = 2.000;
cue_duration                   = 0.200;


% D. making output table _________________________________________________

vnames = {
    'src_subject_id','param_session_id','run_num','param_counterbalance_ver',...
    'param_AR_invalid_sequence','param_valid_type','param_cue_location','param_target_location',...
    'param_trigger_onset','param_start_biopac',...
    'event01_param_jitter','event01_fixation_onset','event01_fixation_onset_biopac','event01_fixation_duration',...
    'event02_cue_type','event02_cue_onset','event02_cue_onset_biopac','event02_cue_duration',...
    'event03_target_type','event03_target_onset','event03_target_onset_biopac',...
    'event04_response_key','event04_response_keyname','event04_response_onset','event04_RT',...
    'event04_fixation_remainder_onset','event04_fixation_duration',...
    'event05_fixation_onset','event05_fixation_onset_biopac',...
    'param_end_instruct_onset','param_end_biopac','param_experiment_duration',...
    'RAW_event01_fixation_onset','RAW_event01_fixation_onset_biopac',...
    'RAW_event02_cue_onset','RAW_event02_cue_onset_biopac',...
    'RAW_event03_target_onset','RAW_event03_target_onset_biopac',...
    'RAW_event04_response_onset','RAW_event04_fixation_remainder_onset',...
    'RAW_event05_fixation_onset','RAW_event05_fixation_onset_biopac',...
    'RAW_param_end_instruct_onset','RAW_param_end_biopac'};
vtypes = {
    'double','double','double','double','double','string','string','string','double','double',...
    'double','double','double','double',...
    'string','double','double','double',...
    'string','double','double',...
    'double','string','double','double','double','double',...
    'double','double',...
    'double','double','double',...
    'double','double',...
    'double','double',...
    'double','double',...
    'double','double','double','double','double','double'};
T = table('Size', [size(countBalMat,1) size(vnames,2)], 'VariableNames', vnames, 'VariableTypes', vtypes);
T.src_subject_id(:)            = sub_num;
T.param_session_id(:)          = session;
T.run_num(:)                   = run_num;
T.param_counterbalance_ver(:)  = sub_num;
T.event01_param_jitter         = countBalMat.jitter;
T.param_AR_invalid_sequence    = countBalMat.AR_invalid_sequence;
T.param_valid_type             = countBalMat.valid_type;
T.param_cue_location           = countBalMat.cue;
T.param_target_location        = countBalMat.target;
T.event02_cue_type             = countBalMat.cue;
T.event03_target_type          = countBalMat.target;
%T.event04_response_keyname    = cell(size(countBalMat,1),1);

% E. Keyboard information _____________________________________________________
KbName('UnifyKeyNames');
p.keys.confirm                 = KbName('return');
p.keys.right                   = KbName('3#');
p.keys.left                    = KbName('1!');
p.keys.space                   = KbName('space');
p.keys.esc                     = KbName('ESCAPE');
p.keys.trigger                 = KbName('5%');
p.keys.start                   = KbName('s');
p.keys.end                     = KbName('e');

[id, name]                     = GetKeyboardIndices;
trigger_index                  = find(contains(name, 'Current Designs'));
trigger_inputDevice            = id(trigger_index);

keyboard_index                 = find(contains(name, 'AT Translated Set 2 Keyboard'));
keyboard_inputDevice           = id(keyboard_index);


% F. fmri Parameters __________________________________________________________
TR                             = 0.46;

% G. instructions _____________________________________________________
instruct_filepath              = fullfile(main_dir, 'design', 'instructions');
instruct_start_name            = ['task-', taskname, '_start.png'];
instruct_end_name              = ['task-', taskname, '_end.png'];
instruct_start                 = fullfile(instruct_filepath, instruct_start_name);
instruct_end                   = fullfile(instruct_filepath, instruct_end_name);

%% -----------------------------------------------------------------------------
%                              Start Experiment
% ------------------------------------------------------------------------------

% ______________________________ Instructions _________________________________
Screen('TextSize',p.ptb.window,72);
start.texture = Screen('MakeTexture',p.ptb.window, imread(instruct_start));
Screen('DrawTexture',p.ptb.window,start.texture,[],[]);
Screen('Flip',p.ptb.window);

% ____________________ 1. Wait for Trigger to Begin ______________________
DisableKeysForKbCheck([]);
HideCursor;
%KbTriggerWait(p.keys.start, stim_PC);
WaitKeyPress(p.keys.start);
Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
    p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
Screen('Flip', p.ptb.window);
% T.param_triggerOnset(:) = KbTriggerWait(p.keys.trigger);
WaitKeyPress(p.keys.trigger);
T.param_trigger_onset(:) = GetSecs;
%T.param_trigger_onset(:) = KbTriggerWait(p.keys.trigger);
T.param_start_biopac(:)                     = biopac_linux_matlab(biopac, channel, channel.trigger, 1);
% T.param_trigger_onset(:) = GetSecs;
WaitSecs(TR*6);

% __________________________ Experimental loop ___________________________
for trl = 1:size(countBalMat,1)

    % ------------------------------------------------------------------------
    %                        1. Fixtion Jitter 300 / 120 = 2.5 sec
    % -------------------------------------------------------------------------

    Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
        p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
    Screen('FrameRect', p.ptb.window, p.ptb.white, p.rect.allRects, p.rect.penWidthPixels);
    T.RAW_event01_fixation_onset(trl) = Screen('Flip', p.ptb.window);
    T.RAW_event01_fixation_onset_biopac(trl)  = biopac_linux_matlab(biopac, channel, channel.fixation, 1);
    WaitSecs('UntilTime', T.RAW_event01_fixation_onset(trl) + countBalMat.jitter(trl))
    offset = biopac_linux_matlab(biopac, channel, channel.fixation, 0);
    T.event01_fixation_duration(trl) = offset - T.RAW_event01_fixation_onset(trl);

    % ------------------------------------------------------------------------
    %                               2. cue 0.2 s
    % -------------------------------------------------------------------------
    if string(countBalMat.cue{trl}) == "left"
        Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
            p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
        Screen('FrameRect', p.ptb.window, p.ptb.white, p.rect.allRects, p.rect.penWidthPixels);
        Screen('FrameRect', p.ptb.window, p.ptb.green, p.rect.leftRects, p.rect.penWidthPixels);
        T.RAW_event02_cue_onset(trl) = Screen('Flip', p.ptb.window);
        T.RAW_event02_cue_onset_biopac(trl) = biopac_linux_matlab(biopac, channel, channel.cue, 1);
        WaitSecs('UntilTime',T.RAW_event01_fixation_onset(trl) + countBalMat.jitter(trl) + cue_duration);
        cue_offset = biopac_linux_matlab(biopac, channel, channel.cue, 0);
        T.event02_cue_duration(trl) = cue_offset - T.RAW_event02_cue_onset(trl);

    elseif string(countBalMat.cue{trl}) == "right"
        Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
            p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
        Screen('FrameRect', p.ptb.window, p.ptb.white, p.rect.allRects, p.rect.penWidthPixels);
        Screen('FrameRect', p.ptb.window, p.ptb.green, p.rect.rightRects, p.rect.penWidthPixels);
        T.RAW_event02_cue_onset(trl) = Screen('Flip', p.ptb.window);
        T.RAW_event02_cue_onset_biopac(trl) = biopac_linux_matlab(biopac, channel, channel.cue, 1);
        WaitSecs('UntilTime',T.RAW_event01_fixation_onset(trl) + countBalMat.jitter(trl) + cue_duration);
        cue_offset = biopac_linux_matlab(biopac, channel, channel.cue, 0);
        T.event02_cue_duration(trl) = cue_offset- T.RAW_event02_cue_onset(trl);
    else
        error('check!');
    end

    % ------------------------------------------------------------------------
    %                              3. target 2 s
    % -------------------------------------------------------------------------
    if string(countBalMat.target{trl}) == "left"
        Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
            p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
        Screen('FrameRect', p.ptb.window, p.ptb.white, p.rect.allRects, p.rect.penWidthPixels);
        Screen('DrawDots', p.ptb.window, [p.target.leftXpos p.ptb.yCenter], p.target.dotSizePix, p.ptb.green, [], 2);
        T.RAW_event03_target_onset(trl) = Screen('Flip', p.ptb.window);
        T.RAW_event03_target_onset_biopac(trl) = biopac_linux_matlab(biopac, channel, channel.target, 1);
    elseif string(countBalMat.target{trl}) == "right"
        Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
            p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
        Screen('FrameRect', p.ptb.window, p.ptb.white, p.rect.allRects, p.rect.penWidthPixels);
        Screen('DrawDots', p.ptb.window, [p.target.rightXpos p.ptb.yCenter], p.target.dotSizePix, p.ptb.green, [], 2);
        T.RAW_event03_target_onset(trl) = Screen('Flip', p.ptb.window);
        T.RAW_event03_target_onset_biopac(trl) = biopac_linux_matlab(biopac, channel, channel.target, 1);
    end

    % ------------------------------------------------------------------------
    %                            4. button press within 2s
    % -------------------------------------------------------------------------
    biopac_linux_matlab(biopac, channel, channel.target_remainder, 0);
    % 4.1. record key press _______________________________________________
    %     while respToBeMade && timeStim < trial_duration
    while (GetSecs - T.RAW_event03_target_onset(trl)) < trial_duration
        T.event04_response_key(trl) = NaN;
        T.event04_response_keyname{trl} = 'NaN';
        T.RAW_event04_response_onset(trl) = NaN;
        T.event04_RT(trl) = NaN;
        T.event04_fixation_duration(trl) = NaN;
        T.RAW_event04_fixation_remainder_onset(trl) = NaN;

        RT = NaN;
        % [keyIsDown,secs, keyCode] = KbCheck(trigger_inputDevice);
        [~,~,buttonpressed] = GetMouse;
        resp_onset = GetSecs;
        % if keyCode(p.keys.esc)
        % ShowCursor;
        % sca;
        % return
        if buttonpressed(1) % keyCode(p.keys.left)
            T.RAW_event04_response_onset(trl) = resp_onset;
            RT = resp_onset - T.RAW_event03_target_onset(trl);
            T.event04_RT(trl) = resp_onset - T.RAW_event03_target_onset(trl);
            biopac_linux_matlab(biopac, channel, channel.target, 0);
            T.event04_response_key(trl)  = 1;
            T.event04_response_keyname{trl} = 'left';
            WaitSecs(0.5);

            remainder_time = trial_duration - 0.5 - RT;
            Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
                p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
            T.RAW_event04_fixation_remainder_onset(trl) = Screen('Flip', p.ptb.window);
            biopac_linux_matlab(biopac, channel, channel.target_remainder, 1);
            WaitSecs('UntilTime', T.RAW_event03_target_onset(trl) + trial_duration)
            biopac_linux_matlab(biopac, channel, channel.target_remainder, 0);
            T.event04_fixation_duration(trl) = remainder_time;


        elseif buttonpressed(3) % keyCode(p.keys.right)
            T.RAW_event04_response_onset(trl) = resp_onset;
            RT = resp_onset - T.RAW_event03_target_onset(trl);
            T.event04_RT(trl) = resp_onset - T.RAW_event03_target_onset(trl);
            biopac_linux_matlab(biopac, channel, channel.target, 0);
            T.event04_response_key(trl)  = 2; % right
            T.event04_response_keyname{trl} = 'right';
            WaitSecs(0.5);

            remainder_time = trial_duration - 0.5 - RT;
            Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
                p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
            T.RAW_event04_fixation_remainder_onset(trl) = Screen('Flip', p.ptb.window);
            biopac_linux_matlab(biopac, channel, channel.target_remainder, 1);
            WaitSecs('UntilTime', T.RAW_event03_target_onset(trl) + trial_duration)
            biopac_linux_matlab(biopac,channel, channel.target_remainder, 0);
            T.event04_fixation_duration(trl) = remainder_time;
        end

    end
    biopac_linux_matlab(biopac, channel, channel.target, 0);
    biopac_linux_matlab(biopac, channel, channel.target_remainder, 0);

    Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
        p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
    T.RAW_event05_fixation_onset(trl) = Screen('Flip', p.ptb.window);
    T.RAW_event05_fixation_onset_biopac(trl) = biopac_linux_matlab(biopac, channel, channel.fixation, 1);
    WaitSecs('UntilTime',T.RAW_event05_fixation_onset(trl) + 0.2);
    biopac_linux_matlab(biopac, channel, channel.fixation, 0);

    %% ________________________ 7. temporarily save file _______________________
    tmp_file_name = fullfile(sub_save_dir,[strcat('sub-', sprintf('%04d', sub_num)), ...
        strcat('_ses-', sprintf('%02d',session)), '_task-fractionl_run-',taskname,'_TEMPbeh.csv' ]);
    writetable(T,tmp_file_name);

end


% _________________________ End Instructions _____________________________
end_texture = Screen('MakeTexture',p.ptb.window, imread(instruct_end));
Screen('DrawTexture',p.ptb.window,end_texture,[],[]);
T.RAW_param_end_instruct_onset(:) = Screen('Flip',p.ptb.window);
T.RAW_param_end_biopac(:)         = biopac_linux_matlab(biopac, channel, channel.trigger, 0);
T.param_experiment_duration(:)    = T.RAW_param_end_instruct_onset(1) - T.param_trigger_onset(1);

% ------------------------------------------------------------------------
%                              save parameter
% -------------------------------------------------------------------------
trigger_dummy_removed = T.param_trigger_onset(:) - (TR*6);
T.event01_fixation_onset(:) = T.RAW_event01_fixation_onset(:) - trigger_dummy_removed;
T.event01_fixation_onset_biopac(:) = T.RAW_event01_fixation_onset_biopac(:) - trigger_dummy_removed;
T.event02_cue_onset(:) = T.RAW_event02_cue_onset(:) - trigger_dummy_removed;
T.event02_cue_onset_biopac(:) = T.RAW_event02_cue_onset_biopac(:) - trigger_dummy_removed;
T.event03_target_onset(:) = T.RAW_event03_target_onset(:) - trigger_dummy_removed;
T.event03_target_onset_biopac(:) = T.RAW_event03_target_onset_biopac(:) - trigger_dummy_removed;
T.event04_response_onset(:) = T.RAW_event04_response_onset(:) - trigger_dummy_removed;
T.event04_fixation_remainder_onset(:) = T.RAW_event04_fixation_remainder_onset(:) - trigger_dummy_removed;
T.event05_fixation_onset(:) = T.RAW_event05_fixation_onset(:) - trigger_dummy_removed;
T.event05_fixation_onset_biopac(:) = T.RAW_event05_fixation_onset_biopac(:) - trigger_dummy_removed;
T.param_end_instruct_onset(:) = T.RAW_param_end_instruct_onset(1) - T.param_trigger_onset(1) - (TR*6);
T.param_end_biopac(:) = T.RAW_param_end_biopac(1) - T.param_trigger_onset(1) - (TR*6);
T.accuracy = T.event03_target_type == T.event04_response_keyname;
accuracy_freq = sum(T.accuracy);

%% save file ___________________________________________________________________

saveFileName = fullfile(sub_save_dir,[bids_string, '_beh.csv' ]);
repoFileName = fullfile(repo_save_dir,[bids_string, '_beh.csv' ]);
writetable(T,saveFileName);
writetable(T,repoFileName);

psychtoolbox_saveFileName = fullfile(sub_save_dir, [bids_string, '_psychtoolboxparams.mat' ]);
psychtoolbox_repoFileName = fullfile(repo_save_dir, [bids_string, '_psychtoolboxparams.mat' ]);
save(psychtoolbox_saveFileName, 'p');
save(psychtoolbox_repoFileName, 'p');

% ------------------------------------------------------------------------------
%                                payment
% ------------------------------------------------------------------------------
pettycashfile = fullfile(payment_dir,[strcat('sub-', sprintf('%04d', sub_num)), '_run-', sprintf('%02d', run_num),'-', taskname ,'_pettycash.txt' ]);
[fid, message] = fopen(pettycashfile,'w');
if fid < 0
error('failed to open file because: %s', message);
end
fprintf(fid,'*********************************\n*********************************\nThis is the end of the attention task.\n');
fprintf(fid,'This participants total accuracy was %0.2f percent.\n',(accuracy_freq/size(countBalMat,1))*100);
fprintf(fid,'Please pay %0.2f dollars.\nThank you !!\n', ((accuracy_freq/size(countBalMat,1))*10));
fprintf(fid,'*********************************\n*********************************\n');
fclose(fid);
% print in command window
fprintf('*********************************\n*********************************\nThis is the end of the attention task.\n');
fprintf('This participants total accuracy was %0.2f percent.\n',(accuracy_freq/size(countBalMat,1))*100);
fprintf('Please pay %0.2f dollars.\nThank you !!\n', ((accuracy_freq/size(countBalMat,1))*10));
fprintf('*********************************\n*********************************\n');


WaitKeyPress(p.keys.end);
%KbTriggerWait(p.keys.end, stim_PC);
% WaitSecs(0.2);
ShowCursor;

if biopac;  channel.d.close();  end
clear p; clearvars; Screen('Close'); close all; sca;

%% -----------------------------------------------------------------------------
%                                   Function
%-------------------------------------------------------------------------------

function WaitKeyPress(kID)
    while KbCheck(-3); end
    while 1
        [keyIsDown, ~, keyCode ] = KbCheck(-3);
        if keyIsDown
            if keyCode(p.keys.esc)
                cleanup; break;
            elseif keyCode(kID)
                break;
            end
            while KbCheck(-3); end
        end
    end
end

    function [time] = biopac_linux_matlab(biopac, channel, channel_num, state_num)
        if biopac
            channel.d.setFIOState(pyargs('fioNum', int64(channel_num), 'state', int64(state_num)))
            time = GetSecs;
        else
            time = GetSecs;
            return
        end
    end

end
