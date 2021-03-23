function [cfg,expParam] = config_canna(cfg,expParam)
% function [cfg,expParam] = config_expe(cfg,expParam)
%
% Description:
%  Configuration function for memorization experiment. This
%  file should be edited for your particular experiment.

%% Experiment session information
%expParam.subject = 1;
% Set the number of sessions
%expParam.sessionNum = 1;
expParam.nSessions = 4; % 5
expParam.sesTypes = {'study01', 'test01', 'study02', 'test02'}; %

%% If this is session 1, setup the experiment
if expParam.sessionNum == 1
    %% Subject parameters

    % for counterbalancing
    % odd or even subject number
    if mod(str2double(expParam.subject(end)),2) == 0
        expParam.isEven = true;
    else
        expParam.isEven = false;
    end
    % subject number ends in 1-5 or 6-0
%     if str2double(expParam.subject(end)) >= 1 && str2double(expParam.subject(end)) <= 5
%         expParam.is15 = true;
%     else
%         expParam.is15 = false;
%     end

    %% Screen parameters
%     cfg.screen.bgColor = uint8((rgb('White') * 255) + 0.5);
%     cfg.screen.bgColor = uint8((rgb('Black') * 255) + 0.5);
    cfg.screen.blackbgColor = uint8((rgb('Black') * 255) + 0.5);

    %% Stimulus parameters

    % the file extension for your images
    cfg.files.stimFileExt = '.png';

    % scale stimlus down (< 1) or up (> 1)
    cfg.stim.stimScale = 1;

    % image directory
    cfg.files.stimDir = fullfile(cfg.files.expDir,'images');
    % Images name = obj + number (001 to 999 with no missing number) + name
    % list directory
    cfg.files.stimListDir = fullfile(cfg.files.expDir,'stimList');

    % number of items
    % for the study lis0t
    cfg.stim.nStudy = 20;
    % for the test list
    cfg.stim.nTestNew = 20;
    cfg.stim.nTestOld = 20;
    % # of non test buffers at the beginning and end (these images will not be included in the test phase)
    cfg.stim.nonTestBuffersStudy = 3;

    % whether to use different list for each study session
    cfg.stim.differentStimList = true;
    % stimuli list: random or predefine
    cfg.stim.stimListRandom = true;
    % whether to shuffle the stimulus list for presentation
    cfg.stim.shuffle = true;

    % type of items
    % i = images, w = word, TODO: iw = half/half
    % for the study list
    cfg.stim.studyType = 'i'; % 'i'
    % for the test list
    cfg.stim.testType = 'i'; % 'i'

    % practice images stored in separate directories
    expParam.runPractice = true;
    cfg.stim.useSeparatePracStims = true;

    if expParam.runPractice

    end

    %% Define the response keys

    % the experimenter's secret key to continue the experiment
    KbName('UnifyKeyNames');
    cfg.keys.start = 's';
    cfg.keys.trigger = '5%';
    cfg.keys.end = 'e';
    cfg.keys.expContinue = 'g';
    cfg.keys.keyRow = 'upper';

    % subordinate matching keys (counterbalanced based on subNum 1-5, 6-0)
    if expParam.isEven
        % upper row
        cfg.keys.responseKeyNames = {'1!','2@'};
    else
        % middle row
        cfg.keys.responseKeyNames = {'1!','2@'};
    end
%     cfg.keys.responseKeyNames = {'f','j'};
    cfg.keys.oldKey = cfg.keys.responseKeyNames{1};
    cfg.keys.newKey = cfg.keys.responseKeyNames{2};
%
%     if expParam.is15
%         cfg.keys.oldKey = cfg.keys.responseKeyNames{1};
%         cfg.keys.newKey = cfg.keys.responseKeyNames{2};
%     else
%         cfg.keys.oldKey = cfg.keys.responseKeyNames{2};
%         cfg.keys.newKey = cfg.keys.responseKeyNames{1};
%     end

    %% Screen, text, and symbol configuration for size and color

    % Choose a color value (e.g., 210 for gray) to be used as experiment backdrop
    cfg.screen.bgColor = uint8((rgb('Grey') * 255) + 0.5);

    % font sizes
    % basic: small messages printed to the screen
    % instruct: instructions
    % fixSize: fixation
    if ispc
        cfg.text.basicTextSize = 18;
        cfg.text.instructTextSize = 18;
        cfg.text.fixSize = 18;
    elseif ismac
        cfg.text.basicTextSize = 32;
        cfg.text.instructTextSize = 28;
        cfg.text.fixSize = 32;
    elseif isunix
        cfg.text.basicTextSize = 24;
        cfg.text.instructTextSize = 18;
        cfg.text.fixSize = 24;
    end

    % text colors
    cfg.text.basicTextColor = uint8((rgb('Black') * 255) + 0.5);
    cfg.text.GreenTextColor = uint8((rgb('Green') * 255) + 0.5);
    cfg.text.whiteTextColor = uint8((rgb('White') * 255) + 0.5);
    cfg.text.instructColor = uint8((rgb('Black') * 255) + 0.5);
    % text color when experimenter's attention is needed
    cfg.text.experimenterColor = uint8((rgb('Lime') * 255) + 0.5);

    cfg.text.basicFontName = 'Courier New';
    cfg.text.basicFontStyle = 1;

    % number of characters wide at which any text will wrap
    cfg.text.instructCharWidth = 70;

    % key to push to dismiss instruction screen
    cfg.keys.instructContKey = 'space';

    % fixation info
    cfg.text.fixSymbol = '+';
    cfg.text.respSymbol = '?';
    cfg.text.fixationColor = uint8((rgb('Black') * 255) + 0.5);

    % fixation defaults; change in phases if you want other behavior
    fixDuringISI = true;
    fixDuringPreStim = true;
    fixDuringStim = false;

    % "respond faster" text
    cfg.text.respondFaster = 'No response recorded!\nRespond faster!';
    cfg.text.respondFasterColor = uint8((rgb('Red') * 255) + 0.5);
    cfg.text.respondFasterFeedbackTime = 1.5;

    % error text color
    cfg.text.errorTextColor = uint8((rgb('Red') * 255) + 0.5);

    %% Session configuration

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for s = 1 : expParam.nSessions/2
        sesName = ['study', sprintf('%02d', s)];
        if ismember(sesName,expParam.sesTypes)
            cfg.stim.(sesName).fixDuringISI = fixDuringISI;
            cfg.stim.(sesName).fixDuringPreStim = fixDuringPreStim;
            cfg.stim.(sesName).fixDuringStim = fixDuringStim;

            % durations, in seconds
            cfg.stim.(sesName).isi = 1.0;
            cfg.stim.(sesName).stim = 1.0;
            % random intervals are generated on the fly
            cfg.stim.(sesName).isFix = false; % true
            %             cfg.stim.(sesName).preStim = [0.5 0.7];
            % create the stimulus list
            cfg.stim.(sesName).stimListFile = fullfile(cfg.files.subSaveDir,['stimList_' sesName '.txt']);
%            [cfg,expParam] = mem_func_saveStimList_images(cfg,expParam,sesName,[]);%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [cfg,expParam] = mem_func_saveStimList_images(cfg,expParam,sesName);

            % instruction message
            m1 = 'You are going to be shown a series of stimuli.\n\n\n\n';
            m2 = 'Your task is to memorize them. You will be tested on them later.\n\n\n\n';
            m3 = 'Press any key to start.';
            cfg.text.(sesName).instructionsMessage = [m1 m2 m3];
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for s = 1 : expParam.nSessions/2
        sesName = ['test' sprintf('%02d', s)];
        if ismember(sesName,expParam.sesTypes)
            cfg.stim.(sesName).fixDuringISI = fixDuringISI;
            cfg.stim.(sesName).fixDuringPreStim = fixDuringPreStim;
            cfg.stim.(sesName).fixDuringStim = fixDuringStim;

            % durations, in seconds
            cfg.stim.(sesName).isi = 1.0;
            cfg.stim.(sesName).stim = 2.0;
            % random intervals are generated on the fly
            cfg.stim.(sesName).isFix = true;
            cfg.stim.(sesName).preStim = [0.5 1.0];
            % whether to answer as fast as possible or after the stimuli
            cfg.stim.(sesName).answerFast = true; % false: wait after 2.0
            % create the stimulus list
            cfg.stim.(sesName).stimListFile = fullfile(cfg.files.subSaveDir,['stimList_' sesName '.txt']);
            %[cfg,expParam] =
            %mem_func_saveStimList_images(cfg,expParam,sesName,[]);%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [cfg,expParam] = mem_func_saveStimList_images(cfg,expParam,sesName);

            % instruction message
            m1 = 'You are going to be shown a series of stimuli.\n\n\n\n';
            m2 = 'Your task is to decide which stimuli was seen during the first part of the experiment.\n\n\n\n';
            m3 = ['Press "' cfg.keys.oldKey '" if you have seen the stimuli.\n\n'];
            m4 = ['Press "' cfg.keys.newKey '" if you have NOT seen the stimuli.\n\n\n\n'];
            m5 = 'Please put your fingers on the key before starting.\n\n\n\n';
            m6 = 'Press any key to start.';
            cfg.text.(sesName).instructionsMessage = [m1 m2 m3 m4 m5 m6];
        end
    end
end
