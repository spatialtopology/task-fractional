function [cfg,expParam, accuracy_freq] = mem_func_test(p,cfg,expParam,logFile,sesName,sub_num,biopac,channel)
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

% biopac reset
for FIONUM = 1:7
    channel.d.setFIOState(pyargs('fioNum', int64(FIONUM), 'state', int64(0)));
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

% D. making output table ________________________________________________________
vnames = {'param_fmriSession','param_experiment_start','param_memory_session_name'...
    'event01_fixation_onset','event01_fixation_biopac', 'event01_fixation_duration',...
    'event02_image_onset','event02_image_filename',...
    'p3_correct_response','p3_actual_buttonbox','p3_responsekey','p3_responsekeyname',...
    'p3_actual_responseonset','p3_actual_RT',...
    'event04_fixation_onset','event04_fixation_duration','event04_fixation_biopac'...
    'param_end_instruct_onset', 'param_experimentDuration', 'test_accuracy'};
T                              = array2table(zeros(size(stimList,1),size(vnames,2)));
T.Properties.VariableNames     = vnames;
T.event02_image_filename            = cell(size(stimList,1),1);
T.param_memory_session_name    = cell(size(stimList,1),1);
T.p3_responsekeyname           = cell(size(stimList,1),1);

T.param_memory_session_name(:) = {sesName};
T.param_fmriSession(:)         = 4;
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

% ______________________________ Instructions _________________________________
Screen('TextSize',p.ptb.window,72);
start.texture = Screen('MakeTexture',p.ptb.window, imread(instruct_test));
Screen('DrawTexture',p.ptb.window,start.texture,[],[]);
T.param_experiment_start(:) = Screen('Flip', p.ptb.window);
T.param_test_biopac(:)                   = biopac_linux_matlab(biopac,channel, channel.test, 1);
WaitSecs(5);

% DisableKeysForKbCheck([]);
KbName('UnifyKeyNames');
thisGetSecs = GetSecs;
fprintf(logFile,'%f\t%s\t%s\t%s\n',...
    T.param_experiment_start(1),...
    expParam.subject,...
    sesName,...
    'TEST_START');

%     thisGetSecs,...
% ___________________________ 0. Experimental loop ____________________________
% display stimuli
for trl = 1 : length(stimList)
    correctAnswer = oldNew(trl);
    if sessionCfg.isFix

        % _________________________ 1. Fixtion Jitter mean 1 sec _______________________

        Screen('TextSize', p.ptb.window, cfg.text.basicTextSize);
        DrawFormattedText(p.ptb.window, cfg.text.fixSymbol, 'center', 'center', cfg.text.whiteTextColor);
        T.event01_fixation_onset(trl) = Screen('Flip', p.ptb.window);
        T.event01_fixation_biopac(:)                   = biopac_linux_matlab(biopac, channel, channel.fixation, 1);
        timeFix = sessionCfg.preStim(1) + ((sessionCfg.preStim(2) - sessionCfg.preStim(1)).*rand(1,1));
        T.event01_fixation_duration(trl) = timeFix;
        WaitSecs(timeFix);
        biopac_linux_matlab(biopac, channel, channel.fixation, 0);
    end
    switch cfg.stim.studyType
        case('i') % show images
            stimImgFile = fullfile(stimDir,stimList{trl});
            stimImgFile(stimImgFile=='\') = '/';
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
            T.event02_image_biopac(trl)        = biopac_linux_matlab(biopac,channel,  channel.image, 1);


            thisGetSecs = GetSecs;
            fprintf(logFile,'%f\t%s\t%s\t%s\t%s\t%s\n',...
                thisGetSecs,...
                expParam.subject,...
                sesName,...
                'TEST_STIM',...
                'image',...
                stimList{trl});
            T.event02_image_onset(trl) = StimulusOnsetTime;
            T.event02_image_filename{trl} = stimList{trl};

        case('w') % show words
            currentWord = stimList{trl}(7:end-4);
            Screen('TextSize', p.ptb.window, cfg.text.basicTextSize);
            DrawFormattedText(p.ptb.window, currentWord, 'center', 'center', cfg.text.whiteTextColor);
            [VBLTimestamp StimulusOnsetTime FlipTimestamp] = Screen('Flip', p.ptb.window);
            T.event02_image_biopac(trl)        = biopac_linux_matlab(biopac, channel, channel.image, 1);

            thisGetSecs = GetSecs;
            fprintf(logFile,'%f\t%s\t%s\t%s\t%s\t%s\n',...
                thisGetSecs,...
                expParam.subject,...
                sesName,...
                'TEST_STIM',...
                'word',...
                currentWord);
    end
    %     if sessionCfg.answerFast % get the answer as fast as possible
    % Wait for answer
    %     respToBeMade = true;
    keyCode = zeros(1,256);
    timeStim = GetSecs - thisGetSecs;
    %         while respToBeMade && timeStim < 2%sessionCfg.stim
    while KbCheck(-3); end
    if sessionCfg.answerFast
        while (GetSecs - StimulusOnsetTime) < task_duration
            answer = 99;
            RT = 99;
            actual_key = 99;
            responsekeyname = 'nan';
            secs = 99;
            % check the keyboard
            [keyIsDown,secs, keyCode] = KbCheck(-3);
            FlushEvents('keyDown');
            if keyIsDown
                % if keyCode(KbName(cfg.keys.oldKey))
                if keyCode(KbName('1!'))
                    %             respToBeMade = false;
                    answer = 1;
                    actual_key = 1;
                    responsekeyname = 'left';
                    RT = secs-StimulusOnsetTime;
                    biopac_linux_matlab(biopac, channel, channel.image, 0);
                    DrawFormattedText(p.ptb.window, textOld, textLXc,  textYc, cfg.text.experimenterColor); % Text output of mouse position draw in the centre of the screen
                    DrawFormattedText(p.ptb.window, textNew, textRXc,  textYc, cfg.text.whiteTextColor); % Text output of mouse position draw in the centre of the screen
                    Screen('DrawTexture', p.ptb.window, imageTexture, [],[],0);
                    Screen('Flip', p.ptb.window);
                    WaitSecs(0.5);
                    %remainder_time = task_duration-0.5-RT;
                    DrawFormattedText(p.ptb.window, cfg.text.fixSymbol, 'center', 'center', cfg.text.whiteTextColor);
                    Screen('Flip', p.ptb.window);
                    biopac_linux_matlab(biopac, channel, channel.remainder, 1);
                    %WaitSecs(remainder_time);
                    % elseif keyCode(KbName(cfg.keys.newKey))
                elseif keyCode(KbName('2@'))
                    %             respToBeMade = false;
                    answer = 0;
                    actual_key = 2;
                    responsekeyname = 'right';
                    RT = secs-StimulusOnsetTime;
                    biopac_linux_matlab(biopac, channel, channel.image, 0);
                    DrawFormattedText(p.ptb.window, textOld, textLXc,  textYc, cfg.text.whiteTextColor); % Text output of mouse position draw in the centre of the screen
                    DrawFormattedText(p.ptb.window, textNew, textRXc,  textYc, cfg.text.experimenterColor); % Text output of mouse position draw in the centre of the screen
                    Screen('DrawTexture', p.ptb.window, imageTexture, [],[],0);
                    Screen('Flip', p.ptb.window);
                    WaitSecs(0.5);
                    %remainder_time = task_duration-0.5-RT;
                    DrawFormattedText(p.ptb.window, cfg.text.fixSymbol, 'center', 'center', cfg.text.whiteTextColor);
                    Screen('Flip', p.ptb.window);
                    biopac_linux_matlab(biopac, channel, channel.remainder, 1);
                    %WaitSecs(remainder_time);
                end
            end
            %         timeStim = GetSecs - thisGetSecs;
            timeStim = GetSecs - StimulusOnsetTime;
        end
        biopac_linux_matlab(biopac, channel, channel.image, 0);
        biopac_linux_matlab(biopac, channel, channel.remainder, 0);
        switch cfg.stim.studyType
            case('i') % images
                %                 Screen('Close', imageTexture);
                clear stimImg
        end

    end
    thisGetSecs = GetSecs;
    fprintf(logFile,'%f\t%s\t%s\t%s\t%s\t%s\t%f\n',...
        thisGetSecs,...
        expParam.subject,...
        sesName,...
        'TEST_RESP',...
        num2str(correctAnswer),num2str(answer),RT);

    T.p3_correct_response(trl) = correctAnswer;
    T.p3_actual_buttonbox(trl) = actual_key;
    T.p3_responsekey(trl) = answer;
    T.p3_actual_RT(trl) = RT;
    T.p3_responsekeyname{trl} = responsekeyname;
    T.p3_actual_responseonset(trl) = secs;


    % isi
    %     Screen('FillRect', p.ptb.window, cfg.screen.bgColor);
    %     Screen('Flip', p.ptb.window);
    %     WaitSecs(sessionCfg.isi);
end

remaining_time = 120 - (GetSecs - T.param_experiment_start(1));
Screen('DrawLines', p.ptb.window, p.fix.allCoords, p.fix.lineWidthPix, cfg.text.whiteTextColor, [p.ptb.xCenter p.ptb.yCenter]);
T.event04_fixation_onset(:) = Screen('Flip', p.ptb.window);
T.event04_fixation_biopac(:) = biopac_linux_matlab(biopac, channel, channel.fixation, 1);
WaitSecs(remaining_time);
T.event04_fixation_duration(:) = remaining_time;
biopac_linux_matlab(biopac, channel, channel.remainder, 1);


T.param_end_instruct_onset(:) = GetSecs;
biopac_linux_matlab(biopac, channel, channel.test, 0);
T.param_experimentDuration(:) = T.param_end_instruct_onset(1)- T.param_experiment_start(1);
T.test_accuracy = T.p3_correct_response == T.p3_responsekey;
accuracy_freq =  sum(T.test_accuracy);
% __________________________ save parameter ____________________________________
sub_save_dir = cfg.files.sesSaveDir;
saveFileName = fullfile(sub_save_dir,[strcat('sub-', sprintf('%04d', sub_num)), '_task-memory-',sesName, '_beh.csv' ]);
writetable(T,saveFileName);
for FIONUM = 1:7
    channel.d.setFIOState(pyargs('fioNum', int64(FIONUM), 'state', int64(0)));
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
