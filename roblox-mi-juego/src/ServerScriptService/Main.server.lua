-- Servidor principal para Enter the Gungeon
local SharedModule = require(game.ReplicatedStorage.SharedModule)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Variables del juego
local currentRoom = nil
local enemies = {}
local bullets = {}
local items = {}
local playerStats = {}
local gameState = "playing" -- playing, paused, gameOver

-- Configuración
local roomConfig = SharedModule.getRoomConfig()
local enemyTypes = SharedModule.getEnemyTypes()
local bulletStats = SharedModule.getBulletStats()
local itemStats = SharedModule.getItemStats()
local soundIds = SharedModule.getSoundIds()

-- ===== CREACIÓN DE REMOTEEVENTS =====
local function createRemoteEvents()
    local remoteEvents = Instance.new("Folder")
    remoteEvents.Name = "RemoteEvents"
    remoteEvents.Parent = ReplicatedStorage
    
    local fireWeaponEvent = Instance.new("RemoteEvent")
    fireWeaponEvent.Name = "FireWeapon"
    fireWeaponEvent.Parent = remoteEvents
    
    local playerHurtEvent = Instance.new("RemoteEvent")
    playerHurtEvent.Name = "PlayerHurt"
    playerHurtEvent.Parent = remoteEvents
    
    local updateStatsEvent = Instance.new("RemoteEvent")
    updateStatsEvent.Name = "UpdateStats"
    updateStatsEvent.Parent = remoteEvents
    
    local rollEvent = Instance.new("RemoteEvent")
    rollEvent.Name = "Roll"
    rollEvent.Parent = remoteEvents
    
    local enemySpawnEvent = Instance.new("RemoteEvent")
    enemySpawnEvent.Name = "EnemySpawn"
    enemySpawnEvent.Parent = remoteEvents
    
    return {
        fireWeapon = fireWeaponEvent,
        playerHurt = playerHurtEvent,
        updateStats = updateStatsEvent,
        roll = rollEvent,
        enemySpawn = enemySpawnEvent
    }
end

local remoteEvents = createRemoteEvents()

-- ===== CREACIÓN DE HABITACIÓN =====
local function createRoom()
    local room = Instance.new("Model")
    room.Name = "GungeonRoom"
    room.Parent = workspace
    
    -- Suelo
    local floor = Instance.new("Part")
    floor.Name = "Floor"
    floor.Size = roomConfig.roomSize
    floor.Position = Vector3.new(0, -roomConfig.roomSize.Y/2, 0)
    floor.Material = Enum.Material.Wood
    floor.BrickColor = BrickColor.new("Brown")
    floor.Anchored = true
    floor.Parent = room
    
    -- Paredes
    local wallThickness = roomConfig.wallThickness
    local roomSize = roomConfig.roomSize
    
    -- Pared norte
    local northWall = Instance.new("Part")
    northWall.Name = "NorthWall"
    northWall.Size = Vector3.new(roomSize.X + wallThickness*2, roomSize.Y, wallThickness)
    northWall.Position = Vector3.new(0, 0, roomSize.Z/2 + wallThickness/2)
    northWall.Material = Enum.Material.Brick
    northWall.BrickColor = BrickColor.new("Dark stone grey")
    northWall.Anchored = true
    northWall.Parent = room
    
    -- Pared sur
    local southWall = Instance.new("Part")
    southWall.Name = "SouthWall"
    southWall.Size = Vector3.new(roomSize.X + wallThickness*2, roomSize.Y, wallThickness)
    southWall.Position = Vector3.new(0, 0, -roomSize.Z/2 - wallThickness/2)
    southWall.Material = Enum.Material.Brick
    southWall.BrickColor = BrickColor.new("Dark stone grey")
    southWall.Anchored = true
    southWall.Parent = room
    
    -- Pared este
    local eastWall = Instance.new("Part")
    eastWall.Name = "EastWall"
    eastWall.Size = Vector3.new(wallThickness, roomSize.Y, roomSize.Z)
    eastWall.Position = Vector3.new(roomSize.X/2 + wallThickness/2, 0, 0)
    eastWall.Material = Enum.Material.Brick
    eastWall.BrickColor = BrickColor.new("Dark stone grey")
    eastWall.Anchored = true
    eastWall.Parent = room
    
    -- Pared oeste
    local westWall = Instance.new("Part")
    westWall.Name = "WestWall"
    westWall.Size = Vector3.new(wallThickness, roomSize.Y, roomSize.Z)
    westWall.Position = Vector3.new(-roomSize.X/2 - wallThickness/2, 0, 0)
    westWall.Material = Enum.Material.Brick
    westWall.BrickColor = BrickColor.new("Dark stone grey")
    westWall.Anchored = true
    westWall.Parent = room
    
    -- Puerta sur (entrada)
    local door = Instance.new("Part")
    door.Name = "Door"
    door.Size = roomConfig.doorSize
    door.Position = Vector3.new(0, -roomSize.Y/2 + roomConfig.doorSize.Y/2, -roomSize.Z/2 - wallThickness/2)
    door.Material = Enum.Material.Wood
    door.BrickColor = BrickColor.new("Dark orange")
    door.Anchored = true
    door.Parent = room
    
    -- Crear un hueco en la pared sur para la puerta
    local doorHole = Instance.new("Part")
    doorHole.Name = "DoorHole"
    doorHole.Size = Vector3.new(roomConfig.doorSize.X + 1, roomConfig.doorSize.Y + 1, wallThickness + 1)
    doorHole.Position = door.Position
    doorHole.Material = Enum.Material.Air
    doorHole.Transparency = 1
    doorHole.CanCollide = false
    doorHole.Anchored = true
    doorHole.Parent = room
    
    return room
end

-- ===== SISTEMA DE BALAS =====
local function createBullet(startPosition, direction, bulletType, owner)
    local bullet = Instance.new("Part")
    bullet.Name = "Bullet"
    bullet.Size = bulletType.size
    bullet.Material = Enum.Material.Neon
    bullet.BrickColor = BrickColor.new(bulletType.color)
    bullet.Shape = Enum.PartType.Ball
    bullet.CanCollide = false
    bullet.Anchored = false
    bullet.Position = startPosition
    
    -- BodyVelocity para movimiento
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = direction * bulletType.speed
    bodyVelocity.Parent = bullet
    
    -- Información de la bala
    local bulletInfo = Instance.new("Folder")
    bulletInfo.Name = "BulletInfo"
    bulletInfo.Parent = bullet
    
    local ownerValue = Instance.new("StringValue")
    ownerValue.Name = "Owner"
    ownerValue.Value = owner
    ownerValue.Parent = bulletInfo
    
    local damageValue = Instance.new("IntValue")
    damageValue.Name = "Damage"
    damageValue.Value = 1
    damageValue.Parent = bulletInfo
    
    bullet.Parent = workspace
    table.insert(bullets, bullet)
    
    -- Destruir bala después del tiempo de vida
    Debris:AddItem(bullet, bulletType.lifetime)
    
    return bullet
end

-- ===== SISTEMA DE ENEMIGOS =====
local function createEnemy(enemyType, position)
    local enemy = Instance.new("Part")
    enemy.Name = "Enemy"
    enemy.Size = enemyType.size
    enemy.Material = Enum.Material.Neon
    enemy.BrickColor = BrickColor.new(enemyType.color)
    enemy.Shape = Enum.PartType.Ball
    enemy.Position = position
    enemy.Anchored = false
    
    -- Estadísticas del enemigo
    local stats = Instance.new("Folder")
    stats.Name = "Stats"
    stats.Parent = enemy
    
    local health = Instance.new("IntValue")
    health.Name = "Health"
    health.Value = enemyType.health
    health.Parent = stats
    
    local maxHealth = Instance.new("IntValue")
    maxHealth.Name = "MaxHealth"
    maxHealth.Value = enemyType.health
    maxHealth.Parent = stats
    
    local enemyTypeValue = Instance.new("StringValue")
    enemyTypeValue.Name = "EnemyType"
    enemyTypeValue.Value = "bulletKin" -- Por ahora solo bulletKin
    enemyTypeValue.Parent = stats
    
    local lastFireTime = Instance.new("NumberValue")
    lastFireTime.Name = "LastFireTime"
    lastFireTime.Value = 0
    lastFireTime.Parent = stats
    
    local targetPlayer = Instance.new("ObjectValue")
    targetPlayer.Name = "TargetPlayer"
    targetPlayer.Parent = stats
    
    -- IA básica del enemigo
    local humanoid = Instance.new("Humanoid")
    humanoid.WalkSpeed = enemyType.speed
    humanoid.MaxHealth = enemyType.health
    humanoid.Health = enemyType.health
    humanoid.Parent = enemy
    
    -- BodyPosition para movimiento suave
    local bodyPosition = Instance.new("BodyPosition")
    bodyPosition.MaxForce = Vector3.new(4000, 0, 4000)
    bodyPosition.P = 3000
    bodyPosition.D = 500
    bodyPosition.Parent = enemy
    
    enemy.Parent = workspace
    table.insert(enemies, enemy)
    
    return enemy
end

-- ===== IA DE ENEMIGOS =====
local function updateEnemyAI(enemy)
    local stats = enemy:FindFirstChild("Stats")
    if not stats then return end
    
    local health = stats:FindFirstChild("Health")
    local enemyType = stats:FindFirstChild("EnemyType")
    local lastFireTime = stats:FindFirstChild("LastFireTime")
    local targetPlayer = stats:FindFirstChild("TargetPlayer")
    
    if not health or health.Value <= 0 then return end
    
    -- Encontrar jugador más cercano
    local closestPlayer = nil
    local closestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = SharedModule.calculateDistance(
                enemy.Position,
                player.Character.HumanoidRootPart.Position
            )
            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = player
            end
        end
    end
    
    if closestPlayer then
        targetPlayer.Value = closestPlayer
        
        local humanoid = enemy:FindFirstChild("Humanoid")
        local bodyPosition = enemy:FindFirstChild("BodyPosition")
        
        if humanoid and bodyPosition then
            local targetPosition = closestPlayer.Character.HumanoidRootPart.Position
            
            -- Mantener distancia del jugador
            local direction = SharedModule.getDirectionToTarget(enemy.Position, targetPosition)
            local desiredPosition = targetPosition - direction * 8
            
            bodyPosition.Position = desiredPosition
            
            -- Disparar al jugador
            local currentTime = tick()
            local enemyTypeData = enemyTypes[enemyType.Value]
            
            if currentTime - lastFireTime.Value >= enemyTypeData.fireRate then
                local shootDirection = SharedModule.getDirectionToTarget(enemy.Position, targetPosition)
                createBullet(enemy.Position, shootDirection, bulletStats.enemyBullet, "Enemy")
                
                lastFireTime.Value = currentTime
                
                -- Efecto de fogonazo
                SharedModule.createMuzzleFlash(enemy.Position, shootDirection)
            end
        end
    end
end

-- ===== SISTEMA DE COLISIONES =====
local function handleBulletCollision(bullet)
    local bulletInfo = bullet:FindFirstChild("BulletInfo")
    if not bulletInfo then 
        bullet:Destroy()
        return 
    end
    
    local owner = bulletInfo:FindFirstChild("Owner")
    local damage = bulletInfo:FindFirstChild("Damage")
    
    if not owner or not damage then 
        bullet:Destroy()
        return 
    end
    
    -- Verificar colisión con enemigos (si es bala del jugador)
    if owner.Value == "Player" then
        for _, enemy in pairs(enemies) do
            if enemy.Parent and SharedModule.calculateDistance(bullet.Position, enemy.Position) < 3 then
                local enemyStats = enemy:FindFirstChild("Stats")
                if enemyStats then
                    local health = enemyStats:FindFirstChild("Health")
                    if health and health.Value > 0 then
                        health.Value = health.Value - damage.Value
                        
                        -- Efecto de daño
                        SharedModule.createDamageNumber(enemy.Position, damage.Value, false)
                        
                        if health.Value <= 0 then
                            -- Enemigo muerto
                            SharedModule.createExplosionEffect(enemy.Position, 5, enemy.BrickColor.Color)
                            SharedModule.playSound(soundIds.enemyDeath, 0.5, 1, workspace)
                            
                            -- Remover de la lista
                            for i, e in pairs(enemies) do
                                if e == enemy then
                                    table.remove(enemies, i)
                                    break
                                end
                            end
                            
                            enemy:Destroy()
                        end
                    end
                end
                bullet:Destroy()
                return
            end
        end
    end
    
    -- Verificar colisión con jugador (si es bala de enemigo)
    if owner.Value == "Enemy" then
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                if SharedModule.calculateDistance(bullet.Position, player.Character.HumanoidRootPart.Position) < 3 then
                    -- Dañar jugador
                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        humanoid.Health = humanoid.Health - damage.Value
                        
                        -- Notificar al cliente
                        remoteEvents.playerHurt:FireClient(player, humanoid.Health, humanoid.MaxHealth)
                        
                        -- Efecto de daño
                        SharedModule.createDamageNumber(player.Character.HumanoidRootPart.Position, damage.Value, false)
                        SharedModule.playSound(soundIds.playerHurt, 0.7, 1, workspace)
                        
                        if humanoid.Health <= 0 then
                            -- Jugador muerto
                            print(player.Name .. " ha muerto!")
                        end
                    end
                    bullet:Destroy()
                    return
                end
            end
        end
    end
    
    -- Verificar colisión con paredes usando raycast
    local room = workspace:FindFirstChild("GungeonRoom")
    if room then
        for _, part in pairs(room:GetChildren()) do
            if part:IsA("Part") and part.Name ~= "Floor" and part.Name ~= "Door" then
                -- Usar raycast para detectar colisión más precisa
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
                raycastParams.FilterDescendantsInstances = {part}
                
                local ray = workspace:Raycast(bullet.Position, bullet.CFrame.LookVector * 2, raycastParams)
                if ray then
                    bullet:Destroy()
                    return
                end
            end
        end
    end
    
    -- Destruir bala si sale del área de la habitación
    local roomCenter = Vector3.new(0, 0, 0)
    local roomSize = roomConfig.roomSize
    if not SharedModule.isPositionInRoom(bullet.Position, roomCenter, roomSize) then
        bullet:Destroy()
        return
    end
end

-- ===== SPAWN DE ENEMIGOS =====
local function spawnEnemyWave()
    if not currentRoom then return end
    
    local spawnPositions = {
        Vector3.new(-15, 2, -15),
        Vector3.new(15, 2, -15),
        Vector3.new(-15, 2, 15),
        Vector3.new(15, 2, 15)
    }
    
    for _, position in pairs(spawnPositions) do
        local enemyType = "bulletKin"
        createEnemy(enemyTypes[enemyType], position)
    end
end

-- ===== EVENTOS =====
remoteEvents.fireWeapon.OnServerEvent:Connect(function(player, weaponName, direction, position)
    local weaponStats = SharedModule.getWeaponStats()
    local weapon = weaponStats[weaponName]
    if not weapon then return end
    
    -- Crear bala del jugador
    local bulletType = bulletStats.playerBullet
    createBullet(position, direction, bulletType, "Player")
    
    -- Si es shotgun, crear múltiples balas
    if weaponName == "shotgun" then
        for i = 1, weapon.pellets - 1 do
            local spreadDirection = SharedModule.addSpreadToDirection(direction, weapon.spread)
            createBullet(position, spreadDirection, bulletType, "Player")
        end
    end
end)

remoteEvents.roll.OnServerEvent:Connect(function(player, direction, position)
    -- El roll se maneja principalmente en el cliente
    -- Aquí podríamos agregar lógica adicional del servidor si es necesario
end)

-- ===== BUCLE PRINCIPAL =====
local lastEnemySpawn = 0
local enemySpawnInterval = 10 -- segundos

RunService.Heartbeat:Connect(function()
    -- Actualizar IA de enemigos
    for _, enemy in pairs(enemies) do
        if enemy.Parent then
            updateEnemyAI(enemy)
        end
    end
    
    -- Manejar colisiones de balas
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        if bullet.Parent then
            handleBulletCollision(bullet)
        else
            table.remove(bullets, i)
        end
    end
    
    -- Spawn de enemigos
    local currentTime = tick()
    if currentTime - lastEnemySpawn >= enemySpawnInterval then
        spawnEnemyWave()
        lastEnemySpawn = currentTime
    end
end)

-- ===== INICIALIZACIÓN =====
print("=== ENTER THE GUNGEON SERVER INICIADO ===")
print("🎮 Creando habitación del Gungeon...")

-- Crear habitación
currentRoom = createRoom()

-- Configurar jugadores
Players.PlayerAdded:Connect(function(player)
    print("Jugador conectado: " .. player.Name)
    
    -- Inicializar estadísticas del jugador
    playerStats[player.UserId] = {
        health = 6,
        ammo = 999,
        keys = 0,
        currentWeapon = "pistol"
    }
    
    player.CharacterAdded:Connect(function(character)
        print("Personaje de " .. player.Name .. " está listo!")
        
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.WalkSpeed = 16
        humanoid.MaxHealth = 6
        humanoid.Health = 6
        
        -- Posicionar jugador en la habitación
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        humanoidRootPart.Position = Vector3.new(0, 2, -15)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    print("Jugador desconectado: " .. player.Name)
    playerStats[player.UserId] = nil
end)

print("✅ Servidor listo! Esperando jugadores...")
