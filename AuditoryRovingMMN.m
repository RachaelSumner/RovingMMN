% AuditoryRovingMMN

% CREATED:
% Rachael Sumner, July 2020

% EDITED:



% NOTES:

% Adapted to Psychtoolbox-3 from source code written by Marta Garrido for
% Cogent. Contains some orignal code. 

% Requires https://github.com/widmann/ppdev-mex for triggers, else add your
% own and remove all trigger related code.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%
clear all

subj=input('please enter the study ID: ', 's');
session = input('please enter session number: ');

PsychDefaultSetup(2);
InitializePsychSound;

Initiate_PTB = GetSecs;

% Trigger setup % 

try
    ppdev_mex('Open',1); %initilise triggering
catch
    warning('ppdev_mex did not execute correctly - Any triggers will not work'); 
end

%               %


%%%%%BASIC SCREEN SETUP

Priority(1);
ListenChar(-1); %prevent keyboard input going to the MATLAB window

screens = Screen('Screens'); %For projecting to external screen. Get the number of screens in the computer setup
screenNumber = max(screens); %Can change to 0 for single screen. Otherwise displays on the most external screen (grab max number)

black = [0 0 0];  % Matlab colour code for black.
white = [1 1 1];  % Matlab colour code for white.
backgroundgrey = [0.5 0.5 0.5];  % Matlab colour code for grey.
contrastgrey = [0.2 0.2 0.2]; %Matlab colour code for cross luminance changes (from black)

QuitKey = 'q';
CrossKey = 'space';

[window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundgrey);

HideCursor;

% Setup the text type for the window
Screen('TextFont', window, 'Ariel');
Screen('TextSize', window, 40);


%%%% AUDITORY TONE SETUP 

srate=48000;      % sampling rate 
dur = 0.070;      % duration of each event
freq=500;       % defines frequency of principal
t=[0:1/srate:dur];        % during 'dur' does
y=sin(2*pi*freq*t);      %creates a wave form for standard tones=1000Hz (pure)

x=ones(size(y));                        %
xtemp=cos(pi:2*pi/99:(pi+2*pi));         % creates 10 ms of rise and fall times
x(1:50)=xtemp(1:50);                     %  
x(end-49:end)=xtemp(51:end);             %
x=(x+1)/2;

dev = [0 0.10 0.20 0.30 0.40 0.50 0.60]; % creates a vector with deviance from 0 to 60% from freq.

freqd = freq*(1+dev(:)); %    calculates new frequency

tones = [];
for j = 1:length(dev)
    tone = sin(2*pi*freqd(j)*t);      % creates all the wave forms to be presented and stores them in a matrix called tones
    z = tone.*x;
    tones = [tones; z];
end

tones=tones.*0.99;

for n=1:length(dev)
    audiowrite(['snd' num2str(n) '.wav'], tones(n,:), srate);  %Write tones to to .wav
end 

for n=1:length(dev)   
    Sound(n).type = psychwavread(['snd' num2str(n) '.wav']); % Read in .wav and add to struct Sound
    Sound(n).type =  [Sound(n).type(:)'; Sound(n).type(:)']; % Put in stereo 
end 

%%% Seven Tones
tones_seven = [];
order_of_tones =[];
blocks = 500;
tone = 1;


%%%% TRAIN LENGTH SETUP

for i = 1:blocks
    
    % Select a deviant
    x = randperm(7); % Deviants/tone frequencies (tones)
    if x(1) ~= tone % Choose a number between 1-7 that isn't the last one you used
        tone = x(1);
    else
        tone = x(2); % if by chance it is the same as the last one, choose the second number
    end
    
    % Generate a train length (by adding standards)
    y = randperm(5); %% randomly permute an array of 1-5 possible additional standards 
    s = [1:y(1)+5]; % train length is 5 + the randomly selected number between 1-5
    
    tones_seven = [tones_seven ones(1,length(s))*tone]; 
    % The stimulus is trains of tones of length "s", and of frequency "tone"
    % added on to the end of each loop until 500 trains are made
    order_of_tones =[order_of_tones s];

end


%%% VISUAL DISTRACTOR TASK SETUP

tshow = [30:15:90]; % Creates a vector of luminance change times 2-5 s 
tlonger = repmat(tshow, 40); % Creates >~15 min of changes 
ltshow = length(tlonger);
tshow = tlonger(randperm(ltshow)); %Pseudorandomise  


%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% PARADIGM %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pahandle = PsychPortAudio('Open', 3,[],2,srate,2); %7 is the soundcard

DrawFormattedText(window, '+', 'center', 'center', black)
Screen('Flip', window);

FirstCross = GetSecs;
time2change(1) = tshow(1) + FirstCross;

for i = 2:length(tshow) 
    time2change(i) = tshow(i) + time2change(i-1);
end

ChangeResponse = [zeros(1,500)];
ChangeTimesActual = [zeros(1,280)];

i = 0;
v = 1;

    KbQueueCreate; 
    KbQueueStart; 
    
    time = GetSecs;
    
while GetSecs < time + 60*15 % length of task = 15min 

    i = i+1;
    
    %AUDITORY TASK 
    PsychPortAudio('FillBuffer', pahandle, Sound(tones_seven(i)).type)
    PsychPortAudio('Start', pahandle, 1) 
    lptwrite(1, order_of_tones(i)); % Send trigger
    
    WaitSecs(0.25) % offset the cross change by at least 250ms 
    lptwrite(1, 0); % Clear trigger
     
     
    %VISUAL TASK
        if GetSecs > time2change(v)  == 1
            if rem(v,2) == 0 %is even                
                DrawFormattedText(window, '+', 'center', 'center', contrastgrey)
                Screen('Flip', window);
                ChangeTimesActual(v) = GetSecs; 
            lptwrite(1, 201); % Send trigger
                v = v+1;   
            else
                DrawFormattedText(window, '+', 'center', 'center', black)
                Screen('Flip', window);
                ChangeTimesActual(v) = GetSecs; 
            lptwrite(1, 202); % Send trigger
            v = v+1;    
            end          
        end
        
    WaitSecs(0.25)
    lptwrite(1, 0); % Clear trigger

    %Register key press for visual task
    [pressed, firstPress] =  KbQueueCheck;    
    if pressed == 1 && firstPress(32) > 1     
       lptwrite(1, 203); % Send trigger. Not necessary - but does allow you to visually check the participant is doing the vis task
       ChangeResponse(i) = firstPress(32);
       lptwrite(1, 0); % Clear trigger

    end
    KbQueueFlush;
    

    
    %QUIT KEY
    [keyIsDown, secs, keyCode] = KbCheck;
    if find(keyCode) == KbName(QuitKey)
          ppdev_mex('Close',1); %Close port (for triggers)
          KbQueueStop;
          PsychPortAudio('Close', pahandle);
          Screen ('CloseAll');
          ShowCursor;
          ListenChar(0);
          return  
    end 
    
end 
   
    %Register any remaining key press for visual task
    Waitsecs(1.5)
    [pressed, firstPress] =  KbQueueCheck;    
    if pressed == 1 && firstPress(32) > 1            
       lptwrite(1, 203); % Send trigger. Not necessary - but does allow you to visually check the participant is doing the vis task
       ChangeResponse(i) = firstPress(32);
       lptwrite(1, 0); % Send trigger
    end
    KbQueueFlush;

%%% CREATE RESULTS FILE  
   
Results.subj = subj;
Results.SessionNumber = session;
Results.SessionStart = FirstCross; %Start time of visual task in seconds
Results.PlannedTime2Change = time2change; %When the luminance was scripted to change 
Results.ActualTime2Change = ChangeTimesActual(ChangeTimesActual~=0); %Due to imbedding in loop, and forced offset with the deviant, when did they actually change
Results.ResponseTimes = ChangeResponse(ChangeResponse~=0); %Response times (space input only)
Results.TonesandTrains = tones_seven; % Backup to the trigger labels - vector or deviant tones type and n repetitions 
Results.OrderofTones = order_of_tones; % Matches tone n in sequence to tones_seven
%%%%END
KbQueueStop;
PsychPortAudio('Close', pahandle);
ppdev_mex('Close',1); %Close port (for triggers)
Screen ('CloseAll');
ShowCursor;
ListenChar (0);
Priority(0)
results_file_name = ['MMN_Results_',num2str(subj),'_Session',num2str(session)]
save(results_file_name,'Results')


