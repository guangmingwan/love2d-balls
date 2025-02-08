-- 初始化物理世界
local world = love.physics.newWorld(0, 0, true)

-- 定义小球半径
local ballRadius = 20

-- 定义小球列表
local balls = {}

-- 创建红色小球
local redBall = {}
redBall.body = love.physics.newBody(world, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, "dynamic")
redBall.shape = love.physics.newCircleShape(ballRadius)
redBall.fixture = love.physics.newFixture(redBall.body, redBall.shape, 1)
redBall.fixture:setRestitution(0.9)
redBall.color = {1, 0, 0} -- 红色
table.insert(balls, redBall)

-- 创建绿色小球
for i = 1, 8 do
    local greenBall = {}
    local x = math.random(ballRadius, love.graphics.getWidth() - ballRadius)
    local y = math.random(ballRadius, love.graphics.getHeight() - ballRadius)
    greenBall.body = love.physics.newBody(world, x, y, "dynamic")
    greenBall.shape = love.physics.newCircleShape(ballRadius)
    greenBall.fixture = love.physics.newFixture(greenBall.body, greenBall.shape, 1)
    greenBall.fixture:setRestitution(0.9)
    greenBall.color = {0, 1, 0} -- 绿色
    table.insert(balls, greenBall)
end

-- 爆炸函数
function explode(ball)
    local explosionForce = 1000
    for _, otherBall in ipairs(balls) do
        if otherBall ~= ball then
            local dx = otherBall.body:getX() - ball.body:getX()
            local dy = otherBall.body:getY() - ball.body:getY()
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance > 0 then
                local forceX = (dx / distance) * explosionForce
                local forceY = (dy / distance) * explosionForce
                otherBall.body:applyForce(forceX, forceY)
            end
        end
    end
end

-- 更新函数
function love.update(dt)
    world:update(dt)
end

-- 绘制函数
function love.draw()
    for _, ball in ipairs(balls) do
        love.graphics.setColor(ball.color)
        love.graphics.circle("fill", ball.body:getX(), ball.body:getY(), ball.shape:getRadius())
    end
end

-- 鼠标点击事件
function love.mousepressed(x, y, button)
    if button == 1 then
        explode(redBall)
    end
end
