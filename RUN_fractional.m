% 1. grab participant number ___________________________________________________
clear all;
prompt = 'SESSION (default=4): ';
session = input(prompt);
sub_prompt = 'PARTICIPANT (in raw number form, e.g. 1, 2,...,98): ';
sub_num = input(sub_prompt);
biopac_prompt = 'BIOPAC (YES=1, NO=0) : ';
biopac = input(biopac_prompt);
fMRI = 0;

% 2. counterbalance version ____________________________________________________

%% B. Directories ______________________________________________________________
main_dir                        = pwd;

% load counterbalance mat
counterbalancefile              = fullfile(main_dir, 'counterbalance.csv');
countBalMat                     = readtable(counterbalancefile);
task1 = string(countBalMat.task1{sub_num});
task2 = string(countBalMat.task2{sub_num});

line = strcat('Today, sub-', sprintf('%04d', sub_num) ,' will go through tasks:');
task1_line = strcat(' .    1)  ', task1 );
task2_line = strcat(' .    2)  ', task2 );
boxTop(1:length(line))='=';
fprintf('\n%s\n\n %s\n %s\n %s\n \n%s\n',boxTop,line,task1_line,task2_line,boxTop)

switch task1
    case 'tomsaxe'
        chdir_t1 = strcat('cd(''', fullfile(main_dir,'task-tomsaxe' ), ''')');
        t1 = fullfile(main_dir, 'task-tomsaxe', 'tom_localizer');
    case 'tomspunt'
        chdir_t1 = strcat('cd(''', fullfile(main_dir,'task-tomspunt') , ''')');
        t1 = fullfile(main_dir, 'task-tomspunt','RUN_task');
    case 'posner'
        chdir_t1 = strcat('cd(''', fullfile(main_dir,'task-posnerAR' ), ''')');
        t1 = fullfile(main_dir, 'task-posnerAR', 'scripts', 'RUN_posner');
    case 'memory'
        chdir_t1 = strcat('cd(''', fullfile(main_dir,'task-memory') , ''')');
        t1 = fullfile(main_dir, 'task-memory','RUN_memory');
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
        t2 = fullfile(main_dir, 'task-posnerAR', 'scripts', 'RUN_posner');
    case 'memory'
        chdir_t2 = strcat('cd(''', fullfile(main_dir,'task-memory') , ''')');
        t2 = fullfile(main_dir, 'task-memory','RUN_memory');
end


% prompt session number
prompt = 'RUN number (1 or 2): ';
run_num = input(prompt);

run_task1 = strcat(t1, "(" ,num2str(sub_num),",",num2str(run_num),",", num2str(biopac),",", num2str(session),",", num2str(fMRI),  ")");
run_task2 = strcat(t2, '(' ,num2str(sub_num),',',num2str(run_num),",", num2str(biopac),",", num2str(session),",", num2str(fMRI),  ')');

if run_num == 1
eval(chdir_t1);
run(run_task1);
elseif run_num == 2
eval(chdir_t2);
run(run_task2);
end
