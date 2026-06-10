MAX_VELOCITY = 15
MOVE_STEPS = 200
LIGHT_THRESHOLD = 0.55

local vector = require "vector"

function clamp_velocity(velocity)
	if velocity > MAX_VELOCITY then
		return MAX_VELOCITY
	elseif velocity < -MAX_VELOCITY then
		return -MAX_VELOCITY
	else
		return velocity
	end
end

function init()
	left_velocity = robot.random.uniform(0, MAX_VELOCITY)
	right_velocity = robot.random.uniform(0, MAX_VELOCITY)

	robot.wheels.set_velocity(left_velocity, right_velocity)

	wheel_axis_length = robot.wheels.axis_length
	n_steps = 0
end

function obstacle_avoidance_schema(light_detected)
	if light_detected then
		return { length = 0, angle = 0 }
	end

	local proximity_sensors = robot.proximity
	local max_proximity = -1
	local proximity_angle = -1
	local sensor_index = -1
	local schema_vector = { length = 0, angle = 0 }

	for i = 1, #proximity_sensors do
		if proximity_sensors[i].value > max_proximity then
			max_proximity = proximity_sensors[i].value
			proximity_angle = proximity_sensors[i].angle
			sensor_index = i
		end
	end

	if max_proximity ~= -1 then
		if sensor_index <= #robot.proximity / 2 then
			schema_vector = {
				length = MAX_VELOCITY * max_proximity,
				angle = proximity_angle - math.pi / 2
			}
		else
			schema_vector = {
				length = MAX_VELOCITY * max_proximity,
				angle = proximity_angle + math.pi / 2
			}
		end
	end

	return schema_vector
end

function phototaxis_schema(light_detected)
	if light_detected then
		return { length = 0, angle = 0 }
	end

	local light_sensors = robot.light
	local max_light = -1
	local light_angle = -1
	local schema_vector = { length = 0, angle = 0 }

	for i = 1, #light_sensors do
		if light_sensors[i].value > max_light then
			max_light = light_sensors[i].value
			light_angle = light_sensors[i].angle
		end
	end

	if max_light > 0 then
		schema_vector = {
			length = clamp_velocity(MAX_VELOCITY / max_light),
			angle = light_angle
		}
	else
		schema_vector = random_walk_schema()
	end

	return schema_vector
end

function random_walk_schema()
	return {
		length = robot.random.uniform(5, MAX_VELOCITY),
		angle = robot.random.uniform(-math.pi, math.pi)
	}
end

function is_light_detected()
	for i = 1, #robot.light do
		if robot.light[i].value >= LIGHT_THRESHOLD then
			return true
		end
	end

	return false
end

function step()
	n_steps = n_steps + 1

	local light_detected = is_light_detected()

	local obstacle_vector = obstacle_avoidance_schema(light_detected)
	local phototaxis_vector = phototaxis_schema(light_detected)

	local resultant_vector = vector.vec2_polar_sum(
		phototaxis_vector,
		obstacle_vector
	)

	local left_velocity =
		resultant_vector.length -
		(wheel_axis_length / 2) * resultant_vector.angle

	local right_velocity =
		resultant_vector.length +
		(wheel_axis_length / 2) * resultant_vector.angle

	left_velocity = clamp_velocity(left_velocity)
	right_velocity = clamp_velocity(right_velocity)

	robot.wheels.set_velocity(left_velocity, right_velocity)

	if n_steps > MOVE_STEPS then
		reset()
	end
end

function reset()
	left_velocity = robot.random.uniform(0, MAX_VELOCITY)
	right_velocity = robot.random.uniform(0, MAX_VELOCITY)

	robot.wheels.set_velocity(left_velocity, right_velocity)

	n_steps = 0
end

function destroy()
	local x = robot.positioning.position.x
	local y = robot.positioning.position.y
	local distance = math.sqrt((x - 1.5)^2 + y^2)

	print("f_distance " .. distance)
end