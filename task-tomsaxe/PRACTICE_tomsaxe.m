function PRACTICE_tomsaxe(sub_num)
run_num=1;

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
[p.ptb.window, p.ptb.rect]     = PsychImaging('OpenWindow',p.ptb.screenNumber,p.ptb.gray );
[p.ptb.screenXpixels, p.ptb.screenYpixels] = Screen('WindowSize',p.ptb.window);
[p.ptb.xCenter, p.ptb.yCenter] = RectCenter(p.ptb.rect);
p.ptb.ifi                      = Screen('GetFlipInterval',p.ptb.window);
Screen('BlendFunction', p.ptb.window,'GL_SRC_ALPHA','GL_ONE_MINUS_SRC_ALPHA'); % Set up alpha-blending for smooth (anti-aliased) lines
Width = RectWidth(p.ptb.rect);
Height = RectHeight(p.ptb.rect);


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
Screen( 'Preference', 'SkipSyncTests', 0);
Screen( p.ptb.window, 'TextFont', 'Helvetica');
Screen( p.ptb.window, 'TextSize', 30);
tomsaxe_dir			= pwd;
textdir				= fullfile(tomsaxe_dir, 'practice', 'practice_text');


% A. practice __________________________________________________________________
design				                     = [ 1 2 ]; % changed by FRACTIONAL
conds				                       = {'belief','photo'};
condPrefs			                     = {'b','p'};								% stimuli textfile prefixes, used in loading stimuli content
fixDur				                     = 12;	%12									% fixation duration
storyDur		                       = 11;	%10									% story duration
questDur			                     = 6.5;	%4									% probe duration
trialsPerRun		                   = length(design);
key					                       = zeros(trialsPerRun,1);
RT					                       = key;
items				                       = key;
trialsOnsets                       = key;                                      % trial onsets in seconds
endDur                             = 3;
ips					                       = ((trialsPerRun) * (fixDur + storyDur + questDur) + (endDur))/0.46;
trial_type                         = {'false_belief', 'false_photo'};
taskname                           = 'tomsaxe';
TR                                 = 0.46;


% A. practice __________________________________________________________________

practice_path                  = fullfile(main_dir, 'practice', 'introduction');
filelength = numel(dir([practice_path '/*.png']));
for int = 1:filelength
    intro_name                   = ['saxe_practice_slides.0', sprintf('%02d',int),'.png'];
    intro_filename               = fullfile(practice_path, intro_name);

    Screen('TextSize',p.ptb.window,72);
    start.texture = Screen('MakeTexture',p.ptb.window, imread(intro_filename));
    Screen('DrawTexture',p.ptb.window,start.texture,[],[]);
    Screen('Flip',p.ptb.window);
    WaitSecs(0.2);
    KbWait();

end


%% ______________________________ Instructions _________________________________
%% G. instructions _____________________________________________________
instruct_filepath                  = fullfile(tomsaxe_dir,  'instructions');
instruct_start_name                = ['task-', taskname, '_start.png'];
instruct_end_name                  = ['task-', taskname, '_end.png'];
instruct_start                     = fullfile(instruct_filepath, instruct_start_name);
instruct_end                       = fullfile(instruct_filepath, instruct_end_name);

Screen('TextSize',p.ptb.window,72);
start.texture = Screen('MakeTexture',p.ptb.window, imread(instruct_start)); % start image
Screen('DrawTexture',p.ptb.window,start.texture,[],[]);
Screen(p.ptb.window, 'Flip');

WaitKeyPress(p.keys.start)
Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
    p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2); % will flip immediately
Screen('Flip', p.ptb.window);
WaitKeyPress(p.keys.trigger);

WaitSecs(TR*6);

counter				    = zeros(1,2)+(5*(run_num-1));

Screen(p.ptb.window, 'TextSize', 24);
% try
    for trial = 1:trialsPerRun
        cd(textdir);
        trialStart		= GetSecs;
        empty_text		= ' ';

        Screen(p.ptb.window, 'DrawText', empty_text,p.ptb.xCenter,p.ptb.yCenter);
        Screen(p.ptb.window, 'Flip');
        counter(1,design(trial)) = counter(1,design(trial)) + 1;

        %%%%%%%%% Determine stimuli filenames %%%%%%%%%
        trialT			= design(trial);							% trial type. 1 = false belief, 2 = false photograph
        numbeT			= counter(1,trialT);						% the number of the stimuli
        % numbeT      = random(trial);
        storyname		= fullfile(textdir, sprintf('%d%s_story.txt',numbeT,condPrefs{trialT}));
        questname		= fullfile(textdir, sprintf('%d%s_question.txt',numbeT,condPrefs{trialT}));
        items(trial,1)	= numbeT;
        % T.p2_filename{trial} = {sprintf('%d%s_story.txt',numbeT,condPrefs{trialT})};
        % T.p2_filetype{trial} = trial_type{trialT};
        %%%%%%%%% Open Story %%%%%%%%%
        textfid			= fopen(storyname, 'r');
        lCounter		= 1;										% line counter

        while GetSecs - trialStart < fixDur
            Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
                p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
            Screen('Flip', p.ptb.window);
        end					% wait for fixation period to elapse

        %%%%%%%%% Display Story %%%%%%%%%
        while 1
            tline		= fgetl(textfid);							% read line from text file.
            if ~ischar(tline), break, end
            Screen(p.ptb.window, 'DrawText',tline,p.ptb.xCenter-380,p.ptb.yCenter-160+lCounter*45,[255]);
            lCounter	= lCounter + 1;
        end
        fclose(textfid);

        Screen(p.ptb.window, 'Flip');

%         trialsOnsets(trial) = GetSecs-experimentStart;
        %%%%%%%%% Open Question %%%%%%%%%
        textfid			= fopen(questname);
        lCounter		= 1;
        while 1
            tline		= fgetl(textfid);							% read line from text file.
            if ~ischar(tline), break, end
            Screen(p.ptb.window, 'DrawText',tline,p.ptb.xCenter-380,p.ptb.yCenter-160+lCounter*45,[255]);
            lCounter	= lCounter + 1;
        end

        while GetSecs - trialStart < fixDur + storyDur; end			% wait for story presentation period

        %%%%%%%%% Display Question %%%%%%%%%
        p3_ques_onset(trial) = Screen(p.ptb.window, 'Flip');

        responseStart	= GetSecs;

        %%%%%%%%% Collect Response %%%%%%%%%
        % while ( GetSecs - responseStart ) < questDur
        while ( GetSecs - p3_ques_onset(trial) ) < questDur
            [keyIsDown,secs,keyCode]	= KbCheck;					% check to see if a key is being pressed
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %--------------------------SEE NOTE 2-----------------------------%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %             button						= intersect([89:92], find(keyCode));
            %             if(RT(trial,1) == 0) && keyIsDown == 1%~isempty(button)
            %                 RT(trial,1)				= GetSecs - responseStart;
            %                 key(trial,1)			= str2num(KbName(keyCode));
            if keyCode(p.keys.esc)
                ShowCursor;
                sca;
                return
            elseif keyCode(p.keys.right)
                RT(trial,1)				= GetSecs - p3_ques_onset(trial); %responseStart;
                key(trial,1)    	= 4;
                % T.p4_responseonset(trial) = secs;
                % T.p4_responsekey(trial)    = 4;
                % T.p4_RT(trial)    = RT(trial,1);
            elseif keyCode(p.keys.left)
                RT(trial,1)				= GetSecs - p3_ques_onset(trial); %responseStart;
                key(trial,1)			= 1;
                % T.p4_responseonset(trial) = secs;
                % T.p4_responsekey(trial) = 1;
                % T.p4_RT(trial)    = RT(trial,1);

            end
        end

        %%%%%%%%% Save information in the event of a crash %%%%%%%%%
%         cd(behavdir);
        % save_filename = [strcat('sub-', sprintf('%04d', sub_num)), '_ses-04_task-tomsaxe.mat'];
        % save_fullfile = fullfile(sub_save_dir, save_filename);
        % save(save_fullfile,'sub_num','run_num','design','items','key','RT','trialsOnsets');
    end
% catch exception
%     ShowCursor;
%     sca
%     warndlg(sprintf('The experiment has encountered the following error during the main experimental loop: %s',exception.message),'Error');
%     return
% end

%% Final fixation, save information
trials_end			= GetSecs;
% while GetSecs - trials_end < endDur;
  Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
      p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
Screen('Flip', p.ptb.window);

WaitSecs(endDur);
%% _________________________ End Instructions _____________________________
end_texture = Screen('MakeTexture',p.ptb.window, imread(instruct_end));
Screen('DrawTexture',p.ptb.window,end_texture,[],[]);
param_end_instruct_onset(:) = Screen('Flip',p.ptb.window);
% KbTriggerWait(p.keys.end);
WaitKeyPress(p.keys.end);

% T.experimentDuration(:) = T.param_end_instruct_onset(1) - T.param_triggerOnset(1);
% while GetSecs - trials_end < fixDur; end

experimentEnd		= GetSecs;
% experimentDuration	= experimentEnd - experimentStart;
numconds			= 2;

%% __________________________ save parameter ___________________________________
% saveFileName = fullfile(sub_save_dir,[strcat('sub-', sprintf('%04d', sub_num)), '_task-',taskname,'_beh.csv' ]);
% writetable(T,saveFileName);

try
    sca
%     responses = sortrows([design' items key RT]);

%     save(save_fullfile,'sub_num','run_num','design','items','key','RT','trialsOnsets','responses','experimentStart','experimentEnd','experimentDuration','ips');
    ShowCursor;
%     cd(orig_dir);
catch exception
    sca
    ShowCursor;
%     warndlg(sprintf('The experiment has encountered the following error while saving the behavioral data: %s',exception.message),'Error');
    cd(orig_dir);
end					% end main function


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
