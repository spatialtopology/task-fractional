function RUN_task(sub_num, biopac)
order = 0;
test_tag = 0;
fMRI = 1;
% ---------------------
% debug mode % Initial
debug     = 0;   % PTB Debugging

AssertOpenGL;
commandwindow;
ListenChar(2);
if debug
    ListenChar(0);
    PsychDebugWindowConfiguration;
end

global p
Screen('Preference', 'SkipSyncTests', 0);
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
try
    ptbVersion = PsychtoolboxVersion;
catch
    url = 'https://psychtoolbox.org/PsychtoolboxDownload';
    fprintf('\n\t!!! WARNING !!!\n\tPsychophysics Toolbox does not appear to on your search path!\n\tSee: %s\n\n', url);
    return
end
% PsychDefaultSetup(2);
% Print Title ________________________________________________
script_name='----------- Images Test -----------';
boxTop(1:length(script_name))='=';
fprintf('\n%s\n%s\n%s\n',boxTop,script_name,boxTop)

% DEFAULTS ________________________________________________
defaults = task_defaults;
KbName('UnifyKeyNames');
if fMRI
[id, name] = GetKeyboardIndices;
trigger_index = find(contains(name, 'Current Designs'));
trigger_inputDevice = id(trigger_index);
else trigger_inputDevice = -3
end
%
% keyboard_index = find(contains(name, 'AT Translated Set 2 Keyboard'));
% keyboard_inputDevice = id(keyboard_index);
TR = 0.46;
addpath(defaults.path.utilities);


% ------------------------------------------------------------------------------
%                                Parameters
% ------------------------------------------------------------------------------

%% 0. Biopac parameters ________________________________________________________
% task_dir = pwd;
% % load python labjack library "u3"
% cd('/home/spacetop/repos/labjackpython');
% pe = pyenv;
% %  reloadPy()
%     try
%         py.importlib.import_module('u3');
%     catch
%         warning("u3 already imported!");
%     end
% d = py.u3.U3();
% % set every biopac channel to 0
% for channel = 0:7
% d.setFIOState(pyargs('fioNum', int64(channel), 'state', int64(0)));
% end
% cd(task_dir);
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

% biopac channel
channel_trigger    = 0;
channel_fixation_block = 1;
channel_question_block        = 2;
channel_image     = 3;

%% A. directory ________________________________________________________________
main_dir                        = pwd;
taskname                        = 'tomspunt';
sub_save_dir                    = fullfile(main_dir, 'data', strcat('sub-', sprintf('%04d', sub_num)), 'beh' );
if ~exist(sub_save_dir, 'dir')
    mkdir(sub_save_dir)
end

%% B. load design mat __________________________________________________________
X=load([defaults.path.design filesep 'design.mat']);
if order==0, randidx = randperm(4); order = randidx(1); end
design              = X.alldesign{order};
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
nTrialsBlock        = length(unique(trialSeeker(:,2))); % 8

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
% [id,name] = GetKeyboardIndices;
% if size(id,2) == 12;
%     trigger_inputDevice = 9;
%     keyboard_inputDevice = 13;
% end
% C. output table variables ________________________________________________________
%     trialSeeker (stores trial-wise runtime data)
%     1 - block #
%     2 - trial # (within-block)
%     2 - condition (1=WhyFace, 2=WhyHand, 3=HowFace, 4=HowHand)
%     4 - normative response (1=Yes, 2=No) [used to evaluate accuracy]
%     5 - stimulus # (corresponds to qim & qdata from design.mat file)

vnames = {'param_fmriSession', 'param_counterbalanceVer',...
    'param_block_num','param_trial_num',...
    'param_cond_type_num','param_cond_type_string',...
    'param_normative_response',...
    'param_ques_type_string',...
    'param_image_num','param_image_filename',...
    'p1_block_fix','p1_block_fix_dur','p1_block_question_onset','p1_block_isi_blackscreen','p1_question_duration',...
    'p2_image_onset','p2_image_duration',...
    'p3_keypress_RT','p3_keypress_key','p3_keypress_onset'...
    'p4_short_question_onset',...
    'param_end_instruct_onset','total_param_experimentDuration',...
    'RAW_param_triggerOnset',...
    'param_start_biopac',...
    'RAW_p1_block_fix','RAW_p1_block_question_onset','RAW_p1_block_isi_blackscreen',...
    'RAW_p2_image_onset',...
    'RAW_p3_keypress_onset',...
    'RAW_p4_short_question_onset',...
    'RAW_param_end_instruct_onset'};
T                              = array2table(zeros(length(design.trialSeeker),size(vnames,2)));
T.Properties.VariableNames     = vnames;

T.param_fmriSession(:)         = 4;
T.param_counterbalanceVer(:)   = order;
T.param_block_num              = repelem(blockSeeker(:,1),8);
T.param_trial_num              = trialSeeker(:,2);
list_condition                 = {'c1_WhyFace', 'c2_WhyHand', 'c3_HowFace', 'c4_HowHand'};
T.param_cond_type_num          = trialSeeker(:,3);
T.param_cond_type_string       = {list_condition{design.trialSeeker(:,3)}}';
T.param_normative_response     = trialSeeker(:,4);
T.param_ques_type_string       = cell(length(design.trialSeeker),1);
T.param_image_filename          = cell(length(design.trialSeeker),1);
T.param_image_num              = trialSeeker(:,5);

% D. Print Defaults ________________________________________________
fprintf('Test Duration:         %d secs (%d TRs)', totalTime, numTRs);
fprintf('\nTrigger Key:           %s', defaults.trigger);
fprintf(['\nValid Response Keys:   %s' repmat(', %s', 1, length(defaults.valid_keys)-1)], defaults.valid_keys{:});
fprintf('\nForce Quit Key:        %s\n', defaults.escape);
fprintf('%s\n', repmat('-', 1, length(script_name)));


% E. Setup Input Device(s) _____________________________________________________
% switch upper(computer)
%     case 'MACI64'
%         inputDevice = ptb_get_resp_device;
%     case {'PCWIN','PCWIN64'}
%         % JMT:
%         % Do nothing for now - return empty chosen_device
%         % Windows XP merges keyboard input and will process external keyboards
%         % such as the Silver Box correctly
%         inputDevice = [];
%     otherwise
%         % Do nothing - return empty chosen_device
%         inputDevice = [];
% end
% resp_set = ptb_response_set([defaults.valid_keys ]); % response set
% defaults.start defaults.trigger defaults.end defaults.escape
% resp_set = cell2mat(cellfun(@KbName,{'1!', '2@'}, 'Unif', false));
resp_set =  ptb_response_set([defaults.valid_keys defaults.escape]);
% F. Initialize Screen _________________________________________________________
taskname                      = 'tomspunt';
screens                       = Screen('Screens'); % Get the screen numbers
p.ptb.screenNumber            = max(screens); % Draw to the external screen if avaliable
p.ptb.device = PsychHID('Devices');

p.ptb.white                   = WhiteIndex(p.ptb.screenNumber);
p.ptb.black                   = BlackIndex(p.ptb.screenNumber);
[p.ptb.window, p.ptb.rect]    = PsychImaging('OpenWindow', p.ptb.screenNumber, p.ptb.black);
[p.ptb.screenXpixels, p.ptb.screenYpixels] = Screen('WindowSize', p.ptb.window);
p.ptb.ifi                      = Screen('GetFlipInterval', p.ptb.window);
Screen('BlendFunction', p.ptb.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
Screen('TextFont', p.ptb.window, 'Arial');
Screen('TextSize', p.ptb.window, 36);
[p.ptb.xCenter, p.ptb.yCenter] = RectCenter(p.ptb.rect);
p.fix.sizePix                  = 40; % fixation cross - size of the arms
p.fix.lineWidthPix             = 4; % fixation cross - line width
p.fix.xCoords                  = [-p.fix.sizePix p.fix.sizePix 0 0];
p.fix.yCoords                  = [0 0 -p.fix.sizePix p.fix.sizePix];
p.fix.allCoords                = [p.fix.xCoords; p.fix.yCoords];

w.win = p.ptb.window;
w.rect = p.ptb.rect;
w.white = p.ptb.white;
w.black = p.ptb.black;
HideCursor(p.ptb.screenNumber);


% G. Initialize Logfile (Trialwise Data Recording) _____________________________
clock_log =clock;

if ~exist(defaults.path.data,'dir')
    [canSaveData,saveDataMsg,saveDataMsgID] = mkdir(defaults.path.data);
    if canSaveData == false
        error(saveDataMsgID,'Cannot write in directory %s due to the following error: %s',pwd,saveDataMsg);
    end
end
logfile = fullfile(sub_save_dir, sprintf('LOG_sub-%04d_task-tomspunt_order-%02d_time-%s_%02.0f-%02.0f.txt', sub_num, order,date,clock_log(4),clock_log(5)));

fprintf('\nA running log of this session will be saved to %s\n',logfile);
fid=fopen(logfile,'a');
if fid<1
    error('could not open logfile!')
end
fprintf(fid,'Started: %s %2.0f:%02.0f\n',date,clock_log(4),clock_log(5));


% H. Make Images Into Textures ________________________________________________
DrawFormattedText(w.win,sprintf('LOADING\n\n0%% complete'),'center','center',w.white,defaults.font.wrap);
Screen('Flip',w.win);
slideName = cell(length(design.qim),1);
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
fixTex      = Screen('MakeTexture', w.win, imread([defaults.path.stim filesep 'fixation.jpg']));
line1       = strcat('Is the person', repmat('\n', 1, defaults.font.linesep));


% I. Get Coordinates for Centering ISI Cues ________________________________________________
isicues_xpos = zeros(length(design.isicues),1);
isicues_ypos = isicues_xpos;
for q = 1:length(design.isicues)
    [isicues_xpos(q), isicues_ypos(q)] = ptb_center_position(design.isicues{q},w.win);
end


% J. instructions _____________________________________________________
instruct_filepath              = fullfile(main_dir, 'instructions');
instruct_start_name            = ['task-', taskname, '_start.png'];
instruct_end_name              = ['task-', taskname, '_end.png'];
instruct_start                 = fullfile(instruct_filepath, instruct_start_name);
instruct_end                   = fullfile(instruct_filepath, instruct_end_name);


%% -----------------------------------------------------------------------------
%                              START EXPERIMENT
% ------------------------------------------------------------------------------

% ------------------------------------------------------------------------------
%                       0. Present Instruction Screen
% ------------------------------------------------------------------------------
% DisableKeysForKbCheck([]);
start.texture = Screen('MakeTexture',w.win, imread(instruct_start));
Screen('DrawTexture',w.win,start.texture,[],[]);
Screen('Flip',w.win);


% ------------------------------------------------------------------------------
%                           1. Wait for trigger
% ------------------------------------------------------------------------------

% WaitKeyPress(KbName('s'), 1);
secs = KbTriggerWait(KbName('s'),-3);
Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
    p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
Screen('Flip', p.ptb.window);

% WaitKeyPress(KbName('5%'));
T.RAW_param_triggerOnset(:) = KbTriggerWait(KbName('5%'), trigger_inputDevice);
% T.RAW_param_triggerOnset(:) = GetSecs;
T.param_start_biopac(:)                   = biopac_linux_matlab(biopac, channel_trigger, 1);
anchor = T.RAW_param_triggerOnset(1);
WaitSecs(TR*6);


nBlocks = length(blockSeeker);

% ------------------------------------------------------------------------------
% .                          3. Block look start
% ------------------------------------------------------------------------------
for b = 1:nBlocks

    % ________ 3-1. Present Fixation Screen Until Question Onset ________________________
    Screen('DrawTexture',w.win, fixTex);
    T.RAW_p1_block_fix(8*(b-1)+1:8*b) = Screen('Flip',w.win);
    T.CHANGE(:)                   = biopac_linux_matlab(biopac, channel_fixation_block, 1);

%    % ________ 3-2. Get Data for This Block (While Waiting for Block Onset) _____________
    tmpSeeker   = trialSeeker(trialSeeker(:,1)==b,:);
    pbcue       = pbc_brief{blockSeeker(b,4)};  % question cue
    isicue      = design.isicues{blockSeeker(b,4)};  % isi cue
    isicue_x    = isicues_xpos(blockSeeker(b,4));  % isi cue x position
    isicue_y    = isicues_ypos(blockSeeker(b,4));  % isi cue y position

    % ________ 3-3. Prepare Question Cue Screen (Still Waiting)__________________________
    if ~strcmpi(defaults.language, 'german')
        Screen('TextSize',w.win, defaults.font.size1); Screen('TextStyle', w.win, 0);
        DrawFormattedText(w.win,line1,'center','center',w.white, defaults.font.wrap);
        Screen('TextStyle',w.win, 1); Screen('TextSize', w.win, defaults.font.size2);
    end
    DrawFormattedText(w.win, pbcue,'center','center', w.white, defaults.font.wrap);

    % ________ 3-4. Present Question Screen and Prepare First ISI (Blank) Screen ________
    WaitSecs('UntilTime',anchor +TR*6+ blockSeeker(b,3)); % duration of fixation
    T.CHANGE(:)                   = biopac_linux_matlab(biopac, channel_fixation_block, 0);

    T.p1_block_fix_dur(8*(b-1)+1:8*b) = GetSecs - T.RAW_p1_block_fix(8*(b-1)+1);
    T.RAW_p1_block_question_onset(8*(b-1)+1:8*b) = Screen('Flip', w.win); % p2_question_cue
    T.CHANGE(:)                   = biopac_linux_matlab(biopac, channel_question_block, 1);
    Screen('FillRect', w.win, w.black);

    % ________ 3-5. Present Blank Screen Prior to First Trial ___________________________
    WaitSecs('UntilTime', anchor +TR*6+ blockSeeker(b,3) + defaults.cueDur);
    T.CHANGE(:)                   = biopac_linux_matlab(biopac, channel_question_block, 0);
    T.RAW_p1_block_isi_blackscreen(8*(b-1)+1:8*b) = Screen('Flip', w.win); % p3_fixation_onset

% ------------------------------------------------------------------------------
%                             4. Trial loop start
% ------------------------------------------------------------------------------

    for t = 1:nTrialsBlock
        % ________ 4-1. Prepare Screen for Current Trial ________________________________

        Screen('DrawTexture',w.win,slideTex{tmpSeeker(t,5)})
        if t==1
            WaitSecs('UntilTime',anchor +TR*6+ blockSeeker(b,3) + defaults.cueDur + defaults.firstISI);
            T.p1_question_duration(8*(b-1) + t) = T.RAW_p1_block_isi_blackscreen(8*(b-1)+1) - T.RAW_p1_block_question_onset(8*(b-1)+1);
        else
            WaitSecs('UntilTime',offset_dur + defaults.ISI);
            T.p1_question_duration(8*(b-1) + t) = defaults.ISI;
        end

        % ________ 4-2. Present Screen for Current Trial & Prepare ISI Screen ___________
        T.RAW_p2_image_onset(8*(b-1) + t) = Screen('Flip',w.win); % IMAGE WITH OPTIONS
        T.CHANGE(:)                   = biopac_linux_matlab(biopac, channel_image, 1);
        tmpSeeker(t,6) = T.RAW_p2_image_onset(8*(b-1) + t) - (anchor + TR*6);
        if t==nTrialsBlock % present fixation after last trial of block
            Screen('DrawTexture', w.win, fixTex);
        else % present question reminder screen between every block trial
            Screen('DrawText', w.win, isicue, isicue_x, isicue_y);
        end

        % ________ 4-3. Look for Button Press ___________________________________________
        % [resp, rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, defaults.maxDur, defaults.ignoreDur);
        [resp, rt] = ptb_get_resp_windowed_noflip(trigger_inputDevice, resp_set, defaults.maxDur, defaults.ignoreDur);
        offset_dur = Screen('Flip', w.win); % QUESTION CUE
        T.CHANGE(:)                   = biopac_linux_matlab(biopac, channel_image, 0);
        T.p2_image_duration(8*(b-1) + t) = offset_dur - T.RAW_p2_image_onset(8*(b-1) + t);

        % ________ 4-4. Present ISI, ____________________________________________________
        % and Look a Little Longer for a Response if None Was Registered ________________

        norespyet = isempty(resp);

        % if norespyet, [resp, rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, defaults.ISI*0.90); end
        if norespyet, [resp, rt] = ptb_get_resp_windowed_noflip(trigger_inputDevice, resp_set, defaults.ISI*0.90); end
        if ~isempty(resp)
            T.RAW_p3_keypress_onset(8*(b-1) + t) = GetSecs;
            if strcmpi(resp, defaults.escape)
                sca; rmpath(defaults.path.utilities);
                fprintf('\nESCAPE KEY DETECTED\n'); return
            end
            % tmpSeeker(t,8) = find(strcmpi(KbName(resp_set), resp));
            tmpSeeker(t,8) = find(strcmpi(KbName(resp_set), resp));
            tmpSeeker(t,7) = rt + (defaults.maxDur*norespyet);

        end
        tmpSeeker(t,9) = offset_dur;
        T.p3_keypress_RT(8*(b-1) + t) = tmpSeeker(t,7);
        T.p3_keypress_key(8*(b-1) + t) = tmpSeeker(t,8);
        T.RAW_p4_short_question_onset(8*(b-1) + t) = offset_dur;
        T.param_ques_type_string{8*(b-1) + t} = isicue;
        T.param_image_filename{8*(b-1) + t}       = slideName{tmpSeeker(t,5)};

    end % END TRIAL LOOP


% ------------------------------------------------------------------------------
%               5. Store Block Data & Print to Logfile
% ------------------------------------------------------------------------------
    trialSeeker(trialSeeker(:,1)==b,:) = tmpSeeker;
    for t = 1:size(tmpSeeker,1), fprintf(fid,[repmat('%d\t',1,size(tmpSeeker,2)) '\n'],tmpSeeker(t,:)); end
    tmpFileName = fullfile(sub_save_dir,[strcat('sub-', sprintf('%04d', sub_num)), '_task-',taskname,'_TEMPbeh.csv' ]);
    writetable(T,tmpFileName);

end % END BLOCK LOOP


% ------------------------------------------------------------------------------
%             6. Present Fixation Screen Until End of Scan
% ------------------------------------------------------------------------------
WaitSecs('UntilTime', anchor + totalTime + 6*TR);

% Create Results Structure ________________________________________________
result.blockSeeker  = blockSeeker;
result.trialSeeker  = trialSeeker; % check
result.qim          = design.qim; % check
result.qdata        = design.qdata;
result.preblockcues = design.preblockcues;
result.isicues      = design.isicues;

% Save Data to Matlab Variable ____________________________________________
d=clock;
outfile = sprintf('sub-%04d_task-tomspunt_order-%02d_beh', sub_num, order);
% outfile=sprintf('whyhow_sub-%04d_order%d_%s_%02.0f-%02.0f.mat',sub_num,order,date,d(4),d(5));
try
    save([sub_save_dir filesep outfile], 'sub_num', 'result', 'slideName', 'defaults');
catch
    fprintf('couldn''t save %s\n saving to whyhow.mat\n', outfile);
    save whyhow.mat
end


%% -----------------------------------------------------------------------------
%                           END AND SAVE EXPERIMENT
% ------------------------------------------------------------------------------
end_texture = Screen('MakeTexture',w.win, imread(instruct_end));
Screen('DrawTexture',w.win,end_texture,[],[]);
T.RAW_param_end_instruct_onset(:) = Screen('Flip',w.win);
biopac_linux_matlab(biopac, channel_trigger, 0);

% convert variables
T.p1_block_fix(:) = T.RAW_p1_block_fix(:) - T.RAW_param_triggerOnset(:) - (TR*6);
T.p1_block_question_onset(:) = T.RAW_p1_block_question_onset(:) - T.RAW_param_triggerOnset(:) - (TR*6);
T.p1_block_isi_blackscreen(:) = T.RAW_p1_block_isi_blackscreen(:) - T.RAW_param_triggerOnset(:) - (TR*6);
T.p2_image_onset(:) = T.RAW_p2_image_onset(:) - T.RAW_param_triggerOnset(:) - (TR*6);
T.p3_keypress_onset(:) = T.RAW_p3_keypress_onset(:) - T.RAW_param_triggerOnset(:) - (TR*6);
T.p4_short_question_onset = T.RAW_p4_short_question_onset(:) - T.RAW_param_triggerOnset(:) - (TR*6);
T.param_end_instruct_onset(:) = T.RAW_param_end_instruct_onset(:) - T.RAW_param_triggerOnset(:) - (TR*6);
T.total_param_experimentDuration(:) = T.RAW_param_end_instruct_onset(:) - T.RAW_param_triggerOnset(:);

saveFileName = fullfile(sub_save_dir,[strcat('sub-', sprintf('%04d', sub_num)), '_task-',taskname,'_beh.csv' ]);
writetable(T,saveFileName);
KbTriggerWait(KbName('e'), trigger_inputDevice);
ShowCursor;

% Exit ____________________________________________________________________

function [time] = biopac_linux_matlab(biopac, channel_num, state_num)
    if biopac
        d.setFIOState(pyargs('fioNum', int64(channel_num), 'state', int64(state_num)))
        time = GetSecs;
    else
        time = GetSecs;
        return
    end
end

    function reloadPy()
        warning('off', 'MATLAB:ClassInstanceExists')
        clear classes
        mod = py.importlib.import_module('u3');
        py.importlib.reload(mod);

    end
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
ptb_exit;
rmpath(defaults.path.utilities);

end
