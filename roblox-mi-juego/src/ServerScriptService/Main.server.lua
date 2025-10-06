-- Script principal del servidor
local SharedModule = require(game.ReplicatedStorage.SharedModule)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

print("Servidor iniciado!")
print(SharedModule.sayHello("Servidor"))

-- Crear RemoteEvents para comunicación cliente-servidor
local remoteEvents = Instance.new("Folder")
remoteEvents.Name = "RemoteEvents"
remoteEvents.Parent = ReplicatedStorage

local punchEnemyEvent = Instance.new("RemoteEvent")
punchEnemyEvent.Name = "PunchEnemy"
punchEnemyEvent.Parent = remoteEvents

local updateCoinsEvent = Instance.new("RemoteEvent")
updateCoinsEvent.Name = "UpdateCoins"
updateCoinsEvent.Parent = remoteEvents

-- Variables del sistema de enemigos
local playerCoins = {}  -- Tabla para almacenar monedas de cada jugador
local enemies = {}      -- Tabla para rastrear enemigos activos
local ENEMY_SPAWN_RATE = 3  -- Segundos entre spawns
local lastSpawnTime = 0

-- Función para crear un enemigo
local function createEnemy()
    local enemy = Instance.new("Part")
    enemy.Name = "Enemy"
    enemy.Size = SharedModule.getEnemySize()
    enemy.Material = Enum.Material.Neon
    enemy.BrickColor = BrickColor.new("Really red")
    enemy.Shape = Enum.PartType.Ball
    enemy.TopSurface = Enum.SurfaceType.Smooth
    enemy.BottomSurface = Enum.SurfaceType.Smooth
    
    -- Posición aleatoria en el cielo usando las funciones del módulo
    local spawnRange = SharedModule.getSpawnRange()
    local spawnX = math.random(-spawnRange, spawnRange)
    local spawnZ = math.random(-spawnRange, spawnRange)
    enemy.Position = Vector3.new(spawnX, SharedModule.getEnemySpawnHeight(), spawnZ)
    
    -- Añadir BodyVelocity para que caiga
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
    bodyVelocity.Velocity = Vector3.new(0, SharedModule.getEnemyFallSpeed(), 0)
    bodyVelocity.Parent = enemy
    
    -- Estadísticas del enemigo usando funciones del módulo
    local enemyStats = Instance.new("Folder")
    enemyStats.Name = "Stats"
    enemyStats.Parent = enemy
    
    local enemyHealth = SharedModule.getEnemyHealth()
    local health = Instance.new("IntValue")
    health.Name = "Health"
    health.Value = enemyHealth
    health.Parent = enemyStats
    
    local maxHealth = Instance.new("IntValue")
    maxHealth.Name = "MaxHealth"
    maxHealth.Value = enemyHealth
    maxHealth.Parent = enemyStats
    
    local coinReward = Instance.new("IntValue")
    coinReward.Name = "CoinReward"
    coinReward.Value = SharedModule.getCoinReward()
    coinReward.Parent = enemyStats
    
    -- Crear GUI de salud encima del enemigo
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 100, 0, 20)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = enemy
    
    local healthBar = Instance.new("Frame")
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.new(0, 1, 0)  -- Verde
    healthBar.BorderSizePixel = 1
    healthBar.Parent = billboardGui
    
    local healthBackground = Instance.new("Frame")
    healthBackground.Size = UDim2.new(1, 0, 1, 0)
    healthBackground.BackgroundColor3 = Color3.new(1, 0, 0)  -- Rojo
    healthBackground.ZIndex = healthBar.ZIndex - 1
    healthBackground.Parent = billboardGui
    
    -- Función para actualizar barra de salud
    local function updateHealthBar()
        local healthPercent = health.Value / maxHealth.Value
        healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
        
        -- Cambiar color según salud
        if healthPercent > 0.6 then
            healthBar.BackgroundColor3 = Color3.new(0, 1, 0)  -- Verde
        elseif healthPercent > 0.3 then
            healthBar.BackgroundColor3 = Color3.new(1, 1, 0)  -- Amarillo
        else
            healthBar.BackgroundColor3 = Color3.new(1, 0.5, 0)  -- Naranja
        end
    end
    
    health.Changed:Connect(updateHealthBar)
    
    enemy.Parent = workspace
    
    -- Agregar a la lista de enemigos
    table.insert(enemies, enemy)
    
    -- Destruir enemigo si toca el suelo
    enemy.Touched:Connect(function(hit)
        if hit.Name == "Baseplate" or hit.Parent == workspace.Terrain then
            -- Remover de la lista
            for i, e in pairs(enemies) do
                if e == enemy then
                    table.remove(enemies, i)
                    break
                end
            end
            enemy:Destroy()
        end
    end)
    
    print("Enemigo creado en posición:", enemy.Position)
    return enemy
end

-- Función para manejar golpes a enemigos
punchEnemyEvent.OnServerEvent:Connect(function(player, enemyPart, damage)
    if not enemyPart or not enemyPart.Parent then return end
    
    local stats = enemyPart:FindFirstChild("Stats")
    if not stats then return end
    
    local health = stats:FindFirstChild("Health")
    local coinReward = stats:FindFirstChild("CoinReward")
    
    if health and health.Value > 0 then
        -- Aplicar daño
        health.Value = math.max(0, health.Value - damage)
        
        print(player.Name .. " golpeó a un enemigo por " .. damage .. " de daño!")
        
        -- Si el enemigo muere
        if health.Value <= 0 then
            local coins = coinReward and coinReward.Value or 10
            
            -- Dar monedas al jugador
            playerCoins[player.UserId] = (playerCoins[player.UserId] or 0) + coins
            
            -- Informar al cliente sobre las nuevas monedas
            updateCoinsEvent:FireClient(player, playerCoins[player.UserId])
            
            print(player.Name .. " derrotó un enemigo y ganó " .. coins .. " monedas!")
            
            -- Remover enemigo de la lista
            for i, e in pairs(enemies) do
                if e == enemyPart then
                    table.remove(enemies, i)
                    break
                end
            end
            
            -- Destruir enemigo
            enemyPart:Destroy()
        end
    end
end)

-- Sistema de spawn automático de enemigos
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    
    if currentTime - lastSpawnTime >= ENEMY_SPAWN_RATE then
        -- Solo crear enemigos si hay jugadores
        if #game.Players:GetPlayers() > 0 then
            createEnemy()
            lastSpawnTime = currentTime
        end
    end
end)

-- Funcionalidad del servidor para el juego de golpes
game.Players.PlayerAdded:Connect(function(player)
    print("Jugador conectado: " .. player.Name)
    
    -- Inicializar monedas del jugador
    playerCoins[player.UserId] = playerCoins[player.UserId] or 0
    
    -- Cuando el jugador se conecta, configurar su personaje
    player.CharacterAdded:Connect(function(character)
        print("Personaje de " .. player.Name .. " está listo para jugar!")
        
        -- Agregar cualquier configuración adicional del personaje aquí
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.MaxHealth = 100
        humanoid.Health = 100
        
        -- Enviar monedas actuales al cliente
        wait(1)  -- Esperar a que el cliente esté listo
        updateCoinsEvent:FireClient(player, playerCoins[player.UserId])
    end)
end)

game.Players.PlayerRemoving:Connect(function(player)
    print("Jugador desconectado: " .. player.Name)
    -- Las monedas se mantienen guardadas para cuando regrese
end)
