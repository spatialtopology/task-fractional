function [cfg,expParam] = mt_saveStimList_images(cfg,expParam,sesName)

if nargin < 3
    error('Not enough input arguments!');
end

phase = sesName(1:4);
phaseNum = str2num(sesName(5));

if exist(cfg.files.expParamFile,'file')
    error('Experiment parameter file should not exist before stimulus list has been created: %s',cfg.files.expParamFile);
end


fprintf('Creating stimulus list for %s%d...',phase,phaseNum);

% find all stim
imNames = dir(fullfile(cfg.files.stimDir, ['*' cfg.files.stimFileExt]));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% List to study
if strcmp(phase,'stud')
    %%%%%%%%%%%%%%%%%%%%%%%%
    % Random list
    if cfg.stim.stimListRandom
        fid = fopen(cfg.stim.(sesName).stimListFile,'w');
        %%%%%%%%%%%%%%%%%%%%%%%%
        % Create the first list
        if phaseNum == 1
            % randomly choose the images, including non test buffers
            nbIm = cfg.stim.nStudy+2*cfg.stim.nonTestBuffersStudy;
            cfg.stim.(sesName).imToPick(:,1) = sort(randperm(length(imNames),nbIm));
            % print the stimulus info to the stimulus list file
            for im = 1 : nbIm
                fprintf(fid,'%s\n',imNames(cfg.stim.(sesName).imToPick(im)).name);
            end
            cfg.stim.(sesName).imToPick(:,2) = 1;
            whichBuffers = randperm(nbIm,2*cfg.stim.nonTestBuffersStudy);
            cfg.stim.(sesName).imToPick(whichBuffers,2) = 0;
            %%%%%%%%%%%%%%%%%%%%%%%%
            % Create lists different from the first one
        else
            % load previous lists
            imAlreadyUsed = [];
            for p = 1 : phaseNum-1
                sesNamePrev = [phase num2str(p)];
                imAlreadyUsed = [imAlreadyUsed; cfg.stim.(sesNamePrev).imToPick(:,1)];
            end
            % randomly choose the images
            nbIm = cfg.stim.nStudy+2*cfg.stim.nonTestBuffersStudy;
            imToPick = sort(randperm(length(imNames),nbIm));
            % delete images already used
            for im = 1 : nbIm
                currentIm = imToPick(im);
                while ismember(currentIm,imAlreadyUsed)
                    currentIm = randperm(length(imNames),1);
                end
                imAlreadyUsed = [imAlreadyUsed;currentIm];
                listToTest(im) = currentIm;
            end
            cfg.stim.(sesName).imToPick(:,1) = sort(listToTest);
            cfg.stim.(sesName).imToPick(:,2) = 1;
            whichBuffers = randperm(nbIm,2*cfg.stim.nonTestBuffersStudy);
            cfg.stim.(sesName).imToPick(whichBuffers,2) = 0;
            % print the stimulus info to the stimulus list file
            for im = 1 : nbIm
                fprintf(fid,'%s\n',imNames(cfg.stim.(sesName).imToPick(im)).name);
            end
        end
    fclose(fid);   
    %%%%%%%%%%%%%%%%%%%%%%%%
    % Predefined list
    else
        source = [cfg.files.stimListDir '\stimList_' sesName '.txt'];
        destination = [cfg.stim.(sesName).stimListFile];
        copyfile(source,destination);
        
        formatStr = '%s';
        commentStyle = '!!!'; 
        
        if exist(destination,'file')
            % read the real file
            fid = fopen(destination,'r');
            logData = textscan(fid,formatStr,'Delimiter','\t','emptyvalue',NaN,'CommentStyle',commentStyle);
            fclose(fid);
        end
        
        for i = 1 : length(logData{1})
            cfg.stim.(sesName).imToPick(:,1) = str2num(logData{1}{i}(4:6));
            if i <= cfg.stim.nonTestBuffersStudy || i > cfg.stim.nStudy + cfg.stim.nonTestBuffersStudy
                cfg.stim.(sesName).imToPick(i,2) = 0;
            else
                cfg.stim.(sesName).imToPick(i,2) = 1;
            end
        end  
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % List to test
elseif strcmp(phase,'test')
    %%%%%%%%%%%%%%%%%%%%%%%%
    % Random list
    if cfg.stim.stimListRandom
        fid = fopen(cfg.stim.(sesName).stimListFile,'w');
        % Load the study list and removed non test buffers
        sesNameStudy = ['stud' num2str(phaseNum)];
        imStudied = cfg.stim.(sesNameStudy).imToPick;
        imStudied = sort(imStudied(imStudied(:,2) == 1));
        
        % Load all study list of the experiment and all previous test list
        % already created
        imAlreadyUsed = [];
        for p = 1 : expParam.nSessions/2
            sesNameStudy = ['stud' num2str(p)];
            imAlreadyUsed = [imAlreadyUsed; cfg.stim.(sesNameStudy).imToPick(:,1)];
        end
        for p = 1 : phaseNum-1
            sesNamePrev = [phase num2str(p)];
            imAlreadyUsed = [imAlreadyUsed; cfg.stim.(sesNamePrev).imToTest(:,1)];
        end
        imAlreadyUsed = sort(imAlreadyUsed);
        
        % Randomly pick up new images
        imToTest(:,1) = randperm(length(imNames),cfg.stim.nTestNew);
        for im = 1 : length(imToTest)
            currentIm = imToTest(im);
            while ismember(currentIm,imAlreadyUsed)
                currentIm = randperm(length(imNames),1);
            end
            imAlreadyUsed = [imAlreadyUsed;currentIm];
            imToTest(im) = currentIm;
        end
        
        % Randomly pick up old image
        imToTest = [imToTest;imStudied(randperm(length(imStudied),cfg.stim.nTestOld))];
        
        imToTest(1:cfg.stim.nTestNew,2) = 0;
        imToTest(cfg.stim.nTestNew+1:end,2) = 1;
        
        [a,b] = sort(imToTest);
        imToTest = imToTest(b(:,1),:);
        cfg.stim.(sesName).imToTest = imToTest;
        for im = 1 : length(imToTest)
            fprintf(fid,'%s\n',imNames(cfg.stim.(sesName).imToTest(im)).name);
        end
    fclose(fid);
    %%%%%%%%%%%%%%%%%%%%%%%%
    % Predefined list
    else
        source = [cfg.files.stimListDir '\stimList_' sesName '.txt'];
        destination = [cfg.stim.(sesName).stimListFile];
        copyfile(source,destination);
        
        formatStr = '%s';
        commentStyle = '!!!'; 
        
        if exist(destination,'file')
            % read the real file
            fid = fopen(destination,'r');
            logData = textscan(fid,formatStr,'Delimiter','\t','emptyvalue',NaN,'CommentStyle',commentStyle);
            fclose(fid);
        end
        
        for i = 1 : length(logData{1})
            cfg.stim.(sesName).imToTest(i,1) = str2num(logData{1}{i}(4:6));
        end  
        
        oldnewfile = [cfg.files.stimListDir '\stimList_' sesName '.mat'];
        load(oldnewfile)
        cfg.stim.(sesName).imToTest(:,2) = oldnew;    
    end
end

fprintf('Done.\n');


