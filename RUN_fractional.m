% 1. grab participant number ___________________________________________________
prompt = 'session number : ';
session = input(prompt);
prompt = 'subject number (in raw number form, e.g. 1, 2,...,98): ';
sub = input(prompt);


% 2. counterbalance version ____________________________________________________

%% B. Directories ______________________________________________________________
main_dir                        = pwd;

% load counterbalance mat
counterbalancefile              = fullfile(main_dir, 'counterbalance.csv');
countBalMat                     = readtable(counterbalancefile);
task1 = string(countBalMat.task1{sub});
task2 = string(countBalMat.task2{sub});
switch task1
    case 'tom'
        t1 = fullfile(main_dir,'tomloc', 'tom_localizer.m');
    case 'whyhow'
        t1 = fullfile(main_dir,'spunt_whyhowlocalizer-00fa102','run_task.m');
    case 'posner'
        t1 = fullfile(main_dir, 'posner-AR', 'scripts', 'posner.m');
    case 'mem'
        t1 = fullfile(main_dir, 'mt_study.m');
end
switch task2
    case 'tom'
        t2 = fullfile(main_dir,'tomloc', 'tom_localizer.m');
    case 'whyhow'
        t2 = fullfile(main_dir,'spunt_whyhowlocalizer-00fa102','run_task.m');
    case 'posner'
        t2 = fullfile(main_dir, 'posner-AR', 'scripts', 'posner.m');
    case 'mem'
        t2 = fullfile(main_dir, 'mt_study.m');
        
end

t1; t2;



