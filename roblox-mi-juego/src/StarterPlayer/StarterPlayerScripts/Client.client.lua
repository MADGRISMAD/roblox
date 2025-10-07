-- Cliente principal para Enter the Gungeon
local SharedModule = require(game.ReplicatedStorage.SharedModule)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Variables del jugador
local playerStats = SharedModule.getPlayerStats()
local currentWeapon = "pistol"
local weaponStats = SharedModule.getWeaponStats()
local isRolling = false
local isInvulnerable = false
local lastFireTime = 0
local ammo = 999
local keys = 0

-- Variables de UI
local playerGui = nil
local healthDisplay = nil
local ammoDisplay = nil
local keysDisplay = nil
local crosshair = nil

-- Esperar a que se creen los RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local fireWeaponEvent = remoteEvents:WaitForChild("FireWeapon")
local playerHurtEvent = remoteEvents:WaitForChild("PlayerHurt")
local updateStatsEvent = remoteEvents:WaitForChild("UpdateStats")
local rollEvent = remoteEvents:WaitForChild("Roll")

-- ===== CREACIÓN DE UI =====
local function createUI()
    playerGui = player:WaitForChild("PlayerGui")
    
    -- Crear ScreenGui principal
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GungeonUI"
    screenGui.Parent = playerGui
    
    -- Frame principal con gradiente
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 350, 0, 120)
    mainFrame.Position = UDim2.new(0, 20, 0, 20)
    mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 15)
    mainCorner.Parent = mainFrame
    
    -- Borde con gradiente
    local borderFrame = Instance.new("Frame")
    borderFrame.Name = "BorderFrame"
    borderFrame.Size = UDim2.new(1, 4, 1, 4)
    borderFrame.Position = UDim2.new(0, -2, 0, -2)
    borderFrame.BackgroundColor3 = Color3.new(0.8, 0.4, 0.8)
    borderFrame.BorderSizePixel = 0
    borderFrame.ZIndex = mainFrame.ZIndex - 1
    borderFrame.Parent = mainFrame
    
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 17)
    borderCorner.Parent = borderFrame
    
    -- Título del juego
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "⚔️ ENTER THE GUNGEON ⚔️"
    titleLabel.TextColor3 = Color3.new(1, 0.8, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = mainFrame
    
    -- Display de salud con icono
    local healthContainer = Instance.new("Frame")
    healthContainer.Name = "HealthContainer"
    healthContainer.Size = UDim2.new(1, -20, 0, 25)
    healthContainer.Position = UDim2.new(0, 10, 0, 35)
    healthContainer.BackgroundTransparency = 1
    healthContainer.Parent = mainFrame
    
    local healthIcon = Instance.new("TextLabel")
    healthIcon.Name = "HealthIcon"
    healthIcon.Size = UDim2.new(0, 25, 1, 0)
    healthIcon.Position = UDim2.new(0, 0, 0, 0)
    healthIcon.BackgroundTransparency = 1
    healthIcon.Text = "❤️"
    healthIcon.TextColor3 = Color3.new(1, 0.2, 0.2)
    healthIcon.TextScaled = true
    healthIcon.Font = Enum.Font.SourceSansBold
    healthIcon.Parent = healthContainer
    
    healthDisplay = Instance.new("TextLabel")
    healthDisplay.Name = "HealthDisplay"
    healthDisplay.Size = UDim2.new(1, -30, 1, 0)
    healthDisplay.Position = UDim2.new(0, 30, 0, 0)
    healthDisplay.BackgroundTransparency = 1
    healthDisplay.Text = "Salud: 6/6"
    healthDisplay.TextColor3 = Color3.new(1, 1, 1)
    healthDisplay.TextScaled = true
    healthDisplay.Font = Enum.Font.SourceSansBold
    healthDisplay.TextXAlignment = Enum.TextXAlignment.Left
    healthDisplay.Parent = healthContainer
    
    -- Display de munición con icono
    local ammoContainer = Instance.new("Frame")
    ammoContainer.Name = "AmmoContainer"
    ammoContainer.Size = UDim2.new(1, -20, 0, 25)
    ammoContainer.Position = UDim2.new(0, 10, 0, 65)
    ammoContainer.BackgroundTransparency = 1
    ammoContainer.Parent = mainFrame
    
    local ammoIcon = Instance.new("TextLabel")
    ammoIcon.Name = "AmmoIcon"
    ammoIcon.Size = UDim2.new(0, 25, 1, 0)
    ammoIcon.Position = UDim2.new(0, 0, 0, 0)
    ammoIcon.BackgroundTransparency = 1
    ammoIcon.Text = "🔫"
    ammoIcon.TextColor3 = Color3.new(0.8, 0.8, 0.2)
    ammoIcon.TextScaled = true
    ammoIcon.Font = Enum.Font.SourceSansBold
    ammoIcon.Parent = ammoContainer
    
    ammoDisplay = Instance.new("TextLabel")
    ammoDisplay.Name = "AmmoDisplay"
    ammoDisplay.Size = UDim2.new(1, -30, 1, 0)
    ammoDisplay.Position = UDim2.new(0, 30, 0, 0)
    ammoDisplay.BackgroundTransparency = 1
    ammoDisplay.Text = "Munición: 999"
    ammoDisplay.TextColor3 = Color3.new(1, 1, 1)
    ammoDisplay.TextScaled = true
    ammoDisplay.Font = Enum.Font.SourceSansBold
    ammoDisplay.TextXAlignment = Enum.TextXAlignment.Left
    ammoDisplay.Parent = ammoContainer
    
    -- Display de llaves con icono
    local keysContainer = Instance.new("Frame")
    keysContainer.Name = "KeysContainer"
    keysContainer.Size = UDim2.new(1, -20, 0, 25)
    keysContainer.Position = UDim2.new(0, 10, 0, 95)
    keysContainer.BackgroundTransparency = 1
    keysContainer.Parent = mainFrame
    
    local keysIcon = Instance.new("TextLabel")
    keysIcon.Name = "KeysIcon"
    keysIcon.Size = UDim2.new(0, 25, 1, 0)
    keysIcon.Position = UDim2.new(0, 0, 0, 0)
    keysIcon.BackgroundTransparency = 1
    keysIcon.Text = "🗝️"
    keysIcon.TextColor3 = Color3.new(1, 1, 0.2)
    keysIcon.TextScaled = true
    keysIcon.Font = Enum.Font.SourceSansBold
    keysIcon.Parent = keysContainer
    
    keysDisplay = Instance.new("TextLabel")
    keysDisplay.Name = "KeysDisplay"
    keysDisplay.Size = UDim2.new(1, -30, 1, 0)
    keysDisplay.Position = UDim2.new(0, 30, 0, 0)
    keysDisplay.BackgroundTransparency = 1
    keysDisplay.Text = "Llaves: 0"
    keysDisplay.TextColor3 = Color3.new(1, 1, 1)
    keysDisplay.TextScaled = true
    keysDisplay.Font = Enum.Font.SourceSansBold
    keysDisplay.TextXAlignment = Enum.TextXAlignment.Left
    keysDisplay.Parent = keysContainer
    
    -- Crosshair mejorado
    crosshair = Instance.new("Frame")
    crosshair.Name = "Crosshair"
    crosshair.Size = UDim2.new(0, 30, 0, 30)
    crosshair.Position = UDim2.new(0.5, -15, 0.5, -15)
    crosshair.BackgroundTransparency = 0.3
    crosshair.BackgroundColor3 = Color3.new(1, 0.8, 0)
    crosshair.BorderSizePixel = 0
    crosshair.Parent = screenGui
    
    local crosshairCorner = Instance.new("UICorner")
    crosshairCorner.CornerRadius = UDim.new(0, 15)
    crosshairCorner.Parent = crosshair
    
    -- Efecto de parpadeo en el crosshair
    local crosshairTween = TweenService:Create(
        crosshair,
        TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundTransparency = 0.7}
    )
    crosshairTween:Play()
    
    -- Panel de controles mejorado
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "ControlsFrame"
    controlsFrame.Size = UDim2.new(0, 400, 0, 180)
    controlsFrame.Position = UDim2.new(0, 20, 1, -200)
    controlsFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    controlsFrame.BackgroundTransparency = 0.2
    controlsFrame.BorderSizePixel = 0
    controlsFrame.Parent = screenGui
    
    local controlsCorner = Instance.new("UICorner")
    controlsCorner.CornerRadius = UDim.new(0, 15)
    controlsCorner.Parent = controlsFrame
    
    -- Borde del panel de controles
    local controlsBorder = Instance.new("Frame")
    controlsBorder.Name = "ControlsBorder"
    controlsBorder.Size = UDim2.new(1, 4, 1, 4)
    controlsBorder.Position = UDim2.new(0, -2, 0, -2)
    controlsBorder.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    controlsBorder.BorderSizePixel = 0
    controlsBorder.ZIndex = controlsFrame.ZIndex - 1
    controlsBorder.Parent = controlsFrame
    
    local controlsBorderCorner = Instance.new("UICorner")
    controlsBorderCorner.CornerRadius = UDim.new(0, 17)
    controlsBorderCorner.Parent = controlsBorder
    
    -- Título de controles
    local controlsTitle = Instance.new("TextLabel")
    controlsTitle.Name = "ControlsTitle"
    controlsTitle.Size = UDim2.new(1, 0, 0, 30)
    controlsTitle.Position = UDim2.new(0, 0, 0, 0)
    controlsTitle.BackgroundTransparency = 1
    controlsTitle.Text = "🎮 CONTROLES"
    controlsTitle.TextColor3 = Color3.new(0.2, 1, 0.2)
    controlsTitle.TextScaled = true
    controlsTitle.Font = Enum.Font.SourceSansBold
    controlsTitle.Parent = controlsFrame
    
    -- Lista de controles
    local controlsText = Instance.new("TextLabel")
    controlsText.Size = UDim2.new(1, -20, 1, -40)
    controlsText.Position = UDim2.new(0, 10, 0, 35)
    controlsText.BackgroundTransparency = 1
    controlsText.Text = "WASD - Moverse\n🖱️ Mouse - Apuntar\n🖱️ Click - Disparar\nShift - Rodar (invulnerabilidad)\n1,2,3 - Cambiar arma\n🎯 Objetivo: ¡Sobrevive a las oleadas!"
    controlsText.TextColor3 = Color3.new(1, 1, 1)
    controlsText.TextScaled = true
    controlsText.Font = Enum.Font.SourceSans
    controlsText.TextXAlignment = Enum.TextXAlignment.Left
    controlsText.TextYAlignment = Enum.TextYAlignment.Top
    controlsText.Parent = controlsFrame
    
    -- Panel de arma actual
    local weaponFrame = Instance.new("Frame")
    weaponFrame.Name = "WeaponFrame"
    weaponFrame.Size = UDim2.new(0, 200, 0, 60)
    weaponFrame.Position = UDim2.new(1, -220, 0, 20)
    weaponFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    weaponFrame.BackgroundTransparency = 0.2
    weaponFrame.BorderSizePixel = 0
    weaponFrame.Parent = screenGui
    
    local weaponCorner = Instance.new("UICorner")
    weaponCorner.CornerRadius = UDim.new(0, 15)
    weaponCorner.Parent = weaponFrame
    
    -- Borde del panel de arma
    local weaponBorder = Instance.new("Frame")
    weaponBorder.Name = "WeaponBorder"
    weaponBorder.Size = UDim2.new(1, 4, 1, 4)
    weaponBorder.Position = UDim2.new(0, -2, 0, -2)
    weaponBorder.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    weaponBorder.BorderSizePixel = 0
    weaponBorder.ZIndex = weaponFrame.ZIndex - 1
    weaponBorder.Parent = weaponFrame
    
    local weaponBorderCorner = Instance.new("UICorner")
    weaponBorderCorner.CornerRadius = UDim.new(0, 17)
    weaponBorderCorner.Parent = weaponBorder
    
    -- Display de arma actual
    local weaponDisplay = Instance.new("TextLabel")
    weaponDisplay.Name = "WeaponDisplay"
    weaponDisplay.Size = UDim2.new(1, -20, 1, -20)
    weaponDisplay.Position = UDim2.new(0, 10, 0, 10)
    weaponDisplay.BackgroundTransparency = 1
    weaponDisplay.Text = "🔫 PISTOLA"
    weaponDisplay.TextColor3 = Color3.new(1, 1, 1)
    weaponDisplay.TextScaled = true
    weaponDisplay.Font = Enum.Font.SourceSansBold
    weaponDisplay.Parent = weaponFrame
    
    -- Guardar referencia para actualizaciones
    weaponFrame.WeaponDisplay = weaponDisplay
end

-- ===== ACTUALIZACIÓN DE UI =====
local function updateHealthDisplay(health, maxHealth)
    if healthDisplay then
        healthDisplay.Text = "❤️ Salud: " .. health .. "/" .. maxHealth
        healthDisplay.TextColor3 = health <= 2 and Color3.new(1, 0, 0) or Color3.new(1, 1, 1)
    end
end

local function updateAmmoDisplay()
    if ammoDisplay then
        ammoDisplay.Text = "🔫 Munición: " .. ammo
        ammoDisplay.TextColor3 = ammo <= 10 and Color3.new(1, 0, 0) or Color3.new(1, 1, 1)
    end
end

local function updateKeysDisplay()
    if keysDisplay then
        keysDisplay.Text = "🗝️ Llaves: " .. keys
    end
end

-- ===== SISTEMA DE DISPARO =====
local function canFire()
    local currentTime = tick()
    local weapon = weaponStats[currentWeapon]
    return currentTime - lastFireTime >= weapon.fireRate and ammo > 0
end

local function fireWeapon()
    if not canFire() then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local weapon = weaponStats[currentWeapon]
    lastFireTime = tick()
    
    -- Reducir munición
    if weapon.ammo ~= 999 then
        ammo = math.max(0, ammo - 1)
        updateAmmoDisplay()
    end
    
    -- Obtener dirección del mouse
    local mousePosition = mouse.Hit.Position
    local direction = SharedModule.getDirectionToTarget(humanoidRootPart.Position, mousePosition)
    
    -- Crear efecto de fogonazo
    local muzzlePosition = humanoidRootPart.Position + humanoidRootPart.CFrame.LookVector * 2
    SharedModule.createMuzzleFlash(muzzlePosition, direction)
    
    -- Reproducir sonido de disparo
    SharedModule.playSound(SharedModule.getSoundIds().shoot, 0.3, 1.2, humanoidRootPart)
    
    -- Enviar disparo al servidor
    fireWeaponEvent:FireServer(currentWeapon, direction, humanoidRootPart.Position)
end

-- ===== SISTEMA DE RODAR =====
local function canRoll()
    return not isRolling and not isInvulnerable
end

local function performRoll()
    if not canRoll() then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not humanoidRootPart then return end
    
    isRolling = true
    isInvulnerable = true
    
    -- Obtener dirección de movimiento
    local moveDirection = humanoid.MoveDirection
    if moveDirection.Magnitude == 0 then
        moveDirection = humanoidRootPart.CFrame.LookVector
    end
    
    -- Crear efecto visual de rodar
    SharedModule.createRollEffect(humanoidRootPart.Position, moveDirection)
    
    -- Reproducir sonido de rodar
    SharedModule.playSound(SharedModule.getSoundIds().roll, 0.5, 1, humanoidRootPart)
    
    -- Enviar roll al servidor
    rollEvent:FireServer(moveDirection, humanoidRootPart.Position)
    
    -- Aplicar velocidad de rodar
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
    bodyVelocity.Velocity = moveDirection * playerStats.rollSpeed
    bodyVelocity.Parent = humanoidRootPart
    
    -- Terminar el roll después de la duración
    wait(playerStats.rollDuration)
    bodyVelocity:Destroy()
    isRolling = false
    
    -- Mantener invulnerabilidad por un tiempo adicional
    wait(playerStats.invulnerabilityTime - playerStats.rollDuration)
    isInvulnerable = false
end

-- ===== CAMBIO DE ARMA =====
local function switchWeapon(weaponName)
    if weaponStats[weaponName] then
        currentWeapon = weaponName
        ammo = weaponStats[weaponName].ammo
        updateAmmoDisplay()
        print("Cambiado a: " .. weaponName)
    end
end

-- ===== MANEJO DE ENTRADA =====
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Cambio de armas
    if input.KeyCode == Enum.KeyCode.One then
        switchWeapon("pistol")
    elseif input.KeyCode == Enum.KeyCode.Two then
        switchWeapon("shotgun")
    elseif input.KeyCode == Enum.KeyCode.Three then
        switchWeapon("rifle")
    end
    
    -- Rodar
    if input.KeyCode == Enum.KeyCode.LeftShift then
        performRoll()
    end
end)

-- Disparo con mouse
mouse.Button1Down:Connect(function()
    fireWeapon()
end)

-- ===== EFECTOS VISUALES DE DAÑO =====
local function createDamageEffect()
    if not isInvulnerable then
        local character = player.Character
        if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        -- Crear efecto de parpadeo rojo
        local originalColor = humanoidRootPart.Color
        local flashTween = TweenService:Create(
            humanoidRootPart,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 3, true),
            {Color = Color3.new(1, 0, 0)}
        )
        
        flashTween:Play()
        flashTween.Completed:Connect(function()
            humanoidRootPart.Color = originalColor
        end)
        
        -- Reproducir sonido de daño
        SharedModule.playSound(SharedModule.getSoundIds().playerHurt, 0.7, 1, humanoidRootPart)
    end
end

-- ===== EVENTOS DEL SERVIDOR =====
playerHurtEvent.OnClientEvent:Connect(function(newHealth, maxHealth)
    createDamageEffect()
    updateHealthDisplay(newHealth, maxHealth)
end)

updateStatsEvent.OnClientEvent:Connect(function(stats)
    if stats.ammo then
        ammo = stats.ammo
        updateAmmoDisplay()
    end
    if stats.keys then
        keys = stats.keys
        updateKeysDisplay()
    end
end)

-- ===== INICIALIZACIÓN =====
player.CharacterAdded:Connect(function(character)
    print("=== ENTER THE GUNGEON ===")
    print("🎮 ¡Bienvenido al Gungeon!")
    print("💀 Sobrevive a las oleadas de enemigos")
    print("🔫 Encuentra armas y objetos")
    print("🏃 Usa el roll para esquivar balas")
    print("========================")
    
    -- Crear UI
    createUI()
    
    -- Configurar personaje
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.WalkSpeed = playerStats.moveSpeed
    humanoid.MaxHealth = playerStats.maxHealth
    humanoid.Health = playerStats.maxHealth
    
    -- Inicializar estadísticas
    updateHealthDisplay(playerStats.maxHealth, playerStats.maxHealth)
    updateAmmoDisplay()
    updateKeysDisplay()
    
    -- Configurar cámara
    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Scriptable
    
    -- Seguir al jugador con la cámara (vista isométrica)
    spawn(function()
        while character.Parent do
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                local cameraOffset = Vector3.new(0, 15, 20)
                camera.CFrame = CFrame.lookAt(
                    humanoidRootPart.Position + cameraOffset,
                    humanoidRootPart.Position
                )
            end
            RunService.Heartbeat:Wait()
        end
    end)
end)
