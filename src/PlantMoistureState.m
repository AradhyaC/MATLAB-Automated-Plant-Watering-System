% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Automated Plant Watering System
% Author: Aradhya Chawla
% Class: EECS 1011
% Section: Z
% Instructor: Professor Kai Zhuang
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


function [pState, point] = PlantMoistureState(a, waterModel, satModel, ...
        thresholdModel, dryModel, airModel, model, cState)
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Function PlantMoistureState
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% INPUTS:
% a                 : Arduino object
% satModel          : Sensor moisture level in water-saturated soil
% thresholdModel    : Sensor moisture level threshold to maintain
% dryModel          : Sensor moisture level in dry soil
% model             : Variable containing slope and/or intercept(s)
% cState            : Current state of plant
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% RETURNS:
% pState    : Final plant moisture state = if plant needs watering or not
% point     : Current moisture level of soil

pState = 0;             % Default value
meanVals = [0 0 0];     % pre-defined vector for mean value

for i = 1:3
    % Get point from mathematical model and sensor reading
    meanVals(i) = (readVoltage(a, 'A1') * model(1)) + model(2);
    
    % Set upper threshold to airModel
    if meanVals(i) > waterModel
        meanVals(i) = waterModel;
    end

    % Set lower threshold to waterModel
    if meanVals(i) < airModel
        meanVals(i) = airModel;
    end
end

% Getting average of 3 values for accuracy
point = mean(meanVals);

% If plant is completely dry: begin watering and prompt user
if point <= dryModel
    if cState == 0
        disp('PUMP STARTING: Soil is completely dry')
    end
    pState = 1;

% If plant needs some water: begin watering and prompt user
elseif point < thresholdModel && point > dryModel
    if cState == 0
        disp('PUMP STARTING: Soil needs some water')
    end
    pState = 1;

% If plant has enough water: stop pump and prompt user to avoid
% flooding
elseif point >= thresholdModel
    if cState == 1
        if point >= satModel
            disp('PUMP STOPPING: Soil has been saturated')
        else
            disp('PUMP STOPPING: Soil is wet enough')
        end
    end
    pState = 0;
end
