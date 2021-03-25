function [cfg,expParam, accuracy_freq] = mem_func_test(p,cfg,expParam,logFile,sesName,studydetails,channel)

%% -----------------------------------------------------------------------------
%                              Parameters
% ------------------------------------------------------------------------------

% Description:
%  This function runs the test task. There are no blocks.
task_duration = 2;
fprintf('Running %s (testing)...\n',sesName);

% preparation
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
    sessionCfg.fixDuringStim = false;bio_param
end


% biopac reset ________________________________________________________________
if channel.biopac
for FIONUM = 1:7
    channel.d.setFIOState(pyargs('fioNum', int64(FIONUM), 'state', int64(0)));
end
end

% prepared stimuli list for presentation ________________________________________________________
% load stimuli list
fileToLoad = sessionCfg.stimListFile;
stimList = importdata(fileToLoad);
oldNew = cfg.stim.(sesName).imToTest(:,2);

% randomized ________________________________________________________
if cfg.stim.shuffle
    orderStimTest = randperm(length(stimList),length(stimList));
    stimList = stimList(orderStimTest);
    oldNew = oldNew(orderStimTest);
end


% bids_string ________________________________________________________
% example: sub-0001_ses-01_task-fractional_run-01-memory-test01
taskname = 'memory';
bids_string                     = [strcat('sub-', sprintf('%04d', studydetails.sub_num)), ...
strcat('_ses-',sprintf('%02d', studydetails.session_id)),...
strcat('_task-fractional'),...
strcat('_run-', sprintf('%02d', studydetails.run_order),'_', taskname, '_', sesName)];



% D. making output table ________________________________________________________
%vnames = {'src_subject_id','session_id','RAW_param_experiment_start','param_memory_session_name','RAW_param_start_biopac'...
%    'RAW_event01_fixation_onset', 'event01_fixation_duration',...
%    'RAW_event02_image_onset','event02_image_filename',...
%    'param_answer','event03_response_ptbkey','event03_response_key','event03_response_keyname',...
%    'event03_response_onset','event03_RT',...
%    'event04_fixation_onset','event04_fixation_duration','event04_fixation_biopac'...
%    'param_end_instruct_onset', 'param_experiment_duration', 'test_accuracy', 'event01_fixation_duration'};


vnames = {'src_subject_id','session_id','run_num','param_memory_session_name',...
'event01_fixation_onset','event01_fixation_duration',...
'event02_image_onset','event02_image_filename',...
'param_answer','event03_response_ptbkey','event03_response_key','event03_response_keyname','event03_response_onset','event03_RT',...
'event04_fixation_duration',...
'param_end_instruct_onset','param_experiment_duration','test_accuracy',...
'RAW_param_experiment_start','RAW_param_start_biopac',...
'RAW_event01_fixation_onset','RAW_event01_fixation_biopac',...
'RAW_event02_image_onset','RAW_event02_image_biopac',...
'RAW_event03_response_onset','RAW_event04_fixation_onset','RAW_event04_fixation_biopac'};
vtypes = {'double','double','double','string',...
'double','double',...
'double','string',...
'double','double','double','string','double','double',...
'double',...
'double','double','double',...
'double','double',...
'double','double',...
'double','double',...
'double','double','double'};
T = table('Size', [size(stimList,1) size(vnames,2)], 'VariableNames', vnames, 'VariableTypes', vtypes);
T.src_subject_id(:) = studydetails.sub_num;
T.session_id(:) = studydetails.session_id;
T.run_num(:) = studydetails.run_order;
T.param_memory_session_name(:) = {sesName};
% G. instructions _____________________________________________________
main_dir                       = pwd;
instruct_filepath              = fullfile(main_dir, 'instructions');
instruct_test_name             = 'memory_test.png';
instruct_test                  = fullfile(instruct_filepath, instruct_test_name);

% record the starting date and time for this session ________________________________________________________
% set the starting date and time for this session
thisDate = date;
startTime = fix(clock);
startTime = sprintf('%.2d:%.2d:%.2d',startTime(4),startTime(5),startTime(6));
% put it in the log file
fprintf(logFile,'!!! Start of %s (%s) %s %s\n',sesName,mfilename,thisDate,startTime);

expParam.session.(sesName).date = thisDate;
expParam.session.(sesName).startTime = startTime;

Screen('TextSize', p.ptb.window, cfg.text.basicTextSize);
Screen('TextFont', p.ptb.window, cfg.text.basicFontName);
Screen('TextStyle', p.ptb.window, cfg.text.basicFontStyle);
% DrawFormattedText(p.ptb.window, cfg.text.(sesName).instructionsMessage, 'center', 'center');%, cfg.text.whiteTextColor);

%% -----------------------------------------------------------------------------
%                              Start Experiment
% ------------------------------------------------------------------------------

Screen('TextSize',p.ptb.window,72);
start.texture = Screen('MakeTexture',p.ptb.window, imread(instruct_test));
Screen('DrawTexture',p.ptb.window,start.texture,[],[]);
T.RAW_param_experiment_start(:) = Screen('Flip', p.ptb.window);
T.RAW_param_start_biopac(:) = biopac_linux_matlab(channel, channel.test, 1);
WaitSecs(5);

% DisableKeysForKbCheck([]);
KbName('UnifyKeyNames');
thisGetSecs = GetSecs;
fprintf(logFile,'%f\t%s\t%s\t%s\n',...
    T.RAW_param_experiment_start(1), expParam.subject, sesName, 'TEST_START');

% ___________________________ 0. Experimental loop ____________________________
% display stimuli
for trl = 1 : length(stimList)
    correctAnswer = oldNew(trl);
    if sessionCfg.isFix
    %% -----------------------------------------------------------------------------
    %                        1. Fixtion Jitter mean 1 sec
    %-------------------------------------------------------------------------------
        Screen('TextSize', p.ptb.window, cfg.text.basicTextSize);
        DrawFormattedText(p.ptb.window, cfg.text.fixSymbol, 'center', 'center', cfg.text.whiteTextColor);
        T.RAW_event01_fixation_onset(trl) = Screen('Flip', p.ptb.window);
        T.RAW_event01_fixation_biopac(trl) = biopac_linux_matlab(channel, channel.fixation, 1);
        timeFix = sessionCfg.preStim(1) + ((sessionCfg.preStim(2) - sessionCfg.preStim(1)).*rand(1,1));
        T.event01_fixation_duration(trl) = timeFix;
        WaitSecs('UntilTime', T.RAW_event01_fixation_onset(trl) + timeFix);
        biopac_linux_matlab(channel, channel.fixation, 0);
    end


    %% -----------------------------------------------------------------------------
    %                               2. image texture
    %-------------------------------------------------------------------------------

    switch cfg.stim.studyType
        case('i') % show images
            stimImgFile = fullfile(stimDir,stimList{trl});
            stimImg = imread(stimImgFile);
            stimImg = uint8(stimImg);
            imageTexture = Screen('MakeTexture', p.ptb.window, stimImg);
            Screen('DrawTexture', p.ptb.window, imageTexture, [],[],0,0);
            % 5-2. present scale lines _____________________________________________________
            Yc = 300; % Y coord
            cDist = 20; % vertical line depth
            lXc = -200; % left X coord
            rXc = 200; % right X coord
            lineCoords = [lXc lXc lXc rXc rXc rXc; Yc-cDist Yc+cDist Yc Yc Yc-cDist Yc+cDist];
            %             Screen('DrawLines', p.ptb.window, lineCoords,p.fix.lineWidthPix, p.ptb.black);% [p.ptb.xCenter p.ptb.yCenter], 2);
            % 5-3. present same diff text __________________________________________________
            textOld = 'old';
            textNew = 'new';
            textYc = p.ptb.yCenter + (RectHeight(p.ptb.rect)/2)*.30;
            %             textYc = p.ptb.yCenter + Yc + cDist*4;
            textRXc = p.ptb.xCenter + rXc; % p.ptb.xCenter+120,
            textLXc = p.ptb.xCenter - rXc; % p.ptb.xCenter-250-60,
            DrawFormattedText(p.ptb.window, textOld, textLXc,  textYc, cfg.text.whiteTextColor); % Text output of mouse position draw in the centre of the screen
            DrawFormattedText(p.ptb.window, textNew, textRXc,  textYc, cfg.text.whiteTextColor); % Text output of mouse position draw in the centre of the screen

            [VBLTimestamp StimulusOnsetTime FlipTimestamp] = Screen('Flip', p.ptb.window);
            T.RAW_event02_image_biopac(trl)        = biopac_linux_matlab(channel,  channel.image, 1);

            thisGetSecs = GetSecs;
            fprintf(logFile,'%f\t%s\t%s\t%s\t%s\t%s\n',...
                thisGetSecs, expParam.subject, sesName, 'TEST_STIM', 'image', stimList{trl});
            T.RAW_event02_image_onset(trl) = StimulusOnsetTime;
            T.event02_image_filename{trl} = stimList{trl};

        case('w') % show words
            currentWord = stimList{trl}(7:end-4);
            Screen('TextSize', p.ptb.window, cfg.text.basicTextSize);
            DrawFormattedText(p.ptb.window, currentWord, 'center', 'center', cfg.text.whiteTextColor);
            [VBLTimestamp StimulusOnsetTime FlipTimestamp] = Screen('Flip', p.ptb.window);
            T.RAW_event02_image_biopac(trl)        = biopac_linux_matlab(channel, channel.image, 1);

            thisGetSecs = GetSecs;
            fprintf(logFile,'%f\t%s\t%s\t%s\t%s\t%s\n',...
                thisGetSecs, expParam.subject, sesName, 'TEST_STIM', 'word', currentWord);
    end
    %% -----------------------------------------------------------------------------
    %                                  3. Keypress
    %-------------------------------------------------------------------------------

    keyCode = zeros(1,256);
    timeStim = GetSecs - thisGetSecs;
    %         while respToBeMade && timeStim < 2%sessionCfg.stim
    while KbCheck(-3); end

    if sessionCfg.answerFast
        while (GetSecs - StimulusOnsetTime) < task_duration
            answer = NaN; RT = NaN; actual_key = NaN; responsekeyname = 'NA'; secs = NaN;
            T.RAW_event03_response_onset(trl) = NaN;
            % check the keyboard
            %[keyIsDown,secs, keyCode] = KbCheck(-3);
            [~,~,buttonpressed] = GetMouse;
            resp_onset = GetSecs;
            FlushEvents('keyDown');
            %if keyIsDown
                % if keyCode(KbName(cfg.keys.oldKey))
            if buttonpressed(1)
                %keyCode(KbName('1!'))
                    %             respToBeMade = false;
                    answer = 1; actual_key = 1; responsekeyname = 'left';
                    T.RAW_event03_response_onset(trl) = resp_onset;
                    RT = resp_onset-StimulusOnsetTime;
                    biopac_linux_matlab(channel, channel.image, 0);
                    DrawFormattedText(p.ptb.window, textOld, textLXc,  textYc, cfg.text.experimenterColor); % Text output of mouse position draw in the centre of the screen
                    DrawFormattedText(p.ptb.window, textNew, textRXc,  textYc, cfg.text.whiteTextColor); % Text output of mouse position draw in the centre of the screen
                    Screen('DrawTexture', p.ptb.window, imageTexture, [],[],0);
                    Screen('Flip', p.ptb.window);
                    WaitSecs(0.5);
                    DrawFormattedText(p.ptb.window, cfg.text.fixSymbol, 'center', 'center', cfg.text.whiteTextColor);
                    Screen('Flip', p.ptb.window);
                    biopac_linux_matlab(channel, channel.remainder, 1);
                    WaitSecs('UntilTime', StimulusOnsetTime + task_duration);
            elseif buttonpressed(3)
                %keyCode(KbName('2@'))
                    answer = 0; actual_key = 2; responsekeyname = 'right';
                    T.RAW_event03_response_onset(trl) = resp_onset;
                    RT = resp_onset-StimulusOnsetTime;
                    biopac_linux_matlab(channel, channel.image, 0);
                    DrawFormattedText(p.ptb.window, textOld, textLXc,  textYc, cfg.text.whiteTextColor); % Text output of mouse position draw in the centre of the screen
                    DrawFormattedText(p.ptb.window, textNew, textRXc,  textYc, cfg.text.experimenterColor); % Text output of mouse position draw in the centre of the screen
                    Screen('DrawTexture', p.ptb.window, imageTexture, [],[],0);
                    Screen('Flip', p.ptb.window);
                    WaitSecs(0.5);
                    DrawFormattedText(p.ptb.window, cfg.text.fixSymbol, 'center', 'center', cfg.text.whiteTextColor);
                    Screen('Flip', p.ptb.window);
                    biopac_linux_matlab(channel, channel.remainder, 1);
                    WaitSecs('UntilTime', StimulusOnsetTime + task_duration);
                end
            %end
            %         timeStim = GetSecs - thisGetSecs;
            timeStim = GetSecs - StimulusOnsetTime;
        end
        biopac_linux_matlab(channel, channel.image, 0);
        biopac_linux_matlab(channel, channel.remainder, 0);
        switch cfg.stim.studyType
            case('i') % images
                clear stimImg
        end

    end
    thisGetSecs = GetSecs;
    fprintf(logFile,'%f\t%s\t%s\t%s\t%s\t%s\t%f\n',...
        thisGetSecs, expParam.subject, sesName, 'TEST_RESP', num2str(correctAnswer),num2str(answer),RT);

    T.param_answer(trl) = correctAnswer;
    T.event03_response_ptbkey(trl) = actual_key;
    T.event03_response_key(trl) = answer;
    T.event03_RT(trl) = RT;
    T.event03_response_keyname{trl} = responsekeyname;



    % isi
    %     Screen('FillRect', p.ptb.window, cfg.screen.bgColor);
    %     Screen('Flip', p.ptb.window);
    %     WaitSecs(sessionCfg.isi);
end
%% -----------------------------------------------------------------------------
%                                 4. remaining time
%-------------------------------------------------------------------------------

remaining_time = 120 - (GetSecs - T.RAW_param_experiment_start(1));
Screen('DrawLines', p.ptb.window, p.fix.allCoords, p.fix.lineWidthPix, cfg.text.whiteTextColor, [p.ptb.xCenter p.ptb.yCenter]);
T.RAW_event04_fixation_onset(:) = Screen('Flip', p.ptb.window);
T.RAW_event04_fixation_biopac(:) = biopac_linux_matlab(channel, channel.fixation, 1);
WaitSecs(remaining_time);
T.event04_fixation_duration(:) = remaining_time;
biopac_linux_matlab(channel, channel.fixation, 0);

T.param_end_instruct_onset(:) = GetSecs;
biopac_linux_matlab(channel, channel.test, 0);
T.param_experiment_duration(:) = T.param_end_instruct_onset(1)- T.RAW_param_experiment_start(1);
T.test_accuracy = T.param_answer == T.event03_response_key;
accuracy_freq =  sum(T.test_accuracy);

%% -----------------------------------------------------------------------------
%                               5. save parameter
%-------------------------------------------------------------------------------
T.param_experiment_start(:) = T.RAW_param_experiment_start - - studydetails.trigger_onset - studydetails.dummy;
T.event01_fixation_onset(:) = T.RAW_event01_fixation_onset(:) - studydetails.trigger_onset - studydetails.dummy;
T.event02_image_onset(:) = T.RAW_event01_fixation_onset(:) - studydetails.trigger_onset - studydetails.dummy;
T.event03_response_onset(:) = T.RAW_event01_fixation_onset(:) - studydetails.trigger_onset - studydetails.dummy;

saveFileName = fullfile(studydetails.sub_save_dir,[bids_string, '_beh.csv' ]);
repoFileName = fullfile(studydetails.repo_save_dir,[bids_string, '_beh.csv' ]);
writetable(T,saveFileName);
writetable(T,repoFileName);

if channel.biopac
for FIONUM = 1:7
    channel.d.setFIOState(pyargs('fioNum', int64(FIONUM), 'state', int64(0)));
end
end
% ------------------------------------------------------------------------------
%                                Function
% ------------------------------------------------------------------------------
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
                while KbCheck(-3); end
            end
        end
    end

end
