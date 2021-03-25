function mem_func_calculation(p, cfg,  sesName, studydetails, channel)

if channel.biopac
for FIONUM = 1:7
    channel.d.setFIOState(pyargs('fioNum', int64(FIONUM), 'state', int64(0)));
end
end

% bids_string ________________________________________________________
% example: sub-0001_ses-01_task-fractional_run-01-memory-test01
taskname = 'memory';
bids_string                     = [strcat('sub-', sprintf('%04d', studydetails.sub_num)), ...
strcat('_ses-',sprintf('%02d', studydetails.session_id)),...
strcat('_task-fractional'),...
strcat('_run-', sprintf('%02d', studydetails.run_order),'_', taskname, '_', sesName)];

task_num = str2double(regexp(sesName,'\d*','match'));


vnames = {'param_fmriSession',... %'param_counterbalanceVer','param_triggerOnset',...
    'calc_start', ...
    'p1_fixation_onset','p1_fixation_offset','p1_ptb_fixation_duration','p1_fixation_duration',...
    'p2_operation',...
    'p3_option',...
    'p4_responsekey','p4_responseRT','p4_responsekeyname','p4_correct_answer',...
    'p5_fixation_onset', 'p5_fixation_duration',...
    'calc_accuracy', 'calc_end', 'calc_duration'};

T                              = array2table(zeros(4,size(vnames,2)));
T.Properties.VariableNames     = vnames;
T.p4_responsekeyname           = cell(4,1);
T.param_fmriSession(:)         = studydetails.session_id;

calc_main                      = fullfile(studydetails.main_dir, 'instructions', 'memory_calc.png');

p.fix.sizePix                  = 40; % size of the arms of our fixation cross
p.fix.lineWidthPix             = 4; % Set the line width for our fixation cross
p.fix.xCoords                  = [-p.fix.sizePix p.fix.sizePix 0 0];
p.fix.yCoords                  = [0 0 -p.fix.sizePix p.fix.sizePix];
p.fix.allCoords                = [p.fix.xCoords; p.fix.yCoords];
Screen('BlendFunction', p.ptb.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % Set up alpha-blending for smooth (anti-aliased) lines
Screen('TextFont', p.ptb.window, 'Arial');
Screen('TextSize', p.ptb.window, 50);

fix_duration = 3;
task_duration = 5;

Yc = 300; % Y coord
cDist = 20; % vertical line depth
lXc = -200; % left X coord
rXc = 200; % right X coord

textYc = p.ptb.yCenter + (RectHeight(p.ptb.rect)/2)*.30;
textRXc = p.ptb.xCenter + rXc; % p.ptb.xCenter+120,
textLXc = p.ptb.xCenter - rXc; % p.ptb.xCenter-250-60,

s(1).operation = {'2 x 3 - 4 x 7 + 12',...
    '7 - 3 + 4 x 9 - 14',...
    '8 x 8 - 60 + 8 - 56',...
    ' 9 x 3 - 2 x 3 + 169'};
s(1).options_L = {'-2', '26','-34', '180'};
s(1).options_R = {'-10', '56', '-44', '190'};
s(1).correctanswer = [2,1,2,2];

s(2).operation = {'5 x 7 + 5 - 14 - 28', '120 - 5 x 3 + 3 x 8',...
    '5 x 6 - 3 x 7 + 23', '7 x 8 - 2 + 27 + 99'};
s(2).options_L = {'-2', '116','32', '179'};
s(2).options_R = {'0', '129','30', '180'};
s(2).correctanswer = [1,2,1,2];

%% -----------------------------------------------------------------------------
%                              Main task
% ______________________________________________________________________________

% ________________________ 1. instructions start ________________________________
main = Screen('MakeTexture',p.ptb.window, imread(calc_main));
Screen('DrawTexture',p.ptb.window,main,[],[]);
T.calc_start(:) = Screen('Flip',p.ptb.window);
biopac_linux_matlab( channel, channel.calc, 1);
WaitSecs(5); %4

% for loop
for trl = 1:4
    % ___________________________ 2. print fixation ________________________________
    Screen('DrawLines', p.ptb.window, p.fix.allCoords, p.fix.lineWidthPix, cfg.text.whiteTextColor, [p.ptb.xCenter p.ptb.yCenter]);
    T.p1_fixation_onset(trl) = Screen('Flip', p.ptb.window);
    biopac_linux_matlab( channel, channel.fixation, 1);
    WaitSecs(fix_duration);
    T.p1_fixation_offset(trl) = GetSecs;
      biopac_linux_matlab( channel, channel.fixation, 0);
    T.p1_ptb_fixation_duration(trl) = T.p1_fixation_offset(trl) - T.p1_fixation_onset(trl);
    T.p1_fixation_duration(trl) = 5;

    % ______________________________ 3. print text _________________________________
    DrawFormattedText(p.ptb.window, s(task_num).operation{trl}, 'center','center', cfg.text.whiteTextColor); % Text output of mouse position draw in the centre of the screen
    T.p2_operation(trl) = Screen('Flip',p.ptb.window);
    biopac_linux_matlab( channel, channel.math, 1);
    WaitSecs(20);
    biopac_linux_matlab( channel, channel.math, 0);

    % ____________________________ 4. print options ________________________________
    DrawFormattedText(p.ptb.window, s(task_num).operation{trl}, 'center','center', cfg.text.whiteTextColor); % Text output of mouse position draw in the centre of the screen
    DrawFormattedText(p.ptb.window, s(task_num).options_L{trl}, textLXc,  textYc, cfg.text.whiteTextColor); % Text output of mouse position draw in the centre of the screen
    DrawFormattedText(p.ptb.window, s(task_num).options_R{trl}, textRXc,  textYc, cfg.text.whiteTextColor); % Text output of mouse position draw in the centre of the screen
    [VBLTimestamp StimulusOnsetTime FlipTimestamp] = Screen('Flip',p.ptb.window);
    biopac_linux_matlab( channel, channel.math, 1);
    T.p3_option(trl) = StimulusOnsetTime;
    keyCode = zeros(1,256);

    while (GetSecs - StimulusOnsetTime) < task_duration
        % answer = NaN;
        RT = NaN;
        actual_key = NaN;
        responsekeyname = 'NaN';
        % check the keyboard
        %[keyIsDown,secs, keyCode] = KbCheck(-3);
        [~,~,buttonpressed] = GetMouse;
        resp_onset = GetSecs;
        FlushEvents('keyDown');
        %if keyIsDown
            if buttonpressed(1)
            % if keyCode(KbName('1!')) % left
                actual_key = 1;
                responsekeyname = 'left';
                RT = resp_onset-StimulusOnsetTime;
                biopac_linux_matlab( channel, channel.math, 0);
                DrawFormattedText(p.ptb.window, s(task_num).operation{trl}, 'center','center', cfg.text.whiteTextColor);
                DrawFormattedText(p.ptb.window, s(task_num).options_L{trl}, textLXc,  textYc, cfg.text.experimenterColor ); % Text output of mouse position draw in the centre of the screen
                DrawFormattedText(p.ptb.window, s(task_num).options_R{trl}, textRXc,  textYc, cfg.text.whiteTextColor); % Text output of mouse position draw in the centre of the screen
                Screen('Flip', p.ptb.window);

                WaitSecs(0.5);
                %remainder_time = task_duration-0.5-RT;
                % DrawFormattedText(p.ptb.window, cfg.text.fixSymbol, 'center', 'center', p.ptb.white);
                Screen('DrawLines', p.ptb.window, p.fix.allCoords, p.fix.lineWidthPix, cfg.text.whiteTextColor, [p.ptb.xCenter p.ptb.yCenter]);

                Screen('Flip', p.ptb.window);
                biopac_linux_matlab( channel, channel.remainder, 1);
                %WaitSecs(remainder_time);
            elseif buttonpressed(3)

                actual_key = 2;
                responsekeyname = 'right';
                RT = resp_onset-StimulusOnsetTime;
                biopac_linux_matlab( channel, channel.math, 0);
                DrawFormattedText(p.ptb.window, s(task_num).operation{trl}, 'center','center', cfg.text.whiteTextColor);
                DrawFormattedText(p.ptb.window, s(task_num).options_L{trl}, textLXc,  textYc, cfg.text.whiteTextColor); % Text output of mouse position draw in the centre of the screen
                DrawFormattedText(p.ptb.window, s(task_num).options_R{trl}, textRXc,  textYc, cfg.text.experimenterColor ); % Text output of mouse position draw in the centre of the screen
                Screen('Flip', p.ptb.window);

                WaitSecs(0.5);
                %remainder_time = task_duration-0.5-RT;
                % DrawFormattedText(p.ptb.window, cfg.text.fixSymbol, 'center', 'center', p.ptb.white);
                Screen('DrawLines', p.ptb.window, p.fix.allCoords, p.fix.lineWidthPix, cfg.text.whiteTextColor ,[p.ptb.xCenter p.ptb.yCenter]);

                Screen('Flip', p.ptb.window);
                biopac_linux_matlab( channel, channel.remainder, 1);
                %WaitSecs(remainder_time);
            end
        %end
        %         timeStim = GetSecs - thisGetSecs;
        timeStim = GetSecs - StimulusOnsetTime;
    end
    biopac_linux_matlab( channel, channel.math, 0);
    biopac_linux_matlab( channel, channel.remainder, 0);
    T.p4_responsekey(trl) = actual_key;
    T.p4_responseRT(trl) = RT;
    T.p4_responsekeyname{trl} = responsekeyname;
    T.p4_correct_answer(trl) = s(task_num).correctanswer(trl);



end
% ___________________________ 5. remainder fixation ____________________________
remaining_time = 120 - (GetSecs - T.calc_start(1));
Screen('DrawLines', p.ptb.window, p.fix.allCoords, p.fix.lineWidthPix, cfg.text.whiteTextColor, [p.ptb.xCenter p.ptb.yCenter]);
T.p5_fixation_onset(:) = Screen('Flip', p.ptb.window);
biopac_linux_matlab( channel, channel.remainder, 1);
WaitSecs(remaining_time);
T.p5_fixation_duration(:) = remaining_time;
biopac_linux_matlab( channel, channel.remainder, 0);

T.calc_end(:) = GetSecs;
biopac_linux_matlab( channel, channel.calc, 0);
T.calc_accuracy(trl) = T.p4_correct_answer(trl) == T.p4_responsekey(trl);
T.calc_duration(:) = T.calc_end(1)- T.calc_start(1);

if channel.biopac
for FIONUM = 1:7
    channel.d.setFIOState(pyargs('fioNum', int64(FIONUM), 'state', int64(0)));
end
end
%% __________________________ save parameter ___________________________________
sub_save_dir = cfg.files.sesSaveDir;
saveFileName = fullfile(sub_save_dir,[strcat('sub-', sprintf('%04d', studydetails.sub_num)), '_task-memory-distraction-',num2str(task_num), '_beh.csv' ]);
writetable(T,saveFileName);
end
