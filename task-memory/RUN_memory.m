function RUN_memory(sub_num, biopac)
% function memorizationTask(expName,subNum)


% Input:
%  expName:       the name of the experiment (as a string). You must set up
%                 a config_EXPNAME.m file describing the experiment
%                 configuration.
%  subNum:        the subject number (integer). This will get transformed
%                 into the full subject name EXPNAMEXXX; e.g., subNum=1 =
%                 EXPNAME001.
%
% NB: You can also launch the experiment by just running the command:
%     memorizationTask;
%     A popup window will prompt for the above info. It is not possible to
%     run the photoCellTest using this method.

% Code provided by Tim Curran
% Minimal changes maded by Heejung Jung
% Clear Matlab window:
% clc

% check for Opengl compatibility, abort otherwise:
% AssertOpenGL;
global p
Screen('Preference', 'SkipSyncTests', 0);
PsychDefaultSetup(2);

% Make sure keyboard mapping is the same on all supported operating systems
% Apple MacOS/X, MS-Windows and GNU/Linux:
KbName('UnifyKeyNames');
% Reseed the random-number generator for each experiment:
rng('shuffle');

% need to be in the experiment directory to run it. See if this function is
% in the current directory; if it is then we're in the right spot.
if ~exist(fullfile(pwd,sprintf('%s.m','RUN_memory')),'file')
    error('Must be in the experiment directory to run the experiment.');
end

% process experiment name and subject number ___________________________________

% make sure there are somewhere betwen 0 and 2 arguments
minArg = 0;
maxArg = 2;
narginchk(minArg,maxArg);

% if nargin == 0
    % if no variables are provided, use an input dialogue
%         repeat = 1;
%         while repeat
%             prompt = {'Experiment name (alphanumerics only, no quotes)', 'Subject number (number(s) only)'};
%             defaultAnswer = {'', ''};
%             options.Resize = 'on';
%             answer = inputdlg(prompt,'Subject Information', 1, defaultAnswer, options);
%             [expName, subNum,] = deal(answer{:});
%             if isempty(expName) || ~ischar(expName)
%                 h = errordlg('Experiment name must consist of characters. Try again.', 'Input Error');
%                 repeat = 1;
%                 uiwait(h);
%                 continue
%             end
% 1. grab participant number ___________________________________________________
%     expName = 'canna';
    %prompt = 'session number : ';
    %session = input(prompt);

%     if isempty(sub_num) || ~isnumeric(sub_num) || mod(sub_num,1) ~= 0 || sub_num <= 0
%         prompt = 'subject number (in raw number form, e.g. 1, 2,...,98): ';
%         sub_num = input(prompt);
%         %         if isempty(str2double(subNum)) || ~isnumeric(str2double(subNum)) || mod(str2double(subNum),1) ~= 0 || str2double(subNum) <= 0
%         h = errordlg('Subject number must be an integer (e.g., 9) and greater than zero. Try again.', 'Input Error');
%         repeat = 1;
%         uiwait(h);
%         %             continue
%     end
    %         if ~exist(fullfile(pwd,sprintf('config_%s.m',expName)),'file')
    %             h = errordlg(sprintf('Configuration file for experiment with name ''%s'' does not exist (config_%s.m). Check the experiment name and try again.',expName,expName), 'Input Error');
    %             repeat = 1;
    %             uiwait(h);
    %             continue
    %         else
    %             subNum = str2double(subNum);
    %             repeat = 0;
    %         end
    %     end

% elseif nargin == 0
%     % cannot proceed with one argument
%     error('You provided 1 argument, but you need either zero or two! Must provide either no inputs (%s;) or provide experiment name (as a string) and subject number (as an integer).',mfilename,mfilename,expName);
% end

% Experiment database struct preparation _______________________________________

expParam = struct;
cfg = struct;
expParam.expName = 'canna';

% store the experiment name
expParam.subject = sprintf('%.4d',sub_num);
% set the current directory as the experiment directory
cfg.files.expDir = pwd;

% Set up the data directories and files ________________________________________

% make sure the data directory exists, and that we can save data
cfg.files.dataSaveDir = fullfile(cfg.files.expDir,'data');
if ~exist(cfg.files.dataSaveDir,'dir')
    [canSaveData,saveDataMsg,saveDataMsgID] = mkdir(cfg.files.dataSaveDir);
    if canSaveData == false
        error(saveDataMsgID,'Cannot write in directory %s due to the following error: %s',pwd,saveDataMsg);
    end
end

% make sure subject directory exists
cfg.files.subSaveDir = fullfile(cfg.files.dataSaveDir,['sub-', expParam.subject]);
if (~exist(cfg.files.subSaveDir, 'dir'))
    [canSaveData,saveDataMsg,saveDataMsgID] = mkdir(cfg.files.subSaveDir);
    if canSaveData == false
        error(saveDataMsgID,'Cannot write in directory %s due to the following error: %s',pwd,saveDataMsg);
    end
end


% set name of the file for saving experiment parameters
cfg.files.expParamFile = fullfile(cfg.files.subSaveDir,'experimentParams.mat');
if exist(cfg.files.expParamFile,'file')
%     % if it exists that means this subject has already run a session
    load(cfg.files.expParamFile);
else
    expParam.sessionNum = 1;
    if exist(fullfile(pwd,sprintf('config_canna.m')),'file')
        [cfg,expParam] = config_canna(cfg,expParam);
        [cfg,expParam] = eval(sprintf('config_%s(cfg,expParam);',expParam.expName));
        % save the experiment data
        save(cfg.files.expParamFile,'cfg','expParam');
    else
        error('Configuration file for %s experiment does not exist: %s',fullfile(pwd,sprintf('config_%s.m',expParam.expName)));
    end

end
% expParam.sessionNum = 1;
% Make sure the session number is in order and directories/files exist

% make sure session directory exists
% cfg.files.sesSaveDir = fullfile(cfg.files.subSaveDir,sprintf('session_%d',expParam.sessionNum));
cfg.files.sesSaveDir = fullfile(cfg.files.subSaveDir,'beh');
if ~exist(cfg.files.sesSaveDir,'dir')
    [canSaveData,saveDataMsg,saveDataMsgID] = mkdir(cfg.files.sesSaveDir);
    if canSaveData == false
        error(saveDataMsgID,'Cannot write in directory %s due to the following error: %s',pwd,saveDataMsg);
    end
end

% set name of the session log file
cfg.files.sesLogFile = fullfile(cfg.files.sesSaveDir,'session.txt');
if exist(cfg.files.sesLogFile,'file')
    %error('Log file for this session already exists (%s). Resuming a session is not yet supported.',cfg.files.sesLogFile);
    warning('Log file for this session already exists (%s).',cfg.files.sesLogFile);
    resumeUnanswered = 1;
    while resumeUnanswered
        resumeSession = input(sprintf('Do you want to resume %s session %d? (type 1 for yes or 0 for no and press enter). ',expParam.subject,expParam.sessionNum));
        if isnumeric(resumeSession) && (resumeSession == 1 || resumeSession == 0)
            if resumeSession
                fprintf('Attempting to resume %s session %d (%s)...\n',expParam.subject,expParam.sessionNum,cfg.files.sesLogFile);
                resumeUnanswered = 0;
            else
                fprintf('Exiting...\n');
                return
            end
        end
    end
end

% Save the current experiment data _____________________________________________
save(cfg.files.expParamFile,'cfg','expParam');

% Run the experiment ___________________________________________________________
% fprintf('Running experiment: %s, subject %s, session %d...\n',expParam.expName,expParam.subject,expParam.sessionNum);
fprintf('Running experiment: subject %s, session %d...\n',expParam.subject,expParam.sessionNum);


% Biopac parameters
script_dir = pwd;
% biopac channel
channel = struct;

channel.trigger    = 0;
channel.fixation   = 1;
channel.image      = 2;
channel.math       = 3;
channel.remainder  = 4;
channel.study      = 5;
channel.test       = 6;
channel.calc       = 7;


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


% try
% Open data file
logFile = fopen(cfg.files.sesLogFile,'at');

% Begin PTB display setup ______________________________________________________
% set some font display options; must be set before opening w with Screen
DefaultFontName = 'Courier New';
DefaultFontStyle = 1;
DefaultFontSize = 22;
if ispc
    Screen('Preference','DefaultFontName',DefaultFontName);
    Screen('Preference','DefaultFontStyle',DefaultFontStyle);
    Screen('Preference','DefaultFontSize',DefaultFontSize);
elseif ismac
    Screen('Preference','DefaultFontName',DefaultFontName);
    Screen('Preference','DefaultFontStyle',DefaultFontStyle);
    Screen('Preference','DefaultFontSize',DefaultFontSize);
elseif isunix
    Screen('Preference','DefaultFontName',DefaultFontName);
    Screen('Preference','DefaultFontStyle',DefaultFontStyle);
    Screen('Preference','DefaultFontSize',DefaultFontSize);
end

% Get screenNumber of stimulation display. We choose the display with
% the maximum index, which is usually the right one, e.g., the external
% display on a Laptop:
% screenNumber = max(Screen('Screens'));
% screenRect = Screen('Rect', screenNumber);
% Width = RectWidth(screenRect);
% Height = RectHeight(screenRect);
% cfg.screen.bgColor = GrayIndex(screenNumber);


screens                        = Screen('Screens'); % Get the screen numbers
p.ptb.screenNumber             = max(screens); % Draw to the external screen if avaliable
p.ptb.white                    = WhiteIndex(p.ptb.screenNumber); % Define black and white
p.ptb.black                    = BlackIndex(p.ptb.screenNumber);
% p.ptb.gray                    = GrayIndex(p.ptb.screenNumber);
[p.ptb.window, p.ptb.rect]     = PsychImaging('OpenWindow', p.ptb.screenNumber, p.ptb.black);
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

TR = 0.46;
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

% G. instructions _____________________________________________________
instruct_filepath              = fullfile(cfg.files.expDir, 'instructions');
taskname                       = 'memory';
instruct_start_name            = [ taskname, '_main_start.png'];
instruct_end_name              = [ taskname, '_main_end.png'];
instruct_start                 = fullfile(instruct_filepath, instruct_start_name);
instruct_end                   = fullfile(instruct_filepath, instruct_end_name);

screenNumber = p.ptb.screenNumber;
Width = RectWidth(p.ptb.rect);
Height = RectHeight(p.ptb.rect);


% Set up the color value to be used as experiment background color
if ~isfield(cfg.screen,'bgColor')
    cfg.screen.bgColor = GrayIndex(p.ptb.screenNumber);
    warning('You did not set a value for the background color (cfg.screen.bgColor in your config_%s.m)! It is recommended to set this value. Setting experiment backdrop to the GrayIndex of this screen (%d).',expParam.expName,cfg.screen.bgColor);
    manualBgColor = false;
else
    manualBgColor = true;

end

% Open a double buffered fullscreen window on the stimulation screen
% 'screenNumber' and choose/draw a background color. 'w' is the handle
% used to direct all drawing commands to that window - the "Name" of
% the window. 'wRect/p.ptb.rect' is a rectangle defining the size of the window.
% See "help PsychRects" for help on such rectangles and useful helper
% functions:

% wRect = p.ptb.rect
% [w, wRect] = Screen('OpenWindow', p.ptb.screenNumber, cfg.screen.bgColor);
[p.ptb.window, p.ptb.rect]  = Screen('OpenWindow', p.ptb.screenNumber, cfg.screen.bgColor);
% store the screen dimensions
cfg.screen.wRect = p.ptb.rect;

% Do dummy calls to GetSecs, WaitSecs, KbCheck to make sure
% they are loaded and ready when we need them - without delays
% in the wrong moment:
KbCheck;
WaitSecs(0.1);
GetSecs;

% Set priority for script execution to realtime priority:
% priorityLevel = MaxPriority(p.ptb.window);
% Priority(priorityLevel);

% Run through the experiment ___________________________________________________
% find out what session this will be
sesName = expParam.sesTypes{expParam.sessionNum};

% record the date and start time for this session
expParam.session.(sesName).date = date;
startTime = fix(clock);
expParam.session.(sesName).startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6));


% D. making output table ________________________________________________________
vnames = {'param_fmriSession', 'param_triggerOnset',...
                                'param_end_instruct_onset', 'param_experimentDuration'};
T                              = array2table(zeros(1,size(vnames,2)));
T.Properties.VariableNames         = vnames;
T.param_fmriSession(:) = 4;


% ______________________________ Instructions __________________________________
HideCursor;
Screen('TextSize',p.ptb.window,72);
start.texture = Screen('MakeTexture',p.ptb.window, imread(instruct_start));
Screen('DrawTexture',p.ptb.window,start.texture,[],[]);
Screen('Flip',p.ptb.window);

% ________________________ Wait for Trigger to Begin ___________________________
% 1) wait for 's' key, once pressed, automatically flips to fixation
% 2) wait for trigger '5'
WaitKeyPress(p.keys.start); % press s
Screen('DrawLines', p.ptb.window, p.fix.allCoords,p.fix.lineWidthPix, cfg.text.whiteTextColor, [p.ptb.xCenter p.ptb.yCenter]);
Screen('Flip', p.ptb.window);
%
%         Screen('TextSize', p.ptb.window, cfg.text.basicTextSize);
%         DrawFormattedText(p.ptb.window, cfg.text.fixSymbol, 'center', 'center', cfg.text.basicTextColor);
%         T.p1_fixation_onset(trl) = Screen('Flip', p.ptb.window);


WaitKeyPress(p.keys.trigger);
T.param_triggerOnset(:)          = GetSecs;
T.param_start_biopac(:)                   = biopac_linux_matlab(biopac,channel, channel.trigger, 1);
WaitSecs(TR*6);

% ------------------------------------------------------------------------------
%                              Main task
% ------------------------------------------------------------------------------

[cfg,expParam] = mem_func_study(p,cfg,expParam,logFile,'stud1',sub_num, biopac, channel);
mem_func_calculation(p, cfg, sub_num, 1, biopac, channel);
[cfg,expParam, test1_accuracy] = mem_func_test(p,cfg,expParam,logFile, 'test1',sub_num, biopac, channel);
% -------------------------------------------------------------------------
[cfg,expParam] = mem_func_study(p,cfg,expParam,logFile,'stud2',sub_num, biopac, channel);
mem_func_calculation(p, cfg, sub_num, 2, biopac, channel);
[cfg,expParam, test2_accuracy] = mem_func_test(p, cfg,expParam,logFile, 'test2',sub_num, biopac, channel);



% Session is done

fprintf('Done with %s session %d (%s).\n',expParam.subject,expParam.sessionNum,sesName);

% record the end time for this session
endTime = fix(clock);
expParam.session.(sesName).endTime = sprintf('%.2d:%.2d:%.2d',endTime(4),endTime(5),endTime(6));

% increment the session number for running the next session
expParam.sessionNum = expParam.sessionNum + 1;

% save the experiment data
save(cfg.files.expParamFile,'cfg','expParam');

% close out the log file
fclose(logFile);


% ------------------------------------------------------------------------------
%                                Finish Message
% ------------------------------------------------------------------------------

% _________________________ 7. End Instructions _______________________________
end_texture = Screen('MakeTexture',p.ptb.window, imread(instruct_end));
Screen('DrawTexture',p.ptb.window,end_texture,[],[]);
T.param_end_instruct_onset(:)  = Screen('Flip',p.ptb.window);
WaitKeyPress(p.keys.end); % press s
T.param_experimentDuration(:) = T.param_end_instruct_onset(1) -T.param_triggerOnset(1);
T.param_start_biopac(:)                   = biopac_linux_matlab(biopac, channel, channel.trigger, 0);

%
% _________________________ 8. save parameter _________________________________
sub_save_dir = cfg.files.sesSaveDir;
saveFileName = fullfile(sub_save_dir,[strcat('sub-', sprintf('%04d', sub_num)), '_task-',taskname,'main_beh.csv' ]);
writetable(T,saveFileName);

close all;
sca;

% KbWait(-1,2);
% RestrictKeysForKbCheck([]);
% Screen('Flip', p.ptb.window);
% WaitSecs(1.000);

% Cleanup at end of experiment - Close window, show mouse cursor, close
% result file, switch Matlab/Octave back to priority 0 -- normal
% priority:
% % Screen('CloseAll');
% fclose('all');
ShowCursor;
% ListenChar;
% Priority(0);


% ------------------------------------------------------------------------------
%                                payment
% ------------------------------------------------------------------------------
pettycashfile = fullfile(sub_save_dir,[strcat('sub-', sprintf('%04d', sub_num)), '_pettycash.txt' ]);
fid=fopen(pettycashfile,'w');
total_acc = test1_accuracy + test2_accuracy;
fprintf(fid,'*********************************\n*********************************\nThis is the end of the memory task.\n');
fprintf(fid,'This participants total accuracy was %0.2f out of 80.\n',total_acc);
fprintf(fid,'Please pay %0.2f dollars.\nThank you !!\n', ((total_acc)*0.25));
fprintf(fid,'*********************************\n*********************************\n');
fclose(fid);true
% print in command window
fprintf('*********************************\n*********************************\nThis is the end of the memory task.\n')
fprintf('This participants total accuracy was %0.2f out of 80.\n',total_acc)
fprintf('Please pay %0.2f dollars.\nThank you !!\n', ((total_acc)*0.25))
fprintf('*********************************\n*********************************\n')

% things to consider
% [ ] non-answered items?
% [ ] check if they answered the same thing over and over again

% input(prompt);
% input(prompt2);



% ------------------------------------------------------------------------------
%                                Function
% ------------------------------------------------------------------------------
function [time] = biopac_linux_matlab(biopac, channel, channel_num, state_num)
    if biopac
        channel.d.setFIOState(pyargs('fioNum', int64(channel_num), 'state', int64(state_num)))
        time = GetSecs;
    else
        time = GetSecs;
        return
    end
end


function WaitKeyPress(kID)
while KbCheck(-3); end  % Wait until all keys are released.

while 1
    % Check the state of the keyboard.
    [ keyIsDown, ~, keyCode ] = KbCheck(-3);
    % If the user is pressing a key, then display its code number and name.
    if keyIsDown

        if keyCode(p.keys.esc)
            cleanup; break;
        elseif keyCode(kID)
            break;
        end
        % make sure key's released
%         while KbCheck(-3); end
    end
end
end

end
