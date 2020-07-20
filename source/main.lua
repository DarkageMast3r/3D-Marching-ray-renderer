local imgData = love.image.newImageData(600, 600)
local image = love.graphics.newImage(imgData)

local shader = love.graphics.newShader('shader.glsl')

local position = {0, 55, 0}
local rotation = {0, 0, 0}
local lastMouseX = love.mouse.getX()
local lastMouseY = love.mouse.getY()
local castShadows = false

local function mulVec3(a, b)
    if type(b) == 'number' then
        return {a[1] * b, a[2] * b, a[3] * b}
    else
        return {a[1] * b[1], a[2] * b[2], a[3] * b[3]}
    end
end

local function addVec3(a, b)
    return {a[1] + b[1], a[2] + b[2], a[3] + b[3]}
end

local function subVec3(a, b)
    return {a[1] - b[1], a[2] - b[2], a[3] - b[3]}
end


local function cframeFromAngles(x, y, z)
    x, y, z = math.rad(x), math.rad(y), math.rad(z)
    local fd, up, rt = {1, 0, 0}, {0, 1, 0}, {0, 0, 1}
    local nfd, nup, nrt = fd, up, rt

    nup = addVec3(mulVec3(up,  math.cos(x)),  mulVec3(rt, math.sin(x)))
    nrt = addVec3(mulVec3(up, -math.sin(x)),  mulVec3(rt, math.cos(x)))
    up, rt = nup, nrt

    nfd = addVec3(mulVec3(fd,  math.cos(z)),  mulVec3(up, math.sin(z)))
    nup = addVec3(mulVec3(fd, -math.sin(z)),  mulVec3(up, math.cos(z)))
    fd, up = nfd, nup

    nfd = addVec3(mulVec3(fd,  math.cos(y)),  mulVec3(rt, math.sin(y)))
    nrt = addVec3(mulVec3(fd, -math.sin(y)),  mulVec3(rt, math.cos(y)))
    fd, rt = nfd, nrt


    return {
        fd, up, rt
    }
end

function love.load()
    love.window.setMode(
        600, 600,
        {fullscreen = true}
    )
end

function love.update(dt)
    local deltaX = love.mouse.getX() - lastMouseX
    local deltaY = love.mouse.getY() - lastMouseY
    lastMouseX = love.mouse.getX()
    lastMouseY = love.mouse.getY()

    if love.mouse.isDown(1) then
        rotation = addVec3(
            rotation,
            {
                0,
                -deltaX,
                deltaY
            }
        )
    end

    local renderCF = cframeFromAngles(rotation[1], rotation[2], rotation[3])
    local curCF = cframeFromAngles(0, rotation[2], 0)

    if love.keyboard.isDown('w') then
        position = addVec3(position, curCF[1])
    end
    if love.keyboard.isDown('s') then
        position = subVec3(position, curCF[1])
    end
    if love.keyboard.isDown('space') then
        position = addVec3(position, {0, 1, 0})
    end
    if love.keyboard.isDown('lshift') then
        position = subVec3(position, {0, 1, 0})
    end
    if love.keyboard.isDown('d') then
        position = addVec3(position, curCF[3])
    end
    if love.keyboard.isDown('a') then
        position = subVec3(position, curCF[3])
    end

    shader:send('cframe', renderCF)
    shader:send('position', position)
    shader:send('time', love.timer.getTime())
    shader:send(
        'lights',
        {math.cos(love.timer.getTime() * 2 + math.pi) * 70.7, 70.7, math.sin(love.timer.getTime() * 2 + math.pi) * 70.7, 100},
        {math.cos(love.timer.getTime() * 2) * 70.7, 70.7, math.sin(love.timer.getTime() * 2) * 70.7, 100}
    )
end

function love.draw()
    love.graphics.setShader(shader)
    love.graphics.draw(
        image,
        love.graphics.getWidth()/2 - image:getWidth()/2,
        love.graphics.getHeight()/2 - image:getHeight()/2
    )
    love.graphics.setShader()
    love.graphics.print(
        ('FPS: %s'):format(love.timer.getFPS()),
        5, 5
    )
end

function love.keypressed(key)
    if key == 't' then
        castShadows = not castShadows
        shader:send('castShadows', castShadows)
    end
    if key == 'escape' then
        love.event.quit()
    end
end