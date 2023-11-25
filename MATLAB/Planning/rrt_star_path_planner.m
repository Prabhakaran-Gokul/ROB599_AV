function [planner_waypoints] = rrt_star_path_planner(omap3D, waypoints, safety_buffer)
    % Initialize hardcoded way if the input waypoints is empty
    % TODO make it a valid random waypoint instead
    if isempty(waypoints)
        % [x y z qw qx qy qz]
        startPose = [1 1 5 0.7 1 0 0];
        goalPose = [150 180 35 0.3 0 0.1 0.6];
        waypoints = [startPose; goalPose];
    end

    % Augment waypoints with orientation (0 degrees of roll, pitch and yaw)
    waypoints = [waypoints repmat([1 0 0 0], size(waypoints, 1), 1)];
    
    omap3D.FreeThreshold = omap3D.OccupiedThreshold;
    % Define state space object 
    ss = stateSpaceSE3([-10   400;
                        -10   400;
                        -10   100;
                        inf inf;
                        inf inf;
                        inf inf;
                        inf inf]);
    
    % Add buffer region around the obstacles
    % inflate(omap3D, safety_buffer);

    % Define State Validator Object
    sv = validatorOccupancyMap3D(ss,Map=omap3D);
    sv.ValidationDistance = 0.1;

    % Set up RRT* Path Planner
    planner = plannerRRTStar(ss,sv);
    planner.MaxConnectionDistance = 50;
    planner.GoalBias = 0.8;
    planner.MaxIterations = 1000;
    planner.ContinueAfterGoalReached = true;
    planner.MaxNumTreeNodes = 10000;

    % Plan for given input waypoints
    N = size(waypoints, 1); % waypoints has size of Nx1
    planner_waypoints = [];
    for i=1:N-1
        % [x y z qw qx qy qz]
        startPose = waypoints(i, :);
        goalPose = waypoints(i+1, :);
    
        % Execute path planning
        [pthObj, solnInfo] = plan(planner,startPose,goalPose);
        planner_waypoints = [planner_waypoints; pthObj.States(1:end-1, :)];

        % Check if a path is found
        if (~solnInfo.IsPathFound)
            disp("No Path Found by the RRT*, terminating...")
            return
        end
    end
    planner_waypoints = [planner_waypoints; waypoints(end, :)];

    % Plot map, start pose, and goal pose
    % show(omap3D)
    % hold on
    % scatter3(startPose(1),startPose(2),startPose(3),100,".r")
    % scatter3(goalPose(1),goalPose(2),goalPose(3),100,".g")
    % 
    % % Plot path computed by path planner
    % plot3(pthObj.States(:,1),pthObj.States(:,2),pthObj.States(:,3),"-g")
    % view([-31 63])
    % legend("","Start Position","Goal Position","Planned Path")
    % hold off
    % disp("End")
end