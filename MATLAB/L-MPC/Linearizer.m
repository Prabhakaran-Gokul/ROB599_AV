%% Define the linearization function
function [A, B] = Linearizer(tk1, tk2, tk3, td1, td2, td3, rk1, rk2, rk3, rd1, rd2, rd3, equilibrium, debug)
    
    % Define the symbolic variables
    syms x y z xdot ydot zdot phi theta psy p q r 
    
    % Define the inputs
    syms w1 w2 w3 w4

    % Calculate the jacobian
    Ja = jacobian([tk1; tk2; tk3; td1; td2; td3; rk1; rk2; rk3; rd1; rd2; rd3], [x; y; z; xdot; ydot; zdot; phi; theta; psy; p; q; r ]);
    Jb = jacobian([tk1; tk2; tk3; td1; td2; td3; rk1; rk2; rk3; rd1; rd2; rd3], [w1; w2; w3; w4 ]);
    
    % Print when debugging
    if debug == true
        disp("The symbolic jacobians are:")
        disp(Ja)
        disp(Jb)
    end

    % Check if an equilibrium has been passed
    if isempty(equilibrium)
        A = Ja;
        B = Jb;
    else
        % Evaluate at equilibria
        Ja_equilibrium = (subs(Ja, [x; y; z; xdot; ydot; zdot; phi; theta; psy; p; q; r; w1; w2; w3; w4], equilibrium));
        Jb_equilibrium = (subs(Jb, [x; y; z; xdot; ydot; zdot; phi; theta; psy; p; q; r; w1; w2; w3; w4], equilibrium));
        
        % Print when debugging
        if debug == true
            disp("The jacobians evaluated at the operating point are:")
            disp(Ja_equilibrium)
            disp(Jb_equilibrium)
        end

        A = Ja_equilibrium;
        B = Jb_equilibrium;

    end

end