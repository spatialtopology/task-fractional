function [cfg,expParam] = mem_func_study(p,cfg,expParam,logFile,sesName,sub_num,biopac,channel)
for FIONUM = 1:7
    channel.d.setFIOState(pyargs('fioNum', int64(FIONUM), 'state', int64(0)));
end
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
vnames                         = {'src_subject_id','session_id','param_experiment_start',...
'param_memory_session_name'...
    'p1_fixation_onset','p1_fixation_duration',...
    'event01_stimuli_onset','event01_stimuli_biopac','event01_dummy_stimuli','study_event01_stimuli_filename',...
    'study_event02_isi_onset','study_param_last_fixation','study_param_remaining_time',...
    'study_param_end_instruct_onset', 'study_param_experiment_duration'};
T                              = array2table(zeros(size(stimList,1),size(vnames,2)));
T.Properties.VariableNames     = vnames;
T.param_memory_session_name    = cell(size(stimList,1),1);
T.param_memory_session_name(:) = {sesName};
T.src_subject_id(:)            = sub_num;
T.study_event01_stimuli_filename          = cell(size(stimList,1),1);
T.session_id(:)                = 4;

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
biopac_linux_matlab(biopac, channel, channel.study , 1);
WaitSecs(5);

% display stimuli
for trl = 1 : length(stimList)
    if sessionCfg.isFix
        % _________________________ 1. Fixtion Jitter  _______________________
        Screen('TextSize', p.ptb.window, cfg.text.basicTextSize);
        DrawFormattedText(p.ptb.window, cfg.text.fixSymbol, 'center', 'center', cfg.text.basicTextColor);
        %T.p1_fixation_onset(trl) = Screen('Flip', p.ptb.window);
        biopac_linux_matlab(biopac, channel, channel.fixation, 1);
        timeFix = sessionCfg.preStim(1) + ((sessionCfg.preStim(2) - sessionCfg.preStim(1)).*rand(1,1));
        %T.p1_fixation_duration(trl) = timeFix;
        WaitSecs(timeFix);
        biopac_linux_matlab(biopac, channel, channel.fixation, 0);
    end
    switch cfg.stim.studyType
        case('i') % show images
            stimImgFile = fullfile(stimDir,stimList{trl});
            stimImgFile(stimImgFile=="\") = "/";
            stimImg = imread(stimImgFile);
            stimImg = uint8(stimImg);
            imageTexture = Screen('MakeTexture', p.ptb.window, stimImg);
            Screen('DrawTexture', p.ptb.window, imageTexture, [],[],0,0);
            [VBLTimestamp StimulusOnsetTime FlipTimestamp] = Screen('Flip', p.ptb.window);

            T.event01_stimuli_onset(trl) = StimulusOnsetTime;
            T.event01_stimuli_biopac(trl) = biopac_linux_matlab(biopac, channel, channel.image, 1);
            WaitSecs(sessionCfg.stim);
            biopac_linux_matlab(biopac, channel, channel.image, 0);
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
            T.event01_dummy_stimuli(trl) = type;
            T.event01_stimuli_filename{trl} = stimList{trl};
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
    T.study_event02_isi_onset(trl) = Screen('Flip', p.ptb.window);
    biopac_linux_matlab(biopac, channel, channel.fixation, 1);
    WaitSecs(sessionCfg.isi);
    biopac_linux_matlab(biopac, channel, channel.fixation, 0);
    switch cfg.stim.studyType
        case('i') % images
            clear stimImg
    end

end

remaining_time = 60 - (GetSecs - T.param_experiment_start(1));
Screen('DrawLines', p.ptb.window, p.fix.allCoords, p.fix.lineWidthPix, cfg.text.whiteTextColor, [p.ptb.xCenter p.ptb.yCenter]);
T.study_param_last_fixation(:) = Screen('Flip', p.ptb.window);
biopac_linux_matlab(biopac, channel, channel.remainder ,1);
WaitSecs(remaining_time);
T.study_param_remaining_time(:) = remaining_time;
biopac_linux_matlab(biopac, channel, channel.remainder, 0);

T.study_param_end_instruct_onset(:) = GetSecs;
biopac_linux_matlab(biopac, channel, channel.study , 0);
T.study_param_experiment_duration(:) = T.study_param_end_instruct_onset(1)- T.param_experiment_start(1);
for FIONUM = 1:7
    channel.d.setFIOState(pyargs('fioNum', int64(FIONUM), 'state', int64(0)));
end
% __________________________ save parameter ____________________________________
sub_save_dir = cfg.files.sesSaveDir;
saveFileName = fullfile(sub_save_dir,[strcat('sub-', sprintf('%04d', sub_num)), '_task-memory-',sesName, '_beh.csv' ]);
writetable(T,saveFileName);
end
