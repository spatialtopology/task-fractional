function PRACTICE_memory(sub_num)


% ------------------------------------------------------------------------------
%                                Parameters
% ------------------------------------------------------------------------------

global p
Screen('Preference', 'SkipSyncTests', 1);
HideCursor;
main_dir = pwd;
PsychDefaultSetup(2);
KbName('UnifyKeyNames');
screens                        = Screen('Screens');
p.ptb.screenNumber             = max(screens);
p.ptb.white                    = WhiteIndex(p.ptb.screenNumber); % Define black and white
p.ptb.black                    = BlackIndex(p.ptb.screenNumber);
p.ptb.gray                     = GrayIndex(p.ptb.screenNumber);
p.ptb.green                    = [0 1 0];
cfg.text.fixSymbol = '+';
% text colors
cfg.text.basicTextColor        = uint8((rgb('Black') * 255) + 0.5);
cfg.text.GreenTextColor        = uint8((rgb('Green') * 255) + 0.5);
cfg.text.whiteTextColor        = uint8((rgb('White') * 255) + 0.5);
cfg.text.instructColor         = uint8((rgb('Black') * 255) + 0.5);
cfg.screen.bgColor             = uint8((rgb('Grey') * 255) + 0.5);
cfg.screen.blackbgColor        = uint8((rgb('Black') * 255) + 0.5);
cfg.text.experimenterColor     = uint8((rgb('Lime') * 255) + 0.5);
[p.ptb.window, p.ptb.rect]     = PsychImaging('OpenWindow',p.ptb.screenNumber,p.ptb.gray );

[p.ptb.screenXpixels, p.ptb.screenYpixels] = Screen('WindowSize',p.ptb.window);
[p.ptb.xCenter, p.ptb.yCenter] = RectCenter(p.ptb.rect);
p.ptb.ifi                      = Screen('GetFlipInterval',p.ptb.window);
Screen('BlendFunction', p.ptb.window,'GL_SRC_ALPHA','GL_ONE_MINUS_SRC_ALPHA'); % Set up alpha-blending for smooth (anti-aliased) lines

Width = RectWidth(p.ptb.rect);
Height = RectHeight(p.ptb.rect);

Screen( p.ptb.window, 'TextFont', 'Helvetica');
Screen( p.ptb.window, 'TextSize', 30);

%% E. Keyboard information _____________________________________________________
KbName('UnifyKeyNames');
p.keys.confirm                 = KbName('return');
p.keys.right                   = KbName('2@');
p.keys.left                    = KbName('1!');
p.keys.space                   = KbName('space');
p.keys.esc                     = KbName('ESCAPE');
p.keys.trigger                 = KbName('5%');
p.keys.start                   = KbName('s');
p.keys.end                     = KbName('e');
p.fix.sizePix                  = 40; % size of the arms of our fixation cross
p.fix.lineWidthPix             = 4; % Set the line width for our fixation cross
p.fix.xCoords                  = [-p.fix.sizePix p.fix.sizePix 0 0];
p.fix.yCoords                  = [0 0 -p.fix.sizePix p.fix.sizePix];
p.fix.allCoords                = [p.fix.xCoords; p.fix.yCoords];

% % position of old and new key __________________________________________________
% Yc = 300; % Y coord
% cDist = 20; % vertical line depth
% lXc = -200; % left X coord
% rXc = 200; % right X coord
% lineCoords = [lXc lXc lXc rXc rXc rXc; Yc-cDist Yc+cDist Yc Yc Yc-cDist Yc+cDist];
% %             Screen('DrawLines', p.ptb.window, lineCoords,p.fix.lineWidthPix, p.ptb.black);% [p.ptb.xCenter p.ptb.yCenter], 2);
%
% % 5-3. present same diff text __________________________________________________
% textOld = 'old';
% textNew = 'new';
% textYc = p.ptb.yCenter + (RectHeight(p.ptb.rect)/2)*.30;
% textRXc = p.ptb.xCenter + rXc; % p.ptb.xCenter+120,
% textLXc = p.ptb.xCenter - rXc; % p.ptb.xCenter-250-60,

% ------------------------------------------------------------------------------
%                           1. Practice instructions
% ------------------------------------------------------------------------------
practice_path                  = fullfile(main_dir, 'practice', 'introduction');
filelength = numel(dir([practice_path '/*.png']));
for int = 1:filelength
    intro_name                   = ['memory_practice_slides.0', sprintf('%02d',int),'.png'];
    intro_filename               = fullfile(practice_path, intro_name);

    Screen('TextSize',p.ptb.window,72);
    start.texture = Screen('MakeTexture',p.ptb.window, imread(intro_filename));
    Screen('DrawTexture',p.ptb.window,start.texture,[],[]);
    Screen('Flip',p.ptb.window);
    WaitSecs(0.2);
    KbWait();

end

WaitSecs(0.2);
KbWait();

% ------------------------------------------------------------------------------
%                          2. Memory main instructions
% ------------------------------------------------------------------------------
% 2-1. ready for filepath ______________________________________________________
taskname = 'memory';
instruct_filepath              = fullfile(main_dir,  'instructions');
instruct_start_name            = 'memory_main_start.png';
instruct_end_name              = 'memory_main_end.png'                     ;
instruct_start                 = fullfile(instruct_filepath, instruct_start_name);
instruct_end                   = fullfile(instruct_filepath, instruct_end_name);

% 2-2. show image ______________________________________________________________
Screen('TextSize',p.ptb.window,72);
start.texture = Screen('MakeTexture',p.ptb.window, imread(instruct_start));
Screen('DrawTexture',p.ptb.window,start.texture,[],[]);
Screen('Flip',p.ptb.window);
WaitSecs(0.2);
KbWait();


% ------------------------------------------------------------------------------
%                           3. memory study
% ------------------------------------------------------------------------------
% 3-1. study instruction _______________________________________________________
taskname = 'memory';
instruct_filepath              = fullfile(main_dir,  'instructions');
instruct_study                 = fullfile(instruct_filepath, 'memory_study.png');
Screen('TextSize',p.ptb.window,72);
start.texture = Screen('MakeTexture',p.ptb.window, imread(instruct_study));
Screen('DrawTexture',p.ptb.window,start.texture,[],[]);
Screen('Flip',p.ptb.window);
WaitSecs(5);

% 3-2. present study image _____________________________________________________
study_list = [1, 3, 5, 7, 8];
image_path                     = fullfile(main_dir, 'practice', 'study_items');
for i = 1:length(study_list)
    % study_list(i)
    intro_name                   = ['memory_image_', sprintf('%02d',study_list(i)),'.png'];
    study_filename               = fullfile(image_path, intro_name);

    start.texture = Screen('MakeTexture',p.ptb.window, imread(study_filename));
    Screen('DrawTexture',p.ptb.window,start.texture);
    Screen('Flip',p.ptb.window);

    WaitSecs(1);
end


% ------------------------------------------------------------------------------
%                           4. memory test
% ------------------------------------------------------------------------------
% 4-1. test instruction ________________________________________________________
taskname = 'memory';
instruct_filepath              = fullfile(main_dir,  'instructions');
instruct_study                 = fullfile(instruct_filepath, 'memory_test.png');
Screen('TextSize',p.ptb.window,72);
start.texture = Screen('MakeTexture',p.ptb.window, imread(instruct_study));
Screen('DrawTexture',p.ptb.window,start.texture);
Screen('Flip',p.ptb.window);
WaitSecs(2);

% 4-2. present 10 images with old, new _________________________________________
task_duration = 3;
image_path                     = fullfile(main_dir, 'practice', 'study_items');
test_list = [9,6,7,3,2,1,4,5,8,10];
correct_answer = [0,0,1,1,0,1,0,1,1,0];
p3_correct_response = [];
p3_actual_buttonbox = [];
p3_responsekey =[];

for i = 1:length(test_list)
    test_name                   = ['memory_image_', sprintf('%02d',test_list(i)),'.png'];
    test_filename               = fullfile(image_path, test_name);

    Screen('TextSize',p.ptb.window,36);
    imageTexture = Screen('MakeTexture',p.ptb.window, imread(test_filename));
    Screen('DrawTexture',p.ptb.window,imageTexture,[],[]);
    % 5-2. present scale lines _____________________________________________________
    Yc = 300; % Y coord
    cDist = 20; % vertical line depth
    lXc = -200; % left X coord
    rXc = 200; % right X coord
    lineCoords = [lXc lXc lXc rXc rXc rXc; Yc-cDist Yc+cDist Yc Yc Yc-cDist Yc+cDist];
    % 5-3. present same diff text __________________________________________________
    textOld = 'old';
    textNew = 'new';
    textYc = p.ptb.yCenter + (RectHeight(p.ptb.rect)/2)*.30;
    textRXc = p.ptb.xCenter + rXc; % p.ptb.xCenter+120,
    textLXc = p.ptb.xCenter - rXc; % p.ptb.xCenter-250-60,
    DrawFormattedText(p.ptb.window, textOld, textLXc,  textYc, cfg.text.basicTextColor); % Text output of mouse position draw in the centre of the screen
    DrawFormattedText(p.ptb.window, textNew, textRXc,  textYc, cfg.text.basicTextColor); % Text output of mouse position draw in the centre of the screen

    [VBLTimestamp StimulusOnsetTime FlipTimestamp] = Screen('Flip',p.ptb.window);

    keyCode = zeros(1,256);

    while (GetSecs - StimulusOnsetTime) < task_duration
        answer = 99;
        RT = 99;
        actual_key = 99;
        % check the keyboard
        [keyIsDown,secs, keyCode] = KbCheck(-3);

        if keyIsDown
            if keyCode(KbName('f')) % old
                answer = 1;
                actual_key = 1;
                RT = secs-StimulusOnsetTime;
                imageTexture = Screen('MakeTexture',p.ptb.window, imread(test_filename));
                Screen('DrawTexture',p.ptb.window,imageTexture,[],[]);
                DrawFormattedText(p.ptb.window, textOld, textLXc,  textYc, p.ptb.green ); % Text output of mouse position draw in the centre of the screen
                DrawFormattedText(p.ptb.window, textNew, textRXc,  textYc, cfg.text.basicTextColor); % Text output of mouse position draw in the centre of the screen

                Screen('Flip', p.ptb.window);
                WaitSecs(0.5);
                remainder_time = task_duration-0.5-RT;
                DrawFormattedText(p.ptb.window, cfg.text.fixSymbol, 'center', 'center', cfg.text.basicTextColor);
                Screen('Flip', p.ptb.window);
                WaitSecs(remainder_time);
            elseif keyCode(KbName('j')) % new
                answer = 0;
                actual_key = 4;
                RT = secs-StimulusOnsetTime;
                imageTexture = Screen('MakeTexture',p.ptb.window, imread(test_filename));
                Screen('DrawTexture',p.ptb.window,imageTexture,[],[]);
                DrawFormattedText(p.ptb.window, textOld, textLXc,  textYc, cfg.text.basicTextColor); % Text output of mouse position draw in the centre of the screen
                DrawFormattedText(p.ptb.window, textNew, textRXc,  textYc, p.ptb.green ); % Text output of mouse position draw in the centre of the screen

                Screen('Flip', p.ptb.window);
                WaitSecs(0.5);
                remainder_time = task_duration-0.5-RT;
                DrawFormattedText(p.ptb.window, cfg.text.fixSymbol, 'center', 'center', cfg.text.basicTextColor);
                Screen('Flip', p.ptb.window);
                WaitSecs(remainder_time);
            end
        end
        timeStim = GetSecs - StimulusOnsetTime;
    end
    p3_correct_response(i) = correct_answer(i);
    p3_actual_buttonbox(i) = actual_key;
    p3_responsekey(i) = answer;

end

% ------------------------------------------------------------------------------
%                           5. calculated accuracy
% ------------------------------------------------------------------------------
test_accuracy = p3_correct_response == p3_responsekey;
total_acc = sum(test_accuracy);

line1 = '*********************************\n*********************************\n\nThis is the end of the memory task.';
line2 = strcat('\nThe total accuracy was - ', num2str(total_acc), ' - out of 10.');
line3 = strcat('\nPlease pay - ', num2str(total_acc*2), ' - dollars.\nThank you !!\n');
line4 = ('\n*********************************\n*********************************\n');
lineend = ('\n\n\nPress Space to move on');

DrawFormattedText(p.ptb.window, [line1 line2 line3 line4 lineend], 'center','center', cfg.text.basicTextColor); % Text output of mouse position draw in the centre of the screen
Screen('Flip',p.ptb.window);
KbWait();

% ------------------------------------------------------------------------------
%                           6. end instructions
% ------------------------------------------------------------------------------
end_texture = Screen('MakeTexture',p.ptb.window, imread(instruct_end));
Screen('DrawTexture',p.ptb.window,end_texture,[],[]);
Screen('Flip',p.ptb.window);
WaitSecs(0.2);
KbWait();


sca;

% ------------------------------------------------------------------------------
%                           function:
% ------------------------------------------------------------------------------
function WaitKeyPress(kID)
    while KbCheck(-3); end
    while 1
        [keyIsDown, ~, keyCode ] = KbCheck(-3);
        if keyIsDown
            if keyCode(p.keys.esc)
                cleanup; break;
            elseif keyCode(kID)
                break;
            end
            while KbCheck(-3); end
        end
    end
end

end
