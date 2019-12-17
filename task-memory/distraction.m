function distraction(p, cfg, task_folder,sub_num)

% % set up parameters
%
% Screen('Preference', 'SkipSyncTests', 1);
% PsychDefaultSetup(2);
% screens                        = Screen('Screens'); % Get the screen numbers
% p.ptb.screenNumber             = max(screens); % Draw to the external screen if avaliable
% p.ptb.white                    = WhiteIndex(p.ptb.screenNumber); % Define black and white
% p.ptb.black                    = BlackIndex(p.ptb.screenNumber);
% [p.ptb.window, p.ptb.rect]     = PsychImaging('OpenWindow',p.ptb.screenNumber,p.ptb.black);
% [p.ptb.screenXpixels, p.ptb.screenYpixels] = Screen('WindowSize',p.ptb.window);
% p.ptb.ifi                      = Screen('GetFlipInterval',p.ptb.window);
% Screen('BlendFunction', p.ptb.window,'GL_SRC_ALPHA','GL_ONE_MINUS_SRC_ALPHA'); % Set up alpha-blending for smooth (anti-aliased) lines
% Screen('TextFont', p.ptb.window, 'Arial');
% Screen('TextSize', p.ptb.window, 36);
% [p.ptb.xCenter, p.ptb.yCenter] = RectCenter(p.ptb.rect);
% p.fix.sizePix                  = 40; % size of the arms of our fixation cross
% p.fix.lineWidthPix             = 4; % Set the line width for our fixation cross
% p.fix.xCoords                  = [-p.fix.sizePix p.fix.sizePix 0 0];
% p.fix.yCoords                  = [0 0 -p.fix.sizePix p.fix.sizePix];
% p.fix.allCoords                = [p.fix.xCoords; p.fix.yCoords];
%
%
% KbName('UnifyKeyNames');
% p.keys.confirm                 = KbName('return');
% p.keys.right                   = KbName('4$');
% p.keys.left                    = KbName('1!');
% p.keys.space                   = KbName('space');
% p.keys.esc                     = KbName('ESCAPE');
% p.keys.trigger                 = KbName('5%');
% p.keys.start                   = KbName('s');
% p.keys.end                     = KbName('e');
main_dir = cfg.files.expDir;

%% G. instructions _____________________________________________________
calc_main                      = fullfile(main_dir, 'instructions', 'memory_calc.png');
instruct_filepath              = fullfile(main_dir, 'distraction_task', task_folder);
instruct_start1                = fullfile(instruct_filepath, 'distraction_intro01.png' );
instruct_start2                = fullfile(instruct_filepath, 'distraction_intro02.png' );
instruct_main1                 = fullfile(instruct_filepath, 'distraction_main01.png' );
instruct_main1_prompt          = fullfile(instruct_filepath, 'distraction_main02.png' );
instruct_main1_L               = fullfile(instruct_filepath, 'distraction_main02_L.png' );
instruct_main1_R               = fullfile(instruct_filepath, 'distraction_main02_R.png' );
instruct_main2                 = fullfile(instruct_filepath, 'distraction_main03.png' );
instruct_main2_prompt          = fullfile(instruct_filepath, 'distraction_main04.png' );
instruct_main2_L               = fullfile(instruct_filepath, 'distraction_main04_L.png' );
instruct_main2_R               = fullfile(instruct_filepath, 'distraction_main04_R.png' );
fixation                       = fullfile(instruct_filepath, 'fixation.png' );

%% D. making output table _________________________________________________
vnames = {'param_fmriSession',... %'param_counterbalanceVer','param_triggerOnset',...
'calc_start', ...
'p1_fixation',...
 'p2_instruct1', 'p2_instruct2',...
  'p3_instruct1', 'p3_instruct2', 'p3_responsekey','p3_responsekeyname', 'p3_responseRT'};


    % 'p1_fixation_onset', 'p1_fixation_duration','p1_fixation_offset','p1_ptb_fixation_duration',...
    % 'p2_cue_type','p2_cue_onset','p2_cue_offset','p2_cue_duration',...
    % 'p3_target_onset',...
    % 'p4_responseonset','p4_responsekey','p4_RT', 'p4_fixation_fillin', 'p4_fixation_duration',...
    % 'p5_fixation_onset'};
T                              = array2table(zeros(2,size(vnames,2)));
T.Properties.VariableNames     = vnames;
T.p3_responsekeyname           = cell(2,1);
T.param_fmriSession(:)         = 4;
%% -----------------------------------------------------------------------------
%                              Main task
% ______________________________________________________________________________

% main instruction
main = Screen('MakeTexture',p.ptb.window, imread(calc_main));
Screen('DrawTexture',p.ptb.window,main,[],[]);
T.calc_start(:) = Screen('Flip',p.ptb.window);
WaitSecs(4); %4

% fixation
fix = Screen('MakeTexture',p.ptb.window, imread(fixation));
Screen('DrawTexture',p.ptb.window,fix,[],[]);
T.p1_fixation(1) = Screen('Flip',p.ptb.window);
WaitSecs(1); %4

% instruction
instruct1 = Screen('MakeTexture',p.ptb.window, imread(instruct_start1));
Screen('DrawTexture',p.ptb.window,instruct1,[],[]);
T.p2_instruct1(1) = Screen('Flip',p.ptb.window);
WaitSecs(3);%3

instruct2 = Screen('MakeTexture',p.ptb.window, imread(instruct_start2));
Screen('DrawTexture',p.ptb.window,instruct2,[],[]);
T.p2_instruct2(1) = Screen('Flip',p.ptb.window);
WaitSecs(3);%3

% main task number 1
main1 = Screen('MakeTexture',p.ptb.window, imread(instruct_main1));
Screen('DrawTexture',p.ptb.window,main1,[],[]);
T.p3_instruct1(1) = Screen('Flip',p.ptb.window);
WaitSecs(45);%45

main1_prompt = Screen('MakeTexture',p.ptb.window, imread(instruct_main1_prompt));
Screen('DrawTexture',p.ptb.window,main1_prompt,[],[]);
timing.initialized = Screen('Flip',p.ptb.window);
T.p3_instruct2(1) = timing.initialized;
task_duration = 5;
while GetSecs - timing.initialized < task_duration
    [keyIsDown,secs, keyCode] = KbCheck;
    RT = 99;
    response = 99;
    responsekeyname = 'NaN';
    if keyCode(p.keys.esc)
        ShowCursor;
        sca;
        return
    elseif keyCode(p.keys.left)
        RT = secs - timing.initialized;
        response = keyCode(p.keys.right);
        responsekeyname = 'left';
        main1_L = Screen('MakeTexture',p.ptb.window, imread(instruct_main1_L));
        Screen('DrawTexture',p.ptb.window,main1_L,[],[]);
        Screen('Flip', p.ptb.window);
%         WaitSecs(0.5);
%         remainder_time = task_duration-0.5-RT;
%         Screen('DrawTexture',p.ptb.window,fix,[],[]);
%         Screen('Flip', p.ptb.window);
%         WaitSecs(remainder_time);
    elseif keyCode(p.keys.right)

        RT = secs - timing.initialized;
        response = keyCode(p.keys.right);
        responsekeyname = 'right';
        main1_R = Screen('MakeTexture',p.ptb.window, imread(instruct_main1_R));
        Screen('DrawTexture',p.ptb.window,main1_R,[],[]);
        Screen('Flip', p.ptb.window);
%         WaitSecs(0.5);
%
%         remainder_time = task_duration-0.5-RT;
%         Screen('DrawTexture',p.ptb.window,fix,[],[]);
%         Screen('Flip', p.ptb.window);
%         WaitSecs(remainder_time);
    end
end
T.p3_responsekey(1) = response;
T.p3_responseRT(1) = RT;
T.p3_responsekeyname{1} = responsekeyname;

% fixation
fix = Screen('MakeTexture',p.ptb.window, imread(fixation));
Screen('DrawTexture',p.ptb.window,fix,[],[]);
T.p1_fixation(2) = Screen('Flip',p.ptb.window);
WaitSecs(5); %4

% main task number 2
main2 = Screen('MakeTexture',p.ptb.window, imread(instruct_main2));
Screen('DrawTexture',p.ptb.window,main2,[],[]);
T.p3_instruct1(2) = Screen('Flip',p.ptb.window);
WaitSecs(45);

main2_prompt = Screen('MakeTexture',p.ptb.window, imread(instruct_main2_prompt));
Screen('DrawTexture',p.ptb.window,main2_prompt,[],[]);
timing.initialized =Screen('Flip',p.ptb.window);


T.p3_instruct2(2) = timing.initialized;
task_duration = 5;
while GetSecs - timing.initialized < task_duration
    response = 99;
    [keyIsDown,secs, keyCode] = KbCheck;
    if keyCode(p.keys.esc)
        ShowCursor;
        sca;
        return
    elseif keyCode(p.keys.left)
        RT = secs - timing.initialized;
        response = 1;
        responsekeyname = 'left';
        main2_L = Screen('MakeTexture',p.ptb.window, imread(instruct_main2_L));
        Screen('DrawTexture',p.ptb.window,main2_L,[],[]);
        Screen('Flip', p.ptb.window);
%         WaitSecs(0.5);

%         remainder_time = task_duration-0.5-RT;
%         Screen('DrawTexture',p.ptb.window,fix,[],[]);
%         Screen('Flip', p.ptb.window);
%         WaitSecs(remainder_time);
    elseif keyCode(p.keys.right)

        RT = secs - timing.initialized;
        response = 2;
        responsekeyname = 'right';
        main2_R = Screen('MakeTexture',p.ptb.window, imread(instruct_main2_R));
        Screen('DrawTexture',p.ptb.window,main2_R,[],[]);
        Screen('Flip', p.ptb.window);
%         WaitSecs(0.5);
%
%         remainder_time = task_duration-0.5-RT;
%         Screen('DrawTexture',p.ptb.window,fix,[],[]);
%         Screen('Flip', p.ptb.window);
%         WaitSecs(remainder_time);
    end
end
% fixation

T.p3_responsekey(2)= response;
T.p3_responseRT(2) = RT;
T.p3_responsekeyname{2} = responsekeyname;

fix = Screen('MakeTexture',p.ptb.window, imread(fixation));
Screen('DrawTexture',p.ptb.window,fix,[],[]);
T.calc_end(:) = Screen('Flip',p.ptb.window);
WaitSecs(5); %4
% close
T.calc_duration(:) = T.calc_end(1) +5 - T.calc_start(1);

%% __________________________ save parameter ___________________________________
sub_save_dir = cfg.files.sesSaveDir;
saveFileName = fullfile(sub_save_dir,[strcat('sub-', sprintf('%04d', sub_num)), '_task-memory-distraction-',task_folder, '_beh.csv' ]);
writetable(T,saveFileName);

end
