classdef trackable < handle
% The "trackable.trackable" class is used in conjunction with the OptiTrack
% tracking system to get state information of OptiTrack trackable objects
% into Matlab.
%
% NOTES:
%   To get more information on this class type "doc trackable.trackable" into the
%   command window.
%
% NECESSARY FILES AND/OR PACKAGES:
%   +trackable, quaternion.m
%
% SEE ALSO: TODO: Add see alsos
%    relatedFunction1 | relatedFunction2
%
% AUTHOR:
%    Rowland O'Flaherty (www.rowlandoflaherty.com)
%
% VERSION: 
%   Created 24-OCT-2012
%-------------------------------------------------------------------------------

%% Properties ------------------------------------------------------------------
properties (GetAccess = public, SetAccess = private)
    device % (string) Trackable device name
    host % (string) Server computer host name
    port % (string) Server port number
    
    validServer = false % (1 x 1 logical) True if the server connection is valid
end

properties (Access = protected)
    ticID % (1 x 1 number) Tic ID used with toc to get current running time.
end

properties (Access = public, Hidden = true)
    figHandle = [] % (1 x 1 graphics object) Figure handle for plot
    axisHandle = [] % (1 x 1 graphics object) Axis handle for plot
    graphicsHandles = [] % (? x 1 graphics objects) Graphics handles for plot
end

properties (SetAccess = private, GetAccess = protected, Hidden = true)
    settingFlag = false % (1 x l logical) Flag used to signal to other methods that properties time, position, orientation are in the process of being set.
end

properties (Access = private, Hidden = true)
    timeRaw_ = nan % (1 x 1 number) Raw time data
    timeOffset_ = 0 % (1 x 1 number) Time offset
    positionRaw_ = nan(3,1) % (3 x 1 number) Raw position data
    positionOffset_ = zeros(3,1) % (3 x 1 number) Position offset
    orientationRaw_ = quaternion(nan(4,1)) % (1 x 1 quaternion) Raw orientation data
    orientationOffset_ = quaternion([1;0;0;0]) % (1 x 1 quaternion) Orientation offset
    orientationLocalCorrection_ = quaternion([0 0 1; 0 -1 0; 1 0 0]) % (1 x 1 quaternion) Used to realign local reference of trackable.
    orientationGlobalCorrection_ = quaternion([0 0 1; 0 1 0; -1 0 0]) % (1 x 1 quaternion) Used to realign global of orientation reference frame with position refernce frame.
end

properties (Dependent = true, SetAccess = public)
    time % (1 x 1 number) Current time
    position % (3 x 1 number) Current position [Cartesian (x,y,z)]
    orientation % (1 x 1 quaternion) Current orientation
end

properties (GetAccess = public, SetAccess = private)
    velocity = nan(3,1) % (3 x 1 number) Current velocity
    angularVelocity = nan(3,1) % (3 x 1 number) Current angular velocity
end

properties (Dependent = true, SetAccess = private)
    transform % (4 x 4 number) Homogeneous tranform matrix of current position and orientation.
end

properties (Access = public)
    coordScale = [1;1;1]; % (3 x 1 positive numbers) Scaling of raw coordinates (this is applied before coordinates are rotated to desired coordinates).
    coordOrientation = quaternion(); % (1 x 1 quaternion) Orientation of desired coordinates in raw coordinates.
    tapeFlag = false % (1 x 1 logical) If true tape recorder is on.
end

properties (GetAccess = public, SetAccess = private)
    tapeLength = 0; % (1 x 1 positive integer) Length of record tapes.
end

properties (GetAccess = public, SetAccess = private, Hidden = true)
    timeTapeVec = nan(1,0) % (1 x ? number) Recording of update times.
    positionTapeVec = nan(3,0) % (3 x ? number) Recording of past positions.
    orientationTapeVec = quaternion.empty(1,0) % (1 x ? quaternion) Recording of past orientations.
    velocityTapeVec = nan(3,0) % (3 x ? number) Recording of past velocities.
    angularVelocityTapeVec = nan(3,0) % (3 x ? number) Recording of past angular velocities.
end

properties (Dependent = true, SetAccess = private)
    timeTape % (1 x ? number) Recording of update times.
    positionTape % (3 x ? number) Recording of past positions.
    orientationTape % (1 x ? quaternion) Recording of past orientations.
    velocityTape % (3 x ? number) Recording of past velocities.
    angularVelocityTape % (3 x ? number) Recording of past angular velocities.
end

properties (Dependent = true, SetAccess = private, Hidden = true)
   tapeVecSize % (1 x 1 positive integer) % Actual size of tape vectors
end

properties (GetAccess = public, SetAccess = private, Hidden = true) 
    tapeCatSize = 500; % (1 x 1 positive integer) % Size to increase tape vectors when they fill up
end

%% Constructor -----------------------------------------------------------------
methods
    function trackableObj = trackable(device,host,port)
        % Constructor function for the "trackable" class.
        %
        % SYNTAX:
        %   trackableObj = trackable(device,host,port)
        %
        % INPUTS:
        %   device - (string) [''] 
        %       Sets the "trackableObj.device" property.
        %
        %   host - (string) [''] 
        %       Sets the "trackableObj.host" property.
        %
        %   port - (string) [''] 
        %       Sets the "trackableObj.port" property.
        %
        % OUTPUTS:
        %   trackableObj - (1 x 1 trackable object) 
        %       A new instance of the "trackable.trackable" class.
        %
        % NOTES:
        %
        %-----------------------------------------------------------------------
        
        % Check number of arguments
        narginchk(0,3)

        % Apply default values
        if nargin < 1, device = ''; end
        if nargin < 2, host = ''; end
        if nargin < 3, port = ''; end

        % Check input arguments for errors
        assert(ischar(device),...
            'trackable:trackable:device',...
            'Input argument "device" must be a string.')
        
        assert(ischar(host),...
            'trackable:trackable:host',...
            'Input argument "host" must be a string.')
        
        assert(ischar(port),...
            'trackable:trackable:port',...
            'Input argument "port" must be a string.')
        
        
        % Assign properties
        trackableObj.device = device;
        if ~isempty(device) && ~isempty(host) && ~isempty(port)
            trackableObj.setServerInfo(device,host,port);
        end
        trackableObj.ticID = tic;
    end
end
%-------------------------------------------------------------------------------

%% Destructor ------------------------------------------------------------------
% methods (Access = public)
%     function delete(trackableObj)
%         % Destructor function for the "trackableObj" class.
%         %
%         % SYNTAX:
%         %   delete(trackableObj)
%         %
%         % INPUTS:
%         %   trackableObj - (1 x 1 trackable.trackable)
%         %       An instance of the "trackable.trackable" class.
%         %
%         % NOTES:
%         %
%         %-----------------------------------------------------------------------
%         
%     end
% end
%-------------------------------------------------------------------------------

%% Property Methods ------------------------------------------------------------
methods
    function trackableObj = set.coordScale(trackableObj,coordScale)  %#ok<*MCHV2>
        % Overloaded assignment operator function for the "coordScale" property.
        %
        % SYNTAX:
        %   trackableObj.coordScale = coordScale
        %
        % INPUT:
        %   coordScale - (3 x 1 positive number)
        %
        % NOTES:
        %
        %-----------------------------------------------------------------------
        assert(isnumeric(coordScale) && isreal(coordScale) && numel(coordScale) == 3 && all(coordScale > 0),...
            'trackable:trackable:set:coordScale',...
            'Property "coordScale" must be set to a 3 x 1 positive number.')
        coordScale = coordScale(:);
        
        trackableObj.coordScale = coordScale;
    end
    
    function trackableObj = set.coordOrientation(trackableObj,coordOrientation)  %#ok<*MCHV2>
        % Overloaded assignment operator function for the "coordOrientation" property.
        %
        % SYNTAX:
        %   trackableObj.coordOrientation = coordOrientation
        %
        % INPUT:
        %   coordOrientation - (1 x 1 quaternion)
        %
        % NOTES:
        %
        %-----------------------------------------------------------------------
        assert(isa(coordOrientation,'quaternion') && numel(coordOrientation) == 1,...
            'trackable:trackable:set:coordOrientation',...
            'Property "coordOrientation" must be set to a 1 x 1 quaternion.')
        
        trackableObj.coordOrientation = coordOrientation;
    end
    
    function trackableObj = set.tapeFlag(trackableObj,tapeFlag)  %#ok<*MCHV2>
        % Overloaded assignment operator function for the "tapeFlag" property.
        %
        % SYNTAX:
        %   trackableObj.tapeFlag = tapeFlag
        %
        % INPUT:
        %   tapeFlag - (1 x 1 logical)
        %
        % NOTES:
        %
        %-----------------------------------------------------------------------
        assert((islogical(tapeFlag) && numel(tapeFlag) == 1) || ...
            strcmp(tapeFlag,'Off') || strcmp(tapeFlag,'On'),...
            'trackable:trackable:set:tapeFlag',...
            'Property "tapeFlag" must be set to a 1 x 1 logical.')
        
        if strcmp(tapeFlag,'Off')
            tapeFlag = false;
        elseif strcmp(tapeFlag,'On')
            tapeFlag = true;
        elseif ~tapeFlag
            trackableObj.writeToTape(nan,nan(3,1),quaternion(nan(4,1)),nan(3,1),nan(3,1));
        end
        trackableObj.tapeFlag = tapeFlag;
    end
    
    function trackableObj = set.time(trackableObj,time) 
        % Overloaded assignment operator function for the "time" property.
        %
        % SYNTAX:
        %   trackableObj.time = time
        %
        % INPUT:
        %   time - (1 x 1 real number)
        %
        % NOTES:
        %
        %-----------------------------------------------------------------------
        assert(isnumeric(time) && isreal(time) && numel(time) == 1,...
            'trackable:trackable:set:time',...
            'Property "time" must be set to a 1 x 1 real number.')
        
        % Briefly turn off tape for this update
        tapeFlag = trackableObj.tapeFlag;
        if tapeFlag
            tapeFlag = 'On';
        else
            tapeFlag = 'Off';
        end
        trackableObj.tapeFlag = 'Off';
        trackableObj.settingFlag = true;
        trackableObj.update();
        trackableObj.settingFlag = false;
        trackableObj.tapeFlag = tapeFlag; % Reset tapeFlag
        
        if isnan(trackableObj.timeRaw_)
            trackableObj.timeRaw_ = time;
        end
        trackableObj.timeOffset_ = trackableObj.timeRaw_ - time;
        
        if trackableObj.tapeFlag
            trackableObj.writeToTape();
        end
    end
    
    function trackableObj = set.position(trackableObj,position) 
        % Overloaded assignment operator function for the "position" property.
        %
        % SYNTAX:
        %   trackableObj.position = position
        %
        % INPUT:
        %   position - (3 x 1 real number)
        %
        % NOTES:
        %
        %-----------------------------------------------------------------------
        assert(isnumeric(position) && isreal(position) && numel(position) == 3,...
            'trackable:trackable:set:position',...
            'Property "position" must be set to a 3 x 1 real number.')
        position = position(:);
        
        % Briefly turn off tape for this update
        tapeFlag = trackableObj.tapeFlag;
        if tapeFlag
            tapeFlag = 'On';
        else
            tapeFlag = 'Off';
        end
        trackableObj.tapeFlag = 'Off';
        trackableObj.settingFlag = true;
        trackableObj.update();
        trackableObj.settingFlag = false;
        trackableObj.tapeFlag = tapeFlag; % Reset tapeFlag
        
        if any(isnan(trackableObj.positionRaw_))
            trackableObj.positionRaw_ = position;
        end
        trackableObj.positionOffset_ = trackableObj.positionRaw_ - position;
        
        if trackableObj.tapeFlag
            trackableObj.writeToTape();
        end
    end
    
    function trackableObj = set.orientation(trackableObj,orientation) 
        % Overloaded assignment operator function for the "orientation" property.
        %
        % SYNTAX:
        %   trackableObj.orientation = orientation
        %
        % INPUT:
        %   orientation - (1 x 1 quaternion or 4 x 1 real number with the norm equal to 1)
        %
        % NOTES:
        %   A warning is displayed if the norm of the argument
        %   "orientation" is greater than 0.01 units from from 1;
        %
        %-----------------------------------------------------------------------
        assert((isa(orientation,'quaternion') && numel(orientation) == 1 ) || ...
            (isnumeric(orientation) && isreal(orientation) && numel(orientation) == 4),...
            'trackable:trackable:set:orientation',...
            'Property "orientation" must be a 1 x 1 quaternion or a 4 x 1 real number.')
        
        if ~isa(orientation,'quaternion')
            orientation = orientation(:);
            if abs(norm(orientation) - 1) > .01;
                warning('trackable:trackable:set:orientation',...
                    'Property "orientation" norm is not very close to 1. (Norm = %.3f)',norm(orientation))
            end
            orientation = orientation / norm(orientation);
            orientation = quaternion(orientation);
        end
        
        % Briefly turn off tape for this update
        tapeFlag = trackableObj.tapeFlag;
        if tapeFlag            
            tapeFlag = 'On';
        else
            tapeFlag = 'Off';
        end
        trackableObj.tapeFlag = 'Off';
        trackableObj.settingFlag = true;
        trackableObj.update();
        trackableObj.settingFlag = false;
        trackableObj.tapeFlag = tapeFlag; % Reset tapeFlag
        
        if isnan(trackableObj.orientationRaw_)
            trackableObj.orientationRaw_ = orientation;
        end
        
        trackableObj.orientationOffset_ = orientation' * trackableObj.orientationRaw_;
        
        if trackableObj.tapeFlag
            trackableObj.writeToTape();
        end
    end

    function time = get.time(trackableObj)
        % Overloaded query operator function for the "time" property.
        %
        % SYNTAX:
        %	  time = trackableObj.time
        %
        % OUTPUT:
        %   time - (1 x 1 number)
        %       Time updated with offset.
        %
        % NOTES:
        %
        %-----------------------------------------------------------------------

        time = trackableObj.timeRaw_ - trackableObj.timeOffset_;
    end
    
    function position = get.position(trackableObj)
        % Overloaded query operator function for the "position" property.
        %
        % SYNTAX:
        %	  position = trackableObj.position
        %
        % OUTPUT:
        %   position - (3 x 1 number)
        %       Position updated with offset.
        %
        % NOTES:
        %
        %-----------------------------------------------------------------------

        position = trackableObj.positionRaw_ - trackableObj.positionOffset_;
    end
    
    function orientation = get.orientation(trackableObj)
        % Overloaded query operator function for the "orientation" property.
        %
        % SYNTAX:
        %	  orientation = trackableObj.orientation
        %
        % OUTPUT:
        %   orientation - (1 x 1 quaternion)
        %       Orientation updated with offset.
        %
        % NOTES:
        %
        %-----------------------------------------------------------------------
        
        orientation = trackableObj.orientationRaw_ * trackableObj.orientationOffset_';
    end
    
    function transform = get.transform(trackableObj)
        % Overloaded query operator function for the "transform" property.
        %
        % SYNTAX:
        %	  transform = trackableObj.transform
        %
        % OUTPUT:
        %   transform - (4 x 4 number)
        %       Homogenous transform matrix.
        %
        % NOTES:
        %   See http://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
        %
        %-----------------------------------------------------------------------
        
        p = trackableObj.position;
        r = trackableObj.orientation.rot;

        transform = [r p;[zeros(1,3) 1]];
    end
    
    function timeTape = get.timeTape(trackableObj)
        % Overloaded query operator function for the "timeTape" property.
        %
        % SYNTAX:
        %	  timeTape = trackableObj.timeTape
        %
        % OUTPUT:
        %   timeTape - (1 x ? number)
        %       Time record vector.
        %
        % NOTES:
        %
        %-----------------------------------------------------------------------
        
        timeTape = trackableObj.timeTapeVec(:,1:trackableObj.tapeLength);
    end
    
    function positionTape = get.positionTape(trackableObj)
        % Overloaded query operator function for the "positionTape" property.
        %
        % SYNTAX:
        %	  positionTape = trackableObj.positionTape
        %
        % OUTPUT:
        %   positionTape - (3 x ? number)
        %       Position record vector.
        %
        % NOTES:
        %
        %-----------------------------------------------------------------------
        
        positionTape = trackableObj.positionTapeVec(:,1:trackableObj.tapeLength);
    end
    
    function orientationTape = get.orientationTape(trackableObj)
        % Overloaded query operator function for the "orientationTape" property.
        %
        % SYNTAX:
        %	  orientationTape = trackableObj.orientationTape
        %
        % OUTPUT:
        %   orientationTape - (1 x ? number)
        %       Orientation record vector.
        %
        % NOTES:
        %
        %-----------------------------------------------------------------------
        
        orientationTape = trackableObj.orientationTapeVec(:,1:trackableObj.tapeLength);
    end
    
    function velocityTape = get.velocityTape(trackableObj)
        % Overloaded query operator function for the "velocityTape" property.
        %
        % SYNTAX:
        %	  velocityTape = trackableObj.velocityTape
        %
        % OUTPUT:
        %   velocityTape - (3 x ? number)
        %       Velocity record vector.
        %
        % NOTES:
        %
        %-----------------------------------------------------------------------
        
        velocityTape = trackableObj.velocityTapeVec(:,1:trackableObj.tapeLength);
    end
    
    function angularVelocityTape = get.angularVelocityTape(trackableObj)
        % Overloaded query operator function for the "angularVelocityTape" property.
        %
        % SYNTAX:
        %	  angularVelocityTape = trackableObj.angularVelocityTape
        %
        % OUTPUT:
        %   angularVelocityTape - (3 x ? number)
        %       Angular velocity record vector.
        %
        % NOTES:
        %
        %-----------------------------------------------------------------------
        
        angularVelocityTape = trackableObj.angularVelocityTapeVec(:,1:trackableObj.tapeLength);
    end
    
    function tapeVecSize = get.tapeVecSize(trackableObj)
        % Overloaded query operator function for the "tapeVecSize" property.
        %
        % SYNTAX:
        %	  tapeVecSize = trackableObj.tapeVecSize
        %
        % OUTPUT:
        %   tapeVecSize - (1 x 1 positive integer)
        %       Orientation record vector.
        %
        % NOTES:
        %
        %-----------------------------------------------------------------------
        
        tapeVecSize = size(trackableObj.timeTapeVec,2);
    end
end
%-------------------------------------------------------------------------------

%% General Methods -------------------------------------------------------------
methods (Access = public)
    function validServer = setServerInfo(trackableObj,device,host,port)
        % The "setServerInfo" method updates the server information for
        % this trackable object.
        %
        % SYNTAX:
        %   validServer = trackableObj.setServerInfo(device,host,port)
        %
        % INPUTS:
        %   trackableObj - (1 x 1 trackable.trackable)
        %       An instance of the "trackable.trackable" class.
        %
        %   device - (string)
        %       Trackable device name.
        %
        %   host - (string)
        %       Server computer host name.
        %
        %   port - (string)
        %       Server port number.
        %
        % OUTPUTS:
        %   validServer - (1 x 1 logical) 
        %       True if the server is valid and producing data.
        %
        % NOTES:
        %
        %-----------------------------------------------------------------------

        % Check number of arguments
        narginchk(4,4)
        
        % Check arguments for errors
        assert(~isempty(device) && ischar(device),...
            'trackable:trackable:setServerInfo:device',...
            'Input argument "device" must be a non-empty string.')
        
        assert(~isempty(host) && ischar(host),...
            'trackable:trackable:setServerInfo:host',...
            'Input argument "host" must be a non-empty string.')
        
        assert(~isempty(port) && ischar(port),...
            'trackable:trackable:setServerInfo:port',...
            'Input argument "port" must be a non-empty string.')
        
        trackableObj.device = device;
        trackableObj.host = host;
        trackableObj.port = port;
        trackableObj.validate();
        validServer = trackableObj.validServer;
    end
    
    function resetTape(trackableObj)
        % The "clearTape" method resets the tape records back to nothing.
        %
        % SYNTAX:
        %   trackableObj.resetTape()
        %
        % INPUTS:
        %   trackableObj - (1 x 1 trackable.trackable)
        %       An instance of the "trackable.trackable" class.
        %
        % OUTPUTS:
        %
        % NOTES:
        %
        %-----------------------------------------------------------------------
        
        trackableObj.tapeLength = 0;
        trackableObj.timeTapeVec = nan(1,0);
        trackableObj.positionTapeVec = nan(3,0);
        trackableObj.orientationTapeVec = quaternion.empty(1,0);
        trackableObj.velocityTapeVec = nan(3,0);
        trackableObj.angularVelocityTapeVec = nan(3,0);
        
    end
end

methods (Access = private)
    function writeToTape(trackableObj,time,position,orientation,velocity,angularVelocity)
        % The "writeToTape" method sets adds data to the tape properties.
        %
        % SYNTAX:
        %   trackableObj.writeToTape(time,position,orientation)
        %
        % INPUTS:
        %   trackableObj - (1 x 1 trackable.trackable)
        %       An instance of the "trackable.trackable" class.
        %
        %   time - (1 x 1 number)
        %       Time value recorded to the "timeTape" property.
        %
        %   position - (3 x 1 number)
        %       Position value recorded to the "positionTape" property.
        %
        %   orientation - (1 x 1 number)
        %       Orientation value recorded to the "orientationTape" property.
        %
        %   velocity - (3 x 1 number)
        %       Velocity value recorded to the "velocityTape" property.
        %
        %   angularVelocity - (3 x 1 number)
        %       Angular velocity value recorded "angularVelocityTape"
        %       property.
        %
        % NOTES:
        %
        %-----------------------------------------------------------------------
        
        if nargin < 2, time = trackableObj.time; end
        if nargin < 3, position = trackableObj.position; end
        if nargin < 4, orientation = trackableObj.orientation; end
        if nargin < 5, velocity = trackableObj.velocity; end
        if nargin < 6, angularVelocity = trackableObj.angularVelocity; end
        
        if trackableObj.tapeLength + 1 > trackableObj.tapeVecSize % Increase vector size
            trackableObj.timeTapeVec = [trackableObj.timeTapeVec nan(1,trackableObj.tapeCatSize)];
            trackableObj.positionTapeVec = [trackableObj.positionTapeVec nan(3,trackableObj.tapeCatSize)];
            trackableObj.orientationTapeVec = [trackableObj.orientationTapeVec repmat(quaternion(nan(4,1)),1,trackableObj.tapeCatSize)];
            trackableObj.velocityTapeVec = [trackableObj.velocityTapeVec nan(3,trackableObj.tapeCatSize)];
            trackableObj.angularVelocityTapeVec = [trackableObj.angularVelocityTapeVec nan(3,trackableObj.tapeCatSize)];
        end
        trackableObj.tapeLength = trackableObj.tapeLength + 1;
        trackableObj.timeTapeVec(:,trackableObj.tapeLength) = time;
        trackableObj.positionTapeVec(:,trackableObj.tapeLength) = position;
        trackableObj.orientationTapeVec(:,trackableObj.tapeLength) = orientation;
        trackableObj.velocityTapeVec(:,trackableObj.tapeLength) = velocity;
        trackableObj.angularVelocityTapeVec(:,trackableObj.tapeLength) = angularVelocity;
    end
end
%-------------------------------------------------------------------------------

%% Methods in separte files ----------------------------------------------------
methods (Access = public)
    validate(trackableObj)
    update(trackableObj,timeRaw,positionRaw,orientationRaw)
    plot(trackableObj)
end
%-------------------------------------------------------------------------------
    
end
