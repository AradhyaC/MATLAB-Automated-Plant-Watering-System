% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Automated Plant Watering System
% Author: Aradhya Chawla
% Class: EECS 1011
% Section: Z
% Instructor: Professor Kai Zhuang
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


% Clear all variables; Close all figures; Clear all previous outputs
clear all; close all; clc;

% Define arduino object
a = arduino('COM4','Uno');

% Constants
airMoisture = 3.59;         % Voltage of sensor in open air
dryMoisture = 3.45;         % Voltage of sensor in dry soil
thresholdMoisture = 3.1;    % Voltage of sensor in perfect soil moisture
satMoisture = 2.98;         % Voltage of sensor in water-saturated soil
waterMoisture = 2.58;       % Voltage of sensor in water

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Graph showing a mathematical Model of the Moisture Sensor
mFig = figure(1);
mFig.Units = 'normalized';
mFig.Position = [0 0.5 0.5 0.38];
ax1 = gca;
x = [waterMoisture airMoisture];
y = [1 0];

% Contains model properties; slope and intercepts
model = polyfit(x,y,1);
xModel = [3.8, 2.4];
yModel = polyval(model, xModel);

% Voltage values converted to Moisture model
airModel = ((airMoisture * model(1)) + model(2));
dryModel = ((dryMoisture * model(1)) + model(2));
thresholdModel = ((thresholdMoisture * model(1)) + model(2));
satModel = ((satMoisture * model(1)) + model(2));
waterModel = ((waterMoisture * model(1)) + model(2));

% Plot relevant markers and fit line
hold on
plot(xModel,yModel,'Color','#D95319');
plot([waterMoisture satMoisture dryMoisture airMoisture], ...
    [waterModel satModel dryModel airModel], ...
    '.','MarkerSize',20,'Color','#0072BD')

% Add labels to markers
text(waterMoisture + 0.04,waterModel+0.01,'water moisture')
text(satMoisture + 0.04,satModel+0.01,'water-saturated soil moisture')
text(dryMoisture - 0.25,dryModel+0.01,'dry soil moisture')
text(airMoisture - 0.2,airModel,'air moisture')

% Add title and labels to axes
title('Model of Grove Capacitive Moisture Sensor')
xlabel('Sensor Voltage (𝒱)')
ylabel('Soil Wetness (𝒮)')
hold off

% Final Equation from model properties
if model(2) ~= 0
    modelEquation = '𝒮 = '+string(model(1))+'𝒱 + '+string(model(2));
else
    modelEquation = '𝒮 = '+string(model(1))+'𝒱';
end
text(3.2,0.9,modelEquation)     % Show equation on graph

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Live graph of soil moisture (x) vs time (y)
live = figure(2);
live.Units = 'normalized';
live.Position = [0 0 0.5 0.5];

% Moisture level line
moist_line = animatedline;

% Water moisture level line
wLine = animatedline('Color','#0072BD','LineStyle','--');

% Saturated soil moisture level line
sLine = animatedline('Color','#4DBEEE','LineStyle','--');

% Threshold moisture level line
tLine = animatedline('Color','#77AC30','LineStyle','--');

% Dry soil moisture level line
dLine = animatedline('Color','#EDB120','LineStyle','--');

% Air moisture level line
aLine = animatedline('Color','r','LineStyle','--');

ax2 = gca;
title('Moisture Level of Soil over Time')
ylabel('Moisture Level of Soil')
xlabel('Time [HH:MM:SS]')

% Setting y-limits to view whole graph and annotations
ax2.YLim = [-0.1 1.5];

stop = false;                   % Emergency break state
startTime = datetime('now');    % Time before first measurment
tic;                            % Timer
cState = 0;                     % current state of plant




while ~stop
    [~] = toc;      % [~] removes unnecessary "Elapsed Time" output
    
    % Gets difference between current time and start time = Elapsed time
    t = datetime('now') - startTime;
    
    % Threshold moisture level with fine adjustment using potentiometer
    tFineAdjust = round(((readVoltage(a, 'A0')/5)-0.5),2);
    adjThresholdModel = thresholdModel+tFineAdjust;

    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % Call PlantMoistureState function to get current state of plant
    [pState, point] = PlantMoistureState(a, waterModel, satModel, ...
        adjThresholdModel, dryModel, airModel, model, cState);
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    % Adds moisture level point and elapsed time to graph
    addpoints(wLine,datenum(t),waterModel);
    addpoints(sLine,datenum(t),satModel);
    addpoints(tLine,datenum(t),adjThresholdModel);
    addpoints(dLine,datenum(t),dryModel);
    addpoints(aLine,datenum(t),airModel);
    addpoints(moist_line,datenum(t),point);

    % Keeps graph x-axis moving within a 15-second window
    ax2.XLim = datenum([t-seconds(15) t]);

    % Adds and updates Threshold value annotation
    aCol = 'black';
    if tFineAdjust ~= 0
        aCol = 'red';
    else
        aCol = 'black';
    end
    delete(findall(live,'Tag','thresholdBox'));
    annotStr = {'Soil Moisture Threshold', ...
        string(thresholdModel)+'+('+string(tFineAdjust)+') = '+ ...
        string(adjThresholdModel)};
    annotation(live,'textbox',[0.2 0.9 0 0], 'String',annotStr, ...
        'FitBoxToText','on', 'Tag', 'thresholdBox',Color=aCol);

    lgd = legend(ax2, ...
        '  Current Moisture', ...
        '  Water', ...
        '  Water-Saturated Soil', ...
        '  Threshold (Adjusted)', ...
        '  Dry Soil', ...
        '  Air');
    lgd.FontSize = 5;
    title(lgd, 'Moisture Levels Legend')

    % Changes x-ticks to time and perserves x limits defined by XLim
    datetick(ax2,'x','keeplimits');
    drawnow;    % Update figure

    % Changes arduino modules' states according to plant state
    if pState == 1
        writeDigitalPin(a,"D7",1)       % Activate pump
        writeDigitalPin(a,"D4",1)       % Switch on indicator light
        writePWMDutyCycle(a,"D5",0.8)   % Switch on buzzer
        cState = pState;
    elseif pState == 0
        writeDigitalPin(a,"D7",0)       % De-activate pump
        writeDigitalPin(a,"D4",0)       % Switch off indicator light
        writePWMDutyCycle(a,"D5",0)     % Switch off buzzer
        cState = pState;
    end

    % Emergency break button
    stop = readDigitalPin(a,"D6");
end

% If Emergency break button activated: 
% stop pump, light, buzzer, and prompt user
writeDigitalPin(a,"D7",0)
writeDigitalPin(a,"D4",0)
writePWMDutyCycle(a,"D5",0)
disp('EMERGENCY STOP')
