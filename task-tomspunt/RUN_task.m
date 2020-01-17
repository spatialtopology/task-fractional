function RUN_task(sub_num)
order = 0;
test_tag = 0;
% ---------------------
% debug mode % Initial
% debug     = 1;   % PTB Debugging
%
% AssertOpenGL;
% commandwindow;
% ListenChar(2);
% if debug
%     ListenChar(0);
%     PsychDebugWindowConfiguration;
% end

global p
Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(2);
% RUN_TASK  Run Why/How Localizer Task
%
%   USAGE: run_task([order], [test_tag])
%
%   OPTIONAL ARGUMENTS
%       order:      choose from 1,2,3, or 4 - 0 (default) will choose randomly
%       test_tag:   if set to 1, will quit after first block
%
%   This function accepts two arguments. The first specifies the order to
%   use. There are 4 orders to choose from. If you do not specify this
%   argument, if you leave it empty, or if you define as zero, then the
%   order will be randomly chosen for you. The second argument, when
%   specified with the value of "1", will do a brief test run of the task
%   (which lasts only 20 seconds).
%
%   EXAMPLE USAGE
%    >> run_task        % Runs a randomly chosen order of the full task
%    >> run_task(3)     % Runs order #3 of the full task
%    >> run_task(0, 1)  % Does a brief test run of a randomly chosen order
%
%   Total runtime depends on settings in the task_defaults.m file that
%   should be in the same folder as this file. The default runtime from
%   trigger onset is 304 seconds. This corresponds to the 'fast' setting
%   under defaults.pace in the task_defaults.m file. The default runtime
%   for the 'slow' setting is 382 seconds. These values may be
%   automatically adjusted to be a multiple of your TR, which is also
%   specified in the task_defaults.m file. See the task_defaults.m file for
%   further information. To see the actual run time for the settings you've
%   specified, simply run this function.
%
%   COLUMN KEY FOR KEY OUTPUT VARIABLES (SAVED ON TASK COMPLETION)
%
%     blockSeeker (stores block-wise runtime data)
%     1 - block #
%     2 - condition (1=WhyFace, 2=WhyHand, 3=HowFace, 4=HowHand)
%     3 - scheduled onset (s)
%     4 - cue # (corresponds to variables preblockcues & isicues located in
%     a structure stored in the design.mat file. Both are cell arrays
%     containing the filenames for the cue screens contained in thefolder
%     "questions")
%
%     trialSeeker (stores trial-wise runtime data)
%     1 - block #
%     2 - trial # (within-block)
%     3 - condition (1=WhyFace, 2=WhyHand, 3=HowFace, 4=HowHand)
%     4 - normative response (1=Yes, 2=No) [used to evaluate accuracy]
%     5 - stimulus # (corresponds to qim & qdata from design.mat file)
%     6 - (saved during runtime) actual trial onset (s)
%     7 - (saved during runtime) response time to onset (s) [0 if No Resp]
%     8 - (saved during runtime) actual response [0 if No Resp]
%     9 - (saved during runtime) actual trial offset
%
%   FOR DESIGN DETAILS, SEE STUDY 3 IN:
%    Spunt, R. P., & Adolphs, R. (2014). Validating the why/how contrast
%    for functional mri studies of theory of mind. Neuroimage, 99, 301-311.
%
%   This code uses Psychophysics Toolbox Version 3 (PTB-3) running in
%   MATLAB (The Mathworks, Inc.). To learn more: http://psychtoolbox.org
%_______________________________________________________________________
% Copyright (C) 2014  Bob Spunt, Ph.D.
if nargin<1, order = 0; end
if nargin<2, test_tag = 0; end
if isempty(order), order = 0; end

% Check for Psychtoolbox ________________________________________________
% try
%     ptbVersion = PsychtoolboxVersion;
% catch
%     url = 'https://psychtoolbox.org/PsychtoolboxDownload';
%     fprintf('\n\t!!! WARNING !!!\n\tPsychophysics Toolbox does not appear to on your search path!\n\tSee: %s\n\n', url);
%     return
% end
% PsychDefaultSetup(2);
% Print Title ________________________________________________
script_name='----------- Images Test -----------'; boxTop(1:length(script_name))='=';
fprintf('\n%s\n%s\n%s\n',boxTop,script_name,boxTop)

% DEFAULTS ________________________________________________
defaults = task_defaults;
KbName('UnifyKeyNames');
trigger = KbName(defaults.trigger);
% KbTriggerWait(trigger);
TR = 0.46;
% T.param_triggerOnset(:) = KbTriggerWait(p.keys.trigger);


addpath(defaults.path.utilities);

% -------------------------------------------------------------------------
%                                Parameters
% _________________________________________________________________________
% task_dir                        = pwd;
main_dir                        = pwd;
taskname                        = 'tomspunt';


sub_save_dir                    = fullfile(main_dir, 'data', strcat('sub-', sprintf('%04d', sub_num)), 'beh' );
if ~exist(sub_save_dir, 'dir')
    mkdir(sub_save_dir)
end
% Load Design and Setup Seeker Variable ________________________________________________
load([defaults.path.design filesep 'design.mat']);
if order==0, randidx = randperm(4); order = randidx(1); end
% design              = alldesign{order};
design              = alldesign{order};
switch lower(defaults.language)
    case 'german'
        pbc_brief           = design.preblockcues;
    otherwise
        pbc_brief           = regexprep(design.preblockcues,'Is the person ','');
end
trialSeeker         = design.trialSeeker;
trialSeeker(:,6:9)  = 0;
blockSeeker         = design.blockSeeker;
BOA                 = diff([blockSeeker(:,3); design.totalTime]);
nTrialsBlock        = length(unique(trialSeeker(:,2)));
switch lower(defaults.pace)
    case 'fast'
        defaults.cueDur         = 2.10;   % dur of question presentation
        defaults.maxDur         = 1.70;   % (max) dur of trial
        defaults.ISI            = 0.30;   % dur of interval between stimuli within blocks
        defaults.firstISI       = 0.15;   % dur of interval between question and first trial of each block
    case 'slow'
        defaults.cueDur         = 2.50;   % dur of question presentation
        defaults.maxDur         = 2.25;   % (max) dur of trial
        defaults.ISI            = 0.30;   % dur of interval between stimuli within blocks
        defaults.firstISI       = 0.15;   % dur of interval between question and first trial of each block
        maxBlockDur             = defaults.cueDur + defaults.firstISI + (nTrialsBlock*defaults.maxDur) + (nTrialsBlock-1)*defaults.ISI;
        BOA                     = BOA + (maxBlockDur - min(BOA));
    otherwise
        fprintf('\n\n| - Invalid option in "defaults.pace" \n| - Valid options: ''fast'' or ''slow'' (change in task_defaults.m)\n\n');
        return;
end
eventTimes          = cumsum([defaults.prestartdur; BOA]);
blockSeeker(:,3)    = eventTimes(1:end-1);
numTRs              = ceil(eventTimes(end)/defaults.TR);
totalTime           = defaults.TR*numTRs;


% D. making output table ________________________________________________________


vnames = {'param_fmriSession', 'param_counterbalanceVer','param_triggerOnset',...
                                'param_block_num','param_trial_num',...
                                'param_cond_num','param_cond_type','param_normative_response',...
                                'param_stimulus_no','param_filename',...
                                'p1_trial_onset','p1_isi',...
                                'p2_RT','p2_actual_response_key','p3_trialoffset',...
                                'param_end_instruct_onset', 'param_experimentDuration'};
T                              = array2table(zeros(length(design.trialSeeker),size(vnames,2)));
T.Properties.VariableNames     = vnames;
T.param_cond_type              = cell(length(design.trialSeeker),1);
% condition (1=WhyFace, 2=WhyHand, 3=HowFace, 4=HowHand)
T.param_counterbalanceVer(:)      = order;
T.param_cond_type              = cell(length(design.qim),1);
T.param_filename               = design.qim(:,2);
T.param_block_num              = trialSeeker(:,1);
T.param_trial_num              = trialSeeker(:,2);
T.param_cond_num               = trialSeeker(:,3);
% T.param_cond_type              = % condition (1=WhyFace, 2=WhyHand, 3=HowFace, 4=HowHand)
T.param_normative_response     = trialSeeker(:,4);
T.param_stimulus_no            = trialSeeker(:,5);
%     trialSeeker (stores trial-wise runtime data)
%     1 - block #
%     2 - trial # (within-block)
%     2 - condition (1=WhyFace, 2=WhyHand, 3=HowFace, 4=HowHand)
%     4 - normative response (1=Yes, 2=No) [used to evaluate accuracy]
%     5 - stimulus # (corresponds to qim & qdata from design.mat file)


% Print Defaults ________________________________________________
fprintf('Test Duration:         %d secs (%d TRs)', totalTime, numTRs);
fprintf('\nTrigger Key:           %s', defaults.trigger);
fprintf(['\nValid Response Keys:   %s' repmat(', %s', 1, length(defaults.valid_keys)-1)], defaults.valid_keys{:});
fprintf('\nForce Quit Key:        %s\n', defaults.escape);
fprintf('%s\n', repmat('-', 1, length(script_name)));

% Get Subject ID ________________________________________________
if ~test_tag
    subjectID = ptb_get_input_string('\nEnter Subject ID: ');
else
    subjectID = 'TEST';
end

% Setup Input Device(s) %%
switch upper(computer)
  case 'MACI64'
    inputDevice = ptb_get_resp_device;
  case {'PCWIN','PCWIN64'}
    % JMT:
    % Do nothing for now - return empty chosen_device
    % Windows XP merges keyboard input and will process external keyboards
    % such as the Silver Box correctly
    inputDevice = [];
  otherwise
    % Do nothing - return empty chosen_device
    inputDevice = [];
end
resp_set = ptb_response_set([defaults.valid_keys defaults.start defaults.trigger defaults.end defaults.escape]); % response set
%
% Initialize Screen ________________________________________________
% screens                       = Screen('Screens'); % Get the screen numbers
% p.ptb.screenNumber            = max(screens); % Draw to the external screen if avaliable
%
% try
%     w = ptb_setup_screen(0,250,defaults.font.name,defaults.font.size1, defaults.screenres); % setup screen
% catch
%     disp('Could not change to recommend screen resolution. Using current.');
%     w = ptb_setup_screen(0,250,defaults.font.name,defaults.font.size1);
% end
taskname                      = 'tomspunt';
screens                       = Screen('Screens'); % Get the screen numbers
p.ptb.screenNumber            = max(screens); % Draw to the external screen if avaliable
p.ptb.white                   = WhiteIndex(p.ptb.screenNumber); % Define black and white
p.ptb.black                   = BlackIndex(p.ptb.screenNumber);
[p.ptb.window, p.ptb.rect]    = PsychImaging('OpenWindow', p.ptb.screenNumber, p.ptb.black);
[p.ptb.screenXpixels, p.ptb.screenYpixels] = Screen('WindowSize', p.ptb.window);
p.ptb.ifi                      = Screen('GetFlipInterval', p.ptb.window);
Screen('BlendFunction', p.ptb.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % Set up alpha-blending for smooth (anti-aliased) lines
Screen('TextFont', p.ptb.window, 'Arial');
Screen('TextSize', p.ptb.window, 36);
[p.ptb.xCenter, p.ptb.yCenter] = RectCenter(p.ptb.rect);
p.fix.sizePix                  = 40; % size of the arms of our fixation cross
p.fix.lineWidthPix             = 4; % Set the line width for our fixation cross
% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
p.fix.xCoords                  = [-p.fix.sizePix p.fix.sizePix 0 0];
p.fix.yCoords                  = [0 0 -p.fix.sizePix p.fix.sizePix];
p.fix.allCoords                = [p.fix.xCoords; p.fix.yCoords];

w.win = p.ptb.window;
w.rect = p.ptb.rect;
w.white = p.ptb.white;
w.black = p.ptb.black;
HideCursor(p.ptb.screenNumber);
% Initialize Logfile (Trialwise Data Recording) ________________________________________________
d=clock;


if ~exist(defaults.path.data,'dir')
    [canSaveData,saveDataMsg,saveDataMsgID] = mkdir(defaults.path.data);
    if canSaveData == false
        error(saveDataMsgID,'Cannot write in directory %s due to the following error: %s',pwd,saveDataMsg);
    end
end
logfile=fullfile(defaults.path.data, sprintf('LOG_whyhow_sub%s.txt', subjectID));
fprintf('\nA running log of this session will be saved to %s\n',logfile);
fid=fopen(logfile,'a');
if fid<1
    error('could not open logfile!')
end
fprintf(fid,'Started: %s %2.0f:%02.0f\n',date,d(4),d(5));

% Make Images Into Textures ________________________________________________
DrawFormattedText(w.win,sprintf('LOADING\n\n0%% complete'),'center','center',w.white,defaults.font.wrap);
Screen('Flip',w.win);
slideName = cell(length(design.qim));
slideTex = slideName;
for i = 1:length(design.qim)
    slideName{i} = design.qim{i,2};
    tmp1 = imread([defaults.path.stim filesep slideName{i}]);
    tmp2 = tmp1;
    slideTex{i} = Screen('MakeTexture',w.win,tmp2);
    DrawFormattedText(w.win,sprintf('LOADING\n\n%d%% complete', ceil(100*i/length(design.qim))),'center','center',w.white,defaults.font.wrap);
    Screen('Flip',w.win);
end
instructTex = Screen('MakeTexture', w.win, imread([defaults.path.stim filesep 'instruction.jpg']));
fixTex = Screen('MakeTexture', w.win, imread([defaults.path.stim filesep 'fixation.jpg']));
line1       = strcat('Is the person', repmat('\n', 1, defaults.font.linesep));

% Get Coordinates for Centering ISI Cues ________________________________________________
isicues_xpos = zeros(length(design.isicues),1);
isicues_ypos = isicues_xpos;
for q = 1:length(design.isicues)
    [isicues_xpos(q), isicues_ypos(q)] = ptb_center_position(design.isicues{q},w.win);
end

% G. instructions _____________________________________________________
instruct_filepath              = fullfile(main_dir, 'instructions');
instruct_start_name            = ['task-', taskname, '_start.png'];
instruct_end_name              = ['task-', taskname, '_end.png'];
instruct_start                 = fullfile(instruct_filepath, instruct_start_name);
instruct_end                   = fullfile(instruct_filepath, instruct_end_name);


%==========================================================================
%
% START TASK PRESENTATION
%
%==========================================================================

% Present Instruction Screen ________________________________________________
% Screen('DrawTexture',w.win, instructTex);
start.texture = Screen('MakeTexture',w.win, imread(instruct_start));
Screen('DrawTexture',w.win,start.texture,[],[]);
Screen('Flip',w.win);


%% Wait for Trigger to Begin %%
% DisableKeysForKbCheck([]);
% KbTriggerWait(KbName(defaults.start)); % press s
% WaitKeyPress(KbName(defaults.start));

WaitKeyPress(KbName('s'));
Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
Screen('Flip', p.ptb.window);
% T.param_triggerOnset(:) = KbTriggerWait(trigger); % wait for scanner 5
WaitKeyPress(KbName('5%'));
T.param_triggerOnset(:) = GetSecs;
anchor = T.param_triggerOnset(1);
WaitSecs(TR*6);

try

    if test_tag, nBlocks = 1; totalTime = round(totalTime*.075); % for test run
    else nBlocks = length(blockSeeker); end
    %======================================================================
    % BEGIN BLOCK LOOP
    %======================================================================
    for b = 1:nBlocks

        % Present Fixation Screen Until Question Onset ________________________________________________
        Screen('DrawTexture',w.win, fixTex);
        Screen('Flip',w.win);

        % Get Data for This Block (While Waiting for Block Onset) ________________________________________________
        tmpSeeker   = trialSeeker(trialSeeker(:,1)==b,:);
        pbcue       = pbc_brief{blockSeeker(b,4)};  % question cue
        isicue      = design.isicues{blockSeeker(b,4)};  % isi cue
        isicue_x    = isicues_xpos(blockSeeker(b,4));  % isi cue x position
        isicue_y    = isicues_ypos(blockSeeker(b,4));  % isi cue y position

        % Prepare Question Cue Screen (Still Waiting)________________________________________________
        if ~strcmpi(defaults.language, 'german')
            Screen('TextSize',w.win, defaults.font.size1); Screen('TextStyle', w.win, 0);
            DrawFormattedText(w.win,line1,'center','center',w.white, defaults.font.wrap);
            Screen('TextStyle',w.win, 1); Screen('TextSize', w.win, defaults.font.size2);
        end
        DrawFormattedText(w.win, pbcue,'center','center', w.white, defaults.font.wrap);

        % Present Question Screen and Prepare First ISI (Blank) Screen ________________________________________________
        WaitSecs('UntilTime',anchor + blockSeeker(b,3)); Screen('Flip', w.win); % p2_question_cue
        Screen('FillRect', w.win, w.black);

        % Present Blank Screen Prior to First Trial ________________________________________________
        WaitSecs('UntilTime',anchor + blockSeeker(b,3) + defaults.cueDur); Screen('Flip', w.win); % p3_fixation_onset

        %==================================================================
        % BEGIN TRIAL LOOP
        %==================================================================
        for t = 1:nTrialsBlock

            %% Prepare Screen for Current Trial %%
            Screen('DrawTexture',w.win,slideTex{tmpSeeker(t,5)})
            if t==1 , WaitSecs('UntilTime',anchor + blockSeeker(b,3) + defaults.cueDur + defaults.firstISI);
            else WaitSecs('UntilTime',anchor + offset_dur + defaults.ISI); end

            % Present Screen for Current Trial & Prepare ISI Screen ________________________________________________

            T.p1_trial_onset(8*(b-1) + t) = Screen('Flip',w.win);
            onset = GetSecs; tmpSeeker(t,6) = onset - anchor;
            if t==nTrialsBlock % present fixation after last trial of block
                Screen('DrawTexture', w.win, fixTex);
            else % present question reminder screen between every block trial
                Screen('DrawText', w.win, isicue, isicue_x, isicue_y);
            end

            % Look for Button Press ________________________________________________
            [resp, rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, defaults.maxDur, defaults.ignoreDur);
            offset_dur = GetSecs - anchor;

            % Present ISI, and Look a Little Longer for a Response if None Was Registered ________________________________________________
            T.p1_isi(8*(b-1) + t) = Screen('Flip', w.win);
            norespyet = isempty(resp);
            if norespyet, [resp, rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, defaults.ISI*0.90); end
            if ~isempty(resp)
                if strcmpi(resp, defaults.escape)
                    sca; rmpath(defaults.path.utilities)
                    fprintf('\nESCAPE KEY DETECTED\n'); return
                end
                tmpSeeker(t,8) = find(strcmpi(KbName(resp_set), resp));
%                 tmpSeeker(t,8) = str2num(resp(1));
%                 tmpSeeker(t,8) = resp;
                tmpSeeker(t,7) = rt + (defaults.maxDur*norespyet);
            end
            tmpSeeker(t,9) = offset_dur;
        T.p2_RT(8*(b-1) + t) = tmpSeeker(t,7);
%         if tmpSeeker(t,8) == 2
%             T.p2_actual_response_key(8*(b-1) + t) = 4;
%         else
        T.p2_actual_response_key(8*(b-1) + t) = tmpSeeker(t,8);
%         end
        T.p3_trialoffset(8*(b-1) + t) = offset_dur;
        end % END TRIAL LOOP

        % Store Block Data & Print to Logfile ________________________________________________
        trialSeeker(trialSeeker(:,1)==b,:) = tmpSeeker;
        for t = 1:size(tmpSeeker,1), fprintf(fid,[repmat('%d\t',1,size(tmpSeeker,2)) '\n'],tmpSeeker(t,:)); end
        tmpFileName = fullfile(sub_save_dir,[strcat('sub-', sprintf('%04d', sub_num)), '_task-',taskname,'_TEMPbeh.csv' ]);
        writetable(T,tmpFileName);
    end % END BLOCK LOOP

    % Present Fixation Screen Until End of Scan ________________________________________________
%     WaitSecs('UntilTime', anchor + totalTime);

catch

    ptb_exit;
    rmpath(defaults.path.utilities);
    psychrethrow(psychlasterror);

end

% Create Results Structure ________________________________________________
result.blockSeeker  = blockSeeker;
result.trialSeeker  = trialSeeker;
result.qim          = design.qim;
result.qdata        = design.qdata;
result.preblockcues = design.preblockcues;
result.isicues      = design.isicues;

% Save Data to Matlab Variable ____________________________________________
d=clock;
outfile=sprintf('whyhow_%s_order%d_%s_%02.0f-%02.0f.mat',subjectID,order,date,d(4),d(5));
try
    save([sub_save_dir filesep outfile], 'subjectID', 'result', 'slideName', 'defaults');
catch
	fprintf('couldn''t save %s\n saving to whyhow.mat\n', outfile);
	save whyhow.mat
end

% End of Test Screen ________________________________________________
% DrawFormattedText(w.win,'TEST COMPLETE\n\nPress any key to exit.','center','center',w.white,defaults.font.wrap);
% Screen('Flip', w.win);
% KbTriggerWait(KbName(defaults.end));
% instruct_end_name
%
% start.texture = Screen('MakeTexture',w.win, imread(instruct_start_name));
% Screen('DrawTexture',w.win,,start.texture,[],[]);
% Screen('Flip',w.win,);
%

% __________________________ End Instructions _____________________________
end_texture = Screen('MakeTexture',w.win, imread(instruct_end));
Screen('DrawTexture',w.win,end_texture,[],[]);
T.param_end_instruct_onset(:) = Screen('Flip',w.win);
WaitKeyPress(KbName('e'));

T.param_experimentDuration(:) = T.param_end_instruct_onset(1) - T.param_triggerOnset(1);

saveFileName = fullfile(sub_save_dir,[strcat('sub-', sprintf('%04d', sub_num)), '_task-',taskname,'_beh.csv' ]);
writetable(T,saveFileName);

ShowCursor;

% Exit ____________________________________________________________________
ptb_exit;
rmpath(defaults.path.utilities);

function WaitKeyPress(kID)
while KbCheck(-3); end  % Wait until all keys are released.

while 1
    % Check the state of the keyboard.
    [ keyIsDown, ~, keyCode ] = KbCheck(-3);
    % If the user is pressing a key, then display its code number and name.
    if keyIsDown

        if keyCode(KbName('ESCAPE'))
            cleanup; break;
        elseif keyCode(kID)
            break;
        end
        % make sure key's released
        while KbCheck(-3); end
    end
end
end

end
