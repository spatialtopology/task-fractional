function [cfg,expParam] = mt_test(w,cfg,expParam,logFile,sesName)
% function [cfg,expParam] = mt_test(w,cfg,expParam,logFile,sesName)

% Description:
%  This function runs the test task. There are no blocks.

fprintf('Running %s (testing)...\n',sesName);

%% set the starting date and time for this session
thisDate = date;
startTime = fix(clock);
startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6));

%% record the starting date and time for this session

expParam.session.(sesName).date = thisDate;
expParam.session.(sesName).startTime = startTime;

% put it in the log file
fprintf(logFile,'!!! Start of %s (%s) %s %s\n',sesName,mfilename,thisDate,startTime);

thisGetSecs = GetSecs;
fprintf(logFile,'%f\t%s\t%s\t%s\n',...
    thisGetSecs,...
    expParam.subject,...
    sesName,...
    'TEST_START');

%% preparation
sessionCfg = cfg.stim.(sesName);
stimDir = cfg.files.stimDir;

% defauls is to show images
if ~isfield(cfg.stim,'studyType')
    cfg.stim.studyType = 'i';
end

% default is to not print out trial details
if ~isfield(cfg.text,'printTrialInfo') || isempty(cfg.text.printTrialInfo)
    cfg.text.printTrialInfo = false;
end

% default is to show fixation during ISI
if ~isfield(sessionCfg,'fixDuringISI')
    sessionCfg.fixDuringISI = true;
end
% default is to show fixation during preStim
if ~isfield(sessionCfg,'fixDuringPreStim')
    sessionCfg.fixDuringPreStim = true;
end
% default is to not show fixation with the stimulus
if ~isfield(sessionCfg,'fixDuringStim')
    sessionCfg.fixDuringStim = false;
end

%% prepared stimuli list for presentation
% load stimuli list
fileToLoad = sessionCfg.stimListFile;
stimList = importdata(fileToLoad);
oldNew = cfg.stim.(sesName).imToTest(:,2);

% randomized
if cfg.stim.shuffle
    orderStimTest = randperm(length(stimList),length(stimList));
    stimList = stimList(orderStimTest);
    oldNew = oldNew(orderStimTest);
end

%% display stimuli
for s = 1 : length(stimList)
    correctAnswer = oldNew(s);
    if sessionCfg.isFix
        % fixation cross
        Screen('TextSize', w, cfg.text.basicTextSize);
        DrawFormattedText(w, cfg.text.fixSymbol, 'center', 'center', cfg.text.basicTextColor);
        Screen('Flip', w);
        timeFix = sessionCfg.preStim(1) + ((sessionCfg.preStim(2) - sessionCfg.preStim(1)).*rand(1,1));
        WaitSecs(timeFix);
    end
    switch cfg.stim.studyType
        case('i') % show images
            stimImgFile = fullfile(stimDir,stimList{s});
            stimImgFile(stimImgFile=='\') = '/';
            stimImg = imread(stimImgFile);
            stimImg = uint8(stimImg);
            imageTexture = Screen('MakeTexture', w, stimImg);
            Screen('DrawTexture', w, imageTexture, [],[],0,0);
            [VBLTimestamp StimulusOnsetTime FlipTimestamp] = Screen('Flip', w);
            
            thisGetSecs = GetSecs;
            fprintf(logFile,'%f\t%s\t%s\t%s\t%s\t%s\n',...
                thisGetSecs,...
                expParam.subject,...
                sesName,...
                'TEST_STIM',...
                'image',...
                stimList{s});
            
        case('w') % show words
            currentWord = stimList{s}(7:end-4);
            Screen('TextSize', w, cfg.text.basicTextSize);
            DrawFormattedText(w, currentWord, 'center', 'center', cfg.text.basicTextColor);
            [VBLTimestamp StimulusOnsetTime FlipTimestamp] = Screen('Flip', w);
            
            thisGetSecs = GetSecs;
            fprintf(logFile,'%f\t%s\t%s\t%s\t%s\t%s\n',...
                thisGetSecs,...
                expParam.subject,...
                sesName,...
                'TEST_STIM',...
                'word',...
                currentWord);
    end
    if sessionCfg.answerFast % get the answer as fast as possible
        % Wait for answer
        respToBeMade = true;
        keyCode = zeros(1,256);
        timeStim = GetSecs - thisGetSecs;
        while respToBeMade && timeStim < sessionCfg.stim
            % check the keyboard
            [keyIsDown,secs, keyCode] = KbCheck;
            if keyCode(KbName(cfg.keys.oldKey))
                respToBeMade = false;
                answer = '1';
                RT = secs-StimulusOnsetTime;
            elseif keyCode(KbName(cfg.keys.newKey))
                respToBeMade = false;
                answer = '0';
                RT = secs-StimulusOnsetTime;
            end
            timeStim = GetSecs - thisGetSecs;
        end
        
        switch cfg.stim.studyType
            case('i') % images
                Screen('Close', imageTexture);
                clear stimImg
        end
        
        if respToBeMade && timeStim >= sessionCfg.stim %if not answer made after the presentation time of the stimuli, display a ?
            % Question mark
            Screen('TextSize', w, cfg.text.basicTextSize);
            DrawFormattedText(w, cfg.text.respSymbol, 'center', 'center', cfg.text.basicTextColor);
            Screen('Flip', w);
            
            % Wait for answer
            while respToBeMade
                % check the keyboard
                [keyIsDown,secs, keyCode] = KbCheck;
                if keyCode(KbName(cfg.keys.oldKey))
                    respToBeMade = false;
                    answer = '1';
                    RT = secs-StimulusOnsetTime;
                elseif keyCode(KbName(cfg.keys.newKey))
                    respToBeMade = false;
                    answer = '0';
                    RT = secs-StimulusOnsetTime;
                end
            end
        end
        
    else % wait for the presentation time of the stimuli before getting the answer
        WaitSecs(sessionCfg.stim);
        
        % Question mark
        Screen('TextSize', w, cfg.text.basicTextSize);
        DrawFormattedText(w, cfg.text.respSymbol, 'center', 'center', cfg.text.basicTextColor);
        Screen('Flip', w);
        
        % Wait for answer
        respToBeMade = true;
        keyCode = zeros(1,256);
        while respToBeMade
            % check the keyboard
            [keyIsDown,secs, keyCode] = KbCheck;
            if keyCode(KbName(cfg.keys.oldKey))
                respToBeMade = false;
                answer = '1';
                RT = secs-StimulusOnsetTime;
            elseif keyCode(KbName(cfg.keys.newKey))
                respToBeMade = false;
                answer = '0';
                RT = secs-StimulusOnsetTime;
            end
        end
    end
    
    thisGetSecs = GetSecs;
    fprintf(logFile,'%f\t%s\t%s\t%s\t%s\t%s\t%f\n',...
        thisGetSecs,...
        expParam.subject,...
        sesName,...
        'TEST_RESP',...
        num2str(correctAnswer),...
        answer,...
        RT);

    % isi
    Screen('FillRect', w, cfg.screen.bgColor);
    Screen('Flip', w);
    WaitSecs(sessionCfg.isi);
end



