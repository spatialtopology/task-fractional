function [cfg,expParam] = mt_saveStimList_images(cfg,expParam,sesName,stimListToLoad)
% function [cfg] = mt_saveStimList_images(cfg,sesName,stimListToLoad)

if nargin < 3
    error('Not enough input arguments!');
end

phase = sesName(1:4);
phaseNum = str2num(sesName(5));

if ~cfg.stim.stimListRandom && strcmp(phase,'stud')
    if isempty(stimListToLoad)
        error('Please provide a stimuli list to load');
    end
end

if exist(cfg.files.expParamFile,'file')
    error('Experiment parameter file should not exist before stimulus list has been created: %s',cfg.files.expParamFile);
end


fprintf('Creating stimulus list for %s%d...',phase,phaseNum);


fid = fopen(cfg.stim.(sesName).stimListFile,'w');
% find all stim
imNames = dir(fullfile(cfg.files.stimDir, ['*' cfg.files.stimFileExt]));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% List to study
if strcmp(phase,'stud')
    % Random list
    if cfg.stim.stimListRandom
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
            cfg.stim.(sesName).imToPick(:,1) = sort(imToPick);
            cfg.stim.(sesName).imToPick(:,2) = 1;
            whichBuffers = randperm(nbIm,2*cfg.stim.nonTestBuffersStudy);
            cfg.stim.(sesName).imToPick(whichBuffers,2) = 0;
            % print the stimulus info to the stimulus list file
            for im = 1 : nbIm
                fprintf(fid,'%s\n',imNames(cfg.stim.(sesName).imToPick(im)).name);
            end
            %
        end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Predefined list
    else
        %%%%%%%%%%%%%%%%%%%%%%%%
        % Create the first list
        if phaseNum == 1
            % Load predefined list
            fileListToTest = fullfile(cfg.files.stimListDir,stimListToLoad);
            listToTest = textread(fileListToTest,'%s');
            for im = 1 : length(listToTest)
                imToPick(im,1) =  str2num(listToTest{im}(4:6));
            end
            if cfg.stim.nonTestBuffersStudy > 0
                % Randomly select buffers
                imToPickBuffer = randperm(length(imNames),2*cfg.stim.nonTestBuffersStudy);
                for im = 1 : length(imToPickBuffer)
                    currentIm = imToPickBuffer(im);
                    while ismember(currentIm,imToPick)
                        currentIm = randperm(length(imNames),1);
                    end
                    imToPick = [imToPick;currentIm];
                    imToPickBuffer(im) = currentIm;
                end
                imToPick(1:length(listToTest),2) = 0;
                imToPick(length(listToTest)+1:length(imToPick),2) = 1;
                [a,b] = sort(imToPick);
                imToPick = imToPick(b(:,1),:);
                cfg.stim.(sesName).imToPick = imToPick;
                for im = 1 : length(imToPick)
                    fprintf(fid,'%s\n',imNames(cfg.stim.(sesName).imToPick(im)).name);
                end
            else
                imToPick(im,2) = 0;
                cfg.stim.(sesName).imToPick = imToPick;
                for im = 1 : length(imToPick)
                    fprintf(fid,'%s\n',imNames(cfg.stim.(sesName).imToPick(im)).name);
                end
            end
            %%%%%%%%%%%%%%%%%%%%%%%%
            % Create lists different from the first one
        else
            % Load predefined list
            fileListToTest = fullfile(cfg.files.stimListDir,stimListToLoad);
            listToTest = textread(fileListToTest,'%s');
            for im = 1 : length(listToTest)
                imToPick(im,1) =  str2num(listToTest{im}(4:6));
            end
            if cfg.stim.nonTestBuffersStudy > 0
                % Load previous lists
                imAlreadyUsed = [];
                for p = 1 : phaseNum-1
                    sesNamePrev = [phase num2str(p)];
                    imAlreadyUsed = [imAlreadyUsed; cfg.stim.(sesNamePrev).imToPick(:,1)];
                end
                imAlreadyUsed = [imAlreadyUsed;imToPick];
                % Randomly select buffers
                imToPickBuffer = randperm(length(imNames),2*cfg.stim.nonTestBuffersStudy);
                for im = 1 : length(imToPickBuffer)
                    currentIm = imToPickBuffer(im);
                    while ismember(currentIm,imAlreadyUsed)
                        currentIm = randperm(length(imNames),1);
                    end
                    imToPick = [imToPick;currentIm];
                    imToPickBuffer(im) = currentIm;
                end
                imToPick(1:length(listToTest),2) = 0;
                imToPick(length(listToTest)+1:length(imToPick),2) = 1;
                [a,b] = sort(imToPick);
                imToPick = imToPick(b(:,1),:);
                cfg.stim.(sesName).imToPick = imToPick;
                for im = 1 : length(imToPick)
                    fprintf(fid,'%s\n',imNames(cfg.stim.(sesName).imToPick(im)).name);
                end
            else
                imToPick(im,2) = 0;
                cfg.stim.(sesName).imToPick = imToPick;
                for im = 1 : length(imToPick)
                    fprintf(fid,'%s\n',imNames(cfg.stim.(sesName).imToPick(im)).name);
                end
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% List to test    
elseif strcmp(phase,'test')
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
end
fclose(fid);

fprintf('Done.\n');


