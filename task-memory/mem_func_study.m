function [cfg,expParam] = mem_func_study(p,cfg,expParam,logFile,sesName,studydetails,channel)

%% -----------------------------------------------------------------------------
%                              Parameters
% ------------------------------------------------------------------------------

%% A. reset biopac ____________________________________________________________
if channel.biopac
for FIONUM = 1:7
    channel.d.setFIOState(pyargs('fioNum', int64(FIONUM), 'state', int64(0)));
end
end

%% B. from original Canna memory script ________________________________________
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
    thisGetSecs, expParam.subject, sesName, 'STUDY_START');

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

%% C. bids_string ________________________________________________________
% example: sub-0001_ses-01_task-fractional_run-01-memory-test01
taskname = 'memory';
bids_string                     = [strcat('sub-', sprintf('%04d', studydetails.sub_num)), ...
strcat('_ses-',sprintf('%02d', studydetails.session_id)),...
strcat('_task-fractional'),...
strcat('_run-', sprintf('%02d', studydetails.run_order),'_', taskname, '_', sesName)];

% D. making output table ________________________________________________________
vnames                         = {'src_subject_id','session_id','run_num','param_experiment_start','param_memory_session_name',...
'event01_fixation_onset','event01_fixation_duration',...
'event02_image_onset','event02_image_filename','event02_dummy_stimuli_type',...
'event03_isi_onset',...
'param_end_instruct_onset','study_experiment_duration',...
'RAW_param_experiment_start','RAW_param_start_biopac','RAW_event01_fixation_onset',...
'RAW_event01_fixation_biopac','RAW_event02_image_onset','RAW_event02_image_biopac',...
'RAW_event03_isi_onset','RAW_event03_isi_biopac','RAW_param_end_instruct_onset'};
vtypes = {'double','double','double','double','string','double','double','double',...
'string','double','double','double','double','double','double','double','double',...
'double','double','double','double','double'};

T = table('Size', [size(stimList,1) size(vnames,2)], 'VariableNames', vnames, 'VariableTypes', vtypes);
T.src_subject_id(:)            = studydetails.sub_num;
T.session_id(:)                = studydetails.session_id ;
T.run_num(:)                   = studydetails.run_order;
T.param_memory_session_name(:) = {sesName};

% G. instructions _____________________________________________________
main_dir                       = pwd;
instruct_filepath              = fullfile(main_dir, 'instructions');
instruct_study_name            = 'memory_study.png';
instruct_study                 = fullfile(instruct_filepath, instruct_study_name);

%% -----------------------------------------------------------------------------
%                              Start Experiment
% ------------------------------------------------------------------------------

Screen('TextSize',p.ptb.window,72);
start.texture = Screen('MakeTexture',p.ptb.window, imread(instruct_study));
Screen('DrawTexture',p.ptb.window,start.texture,[],[]);
T.RAW_param_experiment_start(:) = Screen('Flip', p.ptb.window);
T.RAW_param_start_biopac(:)    = biopac_linux_matlab(channel, channel.study , 1);
WaitSecs(5);

% display stimuli
for trl = 1 : length(stimList)
    if sessionCfg.isFix
        % _________________________ 1. Fixtion Jitter  _______________________
        Screen('TextSize', p.ptb.window, cfg.text.basicTextSize);
        DrawFormattedText(p.ptb.window, cfg.text.fixSymbol, 'center', 'center', cfg.text.basicTextColor);
        T.RAW_event01_fixation_onset(trl) = Screen('Flip', p.ptb.window);
        T.RAW_event01_fixation_biopac(trl) = biopac_linux_matlab(channel, channel.fixation, 1);
        timeFix = sessionCfg.preStim(1) + ((sessionCfg.preStim(2) - sessionCfg.preStim(1)).*rand(1,1));
        T.event01_fixation_duration(trl) = timeFix;
        WaitSecs('UntilTime', T.RAW_event01_fixation_onset(trl) + timeFix);
        biopac_linux_matlab(channel, channel.fixation, 0);
    end
    switch cfg.stim.studyType
        case('i') % show images
            stimImgFile = fullfile(stimDir,stimList{trl});
            stimImg = imread(stimImgFile);
            stimImg = uint8(stimImg);
            imageTexture = Screen('MakeTexture', p.ptb.window, stimImg);
            Screen('DrawTexture', p.ptb.window, imageTexture, [],[],0,0);
            [VBLTimestamp StimulusOnsetTime FlipTimestamp] = Screen('Flip', p.ptb.window);

            T.RAW_event02_image_onset(trl) = StimulusOnsetTime;
            T.RAW_event02_image_biopac(trl) = biopac_linux_matlab( channel, channel.image, 1);
            WaitSecs(sessionCfg.stim);
            biopac_linux_matlab(channel, channel.image, 0);
            type = NaN;
            if isStim(trl)
                type = 1;
            else
                type = 0;
            end

            thisGetSecs = GetSecs;
            fprintf(logFile,'%f\t%s\t%s\t%s\t%s\t%s\t%s\n',...
                thisGetSecs, expParam.subject, sesName, 'STUDY_STIM', 'image', num2str(type), stimList{trl});
            T.event02_dummy_stimuli_type(trl) = type;
            T.event02_image_filename{trl} = stimList{trl};
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
                thisGetSecs, expParam.subject, sesName, 'STUDY_STIM', 'word', type, currentWord);
    end

    % isi
    Screen('FillRect', p.ptb.window, cfg.screen.bgColor)
    T.RAW_event03_isi_onset(trl) = Screen('Flip', p.ptb.window);
    T.RAW_event03_isi_biopac(trl) = biopac_linux_matlab( channel, channel.fixation, 1);
    WaitSecs(sessionCfg.isi);
    biopac_linux_matlab( channel, channel.fixation, 0);
    switch cfg.stim.studyType
        case('i') % images
            clear stimImg
    end

end

remaining_time = 60 - (GetSecs - T.RAW_param_experiment_start(1));
Screen('DrawLines', p.ptb.window, p.fix.allCoords, p.fix.lineWidthPix, cfg.text.whiteTextColor, [p.ptb.xCenter p.ptb.yCenter]);
Screen('Flip', p.ptb.window);
biopac_linux_matlab( channel, channel.remainder ,1);
WaitSecs(remaining_time);
biopac_linux_matlab( channel, channel.remainder, 0);
T.RAW_param_end_instruct_onset(:) = GetSecs;
biopac_linux_matlab( channel, channel.study , 0);
T.study_experiment_duration(:) = T.RAW_param_end_instruct_onset(1)- T.RAW_param_experiment_start(1);

if channel.biopac
for FIONUM = 1:7
    channel.d.setFIOState(pyargs('fioNum', int64(FIONUM), 'state', int64(0)));
end
end
% __________________________ save parameter ____________________________________
T.param_experiment_start(:) = T.RAW_param_experiment_start(:) - studydetails.trigger_onset - studydetails.dummy;
T.event01_fixation_onset(:) = T.RAW_event01_fixation_onset(:)- studydetails.trigger_onset - studydetails.dummy;
T.event02_image_onset(:) = T.RAW_event02_image_onset(:)- studydetails.trigger_onset - studydetails.dummy;
T.event03_isi_onset(:) = T.RAW_event03_isi_onset(:)- studydetails.trigger_onset - studydetails.dummy;
T.param_end_instruct_onset(:) = T.RAW_param_end_instruct_onset(:)- studydetails.trigger_onset - studydetails.dummy;

%sub_save_dir = cfg.files.sesSaveDir;
saveFileName = fullfile(studydetails.sub_save_dir,[bids_string, '_beh.csv' ]);
repoFileName = fullfile(studydetails.repo_save_dir,[bids_string, '_beh.csv' ]);
writetable(T,saveFileName);
writetable(T,repoFileName);

end
