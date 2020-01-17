% To Do
% [x] memory should run 4 times
% [x] there should be a task in between memory 2.5 min each
% [x] time memory task : study 1 min, test 1.5 min
% [x] make sure tomsaxe runs smoothly
% [x] randomize tomsaxe


% 1. grab participant number ___________________________________________________
clear all;
% prompt = 'session number : ';
% session = input(prompt);
prompt = 'subject number (in raw number form, e.g. 1, 2,...,98): ';
sub_num = input(prompt);


% 2. counterbalance version ____________________________________________________

%% B. Directories ______________________________________________________________
main_dir                        = pwd;

% load counterbalance mat
counterbalancefile              = fullfile(main_dir, 'counterbalance.csv');
countBalMat                     = readtable(counterbalancefile);
task1 = string(countBalMat.task1{sub_num});
task2 = string(countBalMat.task2{sub_num});

fprintf(strcat('\nToday, sub-', sprintf('%04d', sub_num) ,' will go through tasks: \n 1)', task1 ,'   \n 2) ', task2 , '\n\n'))

switch task1
    case 'tomsaxe'
        chdir_t1 = strcat('cd(''', fullfile(main_dir,'task-tomsaxe' ), ''')');
        t1 = fullfile(main_dir, 'task-tomsaxe', 'tom_localizer');
    case 'tomspunt'
        chdir_t1 = strcat('cd(''', fullfile(main_dir,'task-tomspunt') , ''')');
        t1 = fullfile(main_dir, 'task-tomspunt','RUN_task');
    case 'posner'
        chdir_t1 = strcat('cd(''', fullfile(main_dir,'task-posnerAR' ), ''')');
        t1 = fullfile(main_dir, 'task-posnerAR', 'scripts', 'posner');
    case 'memory'
        chdir_t1 = strcat('cd(''', fullfile(main_dir,'task-memory') , ''')');
        t1 = fullfile(main_dir, 'task-memory','memorizationTask');
end
switch task2
    case 'tomsaxe'
        chdir_t2 = strcat('cd(''', fullfile(main_dir, 'task-tomsaxe') , ''')');
        t2 = fullfile(main_dir, 'task-tomsaxe', 'tom_localizer');
    case 'tomspunt'
        chdir_t2 = strcat('cd(''',fullfile(main_dir, 'task-tomspunt') , ''')');
        t2 = fullfile(main_dir, 'task-tomspunt','RUN_task');
    case 'posner'
        chdir_t2 = strcat('cd(''', fullfile(main_dir,'task-posnerAR') , ''')');
        t2 = fullfile(main_dir, 'task-posnerAR', 'scripts', 'posner');
    case 'memory'
        chdir_t2 = strcat('cd(''', fullfile(main_dir,'task-memory') , ''')');
        t2 = fullfile(main_dir, 'task-memory','memorizationTask');
end

run_task1 = strcat(t1, '(' ,num2str(sub_num), ')');
run_task2 = strcat(t2, '(' ,num2str(sub_num), ')');

% prompt session number
prompt = 'run number (1 or 2): ';
run_num = input(prompt);

if run_num == 1
eval(chdir_t1);
run(run_task1);
elseif run_num == 2
eval(chdir_t2);
run(run_task2);
end
