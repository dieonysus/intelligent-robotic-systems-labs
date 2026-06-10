MAX_VELOCITY = 15

function init()
	genome_param = os.getenv("GENOME")
	genome = {}
	for num in genome_param:gmatch("[^,]+") do
			table.insert(genome, tonumber(num))
	end
end


function step()
	left_v = MAX_VELOCITY * genome[1]
	right_v = MAX_VELOCITY * genome[2]
	robot.wheels.set_velocity(left_v,right_v)
end


function destroy()
  -- Output the Euclidean distance from the light
  -- DEPENDENCE: argos file
  x = robot.positioning.position.x
  y = robot.positioning.position.y
  d = math.sqrt((x-2)^2 + y^2)
  print('FITNESS:' .. (5-d)/5)
end
