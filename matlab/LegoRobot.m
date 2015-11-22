classdef LegoRobot < Robot

    properties (Constant)
        BLUETOOTH_ADDRESS = '0016530BAFBE';
        COLOR_PORT = lego.NXT.IN_1;
        COLOR_LINE = 2; % BLUE (lego.NXT.SENSOR_TYPE_COLORBLUE;)
        COLOR_INTERACT = 5; % RED (lego.NXT.SENSOR_TYPE_COLORRED;)
        COLOR_BACKGROUND = 6; % WHITE (lego.NXT.SENSOR_TYPE_LIGHT_INACTIVE;)
        
        ULTRASONIC_PORT = lego.NXT.IN_2;

        LEFT_MOTOR = lego.NXT.OUT_A;
        RIGHT_MOTOR = lego.NXT.OUT_C;
        BOTH_MOTORS = lego.NXT.OUT_AC;
        
        MOTOR_POWER_PERCENT = 60;
        
        CENTIMETERS_PER_SECOND = 17.75;
        DEGREES_ROTATE_PER_SECOND = 190;
        ROTATE_TIME_PERCENT_POWER = 60;
        
        TIRE_DIAMETER_CENTIMETERS = 4.3;
        TIRE_RADIUS_CENTIMETERS = LegoRobot.TIRE_DIAMETER_CENTIMETERS / 2;
        TIRE_CIRCUMFERENCE_CENTIMETERS = ...
            2 * pi * LegoRobot.TIRE_RADIUS_CENTIMETERS;
        DEGREES_PER_CENTIMETER = ...
            360 / LegoRobot.TIRE_CIRCUMFERENCE_CENTIMETERS;
    end
    
    properties (Access=private)
        brick
    end

    methods
        function obj = LegoRobot()
            obj.brick = lego.NXT(LegoRobot.BLUETOOTH_ADDRESS);
            obj.brick.setSensorColorFull(LegoRobot.COLOR_PORT);
            obj.brick.setSensorUltrasonic(LegoRobot.ULTRASONIC_PORT);
        end
        
        function shutdown(obj)
            obj.brick.close()
        end
        
        function allStop(obj)
            obj.brick.motorBrake(LegoRobot.BOTH_MOTORS);
        end
        
        function distanceState = getDistanceState(obj)
            distanceState = obj.brick.sensorValue(LegoRobot.ULTRASONIC_PORT);
        end

        function positionState = getPositionState(obj)
            color = obj.brick.sensorValue(LegoRobot.COLOR_PORT);
            if color == LegoRobot.COLOR_LINE
                positionState = Robot.STATE_ON_LINE;
            elseif color == LegoRobot.COLOR_INTERACT
                positionState = Robot.STATE_ON_INTERACTION;
            elseif color == LegoRobot.COLOR_BACKGROUND
                positionState = Robot.STATE_OFF_LINE;
            else
                %fprintf('Not processing color %d\n', color);
                positionState = Robot.STATE_INVALID;
            end
        end

        function leftMotorForward(obj, powerPercent)
            obj.brick.motorForward(LegoRobot.LEFT_MOTOR,...
                                   powerPercent);
        end

        function rightMotorForward(obj, powerPercent)
            obj.brick.motorForward(LegoRobot.RIGHT_MOTOR,...
                                   powerPercent);
        end

        function leftMotorReverse(obj, powerPercent)
            obj.brick.motorReverse(LegoRobot.LEFT_MOTOR,...
                                   powerPercent);
        end

        function rightMotorReverse(obj, powerPercent)
            obj.brick.motorReverse(LegoRobot.RIGHT_MOTOR,...
                                   powerPercent);
        end
        
        function motorForwardRegulated(obj, motorId, powerPercent)
            obj.brick.motorForwardReg(motorId, powerPercent);
        end
        
        function motorReverseRegulated(obj, motorId, powerPercent)
            obj.brick.motorReverseReg(motorId, powerPercent);
        end
        
        function straightForward(obj, powerPercent)
            obj.brick.motorForward(LegoRobot.BOTH_MOTORS,...
                                   powerPercent);
        end
        
        function straightBack(obj, powerPercent)
            obj.brick.motorReverse(LegoRobot.BOTH_MOTORS,...
                                   powerPercent);
        end
        
        function straightForwardRegulated(obj, powerPercent)
            obj.brick.motorForwardReg(LegoRobot.BOTH_MOTORS, powerPercent);
        end
        
        function straightReverseRegulated(obj, powerPercent)
            obj.brick.motorReverseReg(LegoRobot.BOTH_MOTORS, powerPercent);
        end
        
        function forwardCentimetersDegrees(obj, distanceCentimeters,...
                                           powerPercent)
            degrees = distanceCentimeters * LegoRobot.DEGREES_PER_CENTIMETER;
            obj.brick.motorRotateExt(...
                LegoRobot.BOTH_MOTORS, powerPercent, degrees, 0, true,...
                true);
        end
        
        function reverseCentimetersDegrees(obj, distanceCentimeters,...
                                           powerPercent)
            degrees = ...
                -(distanceCentimeters * LegoRobot.DEGREES_PER_CENTIMETER);
            obj.brick.motorRotateExt(...
                LegoRobot.BOTH_MOTORS, powerPercent, degrees, 0, true,...
                true);
        end
        
        function moveDegrees(obj, degrees, powerPercent)
            obj.brick.motorRotateExt(...
                LegoRobot.BOTH_MOTORS, powerPercent, degrees, 0, true,...
                true);
        end
        
        function rotateDegrees(obj, angleDegrees, powerPercent)
            tireDegreesPerRobotDegrees = 2;
            tireAngle = angleDegrees * tireDegreesPerRobotDegrees;
            if angleDegrees >= 0
                turnPercent = 10;
            else
                turnPercent = -10;
            end
            obj.brick.motorRotateExt(LegoRobot.BOTH_MOTORS,...
                                     powerPercent, tireAngle,...
                                     turnPercent, true, true);
        end
        
        function forwardCentimetersTime(obj, distanceCentimeters)
            obj.straightForward(LegoRobot.MOTOR_POWER_PERCENT);
            obj.pauseCentimetersTime(distanceCentimeters);
        end
        
        function reverseCentimetersTime(obj, distanceCentimeters)
            obj.straightBack(LegoRobot.MOTOR_POWER_PERCENT);
            obj.pauseCentimetersTime(distanceCentimeters);
        end
        
        function pauseCentimetersTime(obj, distanceCentimeters)
            pauseTime = ...
                distanceCentimeters / LegoRobot.CENTIMETERS_PER_SECOND;
            pause(pauseTime);
            obj.allStop();
        end
        
        function rotateTime(obj, angleDegrees)
            if angleDegrees >= 0
                obj.leftMotorReverse(LegoRobot.ROTATE_TIME_PERCENT_POWER);
                obj.rightMotorForward(LegoRobot.ROTATE_TIME_PERCENT_POWER);
            else
                obj.rightMotorReverse(LegoRobot.ROTATE_TIME_PERCENT_POWER);
                obj.leftMotorForward(LegoRobot.ROTATE_TIME_PERCENT_POWER);
            end
            
            rotateTimeSeconds = ...
                abs(angleDegrees) / LegoRobot.DEGREES_ROTATE_PER_SECOND;
            pause(rotateTimeSeconds);
            obj.allStop();
        end
    end
end
