function tom_localizer(sub_num)
run_num=1;
%% Version: September 7, 2011
% updated by Heejung Jung
% Date: Jan 28, 2020
%__________________________________________________________________________
%
% This script will localize theory-of-mind network areas by contrasting
% activation during false-belief tasks, in which characters have incorrect
% beliefs about the state of the world, and false-photograph tasks, in
% which a photograph depicts a world state that is no longer the case.
%
% There are blocks of false belief stories, in which a story is told
% involving a false belief, which is presented for 10 seconds, then a
% probe question about the story presented for 4 seconds. In
% between each block, there is a fixation period of 12 seconds.
%
% To run_num this script, you need Matlab and the PsychToolbox, which is available
% as a free download.
%
%__________________________________________________________________________
%
%							INPUTS
%
% - sub_num: STRING The string you wish to use to identify the participant.
%			"PI name"_"study name"_"participant number" is a common
%			convention. This will be the name used to save the files.
% - run_num   : NUMBER The current run_num number. (e.g., 1)
%
% Example usage:
%					tom_localizer("SAX_TOM_01",1)
%
%__________________________________________________________________________
%
%							OUTPUTS
%	The script outputs a behavioural file into the behavioural directory.
%	This contains information about the IPS of the scan, when stories were
%	presented, reaction time, and response info. It also contains
%	information necessary to perform the analysis with SPM. The file is
%	saved as subjectID.tom_localizer.run_num#.m
%
%	In the event of a crash, the script creates a running behavioural file
%	of partial data after each trial.
%__________________________________________________________________________
%
%						  CONDITIONS
%
%				1 - Belief (stimuli  1b to 10b)
%				2 - Photo  (stimuli  1p to 10p)
%
%__________________________________________________________________________
%
%							TIMING
%
% The run length can be calculated according to the following:
%
% (trials per run)*(fixation duration + story duration)+(fixation duration)
%
% The phrases used above are related to the variable values according to
% the following:
%
% trials per run = trialsPerRun
% fixation duration = fixDur
% story duration = storyDur
%
% The default configuration is:
%
% (10 trials per run) * (12 sec fixation + 14 sec story) + (12 sec
% fixation) =
%
% 10 * (12 + 14) + 12 = 272 seconds, 136 ips (given 2 sec TR)
%__________________________________________________________________________
%
%							NOTES
%
%	Note 1
%		Make sure to change the inputs in the 'Variables unique to scanner/
%		computer' section of the script.
%
%	Note 2
%		The use of intersect(89:92, find(keyCode)) determines if the
%		keystroke found by KbCheck is one of the proper response set. Of
%		course, these intersection values are a consequence of the workings
%		of our MRI response button. Your response button may differ.
%		Use KbCheck() to determine which button pushes from the response box
%		correspond to numbers 1:4. Otherwise, you may not retain any
%		behavioural data.
%
%	Note 3
%		For simplicity, we have set up the experiment so that the order of
%		items and conditions is identical for every subject - they see
%		design 1 in run 1, with stimuli 1 - 5 form each condition, in that
%		order. In our own research, we typically counterbalance the order
%		of items within a run, and the order of designs across runs, across
%		subjects (so half of our participants see design 1 in run 2). If
%		you are comfortable enough with matlab, we encourage you to add
%		this counterbalancing back into the experiment - and make sure to
%		save separate variables for each subject tracking the order of
%		items and conditions across runs.
%__________________________________________________________________________
%
%					ADVICE FOR ANALYSIS
%	We analyze this experiment by modelling each trial as a block with a
%	boxcar lasting 14 seconds, during the whole period from the initial
%	presentation of the story to the end of the question presentation.
%	These boxcars are flanked by non-jittered rest periods of 12 seconds
%	each (the fixation duration in the script). While we have analyzed the
%	statement and question periods separately, we have found that the
%	outcomes are nearly identical, due to the BOLD signal being
%	predominantly due to participants reading and encoding the text,
%	rather than answering the questions.
%
%	Analysis consists of five primary steps:
%		1. Motion correction by rigid rotation and translation about the 6
%		   orthogonal axes of motion.
%		2. (optional) Normalization to the SPM template.
%		3. Smoothing, FWHM, 5 mm smoothing kernel if normalization has been
%		   performed, 8 mm otherwise.
%		4. Modeling
%				- Each condition in each run gets a parameter, a boxcar
%				  plot convolved with the standard HRF.
%				- The data is high pass filtered (filter frequency is 128
%				  seconds per cycle)
%		5. A simple contrast and a map of t-test t values is produced for
%		   analysis in each subject. We look for activations thresholded at
%		   p < 0.001 (voxelwise) with a minimum extent threshold of 5
%		   contiguous voxels.
%
%	Random effects analyses show significant results with n > 10
%	participants, though it should be evident that the experiment is
%	working after 3 - 5 individuals.
%__________________________________________________________________________
%
%	Created by Rebecca Saxe & David Dodell-Feder
%	Modified by Nick Dufour (ndufour@mit.edu), December 2010
%__________________________________________________________________________
%
%					Changelog
%   05.19.14 : Added trialsOnsets to record onset of stimuli presentation
%	01.18.11 : Fixed a bug that caused the same stimuli to be loaded during
%			   both runs.
%   09.07.11 : Fixed a bug the erroneously eliminated the final fixation
%			   period.
%__________________________________________________________________________
%


% ------------------------------------------------------------------------------
%                                Parameters
% ------------------------------------------------------------------------------

%% A. directory _____________________________________________________
tomsaxe_dir			= pwd;
textdir				= fullfile(tomsaxe_dir, 'text_files');
sub_save_dir			= fullfile(tomsaxe_dir, 'data', strcat('sub-', sprintf('%04d', sub_num)), 'beh');
if ~exist(sub_save_dir, 'dir')
    mkdir(sub_save_dir)
end


%% B. design parameters _____________________________________________________
design				                     = [ 1 2 2 1 2 1 2 1 1 2 2 1 2 1 1 2 2 1 2 1  ]; % changed by FRACTIONAL
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


%% C. output table variables _____________________________________________________
vnames = {'param_fmriSession', ...
                                  'p1_fixation_onset',...
                                  'p2_filename', 'p2_filetype','p2_story_onset',...
                                  'p3_ques_onset',...
                                  'p4_responseonset','p4_responsekey','p4_RT',...
                                  'experimentDuration',...
                                  'RAW_param_triggerOnset', 'RAW_p1_fixation_onset',...
                                  'RAW_p2_story_onset', 'RAW_p3_ques_onset',...
                                  'RAW_param_end_instruct_onset','RAW_param_final_fixation'};
                                  % 'param_end_instruct_onset',
T                                  = array2table(zeros(trialsPerRun,size(vnames,2)));
T.Properties.VariableNames         = vnames;

T.param_fmriSession(:)             = 4;
T.p2_filetype                      = cell(20,1);
T.p2_filename                      = cell(20,1);


%% D. randomize order _____________________________________________________
% original localizer script did not have randomization
bl_ind = rem(sub_num,5);
if bl_ind ==0
    random_seq = [5,5, 2,2, 1,1, 9,9, 6,6, 10,10, 3,3, 7,7, 8,8, 4,4];
elseif bl_ind ==1
    random_seq = [2,2, 4,4, 1,1, 3,3, 10,10, 9,9, 6,6, 7,7, 8,8, 5,5];
elseif bl_ind ==2
    random_seq = [4,4, 1,1, 6,6, 3,3, 8,8, 7,7, 10,10, 9,9, 5,5, 2,2];
elseif bl_ind ==3
    random_seq = [5,5, 6,6, 9,9, 10,10, 4,4, 1,1, 8,8, 7,7, 3,3, 2,2];
elseif bl_ind ==4
    random_seq = [3,3, 10,10, 1,1, 7,7, 5,5, 4,4, 9,9, 8,8, 6,6, 2,2];
end


%% E. instructions _____________________________________________________________
instruct_filepath                  = fullfile(tomsaxe_dir,  'instructions');
instruct_start_name                = ['task-', taskname, '_start.png'];
instruct_end_name                  = ['task-', taskname, '_end.png'];
instruct_start                     = fullfile(instruct_filepath, instruct_start_name);
instruct_end                       = fullfile(instruct_filepath, instruct_end_name);


%% F. Verify that all necessary files and folders are in place _________________
if isempty(dir(textdir))
    uiwait(warndlg(sprintf('Your stimuli directory is missing! Please create directory %s and populate it with stimuli. When Directory is created, hit ''Okay''',textdir),'Missing Directory','modal'));
end
if isempty(dir(sub_save_dir))
    outcome = questdlg(sprintf('Your behavioral directory is missing! Please create directory %s.',sub_save_dir),'Missing Directory','Okay','Do it for me','Do it for me');
    if strcmpi(outcome,'Do it for me')
        mkdir(sub_save_dir);
        if isempty(dir(sub_save_dir))
            warndlg(sprintf('Couldn''t create directory %s!',sub_save_dir),'Missing Directory');
            return
        end
    else
        if isempty(dir(sub_save_dir))
            return
        end
    end
end


%% G. Verify that all necessary files and folders are in place _________________

%  Here, all necessary PsychToolBox functions are initiated and the
%  instruction screens are set up.
try
    cd(textdir);
    HideCursor;

    Screen('Preference', 'SkipSyncTests', 1);
    PsychDefaultSetup(2);
    screens                        = Screen('Screens');
    p.ptb.screenNumber             = max(screens);
    p.ptb.white                    = WhiteIndex(p.ptb.screenNumber); % Define black and white
    p.ptb.black                    = BlackIndex(p.ptb.screenNumber);
    p.ptb.green                    = [0 1 0];
    [p.ptb.window, p.ptb.rect]     = PsychImaging('OpenWindow',p.ptb.screenNumber,p.ptb.black);
    [p.ptb.screenXpixels, p.ptb.screenYpixels] = Screen('WindowSize',p.ptb.window);
    [p.ptb.xCenter, p.ptb.yCenter] = RectCenter(p.ptb.rect);
    p.ptb.ifi                      = Screen('GetFlipInterval',p.ptb.window);
    Screen('BlendFunction', p.ptb.window,'GL_SRC_ALPHA','GL_ONE_MINUS_SRC_ALPHA');

%% H. Keyboard information _____________________________________________________
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
catch exception
    ShowCursor;
    sca;
    warndlg(sprintf('PsychToolBox has encountered the following error: %s',exception.message),'Error');
    return
end


%% -----------------------------------------------------------------------------
%                              START EXPERIMENT
% ------------------------------------------------------------------------------

% ------------------------------------------------------------------------------
%                       0. Present Instruction Screen
% ------------------------------------------------------------------------------
Screen('TextSize',p.ptb.window,72);
start.texture = Screen('MakeTexture',p.ptb.window, imread(instruct_start)); % start image
Screen('DrawTexture',p.ptb.window,start.texture,[],[]);
Screen(p.ptb.window, 'Flip');

% ------------------------------------------------------------------------------
%                           1. Wait for trigger
% ------------------------------------------------------------------------------
WaitKeyPress(p.keys.start)
Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
    p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2); % will flip immediately
Screen('Flip', p.ptb.window);

WaitKeyPress(p.keys.trigger);
T.RAW_param_triggerOnset(:) = GetSecs;
experimentStart = T.RAW_param_triggerOnset(1);
WaitSecs(TR*6);

counter				    = zeros(1,2)+(5*(run_num-1));
Screen(p.ptb.window, 'TextSize', 24);

% ------------------------------------------------------------------------------
%                          2. trial loop
% ------------------------------------------------------------------------------
for trial = 1:trialsPerRun
    cd(textdir);
    trialStart		= GetSecs;
    empty_text		= ' ';

    Screen(p.ptb.window, 'DrawText', empty_text,p.ptb.xCenter,p.ptb.yCenter);
    Screen(p.ptb.window, 'Flip');
    counter(1,design(trial)) = counter(1,design(trial)) + 1;

% ------------------------------------------------------------------------------
%                          3. Determine stimuli filenames
% ------------------------------------------------------------------------------
    trialT			= design(trial);							% trial type. 1 = false belief, 2 = false photograph
    % numbeT			= counter(1,trialT);						% the number of the stimuli
    numbeT      = random_seq(trial);
    storyname		= fullfile(textdir, sprintf('%d%s_story.txt',numbeT,condPrefs{trialT}));
    questname		= fullfile(textdir, sprintf('%d%s_question.txt',numbeT,condPrefs{trialT}));
    items(trial,1)	= numbeT;
    T.p2_filename{trial} = {sprintf('%d%s_story.txt',numbeT,condPrefs{trialT})};
    T.p2_filetype{trial} = trial_type{trialT};

% ------------------------------------------------------------------------------
%                          4. Present story
% ------------------------------------------------------------------------------
    % ________ 4-1. Open Story _________________________________________________
    textfid			= fopen(storyname, 'r');
    lCounter		= 1;										% line counter

    while GetSecs - trialStart < fixDur
        Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
            p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
        T.RAW_p1_fixation_onset(trial) = Screen('Flip', p.ptb.window);
    end					% wait for fixation period to elapse

    % ________ 4-2. Display Story ______________________________________________
    while 1
        tline		= fgetl(textfid);							% read line from text file.
        if ~ischar(tline), break, end
        Screen(p.ptb.window, 'DrawText',tline,p.ptb.xCenter-380,p.ptb.yCenter-160+lCounter*45,[255]);
        lCounter	= lCounter + 1;
    end
    fclose(textfid);
    T.RAW_p2_story_onset(trial) = Screen(p.ptb.window, 'Flip');
    trialsOnsets(trial) = GetSecs-experimentStart;

% ------------------------------------------------------------------------------
%                          5. Present Question
% ------------------------------------------------------------------------------

    % ________ 5-1. Open question ______________________________________________
    textfid			= fopen(questname);
    lCounter		= 1;
    while 1
        tline		= fgetl(textfid);			        		% read line from text file.
        if ~ischar(tline), break, end
        Screen(p.ptb.window, 'DrawText',tline,p.ptb.xCenter-380,p.ptb.yCenter-160+lCounter*45,[255]);
        lCounter	= lCounter + 1;
    end

    while GetSecs - trialStart < fixDur + storyDur; end	% wait for story presentation period

    % ________ 5-2. Display Question ___________________________________________
    T.RAW_p3_ques_onset(trial) = Screen(p.ptb.window, 'Flip');

    responseStart	= GetSecs;

% ------------------------------------------------------------------------------
%                          6. Get Response
% ------------------------------------------------------------------------------
    while ( GetSecs - T.RAW_p3_ques_onset(trial) ) < questDur
        [keyIsDown,secs,keyCode]	= KbCheck; % check to see if a key is being pressed

        if keyCode(p.keys.esc)
            ShowCursor;
            sca;
            return
        elseif keyCode(p.keys.right)
            RT(trial,1)				= GetSecs - T.RAW_p3_ques_onset(trial); %responseStart;
            key(trial,1)    	= 2;
            T.p4_responseonset(trial) = secs;
            T.p4_responsekey(trial)    = 2;
            T.p4_RT(trial)    = RT(trial,1);
        elseif keyCode(p.keys.left)
            RT(trial,1)				= GetSecs - T.RAW_p3_ques_onset(trial); %responseStart;
            key(trial,1)			= 1;
            T.p4_responseonset(trial) = secs;
            T.p4_responsekey(trial) = 1;
            T.p4_RT(trial)    = RT(trial,1);

        end
    end

% ------------------------------------------------------------------------------
%                        7. Save information in the event of a crash
% ------------------------------------------------------------------------------
    save_filename = [strcat('sub-', sprintf('%04d', sub_num)), '_ses-04_task-tomsaxe.mat'];
    save_fullfile = fullfile(sub_save_dir, save_filename);
    save(save_fullfile,'sub_num','run_num','design','items','key','RT','trialsOnsets');
end

% Final fixation, save information
trials_end			= GetSecs;
Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
    p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
T.RAW_param_final_fixation(:) = Screen('Flip', p.ptb.window);

WaitSecs(endDur);

% ------------------------------------------------------------------------------
%                       END AND SAVE EXPERIMENT
% ------------------------------------------------------------------------------
% _________________________ End Instructions _____________________________
end_texture = Screen('MakeTexture',p.ptb.window, imread(instruct_end));
Screen('DrawTexture',p.ptb.window,end_texture,[],[]);
T.RAW_param_end_instruct_onset(:) = Screen('Flip',p.ptb.window);


T.experimentDuration(:) = T.RAW_param_end_instruct_onset(1) - T.RAW_param_triggerOnset(1);
experimentEnd		= GetSecs;
experimentDuration	= T.experimentDuration(1);
numconds			= 2;

% convert variables
T.p1_fixation_onset(:) = T.RAW_p1_fixation_onset(:)- T.RAW_param_triggerOnset(:) - (TR*6);
T.p2_story_onset(:) = T.RAW_p2_story_onset(:) - T.RAW_param_triggerOnset(:) - (TR*6);
T.p3_ques_onset(:) = T.RAW_p3_ques_onset(:) - T.RAW_param_triggerOnset(:) - (TR*6);

%% __________________________ save parameter ___________________________________
saveFileName = fullfile(sub_save_dir,[strcat('sub-', sprintf('%04d', sub_num)), '_task-',taskname,'_beh.csv' ]);
writetable(T,saveFileName);
WaitKeyPress(p.keys.end);

try
    sca
    responses = sortrows([design' items key RT]);

    save(save_fullfile,'sub_num','run_num','design','items','key','RT','trialsOnsets','responses','experimentStart','experimentEnd','experimentDuration','ips');
    ShowCursor;
    %     cd(orig_dir);
catch exception
    sca
    ShowCursor;
    warndlg(sprintf('The experiment has encountered the following error while saving the behavioral data: %s',exception.message),'Error');
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
