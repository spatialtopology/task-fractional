function RUN_posner(sub_num)

% created by Heejung Jung
% 2019.11.15

%--------------------------------------------------------------------------
%                          Experiment parameters
%--------------------------------------------------------------------------

% A. psychtoolbox parameters _____________________________________________
global p

Screen('Preference', 'SkipSyncTests', 1);
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

% building shapes
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
main_dir                       = fileparts(task_dir);
taskname                       = 'posner';
counterbalancefile             = fullfile(main_dir,'design', 's04_counterbalance', ...
    [strcat('sub-', sprintf('%04d', sub_num)),'_task-', taskname '_counterbalance.csv']);
countBalMat                    = readtable(counterbalancefile);
sub_save_dir                   = fullfile(main_dir, 'data', strcat('sub-', sprintf('%04d', sub_num)), 'beh' );
if ~exist(sub_save_dir, 'dir')
    mkdir(sub_save_dir)
end


% C. experiment parameters _______________________________________________
% cue to target duration: 200ms
% response: give 2s
trial_duration                 = 2.000;
cue_duration                   = 0.200;


% D. making output table _________________________________________________
vnames = {'param_fmriSession', 'param_counterbalanceVer','RAW_param_triggerOnset',...
    'param_AR_invalid_sequence', 'param_valid_type',... %'param_cue', 'param_target',...
    'p1_fixation_onset', 'p1_param_jitter','p1_fixation_offset','p1_ptb_fixation_duration',...
    'p2_cue_type','p2_cue_onset','p2_cue_offset','p2_cue_duration',...
    'p3_target_type','p3_target_onset',...
    'p4_responseonset','p4_responsekey','p4_responsekeyname','p4_RT', 'p4_fixation_fillin', 'p4_fixation_duration',...
    'p5_fixation_onset',...
    'RAW_p1_fixation_onset','RAW_p1_fixation_offset',...
    'RAW_p2_cue_onset','RAW_p2_cue_offset',...
    'RAW_p3_target_onset',...
    'RAW_p4_responseonset','RAW_p4_fixation_fillin',...
    'RAW_p5_fixation_onset',...
    'RAW_param_end_instruct_onset', 'experimentDuration'};

T                              = array2table(zeros(size(countBalMat,1),size(vnames,2)));
T.Properties.VariableNames     = vnames;
T.param_fmriSession(:)         = 4;
T.param_counterbalanceVer(:)   = sub_num;
T.p1_param_jitter              = countBalMat.jitter;
T.param_AR_invalid_sequence    = countBalMat.AR_invalid_sequence;
T.param_valid_type             = countBalMat.valid_type;
T.p2_cue_type                  = countBalMat.cue;
T.p3_target_type               = countBalMat.target;
T.p4_responsekeyname           = cell(size(countBalMat,1),1);


% E. Keyboard information _____________________________________________________
KbName('UnifyKeyNames');
p.keys.confirm                 = KbName('return');
p.keys.right                   = KbName('2@');
p.keys.left                    = KbName('1!');
p.keys.space                   = KbName('space');
p.keys.esc                     = KbName('ESCAPE');
p.keys.trigger                 = KbName('5%');
p.keys.start                   = KbName('s');
p.keys.end                     = KbName('e');


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
% KbTriggerWait(p.keys.start);
WaitKeyPress(p.keys.start);
Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
    p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
Screen('Flip', p.ptb.window);
% T.param_triggerOnset(:) = KbTriggerWait(p.keys.trigger);
WaitKeyPress(p.keys.trigger);
T.RAW_param_triggerOnset(:) = GetSecs;
WaitSecs(TR*6);

% __________________________ Experimental loop ___________________________
for trl = 1:size(countBalMat,1)

    % ------------------------------------------------------------------------
    %                        1. Fixtion Jitter 300 / 120 = 2.5 sec
    % -------------------------------------------------------------------------
    jitter1 = countBalMat.jitter(trl);
    Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
        p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
    Screen('FrameRect', p.ptb.window, p.ptb.white, p.rect.allRects, p.rect.penWidthPixels);
    T.RAW_p1_fixation_onset(trl) = Screen('Flip', p.ptb.window);
    WaitSecs(jitter1);
    T.RAW_p1_fixation_offset(trl) = GetSecs;
    T.p1_ptb_fixation_duration(trl) = T.RAW_p1_fixation_offset(trl) - T.RAW_p1_fixation_onset(trl);
    % T.p1_fixation_duration(trl) = countBalMat.jitter(trl);

    % ------------------------------------------------------------------------
    %                               2. cue 0.2 s
    % -------------------------------------------------------------------------
    if string(countBalMat.cue{trl}) == "left"
        Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
            p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
        Screen('FrameRect', p.ptb.window, p.ptb.white, p.rect.allRects, p.rect.penWidthPixels);
        Screen('FrameRect', p.ptb.window, p.ptb.green, p.rect.leftRects, p.rect.penWidthPixels);
        T.RAW_p2_cue_onset(trl) = Screen('Flip', p.ptb.window);
        WaitSecs(cue_duration);
        T.RAW_p2_cue_offset(trl) = GetSecs;
        T.p2_cue_duration(trl) = T.RAW_p2_cue_offset(trl)- T.RAW_p2_cue_onset(trl);

    elseif string(countBalMat.cue{trl}) == "right"
        Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
            p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
        Screen('FrameRect', p.ptb.window, p.ptb.white, p.rect.allRects, p.rect.penWidthPixels);
        Screen('FrameRect', p.ptb.window, p.ptb.green, p.rect.rightRects, p.rect.penWidthPixels);
        T.RAW_p2_cue_onset(trl) = Screen('Flip', p.ptb.window);
        WaitSecs(cue_duration);
        T.RAW_p2_cue_offset(trl) = GetSecs;
        T.p2_cue_duration(trl) = T.RAW_p2_cue_offset(trl)- T.RAW_p2_cue_onset(trl);
    else
        error('check!');
    end
    % T.p2_cue_type{trl} = string(countBalMat.cue(trl));


    % ------------------------------------------------------------------------
    %                              3. target 2 s
    % -------------------------------------------------------------------------
    if string(countBalMat.target{trl}) == "left"
        Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
            p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
        Screen('FrameRect', p.ptb.window, p.ptb.white, p.rect.allRects, p.rect.penWidthPixels);
        Screen('DrawDots', p.ptb.window, [p.target.leftXpos p.ptb.yCenter], p.target.dotSizePix, p.ptb.green, [], 2);
        T.RAW_p3_target_onset(trl) = Screen('Flip', p.ptb.window);
    elseif string(countBalMat.target{trl}) == "right"
        Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
            p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
        Screen('FrameRect', p.ptb.window, p.ptb.white, p.rect.allRects, p.rect.penWidthPixels);
        Screen('DrawDots', p.ptb.window, [p.target.rightXpos p.ptb.yCenter], p.target.dotSizePix, p.ptb.green, [], 2);
        T.RAW_p3_target_onset(trl) = Screen('Flip', p.ptb.window);
    end

    % ------------------------------------------------------------------------
    %                            4. button press within 2s
    % -------------------------------------------------------------------------
    % 4.1. record key press _______________________________________________
    %     while respToBeMade && timeStim < trial_duration
    while (GetSecs - T.RAW_p3_target_onset(trl)) < trial_duration
        T.p4_responsekey(trl) = 0;
        T.p4_responsekeyname{trl} = 'nan';
        RT = 99;
        [keyIsDown,secs, keyCode] = KbCheck;

        if keyCode(p.keys.esc)
            ShowCursor;
            sca;
            return
        elseif keyCode(p.keys.left)
            RT = secs - T.RAW_p3_target_onset(trl);
            T.p4_RT(trl) = secs - T.RAW_p3_target_onset(trl);
            T.p4_responsekey(trl)  = 1;
            T.p4_responsekeyname{trl} = 'left';
            WaitSecs(0.5);
            remainder_time = trial_duration - 0.5 - RT;
            Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
                p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
            T.RAW_p4_fixation_fillin(trl) = Screen('Flip', p.ptb.window);
            WaitSecs(remainder_time);
            T.p4_fixation_duration(trl) = remainder_time;


        elseif keyCode(p.keys.right)
            RT = secs - T.RAW_p3_target_onset(trl);
            T.p4_RT(trl) = secs - T.RAW_p3_target_onset(trl);
            T.p4_responsekey(trl)  = 2; % right
            T.p4_responsekeyname{trl} = 'right';
            WaitSecs(0.5);
            remainder_time = trial_duration - 0.5 - RT;
            Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
                p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
            T.RAW_p4_fixation_fillin(trl) = Screen('Flip', p.ptb.window);
            WaitSecs(remainder_time);
            T.p4_fixation_duration(trl) = remainder_time;

        end

    end
    T.RAW_p4_responseonset(trl) = secs;
    % T.p4_responsekey(trl) = response;
    % T.p4_RT(trl) = RT;

    Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
        p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
    T.RAW_p5_fixation_onset(trl) = Screen('Flip', p.ptb.window);
    WaitSecs(0.2)
end


% _________________________ End Instructions _____________________________
end_texture = Screen('MakeTexture',p.ptb.window, imread(instruct_end));
Screen('DrawTexture',p.ptb.window,end_texture,[],[]);
T.RAW_param_end_instruct_onset(:) = Screen('Flip',p.ptb.window);
T.experimentDuration(:) = T.RAW_param_end_instruct_onset(1) - T.RAW_param_triggerOnset(1);

% ------------------------------------------------------------------------
%                              save parameter
% -------------------------------------------------------------------------
T.p1_fixation_onset(:) = T.RAW_p1_fixation_onset(:) - T.RAW_param_triggerOnset(:) - (TR*6);
T.p1_fixation_offset(:) = T.RAW_p1_fixation_offset(:) - T.RAW_param_triggerOnset(:) - (TR*6);
T.p2_cue_onset(:) = T.RAW_p2_cue_onset(:) - T.RAW_param_triggerOnset(:) - (TR*6);
T.p2_cue_offset(:) = T.RAW_p2_cue_offset(:) - T.RAW_param_triggerOnset(:) - (TR*6);
T.p3_target_onset(:) = T.RAW_p3_target_onset(:) - T.RAW_param_triggerOnset(:) - (TR*6);
T.p4_responseonset(:) = T.RAW_p4_responseonset(:) - T.RAW_param_triggerOnset(:) - (TR*6);
T.p4_fixation_fillin(:) = T.RAW_p4_fixation_fillin(:) - T.RAW_param_triggerOnset(:) - (TR*6);
T.p5_fixation_onset(:) = T.RAW_p5_fixation_onset(:) - T.RAW_param_triggerOnset(:) - (TR*6);

saveFileName = fullfile(sub_save_dir,[strcat('sub-', sprintf('%04d', sub_num)), '_task-',taskname,'_beh.csv' ]);
writetable(T,saveFileName);

psychtoolbox_saveFileName = fullfile(sub_save_dir, [strcat('sub-', sprintf('%04d', sub_num)), '_task-',taskname,'_psychtoolbox_params.mat' ]);
save(psychtoolbox_saveFileName, 'p');

WaitKeyPress(p.keys.end);
WaitSecs(0.2);
ShowCursor;
close all;
sca;

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


end
