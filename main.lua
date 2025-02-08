-- main.lua

-- 设置窗口大小
function love.load()
    love.window.setMode(800, 600)
    math.randomseed(os.time())

    -- 设置图像过滤模式以避免偏色
    love.graphics.setDefaultFilter("nearest", "nearest", 0)

    -- 加载背景图片
    background = love.graphics.newImage("wood_background.jpg")

    -- 确保颜色模式为白色
    love.graphics.setColor(1, 1, 1, 1)

    -- 创建物理世界
    world = love.physics.newWorld(0, 0, true)

    -- 初始化小球
    balls = {}
    for i = 1, 8 do
        local x = math.random(50, 750)
        local y = math.random(50, 550)
        local radius = 20
        local body = love.physics.newBody(world, x, y, "dynamic")
        local shape = love.physics.newCircleShape(radius)
        local fixture = love.physics.newFixture(body, shape, 3)
        fixture:setRestitution(1) -- 完全弹性碰撞
        fixture:setFriction(0) -- 没有摩擦

        table.insert(balls, {
            body = body,
            shape = shape,
            fixture = fixture,
            radius = radius,
            color = {0, 1, 0} -- 绿色
        })
    end

    -- 红色小球
    local x = math.random(50, 750)
    local y = math.random(50, 550)
    local radius = 20
    local body = love.physics.newBody(world, x, y, "dynamic")
    local shape = love.physics.newCircleShape(radius)
    local fixture = love.physics.newFixture(body, shape, 1)
    fixture:setRestitution(1) -- 完全弹性碰撞
    fixture:setFriction(0) -- 没有摩擦

    redBall = {
        body = body,
        shape = shape,
        fixture = fixture,
        radius = radius,
        color = {1, 0, 0} -- 红色
    }

    -- 立即爆炸红色小球
    for i, ball in ipairs(balls) do
        local angle = math.atan2(ball.body:getY() - redBall.body:getY(), ball.body:getX() - redBall.body:getX())
        local force = 5000
        ball.body:applyLinearImpulse(math.cos(angle) * force, math.sin(angle) * force)
    end
end

-- 更新游戏状态
function love.update(dt)
    world:update(dt)

    -- 手动添加阻力
    local friction = 0.89
    for i, ball in ipairs(balls) do
        local vx, vy = ball.body:getLinearVelocity()
        ball.body:setLinearVelocity(vx * friction, vy * friction)
    end

    local vx, vy = redBall.body:getLinearVelocity()
    redBall.body:setLinearVelocity(vx * friction, vy * friction)

    -- 给红色小球施加随机冲量，使其随机移动
    local forceMagnitude = math.random(50, 300) -- 冲量大小范围
    local angle = math.random() * 2 * math.pi -- 随机角度
    redBall.body:applyLinearImpulse(
        math.cos(angle) * forceMagnitude,
        math.sin(angle) * forceMagnitude
    )
    
    -- 边界检测
    for i, ball in ipairs(balls) do
        local x, y = ball.body:getPosition()
        local vx, vy = ball.body:getLinearVelocity()
        if x < ball.radius or x > love.graphics.getWidth() - ball.radius then
            ball.body:setX(math.clamp(x, ball.radius, love.graphics.getWidth() - ball.radius))
            ball.body:setLinearVelocity(-vx, vy)
        end
        if y < ball.radius or y > love.graphics.getHeight() - ball.radius then
            ball.body:setY(math.clamp(y, ball.radius, love.graphics.getHeight() - ball.radius))
            ball.body:setLinearVelocity(vx, -vy)
        end
    end

    local x, y = redBall.body:getPosition()
    local vx, vy = redBall.body:getLinearVelocity()
    if x < redBall.radius or x > love.graphics.getWidth() - redBall.radius then
        redBall.body:setX(math.clamp(x, redBall.radius, love.graphics.getWidth() - redBall.radius))
        redBall.body:setLinearVelocity(-vx, vy)
    end
    if y < redBall.radius or y > love.graphics.getHeight() - redBall.radius then
        redBall.body:setY(math.clamp(y, redBall.radius, love.graphics.getHeight() - redBall.radius))
        redBall.body:setLinearVelocity(vx, -vy)
    end
end

-- 绘制游戏画面
function love.draw()
    love.graphics.setColor(255, 255, 255, 255)
    -- 绘制背景图片
    love.graphics.draw(background, 0, 0)

    -- 绘制红色小球
    love.graphics.setColor(redBall.color)
    love.graphics.circle("fill", redBall.body:getX(), redBall.body:getY(), redBall.radius)

    -- 绘制绿色小球
    for i, ball in ipairs(balls) do
        love.graphics.setColor(ball.color)
        love.graphics.circle("fill", ball.body:getX(), ball.body:getY(), ball.radius)
    end
end

-- 处理键盘输入
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "space" then
        -- 重置游戏
        --for i, ball in ipairs(balls) do
        --    ball.body:setPosition(math.random(50, 750), math.random(50, 550))
        --    ball.body:setLinearVelocity(0, 0)
        --end
        redBall.body:setPosition(math.random(50, 750), math.random(50, 550))
        redBall.body:setLinearVelocity(math.random(-100, 100), math.random(-100, 100))

        -- 立即爆炸红色小球
        for i, ball in ipairs(balls) do
            local angle = math.atan2(ball.body:getY() - redBall.body:getY(), ball.body:getX() - redBall.body:getX())
            local force = 5000
            ball.body:applyLinearImpulse(math.cos(angle) * force, math.sin(angle) * force)
        end
    end
end

-- 辅助函数：限制值在min和max之间
function math.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- 处理鼠标点击
function love.mousepressed(x, y, button)
    if button == 1 then -- 左键点击
        for i, ball in ipairs(balls) do
            local dx = ball.body:getX() - x
            local dy = ball.body:getY() - y
            local distance = math.sqrt(dx * dx + dy * dy) - ball.shape:getRadius()*2 -- 修正距离计算
            if distance < 0 then distance = 0 end
            local force = 5000 / (distance + 1) -- 距离越近，力越大
            local angle = math.atan2(dy, dx)
            ball.body:applyLinearImpulse(math.cos(angle) * force, math.sin(angle) * force)
        end
    end
end