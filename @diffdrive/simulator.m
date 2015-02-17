function [timePlus,posPlus,oriPlus] = simulator(diffdriveObj,timeStep,time,pos,ori,motor)
% The "simulator" method used to simulate the diffdrive.
%
% SYNTAX:
%   [timePlus,posPlus,oriPlus] = diffdriveObj.simulator()
%   [timePlus,posPlus,oriPlus] = diffdriveObj.simulator(timeStep)
%   [timePlus,posPlus,oriPlus] = diffdriveObj.simulator(timeStep,time)
%   [timePlus,posPlus,oriPlus] = diffdriveObj.simulator(timeStep,time,pos)
%   [timePlus,posPlus,oriPlus] = diffdriveObj.simulator(timeStep,time,pos,ori)
%   [timePlus,posPlus,oriPlus] = diffdriveObj.simulator(timeStep,time,pos,ori,motor)
%
% INPUTS:
%   diffdriveObj - (1 x 1 diffdrive)
%       An instance of the "diffdrive" class.
%
%   timeStep - (1 x 1 number)
%       Amount of time to simulate for.
%
%   time - (1 x 1 number) [diffdriveObj.time]
%       Time to simulate from.
%
%   pos - (3 x 1 number) [diffdriveObj.position]
%       Position to simulate from.
%
%   ori - (1 x 1 quaternion) [diffdriveObj.orientation]
%       Orientation to simulate from.
%
%   motor - (2 x 1 number) [diffdriveObj.motor]
%       Motor values to use for simulation.
%
% OUTPUTS:
%   timePlus - (1 x 1 number)
%       Updated simulated robot time.
%
%   posPlus - (3 x 1 number)
%       Updated simulated robot position.
%
%   oriPlus - (1 x 1 quaternion)
%       Updated simulated robot orientation.
%
% NOTES:
%
% NECESSARY FILES AND/OR PACKAGES:
%
% SEE ALSO:
%
% AUTHOR:
%    Rowland O'Flaherty (www.rowlandoflaherty.com) 13-FEB-2015
%--------------------------------------------------------------------------

%% Check Input Arguments

% Check number of arguments
narginchk(1,6)

% Apply default values
if nargin < 2, timeStep = diffdriveObj.timeStep; end
if nargin < 3, time = diffdriveObj.timeSim_; end
if nargin < 4, pos = diffdriveObj.positionSim_; end
if nargin < 5, ori = diffdriveObj.orientationSim_; end
if nargin < 6, motor = diffdriveObj.motor; end

% Check arguments for errors
assert(isnumeric(timeStep) && isreal(timeStep) && numel(timeStep) == 1,...
    'diffdrive:simulator:timeStep',...
    'Input argument "timeStep" must be a 1 x 1 real number.')

assert(isnumeric(time) && isreal(time) && numel(time) == 1,...
    'diffdrive:simulator:time',...
    'Input argument "time" must be a 1 x 1 real number.')

assert(isnumeric(pos) && isreal(pos) && numel(pos) == 3,...
    'diffdrive:simulator:pos',...
    'Input argument "pos" must be a 3 x 1 real number.')
pos = pos(:);

assert(isa(ori,'quaternion') && numel(ori) == 1,...
    'diffdrive:simulator:ori',...
    'Input argument "ori" must be a 1 x 1 real number.')

assert(isnumeric(motor) && isreal(motor) && numel(motor) == 2,...
    'diffdrive:simulator:motor',...
    'Input argument "motor" must be a 2 x 1 real number.')
motor = motor(:);

%% Variables

%% Simulate one step forward
if ~isnan(time)
    timePlus = time + timeStep;
    [v,w] = diffdriveObj.motorValues2linAngVel(motor);
    xD = ori*[v;0;w];
    theta = ori.yaw;
    x = [pos(1:2);theta] + xD * timeStep;
    posPlus = [x(1:2); pos(3)];
    oriPlus = quaternion([0 0 x(3)]); 
else
    timePlus = 0;
    posPlus = [0 0 0]';
    oriPlus = quaternion([0;0;1],0);
end

end