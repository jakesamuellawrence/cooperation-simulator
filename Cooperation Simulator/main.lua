WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720
WORLD_WIDTH = 5641
WORLD_HEIGHT = 1100
PIXELS_IN_METRE = 30
ZOOM_FACTOR = 0.5

STARTING_LOC = {x = 525, y = WORLD_HEIGHT/2}

PLAYER_BODY_SIZE = {x = 25, y = 80}
PLAYER_ARM_SIZE = {x = 8, y = 50}
PLAYER_HEAD_RADIUS = 10
BULLET_RADIUS = 4

ARM_CONTROL_FORCE = 300
-- THRUSTER_FORCE = 2500
THRUSTER_IMPULSE = 3000

THRUSTER_COOLDOWN = 5

THRUSTER_IMAGE_FRAMECOUNT = 20

BULLET_IMPULSE = 200

--if x and y are small, round them before returning them
function deadzonify(x, y)
	if(math.abs(x) < 0.4 and math.abs(y) < 0.4) then
		return 0, 0
	else
		return x, y
	end
end

--deletes and dereferences the rightbullet
function killRightBullet()
	player.body1.rightbullet.fixture:destroy()
	player.body1.rightbullet.body:destroy()
	player.body1.rightbullet.shape:release()

	player.body1.rightbullet.body = nil
	player.body1.rightbullet.shape = nil
	player.body1.rightbullet.fixture = nil
end

--deletes and dereferences the rightbullet
function killLeftBullet()
	player.body1.leftbullet.fixture:destroy()
	player.body1.leftbullet.body:destroy()
	player.body1.leftbullet.shape:release()

	player.body1.leftbullet.body = nil
	player.body1.leftbullet.shape = nil
	player.body1.leftbullet.fixture = nil
end

function isPlayerFixture(f)
	return f == player.torso.fixture or f == player.body1.head.fixture or f == player.body1.leftarm.fixture or f == player.body1.rightarm.fixture or f == player.body2.head.fixture or f == player.body2.leftarm.fixture or f == player.body2.rightarm.fixture
end

function isDeathWallFixture(f)
	for i, wall in ipairs(death_walls) do
		if f == wall.fixture then return true end
	end
	return false
end

function resetGame()
	player.torso.body:setPosition(STARTING_LOC.x, STARTING_LOC.y)
	player.torso.body:setLinearVelocity(0, 0)
	player.body1.head.body:setPosition(STARTING_LOC.x, STARTING_LOC.y)
	player.body1.head.body:setLinearVelocity(0, 0)
	player.body1.leftarm.body:setPosition(STARTING_LOC.x, STARTING_LOC.y)
	player.body1.leftarm.body:setLinearVelocity(0, 0)
	player.body1.rightarm.body:setPosition(STARTING_LOC.x, STARTING_LOC.y)
	player.body1.rightarm.body:setLinearVelocity(0, 0)
	player.body2.head.body:setPosition(STARTING_LOC.x, STARTING_LOC.y)
	player.body2.head.body:setLinearVelocity(0, 0)
	player.body2.leftarm.body:setPosition(STARTING_LOC.x, STARTING_LOC.y)
	player.body2.leftarm.body:setLinearVelocity(0, 0)
	player.body2.rightarm.body:setPosition(STARTING_LOC.x, STARTING_LOC.y)
	player.body2.rightarm.body:setLinearVelocity(0, 0)


	player.torso.joint_to_starting_spot = love.physics.newRevoluteJoint(player.torso.body, starting_spot.body, STARTING_LOC.x, STARTING_LOC.y, false)
end

--called when a physics collision occurs
function beginContact(a, b, coll)
	--do grapple stuff
	if player.body1.rightbullet.state == "moving" then
		if a == player.body1.rightbullet.fixture or b == player.body1.rightbullet.fixture then
			player.body1.rightbullet.state = "toAttach"
			player.body1.rightbullet.collisionX, player.body1.rightbullet.collisionY = coll:getPositions()

			if a == player.body1.rightbullet.fixture then
				player.body1.rightbullet.collisionBody = b:getBody()
			else
				player.body1.rightbullet.collisionBody = a:getBody()
			end
		end
	end
	if player.body1.leftbullet.state == "moving" then
		if a == player.body1.leftbullet.fixture or b == player.body1.leftbullet.fixture then
			player.body1.leftbullet.state = "toAttach"
			player.body1.leftbullet.collisionX, player.body1.leftbullet.collisionY = coll:getPositions()

			if a == player.body1.leftbullet.fixture then
				player.body1.leftbullet.collisionBody = b:getBody()
			else
				player.body1.leftbullet.collisionBody = a:getBody()
			end
		end
	end

	--check for player death
	if (isPlayerFixture(a) and isDeathWallFixture(b)) or (isPlayerFixture(b) and isDeathWallFixture(a)) then
		should_reset = true
	end
end

function love.load()
	if love.joystick.getJoystickCount() ~= 2 then
		print("Please start the game with two controllers connected")
		love.event.quit()
	end

	love.graphics.setBackgroundColor(0.9, 0.9, 0.9)
	love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
	love.physics.setMeter(PIXELS_IN_METRE)

	background_image = love.graphics.newImage("level_background.png")
	torso_image = love.graphics.newImage("body_joined.png")
	p1_arm_image = love.graphics.newImage("grapple_upright.png")
	p1_head_image = love.graphics.newImage("grapple_head.png")
	p2_arm_image = love.graphics.newImage("rocket_upright.png")
	p2_head_image = love.graphics.newImage("rocket_head.png")
	explosion_image = love.graphics.newImage("explosion.png")

	should_reset = true

	right_blast_countdown = 0
	left_blast_countdown = 0

	world = love.physics.newWorld(0, 9.8*PIXELS_IN_METRE, true)
	world:setCallbacks(beginContact, nil, nil, nil)

	player = {
		torso = {},
		body1 = {
			leftarm = {},
			rightarm = {},
			head = {},
			leftbullet = {
				state = "idle"
			},
			rightbullet = {
				state = "idle"
			},
			joystick = love.joystick.getJoysticks()[1]
		},
		body2 = {
			leftarm = {},
			rightarm = {},
			leftcooldown = THRUSTER_COOLDOWN,
			rightcooldown = THRUSTER_COOLDOWN,
			head = {},
			joystick = love.joystick.getJoysticks()[2]
		}
	}

	player.torso.body = love.physics.newBody(world, WINDOW_WIDTH/2, WINDOW_HEIGHT/2, "dynamic")
	player.torso.shape = love.physics.newRectangleShape(PLAYER_BODY_SIZE.x, PLAYER_BODY_SIZE.y)
	player.torso.fixture = love.physics.newFixture(player.torso.body, player.torso.shape)
	player.torso.fixture:setGroupIndex(-1)

	player.body1.leftarm.body = love.physics.newBody(world, (player.torso.body:getX() - PLAYER_BODY_SIZE.x/2) + (PLAYER_ARM_SIZE.x/2), (player.torso.body:getY() - PLAYER_BODY_SIZE.y/2) - (PLAYER_ARM_SIZE.y/2) + PLAYER_ARM_SIZE.x, "dynamic")
	player.body1.leftarm.shape = love.physics.newRectangleShape(PLAYER_ARM_SIZE.x, PLAYER_ARM_SIZE.y)
	player.body1.leftarm.fixture = love.physics.newFixture(player.body1.leftarm.body, player.body1.leftarm.shape)
	player.body1.leftarm.joint_to_torso = love.physics.newRevoluteJoint(player.body1.leftarm.body, player.torso.body, (player.torso.body:getX() - PLAYER_BODY_SIZE.x/2) + (PLAYER_ARM_SIZE.x/2), (player.torso.body:getY() - PLAYER_BODY_SIZE.y/2) + PLAYER_ARM_SIZE.x/2, false)
	player.body1.leftarm.fixture:setGroupIndex(-1)
	player.body1.leftarm.control_joint = love.physics.newMouseJoint(player.body1.leftarm.body, player.body1.leftarm.body:getX(), player.body1.leftarm.body:getY() - PLAYER_ARM_SIZE.y/2 + PLAYER_ARM_SIZE.x)
	player.body1.leftarm.control_joint:setMaxForce(ARM_CONTROL_FORCE)

	player.body1.rightarm.body = love.physics.newBody(world, (player.torso.body:getX() + PLAYER_BODY_SIZE.x/2) - (PLAYER_ARM_SIZE.x/2), (player.torso.body:getY() - PLAYER_BODY_SIZE.y/2) - (PLAYER_ARM_SIZE.y/2) + PLAYER_ARM_SIZE.x, "dynamic")
	player.body1.rightarm.shape = love.physics.newRectangleShape(PLAYER_ARM_SIZE.x, PLAYER_ARM_SIZE.y)
	player.body1.rightarm.fixture = love.physics.newFixture(player.body1.rightarm.body, player.body1.rightarm.shape)
	player.body1.rightarm.joint_to_body = love.physics.newRevoluteJoint(player.body1.rightarm.body, player.torso.body, (player.torso.body:getX() + PLAYER_BODY_SIZE.x/2) - (PLAYER_ARM_SIZE.x/2), (player.torso.body:getY() - PLAYER_BODY_SIZE.y/2) + PLAYER_ARM_SIZE.x/2, false)
	player.body1.rightarm.fixture:setGroupIndex(-1)
	player.body1.rightarm.control_joint = love.physics.newMouseJoint(player.body1.rightarm.body, player.body1.rightarm.body:getX(), player.body1.rightarm.body:getY() - PLAYER_ARM_SIZE.y/2 + PLAYER_ARM_SIZE.x)
	player.body1.rightarm.control_joint:setMaxForce(ARM_CONTROL_FORCE)

	player.body1.head.body = love.physics.newBody(world, (player.torso.body:getX()), (player.torso.body:getY() - PLAYER_BODY_SIZE.y/2) - PLAYER_HEAD_RADIUS, "dynamic")
	player.body1.head.shape = love.physics.newCircleShape(PLAYER_HEAD_RADIUS)
	player.body1.head.fixture = love.physics.newFixture(player.body1.head.body, player.body1.head.shape)
	player.body1.head.joint_to_torso = love.physics.newRevoluteJoint(player.body1.head.body, player.torso.body, (player.torso.body:getX()), (player.torso.body:getY() - PLAYER_BODY_SIZE.y/2), false)
	player.body1.head.fixture:setGroupIndex(-1)
	player.body1.head.joint_to_torso:setLimitsEnabled(true)
	player.body1.head.joint_to_torso:setLimits(-math.pi/4, math.pi/4)

	player.body2.leftarm.body = love.physics.newBody(world, (player.torso.body:getX() + PLAYER_BODY_SIZE.x/2) - (PLAYER_ARM_SIZE.x/2), (player.torso.body:getY() + PLAYER_BODY_SIZE.y/2) + (PLAYER_ARM_SIZE.y/2) - PLAYER_ARM_SIZE.x, "dynamic")
	player.body2.leftarm.shape = love.physics.newRectangleShape(PLAYER_ARM_SIZE.x, PLAYER_ARM_SIZE.y)
	player.body2.leftarm.fixture = love.physics.newFixture(player.body2.leftarm.body, player.body2.leftarm.shape)
	player.body2.leftarm.joint_to_body = love.physics.newRevoluteJoint(player.body2.leftarm.body, player.torso.body, (player.torso.body:getX() + PLAYER_BODY_SIZE.x/2) - (PLAYER_ARM_SIZE.x/2), (player.torso.body:getY() + PLAYER_BODY_SIZE.y/2) - PLAYER_ARM_SIZE.x/2, false)
	player.body2.leftarm.fixture:setGroupIndex(-1)
	player.body2.leftarm.control_joint = love.physics.newMouseJoint(player.body2.leftarm.body, player.body2.leftarm.body:getX(), player.body2.leftarm.body:getY() + PLAYER_ARM_SIZE.y/2 - PLAYER_ARM_SIZE.x)
	player.body2.leftarm.control_joint:setMaxForce(ARM_CONTROL_FORCE)

	player.body2.rightarm.body = love.physics.newBody(world, (player.torso.body:getX() - PLAYER_BODY_SIZE.x/2) + (PLAYER_ARM_SIZE.x/2), (player.torso.body:getY() + PLAYER_BODY_SIZE.y/2) + (PLAYER_ARM_SIZE.y/2) - PLAYER_ARM_SIZE.x, "dynamic")
	player.body2.rightarm.shape = love.physics.newRectangleShape(PLAYER_ARM_SIZE.x, PLAYER_ARM_SIZE.y)
	player.body2.rightarm.fixture = love.physics.newFixture(player.body2.rightarm.body, player.body2.rightarm.shape)
	player.body2.rightarm.joint_to_torso = love.physics.newRevoluteJoint(player.body2.rightarm.body, player.torso.body, (player.torso.body:getX() - PLAYER_BODY_SIZE.x/2) + (PLAYER_ARM_SIZE.x/2), (player.torso.body:getY() + PLAYER_BODY_SIZE.y/2) - PLAYER_ARM_SIZE.x/2, false)
	player.body2.rightarm.fixture:setGroupIndex(-1)
	player.body2.rightarm.control_joint = love.physics.newMouseJoint(player.body2.rightarm.body, player.body2.rightarm.body:getX(), player.body2.rightarm.body:getY() + PLAYER_ARM_SIZE.y/2 + PLAYER_ARM_SIZE.x)
	player.body2.rightarm.control_joint:setMaxForce(ARM_CONTROL_FORCE)

	player.body2.head.body = love.physics.newBody(world, (player.torso.body:getX()), (player.torso.body:getY() + PLAYER_BODY_SIZE.y/2) + PLAYER_HEAD_RADIUS, "dynamic")
	player.body2.head.shape = love.physics.newCircleShape(PLAYER_HEAD_RADIUS)
	player.body2.head.fixture = love.physics.newFixture(player.body2.head.body, player.body2.head.shape)
	player.body2.head.joint_to_torso = love.physics.newRevoluteJoint(player.body2.head.body, player.torso.body, (player.torso.body:getX()), (player.torso.body:getY() + PLAYER_BODY_SIZE.y/2), false)
	player.body2.head.fixture:setGroupIndex(-1)
	player.body2.head.joint_to_torso:setLimitsEnabled(true)
	player.body2.head.joint_to_torso:setLimits(-math.pi/4, math.pi/4)

	walls = {
		{ --ceiling
			body = love.physics.newBody(world, WORLD_WIDTH/2, 30, "static"),
			shape = love.physics.newRectangleShape(WORLD_WIDTH, 60)
		},
		{ --floor
			body = love.physics.newBody(world, WORLD_WIDTH/2, WORLD_HEIGHT-30, "static"),
			shape = love.physics.newRectangleShape(WORLD_WIDTH, 60)
		},
		{ --left wall
			body = love.physics.newBody(world, 30, WORLD_HEIGHT/2, "static"),
			shape = love.physics.newRectangleShape(60, WORLD_HEIGHT)
		},
		{ --right wall
			body = love.physics.newBody(world, WORLD_WIDTH-30, WORLD_HEIGHT/2, "static"),
			shape = love.physics.newRectangleShape(60, WORLD_HEIGHT)
		},
		{ --first wall obstacle   969, 431 -> 1074, 1100   =>   width: 105 height: 669 x: 1021 y: 765
			body = love.physics.newBody(world, 1021, 765, "static"),
			shape = love.physics.newRectangleShape(105, 669)
		}
	}

	death_walls = {
		{ --floor     1074 -> 3006   =>  x: 2040 width: 1932 height: 60
			body = love.physics.newBody(world, 2040, WORLD_HEIGHT-30, "static"),
			shape = love.physics.newRectangleShape(1932, 60)
		},
		{ --first wall from top     	1590, 0 -> 1694, 480   =>   x: 1642 y: 240 width: 104 height: 480
			body = love.physics.newBody(world, 1642, 240, "static"),
			shape = love.physics.newRectangleShape(104, 480)
		},
		{ --first wall from bottom     1996, 767 -> 2098, 1100    =>    x: 2047 y: 933 width: 102 height: 333
			body = love.physics.newBody(world, 2047, 933, "static"),
			shape = love.physics.newRectangleShape(102, 333)
		},
		{ -- first shape  1830,341 -> 2069,202 -> 2121,290 -> 1881,429
			body = love.physics.newBody(world, 1830, 341, "static"),
			shape = love.physics.newPolygonShape(1830-1830, 341-341, 2096-1830, 202-341, 2121-1830, 290-341, 1881-1830, 429-341)
		},
		{ -- second shape  2326,832 -> 2464,695 -> 2601,832 -> 2464,965
			body = love.physics.newBody(world, 2326, 832, "static"),
			shape = love.physics.newPolygonShape(2326-2326, 832-832, 2464-2326, 695-832, 2601-2326, 832-832, 2464-2326, 965-832)
		},
		{ -- third shape  l: 2497 r: 2775 b: 84 t: 362   =>   x: 2636 y: 223 width: 278 height: 278
			body = love.physics.newBody(world, 2636, 223, "static"),
			shape = love.physics.newRectangleShape(278, 278)
		},
		{ -- ceiling squish 2859,60 -> 3101,60 -> 4191,407 -> 4170,476
			body = love.physics.newBody(world, 2859, 60, "static"),
			shape = love.physics.newPolygonShape(2859-2859, 60-60, 3101-2859, 60-60, 4191-2859, 407-60, 4170-2859, 476-60)
		},
		{ -- floor squish 2861,1036 -> 4183,666 -> 4203,736 -> 3005,1071
			body = love.physics.newBody(world, 2861, 1036, "static"),
			shape = love.physics.newPolygonShape(2861-2861, 1036-1036, 4183-2861, 666-1036, 4203-2861, 736-1036, 3005-2861, 1071-1036)
		}
	}

	for i, wall in ipairs(walls) do
		walls[i].fixture = love.physics.newFixture(walls[i].body, walls[i].shape);
	end

	for i, wall in ipairs(death_walls) do
		death_walls[i].fixture = love.physics.newFixture(death_walls[i].body, death_walls[i].shape);
	end

	starting_spot = {
		body = love.physics.newBody(world, STARTING_LOC.x, STARTING_LOC.y, "static")
	}

end

function love.joystickpressed(joystick, key)
	if key == 5 or key == 6 then
		if player.torso.joint_to_starting_spot ~= nil then
			player.torso.joint_to_starting_spot:destroy()
			player.torso.joint_to_starting_spot = nil
		end
	end
end

function love.update(dt)
	--reset if we should
	if should_reset then
		should_reset = false
		resetGame()
	end

	--update cooldowns
	player.body2.leftcooldown = player.body2.leftcooldown + dt
	player.body2.rightcooldown = player.body2.rightcooldown + dt

	--joystick values
	p1_left_x = player.body1.joystick:getGamepadAxis("leftx")
	p1_left_y = player.body1.joystick:getGamepadAxis("lefty")
	p1_right_x = player.body1.joystick:getGamepadAxis("rightx")
	p1_right_y = player.body1.joystick:getGamepadAxis("righty")

	p2_left_x = player.body2.joystick:getGamepadAxis("leftx")
	p2_left_y = player.body2.joystick:getGamepadAxis("lefty")
	p2_right_x = player.body2.joystick:getGamepadAxis("rightx")
	p2_right_y = player.body2.joystick:getGamepadAxis("righty")

	--deadzones
	p1_left_x, p1_left_y = deadzonify(p1_left_x, p1_left_y)
	p1_right_x, p1_right_y = deadzonify(p1_right_x, p1_right_y)

	p2_left_x, p2_left_y = deadzonify(p2_left_x, p2_left_y)
	p2_right_x, p2_right_y = deadzonify(p2_right_x, p2_right_y)

	player.body1.leftarm.control_joint:setTarget(player.body1.leftarm.body:getX() + p1_left_x*50, player.body1.leftarm.body:getY() + p1_left_y*50)
	player.body1.rightarm.control_joint:setTarget(player.body1.rightarm.body:getX() + p1_right_x*50, player.body1.rightarm.body:getY() + p1_right_y*50)
	player.body2.leftarm.control_joint:setTarget(player.body2.leftarm.body:getX() + p2_right_x*50, player.body2.leftarm.body:getY() + p2_right_y*50)
	player.body2.rightarm.control_joint:setTarget(player.body2.rightarm.body:getX() + p2_left_x*50, player.body2.rightarm.body:getY() + p2_left_y*50)

	if p1_left_x == 0 and p1_left_y == 0 then
		player.body1.leftarm.control_joint:setMaxForce(0)
	else
		player.body1.leftarm.control_joint:setMaxForce(ARM_CONTROL_FORCE)
	end
	if p1_right_x == 0 and p1_right_y == 0 then
		player.body1.rightarm.control_joint:setMaxForce(0)
	else
		player.body1.rightarm.control_joint:setMaxForce(ARM_CONTROL_FORCE)
	end
	if p2_left_x == 0 and p2_left_y == 0 then
		player.body2.rightarm.control_joint:setMaxForce(0)
	else
		player.body2.rightarm.control_joint:setMaxForce(ARM_CONTROL_FORCE)
	end
	if p2_right_x == 0 and p2_right_y == 0 then
		player.body2.leftarm.control_joint:setMaxForce(0)
	else
		player.body2.leftarm.control_joint:setMaxForce(ARM_CONTROL_FORCE)
	end

	if player.body2.joystick:getGamepadAxis("triggerright") > 0.4 then
		-- player.torso.body:applyForce(-math.cos(player.body2.rightarm.body:getAngle()+math.pi/2) * THRUSTER_FORCE, -math.sin(player.body2.rightarm.body:getAngle()+math.pi/2) * THRUSTER_FORCE)
		-- player.torso.body:applyForce(-p2_right_x * THRUSTER_FORCE, -p2_right_y * THRUSTER_FORCE)
		if p2_right_x ~= 0 or p2_right_y ~= 0 then
			if player.body2.rightcooldown >= THRUSTER_COOLDOWN then
				player.body2.rightcooldown = 0
				right_blast_countdown = THRUSTER_IMAGE_FRAMECOUNT
				player.torso.body:applyLinearImpulse(-p2_right_x * THRUSTER_IMPULSE, -p2_right_y * THRUSTER_IMPULSE)
			end
		end
	end
	if player.body2.joystick:getGamepadAxis("triggerleft") > 0.4 then
		-- player.torso.body:applyForce(-math.cos(player.body2.leftarm.body:getAngle()+math.pi/2) * THRUSTER_FORCE, -math.sin(player.body2.leftarm.body:getAngle()+math.pi/2) * THRUSTER_FORCE)
		--player.torso.body:applyForce(-p2_left_x * THRUSTER_FORCE, -p2_left_y * THRUSTER_FORCE)
		if p2_left_x ~= 0 or p2_left_y ~= 0 then
			if player.body2.leftcooldown >= THRUSTER_COOLDOWN then
				player.body2.leftcooldown = 0
				left_blast_countdown = THRUSTER_IMAGE_FRAMECOUNT
				player.torso.body:applyLinearImpulse(-p2_left_x * THRUSTER_IMPULSE, -p2_left_y * THRUSTER_IMPULSE)
			end
		end
	end

	if player.body1.joystick:getGamepadAxis("triggerright") > 0.4 then
		if player.body1.rightbullet.state == "idle" then
			if p1_right_x ~= 0 or p1_right_y ~= 0 then
				player.body1.rightbullet.state = "moving"
				tempx, tempy = player.body1.rightarm.body:getWorldPoint(0, -PLAYER_ARM_SIZE.y/2 - 10)
				player.body1.rightbullet.body = love.physics.newBody(world, tempx, tempy, "dynamic")
				player.body1.rightbullet.shape = love.physics.newCircleShape(BULLET_RADIUS)
				player.body1.rightbullet.fixture = love.physics.newFixture(player.body1.rightbullet.body, player.body1.rightbullet.shape)
				player.body1.rightbullet.fixture:setGroupIndex(-1)
				-- player.body1.rightbullet.body:applyLinearImpulse(math.cos(player.body1.rightarm.body:getAngle()-math.pi/2) * BULLET_IMPULSE, math.sin(player.body1.rightarm.body:getAngle()-math.pi/2) * BULLET_IMPULSE)
				player.body1.rightbullet.body:applyLinearImpulse(p1_right_x * BULLET_IMPULSE, p1_right_y * BULLET_IMPULSE)
			end
		elseif player.body1.rightbullet.state == "toAttach" then
			player.body1.rightbullet.state = "attached"
			tempx, tempy = player.body1.rightarm.body:getWorldPoint(0, -PLAYER_ARM_SIZE.y/2+PLAYER_ARM_SIZE.x/2)
			player.body1.rightbullet.distance_joint = love.physics.newDistanceJoint(player.body1.rightarm.body, player.body1.rightbullet.collisionBody, tempx, tempy, player.body1.rightbullet.collisionX, player.body1.rightbullet.collisionY, true)
			killRightBullet()
		end
	else
		if player.body1.rightbullet.state == "moving" then
			player.body1.rightbullet.state = "idle"
			killRightBullet()
		elseif player.body1.rightbullet.state == "attached" then
			player.body1.rightbullet.state = "idle"

			player.body1.rightbullet.collisionBody = nil
			player.body1.rightbullet.collisionX = nil
			player.body1.rightbullet.collisionY = nil
			player.body1.rightbullet.distance_joint:destroy()
			player.body1.rightbullet.distance_joint = nil
		end
	end

	if player.body1.joystick:getGamepadAxis("triggerleft") > 0.4 then
		if player.body1.leftbullet.state == "idle" then
			if p1_left_x ~= 0 or p1_left_y ~= 0 then
				player.body1.leftbullet.state = "moving"
				tempx, tempy = player.body1.leftarm.body:getWorldPoint(0, -PLAYER_ARM_SIZE.y/2 - 10)
				player.body1.leftbullet.body = love.physics.newBody(world, tempx, tempy, "dynamic")
				player.body1.leftbullet.shape = love.physics.newCircleShape(BULLET_RADIUS)
				player.body1.leftbullet.fixture = love.physics.newFixture(player.body1.leftbullet.body, player.body1.leftbullet.shape)
				player.body1.leftbullet.fixture:setGroupIndex(-1)
				-- player.body1.leftbullet.body:applyLinearImpulse(math.cos(player.body1.leftarm.body:getAngle()-math.pi/2) * BULLET_IMPULSE, math.sin(player.body1.leftarm.body:getAngle()-math.pi/2) * BULLET_IMPULSE)
				player.body1.leftbullet.body:applyLinearImpulse(p1_left_x * BULLET_IMPULSE, p1_left_y * BULLET_IMPULSE)
			end
		elseif player.body1.leftbullet.state == "toAttach" then
			player.body1.leftbullet.state = "attached"
			tempx, tempy = player.body1.leftarm.body:getWorldPoint(0, -PLAYER_ARM_SIZE.y/2+PLAYER_ARM_SIZE.x/2)
			player.body1.leftbullet.distance_joint = love.physics.newDistanceJoint(player.body1.leftarm.body, player.body1.leftbullet.collisionBody, tempx, tempy, player.body1.leftbullet.collisionX, player.body1.leftbullet.collisionY, true)
			killLeftBullet()
			end
		else
			if player.body1.leftbullet.state == "moving" then
				player.body1.leftbullet.state = "idle"
				killLeftBullet()
			elseif player.body1.leftbullet.state == "attached" then
				player.body1.leftbullet.state = "idle"

				player.body1.leftbullet.collisionBody = nil
				player.body1.leftbullet.collisionX = nil
				player.body1.leftbullet.collisionY = nil
				player.body1.leftbullet.distance_joint:destroy()
				player.body1.leftbullet.distance_joint = nil
			end
	end

	world:update(dt)
end

function love.draw()
	camera_transform = love.math.newTransform(-player.torso.body:getX()+WINDOW_WIDTH/2, -player.torso.body:getY()+WINDOW_HEIGHT/2, 0, 1, 1, 0, 0, 0, 0)

	love.graphics.applyTransform(camera_transform)

	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.draw(background_image, 0, 0, 0, 1, 1, 0, 0, 0, 0)

	love.graphics.setColor(1, 1, 1, 1)

	--draw player's torso
	-- love.graphics.polygon("line", player.torso.body:getWorldPoints(player.torso.shape:getPoints()))
	love.graphics.draw(torso_image, player.torso.body:getX(), player.torso.body:getY(), player.torso.body:getAngle(), 1, 1, PLAYER_BODY_SIZE.x/2, PLAYER_BODY_SIZE.y/2)

	--draw player's body1
	-- love.graphics.polygon("line", player.body1.leftarm.body:getWorldPoints(player.body1.leftarm.shape:getPoints()))
	-- love.graphics.polygon("line", player.body1.rightarm.body:getWorldPoints(player.body1.rightarm.shape:getPoints()))
	love.graphics.draw(p1_arm_image, player.body1.leftarm.body:getX(), player.body1.leftarm.body:getY(), player.body1.leftarm.body:getAngle(), 1, 1, PLAYER_ARM_SIZE.x/2, PLAYER_ARM_SIZE.y/2)
	love.graphics.draw(p1_arm_image, player.body1.rightarm.body:getX(), player.body1.rightarm.body:getY(), player.body1.rightarm.body:getAngle(), 1, 1, PLAYER_ARM_SIZE.x/2, PLAYER_ARM_SIZE.y/2)
	-- love.graphics.circle("line", player.body1.head.body:getX(), player.body1.head.body:getY(), player.body1.head.shape:getRadius())
	love.graphics.draw(p1_head_image, player.body1.head.body:getX(), player.body1.head.body:getY(), player.body1.head.body:getAngle(), 1, 1, PLAYER_HEAD_RADIUS, PLAYER_HEAD_RADIUS)

	--draw player's body2
	-- love.graphics.polygon("line", player.body2.leftarm.body:getWorldPoints(player.body2.leftarm.shape:getPoints()))
	-- love.graphics.polygon("line", player.body2.rightarm.body:getWorldPoints(player.body2.rightarm.shape:getPoints()))
	if player.body2.rightcooldown < THRUSTER_COOLDOWN then
		love.graphics.setColor(1, 1, 1, 0.5)
	else
		love.graphics.setColor(1, 1, 1, 1)
	end
	love.graphics.draw(p2_arm_image, player.body2.leftarm.body:getX(), player.body2.leftarm.body:getY(), player.body2.leftarm.body:getAngle(), 1, 1, PLAYER_ARM_SIZE.x/2, PLAYER_ARM_SIZE.y/2)

	if player.body2.leftcooldown < THRUSTER_COOLDOWN then
		love.graphics.setColor(1, 1, 1, 0.5)
	else
		love.graphics.setColor(1, 1, 1, 1)
	end
	love.graphics.draw(p2_arm_image, player.body2.rightarm.body:getX(), player.body2.rightarm.body:getY(), player.body2.rightarm.body:getAngle(), 1, 1, PLAYER_ARM_SIZE.x/2, PLAYER_ARM_SIZE.y/2)
	love.graphics.setColor(1, 1, 1, 1)
	-- love.graphics.circle("line", player.body2.head.body:getX(), player.body2.head.body:getY(), player.body2.head.shape:getRadius())
	love.graphics.draw(p2_head_image, player.body2.head.body:getX(), player.body2.head.body:getY(), player.body2.head.body:getAngle(), 1, 1, PLAYER_HEAD_RADIUS, PLAYER_HEAD_RADIUS)

	if left_blast_countdown > 0 then
		left_blast_countdown = left_blast_countdown - 1
		tempx, tempy = player.body2.rightarm.body:getWorldPoint(0, PLAYER_ARM_SIZE.y/2 + 10)
		love.graphics.draw(explosion_image, tempx, tempy, player.body2.rightarm.body:getAngle(), 1, 1, 10, 10)
	end

	if right_blast_countdown > 0 then
		right_blast_countdown = right_blast_countdown - 1
		tempx, tempy = player.body2.leftarm.body:getWorldPoint(0, PLAYER_ARM_SIZE.y/2 + 10)
		love.graphics.draw(explosion_image, tempx, tempy, player.body2.leftarm.body:getAngle(), 1, 1, 10, 10)
	end

	--draw player's grapples
	if player.body1.rightbullet.state == "moving" then
		love.graphics.setColor(0, 0, 0, 1)
		x1, y1 = player.body1.rightarm.body:getWorldPoint(0, -PLAYER_ARM_SIZE.y/2+PLAYER_ARM_SIZE.x)
		x2 = player.body1.rightbullet.body:getX()
		y2 = player.body1.rightbullet.body:getY()
		love.graphics.line(x1, y1, x2, y2)
	elseif player.body1.rightbullet.state == "attached" then
		if player.body1.rightbullet.distance_joint ~= nil then
			love.graphics.setColor(0, 0, 0.6, 1)
			love.graphics.line(player.body1.rightbullet.distance_joint:getAnchors())
		end
	end
	if player.body1.leftbullet.state == "moving" then
		love.graphics.setColor(0, 0, 0, 1)
		x1, y1 = player.body1.leftarm.body:getWorldPoint(0, -PLAYER_ARM_SIZE.y/2+PLAYER_ARM_SIZE.x)
		x2 = player.body1.leftbullet.body:getX()
		y2 = player.body1.leftbullet.body:getY()
		love.graphics.line(x1, y1, x2, y2)
	elseif player.body1.leftbullet.state == "attached" then
		if player.body1.leftbullet.distance_joint ~= nil then
			love.graphics.setColor(0, 0, 0.6, 1)
			love.graphics.line(player.body1.leftbullet.distance_joint:getAnchors())
		end
	end



	love.graphics.setColor(0, 0, 0, 1)

	for i, wall in ipairs(walls) do
		love.graphics.polygon("fill", wall.body:getWorldPoints(wall.shape:getPoints()))
	end

	love.graphics.setColor(0, 1, 0, 1)

	for i, wall in ipairs(death_walls) do
		love.graphics.polygon("fill", wall.body:getWorldPoints(wall.shape:getPoints()))
	end

	--draw ground
	-- love.graphics.polygon("fill", ground.body:getWorldPoints(ground.shape:getPoints()))


	--debuging

	-- love.graphics.print(love.physics.getMeter())
	-- love.graphics.print(-math.cos(player.body2.rightarm.body:getAngle()) * THRUSTER_FORCE .. " " .. -math.sin(player.body2.rightarm.body:getAngle()) * THRUSTER_FORCE)
	-- love.graphics.circle("fill", player.body1.leftarm.body:getX() + p1_left_x*50, player.body1.leftarm.body:getY() + p1_left_y*50, 5)
	-- love.graphics.circle("fill", player.body1.rightarm.body:getX() + p1_right_x*50, player.body1.rightarm.body:getY() + p1_right_y*50, 5)
	-- love.graphics.circle("fill", player.body2.leftarm.body:getX() + p2_right_x*50, player.body2.leftarm.body:getY() + p2_right_y*50, 5)
	-- love.graphics.circle("fill", player.body2.rightarm.body:getX() + p2_left_x*50, player.body2.rightarm.body:getY() + p2_left_y*50, 5)
	--
	-- if player.body1.rightbullet.body ~= nil then
	-- 	love.graphics.circle("fill", player.body1.rightbullet.body:getX(), player.body1.rightbullet.body:getY(), BULLET_RADIUS)
	-- end
	-- if player.body1.leftbullet.body ~= nil then
	-- 	love.graphics.circle("fill", player.body1.leftbullet.body:getX(), player.body1.leftbullet.body:getY(), BULLET_RADIUS)
	-- end
end
