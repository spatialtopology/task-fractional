function [cfg,expParam] = mt_study(p,cfg,expParam,logFile,sesName, sub_num)

% Description:
%  This function runs the study task. There are no blocks.

fprintf('Running %s (study)...\n',sesName);

% set the starting date and time for this session ______________________________
thisDate = date;
startTime = fix(clock);
startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6));

% record the starting date and time for this session 
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

% preparation __________________________________________________________________
sessionCfg = cfg.stim.(sesName);
stimDir = cfg.files.stimDir;

% defauls is to show images ____________________________________________________
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

% prepared stimuli list for presentation _______________________________________
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


% D. making output table ________________________________________________________
vnames                         = {'param_fmriSession','param_experiment_start','param_memory_session_name'...
                                  'p1_fixation_onset','p1_fixation_duration',...
                                  'p2_stimuli_onset','p2_dummy_stimuli','p2_stimuli_filename',...
                                  'p3_fixation_onset','p3_fixation_duration',...
                                  'param_end_instruct_onset', 'param_experimentDuration'};
T                              = array2table(zeros(size(stimList,1),size(vnames,2)));
T.Properties.VariableNames     = vnames;
T.param_memory_session_name    = cell(size(stimList,1),1);
T.param_memory_session_name(:) = {sesName};
T.p2_stimuli_filename          = cell(size(stimList,1),1);

% G. instructions _____________________________________________________
main_dir                       = pwd;
instruct_filepath              = fullfile(main_dir, 'instructions');
instruct_study_name            = 'memory_study.png';
instruct_study                 = fullfile(instruct_filepath, instruct_study_name);

% ______________________________ Instructions _________________________________
Screen('TextSize',p.ptb.window,72);
start.texture = Screen('MakeTexture',p.ptb.window, imread(instruct_study));
Screen('DrawTexture',p.ptb.window,start.texture,[],[]);
T.param_experiment_start(:) = Screen('Flip', p.ptb.window);
WaitSecs(5);

% display stimuli
for trl = 1 : length(stimList)
    if sessionCfg.isFix
        % fixation cross
        Screen('TextSize', p.ptb.window, cfg.text.basicTextSize);
        DrawFormattedText(p.ptb.window, cfg.text.fixSymbol, 'center', 'center', cfg.text.basicTextColor);
        T.p1_fixation_onset(trl) = Screen('Flip', p.ptb.window);
        timeFix = sessionCfg.preStim(1) + ((sessionCfg.preStim(2) - sessionCfg.preStim(1)).*rand(1,1));
        T.p1_fixation_duration(trl) = timeFix;
        WaitSecs(timeFix);
    end
    switch cfg.stim.studyType
        case('i') % show images
            stimImgFile = fullfile(stimDir,stimList{trl});
            stimImgFile(stimImgFile=='\') = '/';
            stimImg = imread(stimImgFile);
            stimImg = uint8(stimImg);
            imageTexture = Screen('MakeTexture', p.ptb.window, stimImg);
            Screen('DrawTexture', p.ptb.window, imageTexture, [],[],0,0);
            [VBLTimestamp StimulusOnsetTime FlipTimestamp] = Screen('Flip', p.ptb.window);
            T.p2_stimuli_onset(trl) = StimulusOnsetTime;
            WaitSecs(sessionCfg.stim);
            type = NaN;
            if isStim(trl)
                type = 1;
            else
                type = 0;
            end

            thisGetSecs = GetSecs;
            fprintf(logFile,'%f\t%s\t%s\t%s\t%s\t%s\t%s\n',...
                thisGetSecs,...
                expParam.subject,...
                sesName,...
                'STUDY_STIM',...
                'image',...
                num2str(type),...
                stimList{trl});
            T.p2_dummy_stimuli(trl) = type;
            T.p2_stimuli_filename{trl} = stimList{trl};
        case('w') % show words
            currentWord = stimList{trl}(7:end-4);
            Screen('TextSize', p.ptb.window, cfg.text.basicTextSize);
            DrawFormattedText(p.ptb.window, currentWord, 'center', 'center', cfg.text.basicTextColor);
            Screen('Flip', p.ptb.window);
            WaitSecs(sessionCfg.stim);

            if isStim(trl)
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
    Screen('FillRect', p.ptb.window, cfg.screen.bgColor)
    Screen('Flip', p.ptb.window);
    WaitSecs(sessionCfg.isi);

    switch cfg.stim.studyType
        case('i') % images
%             Screen('Close', imageTexture);
            clear stimImg
    end

end

remaining_time = 60 - (GetSecs - T.param_experiment_start(1));
Screen('DrawLines', p.ptb.window, p.fix.allCoords, p.fix.lineWidthPix, cfg.text.whiteTextColor, [p.ptb.xCenter p.ptb.yCenter]);
T.p3_fixation_onset(:) = Screen('Flip', p.ptb.window);
WaitSecs(remaining_time);
T.p3_fixation_duration(:) = remaining_time;


T.param_end_instruct_onset(:) = GetSecs;
T.param_experimentDuration(:) = T.param_end_instruct_onset(1)- T.param_experiment_start(1);

% __________________________ save parameter ____________________________________
sub_save_dir = cfg.files.sesSaveDir;
saveFileName = fullfile(sub_save_dir,[strcat('sub-', sprintf('%04d', sub_num)), '_task-memory-',sesName, '_beh.csv' ]);
writetable(T,saveFileName);
end
