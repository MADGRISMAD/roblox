-- Script principal del cliente
local SharedModule = require(game.ReplicatedStorage.SharedModule)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("Cliente iniciado!")
print(SharedModule.sayHello("Cliente"))

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

-- Esperar a que se creen los RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local punchEnemyEvent = remoteEvents:WaitForChild("PunchEnemy")
local updateCoinsEvent = remoteEvents:WaitForChild("UpdateCoins")

-- Variables para el sistema de golpe
local isOnCooldown = false
local COOLDOWN_TIME = 0.5 -- 0.5 segundos entre golpes
local playerCoins = 0

-- Variables para el sistema de doble salto
local jumpsUsed = 0
local maxJumps = SharedModule.getMaxJumps()
local isJumpOnCooldown = false
local lastJumpTime = 0

-- Variables para el sistema de sprint estilo Naruto
local isSprinting = false
local walkingStartTime = 0
local lastPosition = Vector3.new(0, 0, 0)
local sprintEffects = {}
local windSound = nil

-- Crear interfaz de monedas
local function createCoinUI()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Crear ScreenGui principal
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CoinGui"
    screenGui.Parent = playerGui
    
    -- Frame principal para las monedas
    local coinFrame = Instance.new("Frame")
    coinFrame.Size = UDim2.new(0, 200, 0, 60)
    coinFrame.Position = UDim2.new(0, 20, 0, 20)
    coinFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    coinFrame.BackgroundTransparency = 0.3
    coinFrame.BorderSizePixel = 2
    coinFrame.BorderColor3 = Color3.new(1, 1, 0)
    coinFrame.Parent = screenGui
    
    -- Esquinas redondeadas
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = coinFrame
    
    -- Ícono de moneda
    local coinIcon = Instance.new("TextLabel")
    coinIcon.Size = UDim2.new(0, 40, 0, 40)
    coinIcon.Position = UDim2.new(0, 10, 0, 10)
    coinIcon.BackgroundTransparency = 1
    coinIcon.Text = "💰"
    coinIcon.TextColor3 = Color3.new(1, 1, 0)
    coinIcon.TextScaled = true
    coinIcon.Font = Enum.Font.SourceSansBold
    coinIcon.Parent = coinFrame
    
    -- Texto de monedas
    local coinText = Instance.new("TextLabel")
    coinText.Size = UDim2.new(0, 140, 0, 40)
    coinText.Position = UDim2.new(0, 55, 0, 10)
    coinText.BackgroundTransparency = 1
    coinText.Text = "Monedas: " .. playerCoins
    coinText.TextColor3 = Color3.new(1, 1, 1)
    coinText.TextScaled = true
    coinText.Font = Enum.Font.SourceSansBold
    coinText.TextXAlignment = Enum.TextXAlignment.Left
    coinText.Parent = coinFrame
    
    return coinText
end

-- Crear la UI cuando el jugador esté listo
local coinDisplay = nil

-- Funciones para el sistema de doble salto
local function isCharacterOnGround(character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not humanoidRootPart or not humanoid then
        return true  -- Por seguridad, asumir que está en el suelo
    end
    
    -- Verificar si el humanoid está en estado de caída libre
    if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
        return false
    end
    
    -- Usar raycast para detectar el suelo
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}
    
    local ray = workspace:Raycast(
        humanoidRootPart.Position, 
        Vector3.new(0, -5, 0), 
        raycastParams
    )
    
    return ray ~= nil
end

local function createDoubleJumpEffect(character)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Crear efecto de partículas para el doble salto
    local jumpEffect = Instance.new("Explosion")
    jumpEffect.Position = humanoidRootPart.Position - Vector3.new(0, 2, 0)
    jumpEffect.BlastRadius = 5
    jumpEffect.BlastPressure = 0
    jumpEffect.Parent = workspace
    
    -- Crear sonido de doble salto
    local jumpSound = Instance.new("Sound")
    jumpSound.SoundId = "rbxasset://sounds/electronicpingsharp_loud.wav"
    jumpSound.Volume = 0.3
    jumpSound.Pitch = 1.5
    jumpSound.Parent = humanoidRootPart
    jumpSound:Play()
    
    -- Crear texto flotante
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0, 80, 0, 40)
    gui.StudsOffset = Vector3.new(0, 2, 0)
    gui.Parent = humanoidRootPart
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "¡DOBLE SALTO!"
    textLabel.TextColor3 = Color3.new(0, 1, 1)  -- Cian
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = gui
    
    -- Animar el texto hacia arriba
    local upTween = TweenService:Create(
        gui,
        TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {StudsOffset = Vector3.new(0, 5, 0)}
    )
    
    local fadeTween = TweenService:Create(
        textLabel,
        TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 1}
    )
    
    upTween:Play()
    fadeTween:Play()
    
    -- Limpiar después de la animación
    upTween.Completed:Connect(function()
        gui:Destroy()
    end)
    
    jumpSound.Ended:Connect(function()
        jumpSound:Destroy()
    end)
end

local function performJump()
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not humanoidRootPart then return end
    
    local currentTime = tick()
    
    -- Verificar cooldown de salto
    if isJumpOnCooldown or (currentTime - lastJumpTime) < SharedModule.getJumpCooldown() then
        return
    end
    
    local onGround = isCharacterOnGround(character)
    
    -- Si está en el suelo, resetear contador de saltos
    if onGround then
        jumpsUsed = 0
    end
    
    -- Verificar si puede saltar
    if jumpsUsed >= maxJumps then
        return  -- Ya usó todos los saltos disponibles
    end
    
    -- Ejecutar el salto
    local jumpPower = (jumpsUsed == 0) and SharedModule.getJumpPower() or SharedModule.getDoubleJumpPower()
    
    -- Crear BodyVelocity para el salto
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
    bodyVelocity.Velocity = Vector3.new(0, jumpPower, 0)
    bodyVelocity.Parent = humanoidRootPart
    
    -- Remover el BodyVelocity después de un momento
    game:GetService("Debris"):AddItem(bodyVelocity, 0.3)
    
    -- Incrementar contador de saltos
    jumpsUsed = jumpsUsed + 1
    
    -- Si es un doble salto, crear efectos especiales
    if jumpsUsed > 1 then
        createDoubleJumpEffect(character)
        print("¡Doble salto ejecutado!")
    else
        print("Salto normal ejecutado")
    end
    
    -- Activar cooldown temporal
    isJumpOnCooldown = true
    lastJumpTime = currentTime
    
    -- Resetear cooldown
    wait(SharedModule.getJumpCooldown())
    isJumpOnCooldown = false
end

-- Función para crear efecto visual de golpe
local function createPunchEffect(character)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Crear efecto de partículas o explosión visual
    local explosion = Instance.new("Explosion")
    explosion.Position = humanoidRootPart.Position + humanoidRootPart.CFrame.LookVector * 3
    explosion.BlastRadius = SharedModule.getPunchRange()
    explosion.BlastPressure = 0 -- Sin daño real, solo efecto visual
    explosion.Parent = workspace
    
    -- Crear sonido de golpe
    local punchSound = Instance.new("Sound")
    punchSound.SoundId = "rbxasset://sounds/impact_generic.mp3"
    punchSound.Volume = 0.5
    punchSound.Parent = humanoidRootPart
    punchSound:Play()
    
    -- Mostrar mensaje aleatorio de golpe
    local message = SharedModule.getRandomPunchMessage()
    print(message)
    
    -- Crear texto flotante con el mensaje
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0, 100, 0, 50)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.Parent = humanoidRootPart
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = message
    textLabel.TextColor3 = Color3.new(1, 1, 0) -- Amarillo
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = gui
    
    -- Animar el texto hacia arriba y que desaparezca
    local upTween = TweenService:Create(
        gui,
        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {StudsOffset = Vector3.new(0, 6, 0)}
    )
    
    local fadeTween = TweenService:Create(
        textLabel,
        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 1}
    )
    
    upTween:Play()
    fadeTween:Play()
    
    -- Limpiar después de la animación
    upTween.Completed:Connect(function()
        gui:Destroy()
    end)
    
    punchSound.Ended:Connect(function()
        punchSound:Destroy()
    end)
end

-- Función para animar el golpe
local function animatePunch(character)
    local humanoid = character:WaitForChild("Humanoid")
    local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand")
    
    if rightArm then
        -- Crear una animación simple de golpe moviendo el brazo
        local originalCFrame = rightArm.CFrame
        local punchCFrame = rightArm.CFrame * CFrame.new(0, 0, -2)
        
        -- Animación de ida (golpe)
        local punchTween = TweenService:Create(
            rightArm,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {CFrame = punchCFrame}
        )
        
        -- Animación de vuelta (recuperación)
        local returnTween = TweenService:Create(
            rightArm,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {CFrame = originalCFrame}
        )
        
        punchTween:Play()
        punchTween.Completed:Connect(function()
            returnTween:Play()
        end)
    end
end

-- Función para encontrar enemigos cercanos
local function findNearbyEnemies(character)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local nearbyEnemies = {}
    
    -- Buscar todos los enemigos en el workspace
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name == "Enemy" and obj:IsA("Part") then
            local distance = SharedModule.calculateDistance(
                humanoidRootPart.Position, 
                obj.Position
            )
            
            -- Si está dentro del rango de golpe
            if distance <= SharedModule.getPunchRange() then
                table.insert(nearbyEnemies, obj)
            end
        end
    end
    
    return nearbyEnemies
end

-- Función principal de golpe
local function performPunch()
    local character = player.Character
    if not character or isOnCooldown then
        return
    end
    
    print("¡Golpe ejecutado!")
    
    -- Activar cooldown
    isOnCooldown = true
    
    -- Ejecutar animación y efectos
    animatePunch(character)
    createPunchEffect(character)
    
    -- Buscar enemigos cercanos para golpear
    local nearbyEnemies = findNearbyEnemies(character)
    
    if #nearbyEnemies > 0 then
        -- Golpear al enemigo más cercano
        local closestEnemy = nearbyEnemies[1]
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        local closestDistance = SharedModule.calculateDistance(
            humanoidRootPart.Position, 
            closestEnemy.Position
        )
        
        -- Encontrar el enemigo más cercano
        for _, enemy in pairs(nearbyEnemies) do
            local distance = SharedModule.calculateDistance(
                humanoidRootPart.Position, 
                enemy.Position
            )
            if distance < closestDistance then
                closestEnemy = enemy
                closestDistance = distance
            end
        end
        
        -- Calcular daño
        local damage = SharedModule.getPunchDamage(1)
        
        -- Enviar golpe al servidor
        punchEnemyEvent:FireServer(closestEnemy, damage)
        
        print("¡Golpeaste a un enemigo!")
    else
        print("No hay enemigos cerca")
    end
    
    -- Resetear cooldown después del tiempo establecido
    wait(COOLDOWN_TIME)
    isOnCooldown = false
end

-- Detectar clic del mouse
mouse.Button1Down:Connect(function()
    performPunch()
end)

-- Detectar teclas para salto y golpe
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- ESPACIO para saltar (prioridad al salto)
    if input.KeyCode == Enum.KeyCode.Space then
        performJump()
    end
    
    -- F para golpear (nueva tecla para golpear)
    if input.KeyCode == Enum.KeyCode.F then
        performPunch()
    end
end)

-- Detectar salto usando el Humanoid.Jumping (método alternativo)
local function setupJumpDetection(character)
    local humanoid = character:WaitForChild("Humanoid")
    
    -- Detectar cuando el jugador intenta saltar
    humanoid.Jumping:Connect(function()
        -- Solo ejecutar nuestro sistema de salto personalizado
        performJump()
    end)
    
    -- Desactivar el salto automático de Roblox para tener control total
    humanoid.JumpPower = 0
end

-- Función para actualizar la UI de monedas
local function updateCoinDisplay(newAmount)
    playerCoins = newAmount
    if coinDisplay then
        coinDisplay.Text = "Monedas: " .. playerCoins
        
        -- Efecto de animación cuando ganas monedas
        local originalSize = coinDisplay.Size
        local biggerSize = UDim2.new(originalSize.X.Scale * 1.2, originalSize.X.Offset, 
                                   originalSize.Y.Scale * 1.2, originalSize.Y.Offset)
        
        local growTween = TweenService:Create(
            coinDisplay,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = biggerSize}
        )
        
        local shrinkTween = TweenService:Create(
            coinDisplay,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Size = originalSize}
        )
        
        growTween:Play()
        growTween.Completed:Connect(function()
            shrinkTween:Play()
        end)
    end
end

-- Escuchar actualizaciones de monedas del servidor
updateCoinsEvent.OnClientEvent:Connect(function(newAmount)
    updateCoinDisplay(newAmount)
    print("¡Monedas actualizadas! Total: " .. newAmount)
end)

player.CharacterAdded:Connect(function(character)
    print("Personaje creado para: " .. player.Name)
    print("=== CONTROLES ===")
    print("🥊 GOLPE: Clic izquierdo o tecla F")
    print("🦘 SALTO/DOBLE SALTO: Tecla ESPACIO")
    print("💰 OBJETIVO: ¡Derrota enemigos rojos para ganar monedas!")
    print("================")
    
    -- Resetear variables cuando aparezca un nuevo personaje
    isOnCooldown = false
    jumpsUsed = 0
    isJumpOnCooldown = false
    
    -- Configurar sistema de salto personalizado
    setupJumpDetection(character)
    
    -- Crear UI de monedas
    coinDisplay = createCoinUI()
    updateCoinDisplay(playerCoins)
end)
