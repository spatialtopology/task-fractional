function [cfg,expParam] = mt_study(p,cfg,expParam,logFile,sesName)
% function [cfg,expParam] = mt_studylist(p.ptb.window,cfg,expParam,logFile,sesName)
%
% Description:
%  This function runs the study task. There are no blocks.

fprintf('Running %s (study)...\n',sesName);

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
    'STUDY_START');

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
stimListAll = importdata(fileToLoad);
whichBuffers = sessionCfg.imToPick(:,2);

stimListBuffers = stimListAll(whichBuffers==0);
nbBuffersHalf = length(stimListBuffers)/2;
stimListStudy = stimListAll(whichBuffers==1);
nbStim = length(stimListStudy);

isStim = ones(2*nbBuffersHalf+nbStim,1);
isStim(1:nbBuffersHalf,1) = 0;
isStim(end+1-nbBuffersHalf:end,1) = 0;

% randomized
if cfg.stim.shuffle
    orderStimStudy = randperm(length(stimListStudy),length(stimListStudy));
    if ~isempty(stimListBuffers)
        stimList = stimListBuffers(1:nbBuffersHalf);
        stimList = [stimList;stimListStudy(orderStimStudy)];
        stimList = [stimList;stimListBuffers(nbBuffersHalf+1:end)];
    else
        stimList = stimListStudy(orderStimStudy);
    end
else
    if ~isempty(stimListBuffers)
        stimList = stimListBuffers(1:length(stimListBuffers)/2);
        stimList = [stimList;stimListStudy];
        stimList = [stimList;stimListBuffers(length(stimListBuffers)/2+1:end)];
    else
        stimList = stimListStudy;
    end
end

%% display stimuli
for s = 1 : length(stimList)
    if sessionCfg.isFix
        % fixation cross
        Screen('TextSize', p.ptb.window, cfg.text.basicTextSize);
        DrawFormattedText(p.ptb.window, cfg.text.fixSymbol, 'center', 'center', cfg.text.basicTextColor);
        Screen('Flip', p.ptb.window);
        timeFix = sessionCfg.preStim(1) + ((sessionCfg.preStim(2) - sessionCfg.preStim(1)).*rand(1,1));
        WaitSecs(timeFix);
    end
    switch cfg.stim.studyType
        case('i') % show images
            stimImgFile = fullfile(stimDir,stimList{s});
            stimImgFile(stimImgFile=='\') = '/';
            stimImg = imread(stimImgFile);
            stimImg = uint8(stimImg);
            imageTexture = Screen('MakeTexture', p.ptb.window, stimImg);
            Screen('DrawTexture', p.ptb.window, imageTexture, [],[],0,0);
            [VBLTimestamp StimulusOnsetTime FlipTimestamp] = Screen('Flip', p.ptb.window);
            WaitSecs(sessionCfg.stim);
            
            if isStim(s)
                type = '1';
            else
                type = '0';
            end
            
            thisGetSecs = GetSecs;
            fprintf(logFile,'%f\t%s\t%s\t%s\t%s\t%s\t%s\n',...
                thisGetSecs,...
                expParam.subject,...
                sesName,...
                'STUDY_STIM',...
                'image',...
                type,...
                stimList{s});
        case('w') % show words
            currentWord = stimList{s}(7:end-4);
            Screen('TextSize', p.ptb.window, cfg.text.basicTextSize);
            DrawFormattedText(p.ptb.window, currentWord, 'center', 'center', cfg.text.basicTextColor);
            Screen('Flip', p.ptb.window);
            WaitSecs(sessionCfg.stim);
            
            if isStim(s)
                type = '1';
            else
                type = '0';
            end
            
            thisGetSecs = GetSecs;
            fprintf(logFile,'%f\t%s\t%s\t%s\t%s\t%s\t%s\n',...
                thisGetSecs,...
                expParam.subject,...
                sesName,...
                'STUDY_STIM',...
                'word',...
                type,...
                currentWord);
            
    end
    
    % isi
    Screen('FillRect', p.ptb.window, cfg.screen.bgColor);
    Screen('Flip', p.ptb.window);
    WaitSecs(sessionCfg.isi);
    
    switch cfg.stim.studyType
        case('i') % images
%             Screen('Close', imageTexture);
            clear stimImg
    end
end

