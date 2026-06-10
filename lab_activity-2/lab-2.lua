MAX_VELOCITY = 15
PROXIMITY_THRESHOLD = 0.20
LIGHT_THRESHOLD = 0.02
WHEEL_SMOOTHING_FACTOR = 0.4
NUM_SENSORS = 24

function sensor_angle(sensor_id)
    local angle = (sensor_id - 1) * (360 / NUM_SENSORS)

    if angle > 180 then
        angle = angle - 360
    end

    return angle
end

function front_sensor(sensor_id)
    local angle = sensor_angle(sensor_id)
    return math.abs(angle) <= 45
end

function left_sensor(sensor_id)
    local angle = sensor_angle(sensor_id)
    return angle > 45 and angle <= 135
end

function right_sensor(sensor_id)
    local angle = sensor_angle(sensor_id)
    return angle < -45 and angle >= -135
end

function back_sensor(sensor_id)
    local angle = sensor_angle(sensor_id)
    return math.abs(angle) > 135
end

function strongest_sensors()
    local max_light = 0
    local max_proximity = 0

    local sensor_with_max_light = 0
    local sensor_with_max_proximity = 0

    for i = 1, NUM_SENSORS do
        if robot.light[i].value > max_light then
            max_light = robot.light[i].value
            sensor_with_max_light = i
        end

        if robot.proximity[i].value > max_proximity then
            max_proximity = robot.proximity[i].value
            sensor_with_max_proximity = i
        end
    end

    return max_light, sensor_with_max_light, max_proximity, sensor_with_max_proximity
end

function init()
    left_velocity = 0
    right_velocity = 0
    robot.wheels.set_velocity(0, 0)
end

function step()
    local max_light, sensor_with_max_light, max_proximity, sensor_with_max_proximity =
        strongest_sensors()

    local left_wheel = MAX_VELOCITY
    local right_wheel = MAX_VELOCITY

    if max_proximity >= PROXIMITY_THRESHOLD then

        local obstacle_angle = sensor_angle(sensor_with_max_proximity)

        if obstacle_angle > 0 then
            left_wheel = MAX_VELOCITY
            right_wheel = MAX_VELOCITY * WHEEL_SMOOTHING_FACTOR
        else
            left_wheel = MAX_VELOCITY * WHEEL_SMOOTHING_FACTOR
            right_wheel = MAX_VELOCITY
        end

    elseif max_light > LIGHT_THRESHOLD then

        if front_sensor(sensor_with_max_light) then
            left_wheel = MAX_VELOCITY
            right_wheel = MAX_VELOCITY

        elseif left_sensor(sensor_with_max_light) then
            left_wheel = MAX_VELOCITY * WHEEL_SMOOTHING_FACTOR
            right_wheel = MAX_VELOCITY

        elseif right_sensor(sensor_with_max_light) then
            left_wheel = MAX_VELOCITY
            right_wheel = MAX_VELOCITY * WHEEL_SMOOTHING_FACTOR

        elseif back_sensor(sensor_with_max_light) then
            left_wheel = MAX_VELOCITY * WHEEL_SMOOTHING_FACTOR
            right_wheel = -MAX_VELOCITY * WHEEL_SMOOTHING_FACTOR
        end

    else
        left_wheel = robot.random.uniform(5, MAX_VELOCITY)
        right_wheel = robot.random.uniform(5, MAX_VELOCITY)
    end

    robot.wheels.set_velocity(left_wheel, right_wheel)
end

function reset()
    left_velocity = 0
    right_velocity = 0
    robot.wheels.set_velocity(0, 0)
end

function destroy()
    x = robot.positioning.position.x
    y = robot.positioning.position.y

    d = math.sqrt((x - 1.5)^2 + y^2)

    log("distance: " .. d)
end