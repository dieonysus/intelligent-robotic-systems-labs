S = 0.01
W = 0.1
P_s_max = 0.99
P_w_min = 0.005
alpha = 0.1
beta = 0.05

MAX_VELOCITY = 15
MOVE_STEPS = 1000
OBSTACLE_THRESHOLD = 0.5
MAXRANGE = 30

STATE_MOVING = 0
STATE_STOPPED = 1

state = STATE_MOVING
n_steps = 0

function set_led_for_state()
    if state == STATE_MOVING then
        robot.leds.set_single_color(13, "green")
    else
        robot.leds.set_single_color(13, "red")
    end
end

function set_random_velocity()
    local left_v = robot.random.uniform(0, MAX_VELOCITY)
    local right_v = robot.random.uniform(0, MAX_VELOCITY)
    robot.wheels.set_velocity(left_v, right_v)
end

function stop_robot()
    robot.wheels.set_velocity(0, 0)
    state = STATE_STOPPED
    set_led_for_state()
end

function start_random_walk()
    set_random_velocity()
    state = STATE_MOVING
    set_led_for_state()
end

function init()
    n_steps = 0
    start_random_walk()
end

function random_stop(num_robots_sensed)
    local P_s = math.min(P_s_max, S + alpha * num_robots_sensed)

    if robot.random.uniform() <= P_s then
        stop_robot()
    end
end

function random_walk(num_robots_sensed)
    local P_w = math.max(P_w_min, W - beta * num_robots_sensed)

    if robot.random.uniform() <= P_w then
        start_random_walk()
    end
end

function signal_presence(value)
    robot.range_and_bearing.set_data(1, value)
end

function CountRAB()
    local num_robots_sensed = 0

    for i = 1, #robot.range_and_bearing do
        local sensed_robot = robot.range_and_bearing[i]

        if sensed_robot.range < MAXRANGE and sensed_robot.data[1] == STATE_STOPPED then
            num_robots_sensed = num_robots_sensed + 1
        end
    end

    return num_robots_sensed
end

function obstacle_avoidance()
    local max_prox = -1
    local max_prox_idx = -1

    for i = 1, #robot.proximity do
        local proximity_sensor = robot.proximity[i]

        if proximity_sensor.value > max_prox then
            max_prox = proximity_sensor.value
            max_prox_idx = i
        end
    end

    if max_prox_idx == -1 or max_prox <= OBSTACLE_THRESHOLD then
        return
    end

    local left_v = MAX_VELOCITY
    local right_v = MAX_VELOCITY

    if max_prox_idx <= #robot.proximity / 2 then
        right_v = robot.random.uniform(0, 3)
    else
        left_v = robot.random.uniform(0, 3)
    end

    robot.wheels.set_velocity(left_v, right_v)
end

function step()
    n_steps = n_steps + 1

    local num_robots_sensed = CountRAB()

    if state == STATE_MOVING then
        random_stop(num_robots_sensed)
    else
        random_walk(num_robots_sensed)
    end

    signal_presence(state)

    if state == STATE_MOVING then
        obstacle_avoidance()
    end

    if n_steps > MOVE_STEPS then
        reset()
    end
end

function reset()
    n_steps = 0
    start_random_walk()
end

function destroy()
    -- Nothing to clean up
end