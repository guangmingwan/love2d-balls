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
    local x = 50
    local y = 50
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

    -- 创建网格
    grid = createGrid(40, 30, 20, 20)

    -- 初始化路径
    path = findPath(grid, {x = 1, y = 1}, {x = 40, y = 30})

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

    -- 红色小球移动
    if path and #path > 0 then
        local nextNode = path[1]
        local targetX = nextNode.x * 20 + 10
        local targetY = nextNode.y * 20 + 10

        local dx = targetX - redBall.body:getX()
        local dy = targetY - redBall.body:getY()
        local distance = math.sqrt(dx * dx + dy * dy)

        if distance > 1 then
            local angle = math.atan2(dy, dx)
            local force = 1000
            redBall.body:applyLinearImpulse(math.cos(angle) * force, math.sin(angle) * force)
        else
            table.remove(path, 1)
        end
    end

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

    -- 绘制网格
    drawGrid(grid)

    -- 绘制红色小球
    love.graphics.setColor(redBall.color)
    love.graphics.circle("fill", redBall.body:getX(), redBall.body:getY(), redBall.radius)

    -- 绘制绿色小球
    for i, ball in ipairs(balls) do
        love.graphics.setColor(ball.color)
        love.graphics.circle("fill", ball.body:getX(), ball.body:getY(), ball.radius)
    end

    -- 绘制路径（调试用）
    if path then
        love.graphics.setColor(1, 1, 0, 0.5)
        for i, node in ipairs(path) do
            love.graphics.rectangle("fill", node.x * 20, node.y * 20, 20, 20)
        end
    end

    -- 如果没有找到路径，打印寻路失败的信息
    if not path or #path == 0 then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.print("find path fail", 10, 10)
    end

    -- 输出网格状态（调试用）
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Grid Status:", 10, 40)
    for y = 1, #grid do
        local line = ""
        for x = 1, #grid[y] do
            if grid[y][x].walkable then
                line = line .. "0 "
            else
                line = line .. "1 "
            end
        end
        love.graphics.print(line, 10, 40 + y * 15)
    end
end

-- 处理键盘输入
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "space" then
        -- 重置游戏
        for i, ball in ipairs(balls) do
            ball.body:setPosition(math.random(50, 750), math.random(50, 550))
            ball.body:setLinearVelocity(0, 0)
        end
        redBall.body:setPosition(50, 50)
        redBall.body:setLinearVelocity(0, 0)

        -- 创建网格
        grid = createGrid(40, 30, 20, 20)

        -- 初始化路径
        path = findPath(grid, {x = 1, y = 1}, {x = 40, y = 30})

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

-- 创建网格
function createGrid(rows, cols, cellWidth, cellHeight)
    local grid = {}
    for y = 1, rows do
        grid[y] = {}
        for x = 1, cols do
            grid[y][x] = {walkable = true}
        end
    end

    -- 标记绿色小球所在的格子为不可行走
    for i, ball in ipairs(balls) do
        local x, y = ball.body:getPosition()
        local gridX = math.floor(x / cellWidth) + 1
        local gridY = math.floor(y / cellHeight) + 1
        if grid[gridY] and grid[gridY][gridX] then
            grid[gridY][gridX].walkable = false
        end
    end

    return grid
end

-- A*寻路算法
function findPath(grid, startNode, endNode)
    local openSet = {}
    local closedSet = {}
    local cameFrom = {}

    local gScore = {}
    local fScore = {}

    for y = 1, #grid do
        gScore[y] = {}
        fScore[y] = {}
        for x = 1, #grid[y] do
            gScore[y][x] = math.huge
            fScore[y][x] = math.huge
        end
    end

    gScore[startNode.y][startNode.x] = 0
    fScore[startNode.y][startNode.x] = heuristic(startNode, endNode)

    table.insert(openSet, startNode)

    while #openSet > 0 do
        local currentNode = getLowestFScore(openSet, fScore)
        if currentNode.x == endNode.x and currentNode.y == endNode.y then
            return reconstructPath(cameFrom, currentNode)
        end

        table.remove(openSet, indexOf(openSet, currentNode))
        table.insert(closedSet, currentNode)

        for _, neighbor in ipairs(getNeighbors(grid, currentNode)) do
            if not contains(closedSet, neighbor) then
                local tentativeGScore = gScore[currentNode.y][currentNode.x] + 1

                if not contains(openSet, neighbor) then
                    table.insert(openSet, neighbor)
                elseif tentativeGScore >= gScore[neighbor.y][neighbor.x] then
                    goto continue
                end

                cameFrom[neighbor] = currentNode
                gScore[neighbor.y][neighbor.x] = tentativeGScore
                fScore[neighbor.y][neighbor.x] = gScore[neighbor.y][neighbor.x] + heuristic(neighbor, endNode)

                ::continue::
            end
        end
    end

    return nil
end

-- 获取最低F分数的节点
function getLowestFScore(set, fScore)
    local lowestNode = set[1]
    for _, node in ipairs(set) do
        if fScore[node.y][node.x] < fScore[lowestNode.y][lowestNode.x] then
            lowestNode = node
        end
    end
    return lowestNode
end

-- 获取邻居节点
function getNeighbors(grid, node)
    local neighbors = {}
    local directions = {{0, 1}, {1, 0}, {0, -1}, {-1, 0}}

    for _, direction in ipairs(directions) do
        local x = node.x + direction[1]
        local y = node.y + direction[2]
        if grid[y] and grid[y][x] and grid[y][x].walkable then
            table.insert(neighbors, {x = x, y = y})
        end
    end

    return neighbors
end

-- 启发式函数（曼哈顿距离）
function heuristic(a, b)
    return math.abs(a.x - b.x) + math.abs(a.y - b.y)
end

-- 重建路径
function reconstructPath(cameFrom, currentNode)
    local totalPath = {currentNode}
    while cameFrom[currentNode] do
        currentNode = cameFrom[currentNode]
        table.insert(totalPath, 1, currentNode)
    end
    return totalPath
end

-- 检查集合中是否包含某个节点
function contains(set, node)
    for _, element in ipairs(set) do
        if element.x == node.x and element.y == node.y then
            return true
        end
    end
    return false
end

-- 获取节点在集合中的索引
function indexOf(set, node)
    for i, element in ipairs(set) do
        if element.x == node.x and element.y == node.y then
            return i
        end
    end
    return nil
end

-- 绘制网格
function drawGrid(grid)
    local cellWidth = 20
    local cellHeight = 20

    for y = 1, #grid do
        for x = 1, #grid[y] do
            if grid[y][x].walkable then
                love.graphics.setColor(0, 0, 0, 0.1) -- 可行走格子
            else
                love.graphics.setColor(0, 0, 0, 0.5) -- 不可行走格子
            end
            love.graphics.rectangle("line", (x - 1) * cellWidth, (y - 1) * cellHeight, cellWidth, cellHeight)
        end
    end
end