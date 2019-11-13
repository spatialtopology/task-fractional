%% A. Psychtoolbox parameters _________________________________________________
global p

input_counterbalance_file = 'sub-001_task-posner_counterbalance';

% debug mode % Initial
debug     = 1;   % PTB Debugging

AssertOpenGL;
commandwindow;
ListenChar(2);
if debug
    ListenChar(0);
    PsychDebugWindowConfiguration;
end



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

% 2nd attempt
p.rect.baseRect                = [0 0 200 200];
p.rect.squareXpos = [p.ptb.screenXpixels * 0.35 p.ptb.screenXpixels * 0.65];
numSquares = length(p.rect.squareXpos);
p.rect.allRects = nan(4, 3);
for i = 1:numSquares
    p.rect.allRects(:, i) = CenterRectOnPointd(p.rect.baseRect, p.rect.squareXpos(i), p.ptb.yCenter);
end
p.rect.leftRects = CenterRectOnPointd(p.rect.baseRect, p.ptb.screenXpixels * 0.35, p.ptb.yCenter);
p.rect.rightRects = CenterRectOnPointd(p.rect.baseRect, p.ptb.screenXpixels * 0.65, p.ptb.yCenter);
p.rect.penWidthPixels = 6;

p.target.dotSizePix = 20;
p.target.leftXpos = p.ptb.screenXpixels * 0.35;
p.target.rightXpos = p.ptb.screenXpixels * 0.65;
%  1st attempt
p.rect.baseRect                = [0 0 200 200];
p.rect.LcenteredRect           = CenterRectOnPointd(p.rect.baseRect, -100, p.ptb.yCenter);
p.rect.RcenteredRect           = CenterRectOnPointd(p.rect.baseRect, 100, p.ptb.yCenter);
%% B. Directories ______________________________________________________________
task_dir                       = pwd;
sub = 1;
main_dir                       = fileparts(task_dir);
taskname                       = 'posner';

counterbalancefile             = fullfile(main_dir,'design', 's04_counterbalance', [input_counterbalance_file, '.csv']);
countBalMat                    = readtable(counterbalancefile);

sub_save_dir                    = fullfile(main_dir, 'data', strcat('sub-', sprintf('%03d', sub)), 'beh' );
if ~exist(sub_save_dir, 'dir')
    mkdir(sub_save_dir)
end


%% D. making output table ________________________________________________________
vnames = {'param_fmriSession', 'param_counterbalanceVer','param_counterbalanceBlockNum',...
    'p1_fixation_onset', 'p1_fixation_duration',...
    'p2_cue_onset','p1_cue_offset','p2_cue_type',...
    'p3_target_onset',...
    'p4_responseonset','p4_responsekey','p4_RT'};


T                              = array2table(zeros(size(countBalMat,1),size(vnames,2)));
T.Properties.VariableNames     = vnames;

% a                              = split(counterbalancefile,filesep);
% version_chunk                  = split(extractAfter(a(end),"ver-"),"_");
% block_chunk                    = split(extractAfter(a(end),"block-"),["-", "."]);
% T.param_counterbalanceVer(:)   = str2double(version_chunk{1});
% T.param_counterbalanceBlockNum(:) = str2double(block_chunk{1});
% T.param_videoSubject           = countBalMat.video_subject;
% T.param_videoFilename          = countBalMat.video_filename;
% T.param_cue_type               = countBalMat.cue_type;
% T.param_administer_type        = countBalMat.administer;
% T.param_cond_type              = countBalMat.cond_type;
% T.p2_cue_type                  = countBalMat.cue_type;
% T.p2_cue_filename              = countBalMat.cue_image;
% T.p5_administer_type           = countBalMat.administer;
% T.p5_administer_filename       = countBalMat.video_filename;

%% E. Keyboard information _____________________________________________________
KbName('UnifyKeyNames');
p.keys.confirm                 = KbName('return');
p.keys.right                   = KbName('j');
p.keys.left                    = KbName('f');
p.keys.space                   = KbName('space');
p.keys.esc                     = KbName('ESCAPE');
p.keys.trigger                 = KbName('5%');
p.keys.start                   = KbName('s');
p.keys.end                     = KbName('e');

%% F. fmri Parameters __________________________________________________________
TR                             = 0.46;

%% G. Instructions _____________________________________________________________
instruct_start                 = 'The cueing task is about to start. \n Please wait for the experimenter';
instruct_end                   = 'This is the end of the experiment. \n Please wait for the experimenter';


%% -----------------------------------------------------------------------------
%                              Start Experiment
% ------------------------------------------------------------------------------

%% ______________________________ Instructions _________________________________
Screen('TextSize',p.ptb.window,72);
DrawFormattedText(p.ptb.window,instruct_start,'centerblock',p.ptb.screenYpixels/2,255);
Screen('Flip',p.ptb.window);

%% _______________________ Wait for Trigger to Begin ___________________________
DisableKeysForKbCheck([]);
KbTriggerWait(p.keys.start);
KbTriggerWait(p.keys.trigger);
% T.param_triggerOnset(:) = KbTriggerWait(p.keys.trigger);

% WaitSecs(TR*6);

% sequence

% fixation
%% 0. Experimental loop ________________________________________________________
for trl = 1:size(countBalMat,1)
    
    
    %% 1. Fixtion Jitter 0-4 sec ___________________________________________________
    jitter1 = countBalMat.jitter(trl);
    Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
        p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
    Screen('FrameRect', p.ptb.window, p.ptb.white, p.rect.allRects, p.rect.penWidthPixels);
    fStart1 = Screen('Flip', p.ptb.window);
    WaitSecs(jitter1);
    fEnd1 = GetSecs;
    
    T.p1_fixation_onset(trl) = fStart1;
    T.p1_fixation_duration(trl) = fEnd1 - fStart1;
    
    % % 2. cue ________________________________________________________________________
    % Screen('FrameRect', p.ptb.window, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter])
    if string(countBalMat.cue{trl}) == "left"
        Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
            p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
        Screen('FrameRect', p.ptb.window, p.ptb.white, p.rect.allRects, p.rect.penWidthPixels);
        Screen('FrameRect', p.ptb.window, p.ptb.green, p.rect.leftRects, p.rect.penWidthPixels);
        T.p2_cue_onset(trl) = Screen('Flip', p.ptb.window);
        WaitSecs(0.200);
        T.p2_cue_offset(trl) = GetSecs;
        T.p2_cue_duration(trl) = T.p2_cue_offset(trl)- T.p2_cue_onset(trl);
        
    elseif string(countBalMat.cue{trl}) == "right"
        Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
            p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
        Screen('FrameRect', p.ptb.window, p.ptb.white, p.rect.allRects, p.rect.penWidthPixels);
        Screen('FrameRect', p.ptb.window, p.ptb.green, p.rect.rightRects, p.rect.penWidthPixels);
        T.p2_cue_onset(trl) = Screen('Flip', p.ptb.window);
        WaitSecs(0.200);
        
        %timing.initialized = GetSecs;
        %T.p2_cue_offset(trl) = timing.initialized;
        T.p2_cue_offset(trl) = GetSecs;
        T.p2_cue_duration(trl) = T.p2_cue_offset(trl)- T.p2_cue_onset(trl);
    else
        error('check!');
    end
    
    
    % 3. target _______________________________________________________________________
    %Screen('Flip',p.ptb.window);
    % T.p5_administer_onset(trl) = timing.initialized;
    duration = 2.500;
    timing.initialized=GetSecs;
    response = NaN;
    while GetSecs < timing.initialized + duration
        
        if string(countBalMat.target{trl}) == "left"
            % if counterbalanceMat target_appear == left
            Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
                p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
            Screen('FrameRect', p.ptb.window, p.ptb.white, p.rect.allRects, p.rect.penWidthPixels);
            Screen('DrawDots', p.ptb.window, [p.target.leftXpos p.ptb.yCenter], p.target.dotSizePix, p.ptb.green, [], 2);
            
            % Screen('FrameRect', p.ptb.window, p.ptb.green, p.rect.leftRects, p.rect.penWidthPixels);
            T.p3_target_onset(trl) = Screen('Flip', p.ptb.window);
            
            [keyIsDown,secs, keyCode] = KbCheck;
            if keyIsDown
                
                if keyCode(p.keys.esc)
                    ShowCursor;
                    sca;
                    return
                    
                elseif keyCode(p.keys.left)
                    RT = secs - timing.initialized;
                    response = 1;
                    
                    WaitSecs(0.5);
                    
                    remainder_time = duration-0.5-RT;
                    Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
                        p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
                    Screen('Flip', p.ptb.window);
                    WaitSecs(remainder_time);
                    
                elseif keyCode(p.keys.right)
                    
                    RT = secs - timing.initialized;
                    response = 2;
                    % respToBeMade = false;
                    
                    % fill in with fixation cross
                    remainder_time = duration-0.5-RT;
                    Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
                        p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
                    Screen('Flip', p.ptb.window);
                    WaitSecs(remainder_time);
                else
                    % fill in with fixation cross
                    RT = secs - timing.initialized;
                    response = NaN;
                    Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
                        p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
                    Screen('Flip', p.ptb.window);
                    WaitSecs(duration);
                end
                
            end
            while KbCheck(-3); end
        elseif string(countBalMat.target{trl}) == "right"
            % if counterbalanceMat target_appear == left
            Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
                p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
            Screen('FrameRect', p.ptb.window, p.ptb.white, p.rect.allRects, p.rect.penWidthPixels);
            Screen('DrawDots', p.ptb.window, [p.target.rightXpos p.ptb.yCenter], p.target.dotSizePix, p.ptb.green, [], 2);
            
            % Screen('FrameRect', p.ptb.window, p.ptb.green, p.rect.leftRects, p.rect.penWidthPixels);
            T.p3_target_onset(trl) = Screen('Flip', p.ptb.window);
            %     WaitSecs(0.200);
            %     target_offset = GetSecs;
            %     target_duration = target_offset-target_onset;
            
            [keyIsDown,secs, keyCode] = KbCheck;
            if keyIsDown
                if keyCode(p.keys.esc)
                    ShowCursor;
                    sca;
                    return
                    
                elseif keyCode(p.keys.left)
                    RT = secs - timing.initialized;
                    response = 1;
                    
                    WaitSecs(0.5);
                    
                    remainder_time = duration-0.5-RT;
                    Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
                        p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
                    Screen('Flip', p.ptb.window);
                    WaitSecs(remainder_time);
                    
                elseif keyCode(p.keys.right)
                    
                    RT = secs - timing.initialized;
                    response = 2;
                    % respToBeMade = false;
                    
                    % fill in with fixation cross
                    remainder_time = duration-0.5-RT;
                    Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
                        p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
                    Screen('Flip', p.ptb.window);
                    WaitSecs(remainder_time);
                else
                    RT = secs - timing.initialized;
                    response = NaN;
                    % fill in with fixation cross
                    Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
                        p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
                    Screen('Flip', p.ptb.window);
                    WaitSecs(duration);
                end
            end
            while KbCheck(-3); end
            % cue to target duration: 200ms
            % response: give 2s
        end
    end
    % response
    % 4. key press _______________________________________________________________
 
    
    T.p4_responseonset(trl) = secs;
    T.p4_responsekey(trl) = response;
    T.p4_RT(trl) = secs - timing.initialized;
end

%% ______________________________ Instructions _________________________________
Screen('TextSize',p.ptb.window,72);
DrawFormattedText(p.ptb.window,instruct_end,'justifytomax',p.ptb.screenYpixels/2+150,255);
Screen('Flip',p.ptb.window);
DisableKeysForKbCheck([]);
KbTriggerWait(p.keys.end);



%% __________________________ save parameter ___________________________________
saveFileName = fullfile(sub_save_dir,[strcat('sub-', sprintf('%03d', sub)), '_task-',taskname,'_beh.csv' ]);
writetable(T,saveFileName);

% traject_saveFileName = fullfile(sub_save_dir, [strcat('sub-', sprintf('%03d', sub)), '_task-',taskname,'_beh_trajectory.mat' ]);
% save(traject_saveFileName, 'rating_Trajectory');

psychtoolbox_saveFileName = fullfile(sub_save_dir, [strcat('sub-', sprintf('%03d', sub)), '_task-',taskname,'_psychtoolbox_params.mat' ]);
save(psychtoolbox_saveFileName, 'p');

close all;
sca;

