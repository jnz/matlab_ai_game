function [] = rlmain()

dbstop if error; % debugger break on error

global RUN_MAIN_LOOP; % the main loop runs as long as this is set to true
RUN_MAIN_LOOP = true; % set to false to stop simulation
global KB; % global ASCII keyboard input map
KB = zeros(intmax('uint8'), 1);

cleanup_figures   = onCleanup(@() eval('close all'));
cleanup_functions = onCleanup(@() eval('clear functions'));

h = figure(1);
set(h, 'DeleteFcn', @helper_StopLoopFcn);
set(h, 'KeyPressFcn',@helper_keyDownListener);
set(h, 'KeyReleaseFcn', @helper_keyUpListener);
clf;

gamestate.h = h; % Figure handle
gamestate.width = 50;
gamestate.height = 50;
gamestate = gameInit(gamestate);

xlim([0 gamestate.width ]);
ylim([0 gamestate.height]);
axis equal;
axis([0 gamestate.width 0 gamestate.height]);
grid on;
set(gca,'YTick',[]);
set(gca,'XTick',[]);
box on;

dt_sec = 0.1;

dataHist = [];

nn = nnInit();

inputLayer = [ ...
 5.000 40.000  0.000 10.000 40.000  0.000 15.000 40.000  0.000 20.000 40.000  0.000 25.000 40.000  0.000 30.000 40.000  0.000 35.000 40.000  0.000 40.000 27.000 10.000 29.000 10.000  ];
outputNN = nnInput(nn, inputLayer);

AI_ENABLED = true;

while RUN_MAIN_LOOP == true

    [inputLayer, outputLayer] = nnRun(gamestate);
    
    outputNN = nnInput(nn, inputLayer);
    if AI_ENABLED
        INPUT = KB*0;
        if outputNN(1) > outputNN(2) && outputNN(1) > outputNN(3)
            INPUT('d') = 1;
        end
        if outputNN(2) > outputNN(1) && outputNN(2) > outputNN(3)
            INPUT('a') = 1;
        end
    else
        INPUT = KB;
    end
    
    gamestate = gameUpdate(gamestate, dt_sec, INPUT);

    gameDraw(gamestate);
    pause(dt_sec);


    fprintf('Input layer: ');
    fprintf('%.1f ', inputLayer);
    fprintf('Output layer: ');
    fprintf('%.1f ', outputLayer);
    fprintf('\n');
    dataHist = [dataHist; inputLayer, outputLayer']; %#ok<AGROW>
end

if AI_ENABLED == false
    filename = sprintf('data_%s.csv', datestr(now, 'yyyy_mm_dd_HH_MM'));
    csvwrite(filename, dataHist);
end

end

function [gamestate] = gameUpdate(gamestate, dt_sec, KB)

gamestate.gameTime = gamestate.gameTime + dt_sec;

% Player speed based on keyboard input: d move right, a move left
gamestate.player_input = [KB('d'); KB('a')];
vel = 10*[gamestate.player_input(1) - gamestate.player_input(2); 0];
gamestate.entities{gamestate.player_index}.vel = vel;

% Physics update
for i=1:length(gamestate.entities)
    [pos] = entGetPos(gamestate, i);
    pos = pos + gamestate.entities{i}.vel*dt_sec;
    [gamestate] = entSetPos(gamestate, i, pos(1), pos(2));

    if (strcmp(gamestate.entities{i}.class, 'obstacle') > 0)
        if pos(2) < 0
            gamestate.scoreNegative = gamestate.scoreNegative + 1;
            [gamestate] = entSetPos(gamestate, i, pos(1), 40); % FIXME hardcoded number
            gamestate.entities{i}.h.Visible = false;
            gamestate.entities{i}.vel(2) = 0;
            fprintf('Miss! (%i)\n', gamestate.scoreNegative);
        end
        area = rectint(gamestate.entities{i}.h.Position, ...
                       gamestate.entities{gamestate.player_index}.h.Position);
        if area ~= 0
            gamestate.scorePositive = gamestate.scorePositive + 1;
            [gamestate] = entSetPos(gamestate, i, pos(1), 40); % FIXME hardcoded number
            gamestate.entities{i}.h.Visible = false;
            gamestate.entities{i}.vel(2) = 0;
            fprintf('Hit! (%i)\n', gamestate.scorePositive);
        end
    end
end

% Make sure the player cannot leave the arena:
[pos] = entGetPos(gamestate, gamestate.player_index);
if pos(1) > gamestate.width
    pos(1) = gamestate.width;
end
if pos(1) < 0
    pos(1) = 0;
end
entSetPos(gamestate, gamestate.player_index, pos(1), pos(2));

% Think
if gamestate.gameTime > gamestate.nextThinkTime
    lane = floor(1 + rand()*gamestate.max_obstacles);
    assert(lane >= 1 && lane <= gamestate.max_obstacles);

    if gamestate.entities{lane}.h.Visible == false
        gamestate.entities{lane}.h.Visible = true;
        gamestate.entities{lane}.vel(2) = -10;
    end

    gamestate.nextThinkTime = gamestate.gameTime + 1 + rand()*1;
end

end

function [] = gameDraw(gamestate)

drawnow limitrate nocallbacks;

end

function [gamestate] = gameInit(gamestate)

max_obstacles = 8;
ent_count = 1 + max_obstacles;
gamestate.entities = cell(ent_count, 1);
gamestate.scoreNegative = 0;
gamestate.scorePositive = 0;
gamestate.player_input = [0; 0];

for i=1:length(gamestate.entities)
    gamestate.entities{i}.h = rectangle('Position', [0 0 1 1], 'Curvature',[0.5 0.5], 'FaceColor', '#FF0000', 'EdgeColor', 'k', 'LineWidth', 1);
    gamestate.entities{i}.vel = [0; 0];
end

gamestate.player_index = max_obstacles + 1;
gamestate.max_obstacles = max_obstacles;

for i=1:max_obstacles
    [gamestate] = entSetPos(gamestate, i, i*5, 40, 4, 1);
    gamestate.entities{i}.h.Visible = false;
    gamestate.entities{i}.class = 'obstacle';
end

gamestate = entSetPos(gamestate, gamestate.player_index, 20, 5, 5, 1);
gamestate.entities{gamestate.player_index}.class = 'player';
gamestate.entities{gamestate.player_index}.h.FaceColor = '#0000FF';

gamestate.gameTime = 0;
gamestate.nextThinkTime = 1 + rand()*3;

end

function [gamestate] = entSetPos(gamestate, entity_index, pos_x, pos_y, w, h)
gamestate.entities{entity_index}.h.Position(1) = pos_x;
gamestate.entities{entity_index}.h.Position(2) = pos_y;
if nargin > 4
    gamestate.entities{entity_index}.h.Position(3) = w;
    gamestate.entities{entity_index}.h.Position(4) = h;
end
end

function [pos] = entGetPos(gamestate, entity_index)
pos = gamestate.entities{entity_index}.h.Position(1:2)';
end

% Helper functions for keyboard input etc.
% ========================================

function helper_StopLoopFcn(~, ~) % (hObject, event)
% Figure closed event handler function.
global RUN_MAIN_LOOP
RUN_MAIN_LOOP = false;
end

function helper_keyDownListener(~,event)
updateKeys(event, 1);
end

function helper_keyUpListener(~,event)
updateKeys(event, 0);
end

function updateKeys(event, keydown)
global RUN_MAIN_LOOP;
global KB; % global ASCII keyboard input map
if strcmp(event.Key, 'escape') > 0
    RUN_MAIN_LOOP = false;
end
KB(uint8(event.Character)) = keydown;
end

% ------------------------------------------------------------

function [inputLayer, outputLayer] = nnRun(gamestate)

% For each obstacle: pos_x, pos_y, vel_y
% Player: pos_x, vel_x
inputlayers = gamestate.max_obstacles * 3 + 2;

inputLayer = zeros(size(inputlayers, 1), 1);
j = 1;
for i=1:gamestate.max_obstacles
    [pos] = entGetPos(gamestate, i);
    vel_y = abs(gamestate.entities{i}.vel(2));
    inputLayer(j) = pos(1); j = j + 1;
    inputLayer(j) = pos(2); j = j + 1;
    inputLayer(j) = vel_y;  j = j + 1;
end

[pos] = entGetPos(gamestate, gamestate.player_index);

inputLayer(j) = pos(1); j = j + 1;
% vel_x = gamestate.entities{gamestate.player_index}.vel(1);
inputLayer(j) = 0; % vel_x;

% Expected output y
y = [0; 0; 0];
if (gamestate.player_input(1) > 0)
    y(1) = 1;
elseif (gamestate.player_input(2) > 0)
    y(2) = 1;
else
    y(3) = 1; % no action
end
outputLayer = y;

end

function [nn] = nnInit()

W0 = [ ...
 0.025 -0.028 -0.054  0.045 -0.209 -0.333  0.011  0.005 -0.167 -0.134  0.006  0.019 -0.087  0.016 -0.046 ; ...
 0.034 -0.038 -0.068  0.005  0.288 -0.107  0.018  0.016  0.515 -0.095  0.045  0.040 -0.088 -0.039  0.006 ; ...
-0.011  0.004 -0.005  0.016 -0.032  0.176 -0.011  0.063 -0.003 -0.017 -0.010  0.069  0.033 -0.051  0.039 ; ...
-0.072 -0.011 -0.046  0.003 -0.171 -0.295  0.037 -0.021 -0.148 -0.112  0.015 -0.023  0.028  0.099 -0.092 ; ...
-0.074  0.145 -0.028 -0.052  0.188 -0.095  0.001  0.000  0.530  0.080  0.053 -0.048 -0.025  0.004 -0.020 ; ...
-0.061 -0.108  0.037 -0.083 -0.183  0.045  0.002 -0.005 -0.033 -0.009  0.023 -0.028 -0.076  0.006  0.116 ; ...
-0.082 -0.005  0.029  0.007 -0.066 -0.341 -0.037  0.007 -0.229 -0.022 -0.017  0.001  0.055 -0.033  0.072 ; ...
 0.078  0.021  0.061 -0.031  0.182  0.022 -0.070 -0.076  0.385 -0.114  0.028 -0.031  0.070  0.033 -0.052 ; ...
-0.028  0.057 -0.129  0.009 -0.095  0.104 -0.007  0.038 -0.086  0.011  0.042  0.049 -0.043 -0.073  0.033 ; ...
 0.031 -0.049  0.051 -0.015 -0.156 -0.363  0.001 -0.035 -0.117  0.079 -0.007  0.007  0.008  0.028  0.019 ; ...
 0.029 -0.019 -0.014 -0.007  0.060  0.123  0.016 -0.018  0.260 -0.036 -0.083 -0.038 -0.018 -0.004 -0.024 ; ...
 0.053  0.008 -0.009 -0.030 -0.041  0.045  0.095  0.062  0.022 -0.020  0.023 -0.076  0.013 -0.086  0.020 ; ...
-0.039 -0.048  0.068  0.002 -0.187 -0.277  0.075 -0.013 -0.171 -0.007 -0.025 -0.079 -0.007 -0.011  0.027 ; ...
-0.092  0.002 -0.060  0.030 -0.494  0.317 -0.105  0.030 -0.271  0.008 -0.069  0.037 -0.020  0.085 -0.085 ; ...
 0.010 -0.012 -0.066  0.003 -0.130  0.154 -0.080  0.005 -0.102 -0.049  0.009  0.020 -0.075 -0.078  0.010 ; ...
-0.011  0.002  0.068  0.055 -0.066 -0.308 -0.010 -0.099 -0.171  0.050 -0.042 -0.006 -0.011 -0.067  0.013 ; ...
 0.041 -0.020 -0.077 -0.095 -0.320  0.595 -0.076 -0.038 -0.273 -0.022 -0.012 -0.013 -0.019 -0.071 -0.042 ; ...
 0.034 -0.071 -0.071  0.037 -0.030 -0.002 -0.034 -0.013 -0.024  0.006 -0.025 -0.004 -0.054 -0.012  0.024 ; ...
 0.007 -0.045 -0.043 -0.050 -0.186 -0.274 -0.090 -0.047 -0.167 -0.060 -0.040  0.006  0.024  0.032 -0.024 ; ...
-0.013 -0.012 -0.064 -0.065 -0.082  0.213 -0.061 -0.043 -0.169 -0.007  0.014 -0.009 -0.031 -0.058 -0.052 ; ...
-0.005 -0.072 -0.015  0.080  0.034 -1.206 -0.030 -0.097  0.090  0.055 -0.075  0.012  0.002  0.117  0.116 ; ...
-0.027 -0.030 -0.043 -0.011 -0.060 -0.286  0.060 -0.058 -0.187 -0.032 -0.007 -0.040 -0.041 -0.029 -0.076 ; ...
-0.090 -0.038  0.086 -0.070  0.170  0.114 -0.040 -0.085 -0.073 -0.099 -0.007  0.030  0.018 -0.125 -0.047 ; ...
 0.020 -0.056 -0.035 -0.037  0.216 -1.823  0.029  0.015  0.197  0.027  0.000  0.052  0.022 -0.020  0.068 ; ...
-0.007  0.041 -0.014 -0.088  0.828  0.534 -0.011  0.009  0.018  0.072 -0.074 -0.040 -0.057  0.003 -0.090 ; ...
-0.009  0.049  0.067 -0.043 -0.039 -0.065  0.028  0.064 -0.064  0.018  0.008  0.038 -0.030  0.003 -0.005  ];
b0 = [  0.000 -0.007 -0.010  0.000 -0.139 -0.317  0.000  0.000 -0.176  0.000  0.000  0.000 -0.011  0.000  0.000  ];
W1 = [ ...
-0.015 -0.104 -0.060 ; ...
-0.046  0.018 -0.061 ; ...
 0.031 -0.001 -0.027 ; ...
 0.033  0.043  0.023 ; ...
-0.461  0.260  0.244 ; ...
-0.496  0.363 -0.224 ; ...
-0.009  0.007  0.045 ; ...
-0.061 -0.004 -0.072 ; ...
 0.379 -0.326 -0.159 ; ...
-0.008  0.043 -0.001 ; ...
-0.066 -0.015 -0.018 ; ...
 0.094 -0.032 -0.031 ; ...
 0.066 -0.008  0.053 ; ...
-0.008  0.129 -0.020 ; ...
 0.045 -0.052  0.049  ];
b1 = [ -1.597 -0.753  0.098  ];

nn.W0 = W0';
nn.b0 = b0';
nn.f0 = @relu;
nn.W1 = W1';
nn.b1 = b1';
nn.f1 = @sigmoid;

end

function [outputNN] = nnInput(nn, inputLayer)

z0 = nn.W0*inputLayer' + nn.b0;
a1 = nn.f0(z0);
z1 = nn.W1*a1 + nn.b1;
outputNN = nn.f1(z1);

end

function [y] = sigmoid(x)

y = ( 1 + exp(-x) ).^(-1);

end

function [y] = relu(x)

leak = 0.0;
y = max(x*leak, x);

end
