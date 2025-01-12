%% Define the function that performs Model Predictive Control for the MPC
function control_input = DroneMPC(A, B, parameters, initial_conditions, Uprev, time_index)
    % Begin the cvx problem
    cvx_begin

        % Extract the needed variables from the parameters cell array:
        horizon = parameters{1};
        Q = parameters{2};
        R = parameters{3};
        Xbar =  parameters{4};
        Ubar =  parameters{5};
        % Xref =  parameters{6}(time_index:(time_index + horizon - 1), :);
        % Xref = create_valid_horizon(parameters{6}, time_index, horizon, "Xref");
        Xref = QuadrotorReferenceReader(time_index, time_index + horizon - 1, parameters{6});
        % Uref =  parameters{7}(time_index:(time_index + horizon - 2), :);
        % Uref = create_valid_horizon(parameters{7}, time_index, horizon, "Uref");
        Uref = QuadrotorReferenceReader(time_index, time_index + horizon - 2, parameters{7});
        dt = parameters{10};
        eom_params = parameters{11};
        N = length(parameters{6});

        % Define the delta_x and delta_u as cvx variables
         variable delta_X(horizon, parameters{8});
         variable delta_U(horizon - 1, parameters{9});
        
        % Construct the cost function
        cost = 0;
        for i = 1:horizon
            xi = Xbar + delta_X(i, :);
            cost = cost + 0.5*quad_form(xi - Xref(i, :), Q);
        end
        for i = 1:(horizon - 1)
            ui = Ubar + delta_U(i, :);
            cost = cost+ 0.5*quad_form(ui - Uref(i, :), R);
        end
    
        % Define the problem type
        minimize(cost);
        
        subject to
        % Define the initial condition constraint
        Xbar + delta_X(1, :) == initial_conditions;
    
        % Define the dynamics and control constraints
        for i = 1:(horizon-1)
            % update mpc time
            mpc_index = min(time_index + i, N);
            eom_params{2} = mpc_index;
            % dynamics constraints
            Xbar + delta_X(i+1, :) == rk4(Xbar, Ubar, dt, eom_params)  + delta_X(i, :)*A' + delta_U(i, :)*B';
            % control input constraints
            Ubar + delta_U(i, :) <= Ubar*5;
            Ubar + delta_U(i, :) >= 0.0;
            Ubar + delta_U(i, :) - Uprev >= -Ubar*5;
            Ubar + delta_U(i, :) - Uprev <= (Ubar*5) / 2;
            Uprev = Ubar + delta_U(i, :);
        end

    cvx_end
    
    % Compute the desired output
    control_input = Ubar + delta_U(1, :);
end

function new_ref = create_valid_horizon(ref_array, time_index, horizon, ref_name)
    if ref_name == "Xref"
        if (time_index + horizon - 1) > length(ref_array)
            last_val = ref_array(end, :);
            new_ref = [ref_array];
            for i = 1:((time_index + horizon - 1) - length(ref_array))
                new_ref = [new_ref; last_val];
            end
        else
            new_ref = ref_array(time_index:(time_index + horizon - 1), :);
        end
    else
        if (time_index + horizon - 2) > length(ref_array)
            last_val = ref_array(end, :);
            new_ref = [ref_array];
            for i = 1:((time_index + horizon - 2) - length(ref_array))
                new_ref = [new_ref; last_val];
            end
        else
            new_ref = ref_array(time_index:(time_index + horizon - 2), :);
        end
    end    

end

%% Define the function that parses the waypoints safely
function xDesired = QuadrotorReferenceReader(start, finish, reference)

if finish > length(reference)
    % Index the array
    xDesired = reference(start:end,:);    
    current_len = size(xDesired, 1);

    % Add rows if necessary
    while current_len < (finish-start+1)
        
        xDesired(current_len + 1, :) = xDesired(end,:);
        current_len = current_len + 1;
    end
else
    xDesired = reference(start:finish,:);    
end
    %disp(xDesired)
end

