% 1. grab participant number ___________________________________________________
clear all
prompt = 'session number : ';
session = input(prompt);
prompt = 'subject number (in raw number form, e.g. 1, 2,...,98): ';
subj_num = input(prompt);


% 2. counterbalance version ____________________________________________________

%% B. Directories ______________________________________________________________
main_dir                        = pwd;

% load counterbalance mat
counterbalancefile              = fullfile(main_dir, 'counterbalance.csv');
countBalMat                     = readtable(counterbalancefile);
task1 = string(countBalMat.task1{subj_num});
task2 = string(countBalMat.task2{subj_num});
switch task1
    case 'tom'
        t1 = fullfile(main_dir,'tomloc', 'tom_localizer');
    case 'whyhow'
        t1 = fullfile(main_dir,'spunt_whyhowlocalizer-00fa102','run_task');
    case 'posner'
        t1 = fullfile(main_dir, 'posner-AR', 'scripts', 'posner');
    case 'mem'
        t1 = fullfile(main_dir, 'memorizationTask_noeeg','memorizationTask');
end
switch task2
    case 'tom'
        t2 = fullfile(main_dir,'tomloc', 'tom_localizer');
    case 'whyhow'
        t2 = fullfile(main_dir,'spunt_whyhowlocalizer-00fa102','run_task');
    case 'posner'
        t2 = fullfile(main_dir, 'posner-AR', 'scripts', 'posner');
    case 'mem'
        t2 = fullfile(main_dir, 'memorizationTask_noeeg','memorizationTask');
        
end
run_task1 = strcat(t1, '(' ,num2str(subj_num), ')');
run_task2 = strcat(t2, '(' ,num2str(subj_num), ')');
run(run_task1);
run(run_task2);


