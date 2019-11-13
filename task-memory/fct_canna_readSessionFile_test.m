function [respData,typeResponse] = fct_canna_readSessionFile_test(subject,session,dirPath)

fprintf('Processing test %s %s...',subject,session);

commentStyle = '!!!';

logFile = fullfile(dirPath,subject,session,'session.txt');

formatStr = '%.6f%s%s%s%s%s%s';

if exist(logFile,'file')
    % read the real file
    fid = fopen(logFile,'r');
    logData = textscan(fid,formatStr,'Delimiter','\t','emptyvalue',NaN,'CommentStyle',commentStyle);
    fclose(fid);
    
    % find answers & RT
    type = logData{:,4};
    correct_answer = logData{:,5}; 
    correct_answer = correct_answer(strcmp(type,'TEST_RESP'));
    answer = logData{:,6};
    answer = answer(strcmp(type,'TEST_RESP'));
    RT = logData{:,7};
    RT = RT(strcmp(type,'TEST_RESP'));
end

for i = 1 : length(correct_answer)
    % 1 = old, 0 = new
    respData(i,1) = str2num(correct_answer{i});
    respData(i,2) = (correct_answer{i} == answer{i});
    respData(i,3) = str2num(RT{i});
    % 1 = hit / 2 = CR / 3 = Miss / 4 = FA
    if str2num(answer{i}) == str2num(correct_answer{i})
       if str2num(correct_answer{i}) == 1
           typeResponse(i,1) = 1;
       else
           typeResponse(i,1)  = 2;
       end
   elseif str2num(answer{i}) ~= str2num(correct_answer{i})
       if str2num(correct_answer{i}) == 1
           typeResponse(i,1)  = 3;
       else
           typeResponse(i,1)  = 4;
       end
   end
    
    
end

fprintf('Done.\n');
