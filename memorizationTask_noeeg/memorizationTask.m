function memorizationTask(expName,subNum)
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

%% preliminary
% Clear Matlab window:
%clc
home

% check for Opengl compatibility, abort otherwise:
% AssertOpenGL;
global p
Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(2);

% Make sure keyboard mapping is the same on all supported operating systems
% Apple MacOS/X, MS-Windows and GNU/Linux:
KbName('UnifyKeyNames');

% Reseed the random-number generator for each experiment:
rng('shuffle');

% need to be in the experiment directory to run it. See if this function is
% in the current directory; if it is then we're in the right spot.
if ~exist(fullfile(pwd,sprintf('%s.m','memorizationTask')),'file')
    error('Must be in the experiment directory to run the experiment.');
end

%% process experiment name and subject number

% make sure there are somewhere betwen 0 and 2 arguments
minArg = 0;
maxArg = 2;
narginchk(minArg,maxArg);

if nargin == 0
    % if no variables are provided, use an input dialogue
    repeat = 1;
    while repeat
        prompt = {'Experiment name (alphanumerics only, no quotes)', 'Subject number (number(s) only)'};
        defaultAnswer = {'', ''};
        options.Resize = 'on';
        answer = inputdlg(prompt,'Subject Information', 1, defaultAnswer, options);
        [expName, subNum,] = deal(answer{:});
        if isempty(expName) || ~ischar(expName)
            h = errordlg('Experiment name must consist of characters. Try again.', 'Input Error');
            repeat = 1;
            uiwait(h);
            continue
        end
        if isempty(str2double(subNum)) || ~isnumeric(str2double(subNum)) || mod(str2double(subNum),1) ~= 0 || str2double(subNum) <= 0
            h = errordlg('Subject number must be an integer (e.g., 9) and greater than zero. Try again.', 'Input Error');
            repeat = 1;
            uiwait(h);
            continue
        end
        if ~exist(fullfile(pwd,sprintf('config_%s.m',expName)),'file')
            h = errordlg(sprintf('Configuration file for experiment with name ''%s'' does not exist (config_%s.m). Check the experiment name and try again.',expName,expName), 'Input Error');
            repeat = 1;
            uiwait(h);
            continue
        else
            subNum = str2double(subNum);
            repeat = 0;
        end
    end

elseif nargin == 1
    % cannot proceed with one argument
    error('You provided 1 argument, but you need either zero or two! Must provide either no inputs (%s;) or provide experiment name (as a string) and subject number (as an integer).',mfilename,mfilename,expName);
end

%% Experiment database struct preparation

expParam = struct;
cfg = struct;

% store the experiment name
expParam.expName = expName;
expParam.subject = sprintf('%s%.3d',expParam.expName,subNum);

% set the current directory as the experiment directory
cfg.files.expDir = pwd;

%% Set up the data directories and files

% make sure the data directory exists, and that we can save data
cfg.files.dataSaveDir = fullfile(cfg.files.expDir,'data');
if ~exist(cfg.files.dataSaveDir,'dir')
    [canSaveData,saveDataMsg,saveDataMsgID] = mkdir(cfg.files.dataSaveDir);
    if canSaveData == false
        error(saveDataMsgID,'Cannot write in directory %s due to the following error: %s',pwd,saveDataMsg);
    end
end

% make sure subject directory exists
cfg.files.subSaveDir = fullfile(cfg.files.dataSaveDir,expParam.subject);
if (~exist(cfg.files.subSaveDir, 'dir'))
    [canSaveData,saveDataMsg,saveDataMsgID] = mkdir(cfg.files.subSaveDir);
    if canSaveData == false
        error(saveDataMsgID,'Cannot write in directory %s due to the following error: %s',pwd,saveDataMsg);
    end
end


% set name of the file for saving experiment parameters
cfg.files.expParamFile = fullfile(cfg.files.subSaveDir,'experimentParams.mat');
if exist(cfg.files.expParamFile,'file')
    % if it exists that means this subject has already run a session
    load(cfg.files.expParamFile);

    % Make sure there is a session left to run.
    % session number is incremented after the run, so after the final
    % session has been run it will be 1 greater than expParam.nSessions
    if expParam.sessionNum <= expParam.nSessions
        % make sure we want to start this session
        startUnanswered = 1;
        while startUnanswered
            startSession = input(sprintf('Do you want to start %s session %d (%s)? (type 1 or 0 and press enter). ',expParam.subject,expParam.sessionNum,expParam.sesTypes{expParam.sessionNum}));
            if isnumeric(startSession) && (startSession == 1 || startSession == 0)
                if startSession
                    fprintf('Starting %s session %d (%s).\n',expParam.subject,expParam.sessionNum,expParam.sesTypes{expParam.sessionNum});
                    startUnanswered = 0;
                else
                    fprintf('Not starting %s session %d (%s)! If you typed the wrong subject number, exit Matlab and try again.\n',expParam.subject,expParam.sessionNum,expParam.sesTypes{expParam.sessionNum});
                    return
                end
            end
        end
    else
        fprintf('All %s sessions for %s have already been run! Exiting...\n',expParam.nSessions,expParam.subject);
        return
    end
else
    % if it doesn't exist that means we're starting a new subject
    expParam.sessionNum = 1;

    % make sure we want to start this session
    startUnanswered = 1;
    while startUnanswered
        startSession = input(sprintf('Do you want to start %s as a new subject? (type 1 or 0 and press enter). ',expParam.subject));
        if ~isempty(startSession) && isnumeric(startSession) && (startSession == 1 || startSession == 0)
            if startSession
                fprintf('Preparing %s stimuli list.\n',expParam.subject);
                startUnanswered = 0;
            else
                fprintf('Not starting %s session %d! If you typed the wrong subject number, exit Matlab and try again.\n',expParam.subject,expParam.sessionNum);
                return
            end
        end
    end

    % Load the experiment's config file. Must create this for each experiment.
    if exist(fullfile(pwd,sprintf('config_%s.m',expParam.expName)),'file')
        [cfg,expParam] = eval(sprintf('config_%s(cfg,expParam);',expParam.expName));
        % save the experiment data
        save(cfg.files.expParamFile,'cfg','expParam');
    else
        error('Configuration file for %s experiment does not exist: %s',fullfile(pwd,sprintf('config_%s.m',expParam.expName)));
    end
end

%% Make sure the session number is in order and directories/files exist

% make sure session directory exists
cfg.files.sesSaveDir = fullfile(cfg.files.subSaveDir,sprintf('session_%d',expParam.sessionNum));
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
        resumeSession = input(sprintf('Do you want to resume %s session %d? (type 1 or 0 and press enter). ',expParam.subject,expParam.sessionNum));
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

%% Save the current experiment data
save(cfg.files.expParamFile,'cfg','expParam');

%% Run the experiment
fprintf('Running experiment: %s, subject %s, session %d...\n',expParam.expName,expParam.subject,expParam.sessionNum);

% try
    % Open data file
    logFile = fopen(cfg.files.sesLogFile,'at');

    %% Begin PTB display setup
    % set some font display options; must be set before opening w with Screen
    DefaultFontName = 'Courier New';
    DefaultFontStyle = 1;
    DefaultFontSize = 18;
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


    screenNumber = p.ptb.screenNumber;
    Width = RectWidth(p.ptb.rect);
    Height = RectHeight(p.ptb.rect);
    % Hide the mouse cursor:
    HideCursor;

    % Set up the color value to be used as experiment background color
    if ~isfield(cfg.screen,'bgColor')
        cfg.screen.bgColor = GrayIndex(screenNumber);
        warning('You did not set a value for the background color (cfg.screen.bgColor in your config_%s.m)! It is recommended to set this value. Setting experiment backdrop to the GrayIndex of this screen (%d).',expParam.expName,cfg.screen.bgColor);
        manualBgColor = false;
    else
        manualBgColor = true;
    end

    % Open a double buffered fullscreen window on the stimulation screen
    % 'screenNumber' and choose/draw a background color. 'w' is the handle
    % used to direct all drawing commands to that window - the "Name" of
    % the window. 'wRect' is a rectangle defining the size of the window.
    % See "help PsychRects" for help on such rectangles and useful helper
    % functions:

    % wRect = p.ptb.rect
    [w, wRect] = Screen('OpenWindow', screenNumber, cfg.screen.bgColor);

    % store the screen dimensions
    cfg.screen.wRect = wRect;

    % Do dummy calls to GetSecs, WaitSecs, KbCheck to make sure
    % they are loaded and ready when we need them - without delays
    % in the wrong moment:
    KbCheck;
    WaitSecs(0.1);
    GetSecs;

    % Set priority for script execution to realtime priority:
    priorityLevel = MaxPriority(w);
    Priority(priorityLevel);

    %% Run through the experiment
    % find out what session this will be
    sesName = expParam.sesTypes{expParam.sessionNum};

    % record the date and start time for this session
    expParam.session.(sesName).date = date;
    startTime = fix(clock);
    expParam.session.(sesName).startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6));

    switch sesName
        case{'stud1','stud2','stud3','stud4','stud5','stud6','stud7','stud8','stud9'}
            if ~isfield(expParam.session.(sesName),'date')
                expParam.session.(sesName).date = [];
            end
            if ~isfield(expParam.session.(sesName),'startTime')
                expParam.session.(sesName).startTime = [];
            end
            if ~isfield(expParam.session.(sesName),'endTime')
                expParam.session.(sesName).endTime = [];
            end

            sessionIsComplete = false;
            phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_studylist.mat',sesName));
            if exist(phaseProgressFile,'file')
                load(phaseProgressFile);
                if exist('phaseComplete','var') && phaseComplete
                    sessionIsComplete = true;
                end
            end

            if ~sessionIsComplete
                % Show instructions
                isKey = true;
                Screen('TextSize', w, cfg.text.basicTextSize);
                Screen('TextFont', w, cfg.text.basicFontName);
                Screen('TextStyle', w, cfg.text.basicFontStyle);
                DrawFormattedText(w, cfg.text.(sesName).instructionsMessage, 'center', 'center', cfg.text.basicTextColor);
                Screen('Flip', w);
                KbStrokeWait;
                % Start experiment
                [cfg,expParam] = mt_study(w,cfg,expParam,logFile,sesName);
            end

        case{'test1','test2','test3','test4','test5','test6','test7','test8','test9'}
            if ~isfield(expParam.session.(sesName),'date')
                expParam.session.(sesName).date = [];
            end
            if ~isfield(expParam.session.(sesName),'startTime')
                expParam.session.(sesName).startTime = [];
            end
            if ~isfield(expParam.session.(sesName),'endTime')
                expParam.session.(sesName).endTime = [];
            end

            sessionIsComplete = false;
            phaseProgressFile = fullfile(cfg.files.sesSaveDir,sprintf('phaseProgress_%s_studylist.mat',sesName));
            if exist(phaseProgressFile,'file')
                load(phaseProgressFile);
                if exist('phaseComplete','var') && phaseComplete
                    sessionIsComplete = true;
                end
            end

            if ~sessionIsComplete
                % Show instructions
                isKey = true;
                Screen('TextSize', w, cfg.text.basicTextSize);
                Screen('TextFont', w, cfg.text.basicFontName);
                Screen('TextStyle', w, cfg.text.basicFontStyle);
                DrawFormattedText(w, cfg.text.(sesName).instructionsMessage, 'center', 'center', cfg.text.basicTextColor);
                Screen('Flip', w);
                KbStrokeWait;
                % Start experiment
                [cfg,expParam] = mt_test(w,cfg,expParam,logFile,sesName);
            end
    end

    %% Session is done

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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%  Finish Message  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    message = sprintf('Thank you, this session is complete.\n\nPlease wait for the experimenter.');
    Screen('TextSize', w, cfg.text.basicTextSize);
    Screen('TextFont', w, cfg.text.basicFontName);
    Screen('TextStyle', w, cfg.text.basicFontStyle);
    % put the instructions on the screen
    DrawFormattedText(w, message, 'center', 'center', cfg.text.experimenterColor, cfg.text.instructCharWidth);
    Screen('Flip', w);

    % wait until g key is pressed
    RestrictKeysForKbCheck(KbName(cfg.keys.expContinue));
    KbWait(-1,2);
    RestrictKeysForKbCheck([]);
    Screen('Flip', w);
    WaitSecs(1.000);

    % Cleanup at end of experiment - Close window, show mouse cursor, close
    % result file, switch Matlab/Octave back to priority 0 -- normal
    % priority:
    Screen('CloseAll');
    fclose('all');
    ShowCursor;
    ListenChar;
    Priority(0);

    % End of experiment:
%     return

% catch ME
%     sesName = expParam.sesTypes{expParam.sessionNum};
%     fprintf('\nError during %s session %d (%s). Exiting gracefully (saving experimentParams.mat). You should restart Matlab before continuing.\n',expParam.subject,expParam.sessionNum,sesName);
%
%     % record the error date and time for this session
%     errorDate = date;
%     errorTime = fix(clock);
%     expParam.session.(sesName).errorDate = errorDate;
%     expParam.session.(sesName).errorTime = sprintf('%.2d:%.2d:%.2d',errorTime(4),errorTime(5),errorTime(6));
%
%     fprintf(logFile,'!!! ERROR: Crash %s %s\n',errorDate,expParam.session.(sesName).errorTime);
%
%     % save the experiment info in its current state
%     save(cfg.files.expParamFile,'cfg','expParam');
%
%     % close out the session log file
%     fclose(logFile);
%
%     % save out the error information
%     errorFile = fullfile(cfg.files.sesSaveDir,sprintf('error_%s_ses%d_%s_%.2d%.2d%.2d.mat',expParam.subject,expParam.sessionNum,errorDate,errorTime(4),errorTime(5),errorTime(6)));
%     fprintf('Saving error file %s.\n',errorFile);
%     save(errorFile,'ME');
%     errorReport = ME.getReport;
%     if ~isempty(errorReport)
%         fprintf('The error probably occurred because:\n');
%         fprintf('%s',errorReport);
%         fprintf('\n');
%     end
%     fprintf('To manually inspect the error, load the file with this command:\nload(''%s'');\n',errorFile);
%     fprintf('\n\tType ME and look at the ''message'' field (i.e., ME.message) to see WHY the error occured.\n');
%     fprintf('\tType ME.stack(1), ME.stack(2), etc. to see WHERE the error occurred.\n');
% end
