-- Cliente principal para Survival Capitalist Clicker
local SharedModule = require(game.ReplicatedStorage.SharedModule)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Variables del juego
local playerData = nil
local businessTypes = SharedModule.getBusinessTypes()
local upgradeTypes = SharedModule.getUpgradeTypes()
local soundIds = SharedModule.getSoundIds()

-- Variables de UI
local playerGui = nil
local screenGui = nil
local moneyDisplay = nil
local clickButton = nil
local businessFrame = nil
local upgradeFrame = nil
local achievementFrame = nil
local prestigeFrame = nil
local dailyRewardFrame = nil
local missionFrame = nil

-- Variables de animación y efectos
local clickCooldown = false
local businessTimers = {}
local activeEvents = {}
local clickStreak = 0
local lastClickTime = 0
local sessionClicks = 0
local sessionStartTime = tick()

-- Variables de accesibilidad
local autoClickerActive = false
local autoCollectorActive = false
local soundEnabled = true
local animationsEnabled = true

-- Esperar a que se creen los RemoteEvents con timeout
local remoteEvents = nil
local clickEvent = nil
local buyBusinessEvent = nil
local buyUpgradeEvent = nil
local collectBusinessEvent = nil
local saveDataEvent = nil
local loadDataEvent = nil

-- Función para esperar RemoteEvents con timeout
local function waitForRemoteEvents()
    local startTime = tick()
    while not remoteEvents and (tick() - startTime) < 10 do
        remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if remoteEvents then
            clickEvent = remoteEvents:FindFirstChild("Click")
            buyBusinessEvent = remoteEvents:FindFirstChild("BuyBusiness")
            buyUpgradeEvent = remoteEvents:FindFirstChild("BuyUpgrade")
            collectBusinessEvent = remoteEvents:FindFirstChild("CollectBusiness")
            saveDataEvent = remoteEvents:FindFirstChild("SaveData")
            loadDataEvent = remoteEvents:FindFirstChild("LoadData")
            break
        end
        wait(0.1)
    end
    
    if not remoteEvents then
        warn("⚠️ No se pudieron cargar los RemoteEvents")
        return false
    end
    
    return true
end

-- ===== ANIMACIONES =====
local function createClickAnimation()
    if clickCooldown then return end
    clickCooldown = true
    
    -- Animar el botón
    local originalSize = clickButton.Size
    local smallerSize = UDim2.new(originalSize.X.Scale * 0.9, originalSize.X.Offset * 0.9, 
                                 originalSize.Y.Scale * 0.9, originalSize.Y.Offset * 0.9)
    
    local shrinkTween = TweenService:Create(
        clickButton,
        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = smallerSize}
    )
    
    local growTween = TweenService:Create(
        clickButton,
        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = originalSize}
    )
    
    shrinkTween:Play()
    shrinkTween.Completed:Connect(function()
        growTween:Play()
        growTween.Completed:Connect(function()
            clickCooldown = false
        end)
    end)
    
    -- Crear partículas de dinero
    local clickPosition = Vector3.new(0, 0, 0)
    for i = 1, 5 do
        local randomOffset = Vector3.new(
            math.random(-50, 50),
            math.random(0, 50),
            math.random(-50, 50)
        )
        SharedModule.createParticleEffect(clickPosition + randomOffset, "Bright yellow", 0.5)
    end
end

-- ===== CONEXIÓN DE EVENTOS DE UI =====
local function connectUIEvents()
    -- Conectar evento del botón de click
    if clickButton then
        clickButton.MouseButton1Click:Connect(function()
            createClickAnimation()
            if clickEvent then
                clickEvent:FireServer()
            end
            if soundEnabled then
                SharedModule.playSound(soundIds.click, 0.3, 1, workspace)
            end
        end)
        print("✅ Evento de click conectado")
    else
        warn("❌ clickButton no encontrado")
    end
end

-- ===== CREACIÓN DE FRAMES DE CONTENIDO =====
local function createContentFrames(parent)
    -- Frame de negocios mejorado
    businessFrame = Instance.new("ScrollingFrame")
    businessFrame.Name = "BusinessFrame"
    businessFrame.Size = UDim2.new(0, 450, 0, 500)
    businessFrame.Position = UDim2.new(0, 20, 0, 100)
    businessFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    businessFrame.BackgroundTransparency = 0.1
    businessFrame.BorderSizePixel = 0
    businessFrame.ScrollBarThickness = 12
    businessFrame.ScrollBarImageColor3 = Color3.new(0.8, 0.8, 0.8)
    businessFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    businessFrame.Parent = parent
    
    local businessCorner = Instance.new("UICorner")
    businessCorner.CornerRadius = UDim.new(0, 15)
    businessCorner.Parent = businessFrame
    
    local businessGradient = Instance.new("UIGradient")
    businessGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.2, 0.2, 0.4)),
        ColorSequenceKeypoint.new(1, Color3.new(0.1, 0.1, 0.2))
    }
    businessGradient.Parent = businessFrame
    
    local businessTitle = Instance.new("TextLabel")
    businessTitle.Name = "BusinessTitle"
    businessTitle.Size = UDim2.new(1, 0, 0, 50)
    businessTitle.Position = UDim2.new(0, 0, 0, 0)
    businessTitle.BackgroundTransparency = 1
    businessTitle.Text = "🏪 NEGOCIOS"
    businessTitle.TextColor3 = Color3.new(1, 1, 1)
    businessTitle.TextScaled = true
    businessTitle.Font = Enum.Font.SourceSansBold
    businessTitle.TextStrokeTransparency = 0.5
    businessTitle.TextStrokeColor3 = Color3.new(0, 0, 0)
    businessTitle.Parent = businessFrame
    
    -- Frame de mejoras mejorado
    upgradeFrame = Instance.new("ScrollingFrame")
    upgradeFrame.Name = "UpgradeFrame"
    upgradeFrame.Size = UDim2.new(0, 350, 0, 500)
    upgradeFrame.Position = UDim2.new(1, -370, 0, 100)
    upgradeFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    upgradeFrame.BackgroundTransparency = 0.1
    upgradeFrame.BorderSizePixel = 0
    upgradeFrame.ScrollBarThickness = 12
    upgradeFrame.ScrollBarImageColor3 = Color3.new(0.8, 0.8, 0.8)
    upgradeFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    upgradeFrame.Parent = parent
    
    local upgradeCorner = Instance.new("UICorner")
    upgradeCorner.CornerRadius = UDim.new(0, 15)
    upgradeCorner.Parent = upgradeFrame
    
    local upgradeGradient = Instance.new("UIGradient")
    upgradeGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.2, 0.4, 0.2)),
        ColorSequenceKeypoint.new(1, Color3.new(0.1, 0.2, 0.1))
    }
    upgradeGradient.Parent = upgradeFrame
    
    local upgradeTitle = Instance.new("TextLabel")
    upgradeTitle.Name = "UpgradeTitle"
    upgradeTitle.Size = UDim2.new(1, 0, 0, 50)
    upgradeTitle.Position = UDim2.new(0, 0, 0, 0)
    upgradeTitle.BackgroundTransparency = 1
    upgradeTitle.Text = "⚡ MEJORAS"
    upgradeTitle.TextColor3 = Color3.new(1, 1, 1)
    upgradeTitle.TextScaled = true
    upgradeTitle.Font = Enum.Font.SourceSansBold
    upgradeTitle.TextStrokeTransparency = 0.5
    upgradeTitle.TextStrokeColor3 = Color3.new(0, 0, 0)
    upgradeTitle.Parent = upgradeFrame
    
    -- Frame de logros mejorado
    achievementFrame = Instance.new("ScrollingFrame")
    achievementFrame.Name = "AchievementFrame"
    achievementFrame.Size = UDim2.new(0, 300, 0, 200)
    achievementFrame.Position = UDim2.new(1, -320, 0, 620)
    achievementFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    achievementFrame.BackgroundTransparency = 0.1
    achievementFrame.BorderSizePixel = 0
    achievementFrame.ScrollBarThickness = 10
    achievementFrame.ScrollBarImageColor3 = Color3.new(0.8, 0.8, 0.8)
    achievementFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    achievementFrame.Parent = parent
    
    local achievementCorner = Instance.new("UICorner")
    achievementCorner.CornerRadius = UDim.new(0, 15)
    achievementCorner.Parent = achievementFrame
    
    local achievementGradient = Instance.new("UIGradient")
    achievementGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.4, 0.4, 0.2)),
        ColorSequenceKeypoint.new(1, ColorSequenceKeypoint.new(1, Color3.new(0.2, 0.2, 0.1)))
    }
    achievementGradient.Parent = achievementFrame
    
    local achievementTitle = Instance.new("TextLabel")
    achievementTitle.Name = "AchievementTitle"
    achievementTitle.Size = UDim2.new(1, 0, 0, 40)
    achievementTitle.Position = UDim2.new(0, 0, 0, 0)
    achievementTitle.BackgroundTransparency = 1
    achievementTitle.Text = "🏆 LOGROS"
    achievementTitle.TextColor3 = Color3.new(1, 1, 0)
    achievementTitle.TextScaled = true
    achievementTitle.Font = Enum.Font.SourceSansBold
    achievementTitle.TextStrokeTransparency = 0.5
    achievementTitle.TextStrokeColor3 = Color3.new(0, 0, 0)
    achievementTitle.Parent = achievementFrame
    
    -- Frame de recompensas diarias
    dailyRewardFrame = Instance.new("Frame")
    dailyRewardFrame.Name = "DailyRewardFrame"
    dailyRewardFrame.Size = UDim2.new(0, 300, 0, 150)
    dailyRewardFrame.Position = UDim2.new(0, 490, 0, 100)
    dailyRewardFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    dailyRewardFrame.BackgroundTransparency = 0.1
    dailyRewardFrame.BorderSizePixel = 0
    dailyRewardFrame.Parent = parent
    
    local dailyCorner = Instance.new("UICorner")
    dailyCorner.CornerRadius = UDim.new(0, 15)
    dailyCorner.Parent = dailyRewardFrame
    
    local dailyGradient = Instance.new("UIGradient")
    dailyGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.4, 0.2, 0.4)),
        ColorSequenceKeypoint.new(1, Color3.new(0.2, 0.1, 0.2))
    }
    dailyGradient.Parent = dailyRewardFrame
    
    local dailyTitle = Instance.new("TextLabel")
    dailyTitle.Name = "DailyTitle"
    dailyTitle.Size = UDim2.new(1, 0, 0, 40)
    dailyTitle.Position = UDim2.new(0, 0, 0, 0)
    dailyTitle.BackgroundTransparency = 1
    dailyTitle.Text = "🎁 RECOMPENSA DIARIA"
    dailyTitle.TextColor3 = Color3.new(1, 1, 0)
    dailyTitle.TextScaled = true
    dailyTitle.Font = Enum.Font.SourceSansBold
    dailyTitle.Parent = dailyRewardFrame
    
    local dailyButton = Instance.new("TextButton")
    dailyButton.Name = "DailyButton"
    dailyButton.Size = UDim2.new(1, -20, 0, 60)
    dailyButton.Position = UDim2.new(0, 10, 0, 50)
    dailyButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    dailyButton.BackgroundTransparency = 0.2
    dailyButton.BorderSizePixel = 0
    dailyButton.Text = "🎁 RECLAMAR"
    dailyButton.TextColor3 = Color3.new(1, 1, 1)
    dailyButton.TextScaled = true
    dailyButton.Font = Enum.Font.SourceSansBold
    dailyButton.Parent = dailyRewardFrame
    
    local dailyButtonCorner = Instance.new("UICorner")
    dailyButtonCorner.CornerRadius = UDim.new(0, 10)
    dailyButtonCorner.Parent = dailyButton
    
    local dailyStreakLabel = Instance.new("TextLabel")
    dailyStreakLabel.Name = "DailyStreakLabel"
    dailyStreakLabel.Size = UDim2.new(1, -20, 0, 30)
    dailyStreakLabel.Position = UDim2.new(0, 10, 0, 120)
    dailyStreakLabel.BackgroundTransparency = 1
    dailyStreakLabel.Text = "Racha: 0 días"
    dailyStreakLabel.TextColor3 = Color3.new(1, 1, 1)
    dailyStreakLabel.TextScaled = true
    dailyStreakLabel.Font = Enum.Font.SourceSans
    dailyStreakLabel.Parent = dailyRewardFrame
    
    -- Evento del botón de recompensa diaria
    dailyButton.MouseButton1Click:Connect(function()
        -- Aquí se manejará la lógica de recompensa diaria
        print("Reclamando recompensa diaria...")
    end)
end

-- ===== CREACIÓN DE UI MEJORADA =====
local function createUI()
    playerGui = player:WaitForChild("PlayerGui")
    
    -- Crear ScreenGui principal
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SurvivalCapitalistUI"
    screenGui.Parent = playerGui
    
    -- Frame principal con gradiente animado
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Efecto de gradiente animado
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.1, 0.1, 0.2)),
        ColorSequenceKeypoint.new(1, Color3.new(0.05, 0.05, 0.1))
    }
    gradient.Rotation = 45
    gradient.Parent = mainFrame
    
    -- Barra superior con información
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 80)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    topBar.BackgroundTransparency = 0.1
    topBar.BorderSizePixel = 0
    topBar.Parent = mainFrame
    
    local topBarGradient = Instance.new("UIGradient")
    topBarGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.2, 0.2, 0.4)),
        ColorSequenceKeypoint.new(1, Color3.new(0.1, 0.1, 0.2))
    }
    topBarGradient.Parent = topBar
    
    -- Título del juego con efecto de brillo
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(0, 400, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "💰 SURVIVAL CAPITALIST 💰"
    titleLabel.TextColor3 = Color3.new(1, 1, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0.5
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = topBar
    
    -- Efecto de parpadeo en el título
    local titleTween = TweenService:Create(
        titleLabel,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {TextTransparency = 0.3}
    )
    titleTween:Play()
    
    -- Display de dinero mejorado
    local moneyFrame = Instance.new("Frame")
    moneyFrame.Name = "MoneyFrame"
    moneyFrame.Size = UDim2.new(0, 350, 0, 60)
    moneyFrame.Position = UDim2.new(0, 450, 0, 10)
    moneyFrame.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    moneyFrame.BackgroundTransparency = 0.1
    moneyFrame.BorderSizePixel = 0
    moneyFrame.Parent = topBar
    
    local moneyCorner = Instance.new("UICorner")
    moneyCorner.CornerRadius = UDim.new(0, 15)
    moneyCorner.Parent = moneyFrame
    
    local moneyGradient = Instance.new("UIGradient")
    moneyGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.3, 1, 0.3)),
        ColorSequenceKeypoint.new(1, Color3.new(0.1, 0.6, 0.1))
    }
    moneyGradient.Parent = moneyFrame
    
    local moneyIcon = Instance.new("TextLabel")
    moneyIcon.Name = "MoneyIcon"
    moneyIcon.Size = UDim2.new(0, 50, 1, 0)
    moneyIcon.Position = UDim2.new(0, 5, 0, 0)
    moneyIcon.BackgroundTransparency = 1
    moneyIcon.Text = "💰"
    moneyIcon.TextColor3 = Color3.new(1, 1, 0)
    moneyIcon.TextScaled = true
    moneyIcon.Font = Enum.Font.SourceSansBold
    moneyIcon.Parent = moneyFrame
    
    moneyDisplay = Instance.new("TextLabel")
    moneyDisplay.Name = "MoneyDisplay"
    moneyDisplay.Size = UDim2.new(1, -60, 1, 0)
    moneyDisplay.Position = UDim2.new(0, 60, 0, 0)
    moneyDisplay.BackgroundTransparency = 1
    moneyDisplay.Text = "$0"
    moneyDisplay.TextColor3 = Color3.new(1, 1, 1)
    moneyDisplay.TextScaled = true
    moneyDisplay.Font = Enum.Font.SourceSansBold
    moneyDisplay.TextXAlignment = Enum.TextXAlignment.Left
    moneyDisplay.TextStrokeTransparency = 0.5
    moneyDisplay.TextStrokeColor3 = Color3.new(0, 0, 0)
    moneyDisplay.Parent = moneyFrame
    
    -- Display de prestige
    local prestigeFrame = Instance.new("Frame")
    prestigeFrame.Name = "PrestigeFrame"
    prestigeFrame.Size = UDim2.new(0, 200, 0, 60)
    prestigeFrame.Position = UDim2.new(0, 820, 0, 10)
    prestigeFrame.BackgroundColor3 = Color3.new(0.8, 0.2, 0.8)
    prestigeFrame.BackgroundTransparency = 0.1
    prestigeFrame.BorderSizePixel = 0
    prestigeFrame.Parent = topBar
    
    local prestigeCorner = Instance.new("UICorner")
    prestigeCorner.CornerRadius = UDim.new(0, 15)
    prestigeCorner.Parent = prestigeFrame
    
    local prestigeGradient = Instance.new("UIGradient")
    prestigeGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1, 0.3, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.6, 0.1, 0.6))
    }
    prestigeGradient.Parent = prestigeFrame
    
    local prestigeIcon = Instance.new("TextLabel")
    prestigeIcon.Name = "PrestigeIcon"
    prestigeIcon.Size = UDim2.new(0, 50, 1, 0)
    prestigeIcon.Position = UDim2.new(0, 5, 0, 0)
    prestigeIcon.BackgroundTransparency = 1
    prestigeIcon.Text = "🌟"
    prestigeIcon.TextColor3 = Color3.new(1, 1, 0)
    prestigeIcon.TextScaled = true
    prestigeIcon.Font = Enum.Font.SourceSansBold
    prestigeIcon.Parent = prestigeFrame
    
    local prestigeDisplay = Instance.new("TextLabel")
    prestigeDisplay.Name = "PrestigeDisplay"
    prestigeDisplay.Size = UDim2.new(1, -60, 1, 0)
    prestigeDisplay.Position = UDim2.new(0, 60, 0, 0)
    prestigeDisplay.BackgroundTransparency = 1
    prestigeDisplay.Text = "Prestige: 0"
    prestigeDisplay.TextColor3 = Color3.new(1, 1, 1)
    prestigeDisplay.TextScaled = true
    prestigeDisplay.Font = Enum.Font.SourceSansBold
    prestigeDisplay.TextXAlignment = Enum.TextXAlignment.Left
    prestigeDisplay.Parent = prestigeFrame
    
    -- Botón de click principal mejorado
    clickButton = Instance.new("TextButton")
    clickButton.Name = "ClickButton"
    clickButton.Size = UDim2.new(0, 250, 0, 250)
    clickButton.Position = UDim2.new(0.5, -125, 0.4, -125)
    clickButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    clickButton.BackgroundTransparency = 0.1
    clickButton.BorderSizePixel = 0
    clickButton.Text = "👆\nCLICK\nPARA GANAR"
    clickButton.TextColor3 = Color3.new(1, 1, 1)
    clickButton.TextScaled = true
    clickButton.Font = Enum.Font.SourceSansBold
    clickButton.TextStrokeTransparency = 0.5
    clickButton.TextStrokeColor3 = Color3.new(0, 0, 0)
    clickButton.Parent = mainFrame
    
    local clickCorner = Instance.new("UICorner")
    clickCorner.CornerRadius = UDim.new(0, 25)
    clickCorner.Parent = clickButton
    
    local clickGradient = Instance.new("UIGradient")
    clickGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1, 0.3, 0.3)),
        ColorSequenceKeypoint.new(1, Color3.new(0.6, 0.1, 0.1))
    }
    clickGradient.Parent = clickButton
    
    -- Efecto de pulso en el botón de click
    local pulseTween = TweenService:Create(
        clickButton,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundTransparency = 0.3}
    )
    pulseTween:Play()
    
    -- Panel de controles de accesibilidad
    local accessibilityFrame = Instance.new("Frame")
    accessibilityFrame.Name = "AccessibilityFrame"
    accessibilityFrame.Size = UDim2.new(0, 200, 0, 120)
    accessibilityFrame.Position = UDim2.new(1, -220, 0, 10)
    accessibilityFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    accessibilityFrame.BackgroundTransparency = 0.2
    accessibilityFrame.BorderSizePixel = 0
    accessibilityFrame.Parent = topBar
    
    local accessibilityCorner = Instance.new("UICorner")
    accessibilityCorner.CornerRadius = UDim.new(0, 10)
    accessibilityCorner.Parent = accessibilityFrame
    
    local accessibilityTitle = Instance.new("TextLabel")
    accessibilityTitle.Name = "AccessibilityTitle"
    accessibilityTitle.Size = UDim2.new(1, 0, 0, 25)
    accessibilityTitle.Position = UDim2.new(0, 0, 0, 0)
    accessibilityTitle.BackgroundTransparency = 1
    accessibilityTitle.Text = "⚙️ ACCESIBILIDAD"
    accessibilityTitle.TextColor3 = Color3.new(1, 1, 1)
    accessibilityTitle.TextScaled = true
    accessibilityTitle.Font = Enum.Font.SourceSansBold
    accessibilityTitle.Parent = accessibilityFrame
    
    -- Botón de auto-clicker
    local autoClickerButton = Instance.new("TextButton")
    autoClickerButton.Name = "AutoClickerButton"
    autoClickerButton.Size = UDim2.new(1, -10, 0, 25)
    autoClickerButton.Position = UDim2.new(0, 5, 0, 30)
    autoClickerButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
    autoClickerButton.BackgroundTransparency = 0.2
    autoClickerButton.BorderSizePixel = 0
    autoClickerButton.Text = "🤖 Auto-Clicker: OFF"
    autoClickerButton.TextColor3 = Color3.new(1, 1, 1)
    autoClickerButton.TextScaled = true
    autoClickerButton.Font = Enum.Font.SourceSans
    autoClickerButton.Parent = accessibilityFrame
    
    local autoClickerCorner = Instance.new("UICorner")
    autoClickerCorner.CornerRadius = UDim.new(0, 5)
    autoClickerCorner.Parent = autoClickerButton
    
    -- Botón de auto-colector
    local autoCollectorButton = Instance.new("TextButton")
    autoCollectorButton.Name = "AutoCollectorButton"
    autoCollectorButton.Size = UDim2.new(1, -10, 0, 25)
    autoCollectorButton.Position = UDim2.new(0, 5, 0, 60)
    autoCollectorButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.6)
    autoCollectorButton.BackgroundTransparency = 0.2
    autoCollectorButton.BorderSizePixel = 0
    autoCollectorButton.Text = "🔄 Auto-Colector: OFF"
    autoCollectorButton.TextColor3 = Color3.new(1, 1, 1)
    autoCollectorButton.TextScaled = true
    autoCollectorButton.Font = Enum.Font.SourceSans
    autoCollectorButton.Parent = accessibilityFrame
    
    local autoCollectorCorner = Instance.new("UICorner")
    autoCollectorCorner.CornerRadius = UDim.new(0, 5)
    autoCollectorCorner.Parent = autoCollectorButton
    
    -- Botón de sonido
    local soundButton = Instance.new("TextButton")
    soundButton.Name = "SoundButton"
    soundButton.Size = UDim2.new(1, -10, 0, 25)
    soundButton.Position = UDim2.new(0, 5, 0, 90)
    soundButton.BackgroundColor3 = Color3.new(0.6, 0.6, 0.2)
    soundButton.BackgroundTransparency = 0.2
    soundButton.BorderSizePixel = 0
    soundButton.Text = "🔊 Sonido: ON"
    soundButton.TextColor3 = Color3.new(1, 1, 1)
    soundButton.TextScaled = true
    soundButton.Font = Enum.Font.SourceSans
    soundButton.Parent = accessibilityFrame
    
    local soundCorner = Instance.new("UICorner")
    soundCorner.CornerRadius = UDim.new(0, 5)
    soundCorner.Parent = soundButton
    
    -- Eventos de botones de accesibilidad
    autoClickerButton.MouseButton1Click:Connect(function()
        autoClickerActive = not autoClickerActive
        autoClickerButton.Text = "🤖 Auto-Clicker: " .. (autoClickerActive and "ON" or "OFF")
        autoClickerButton.BackgroundColor3 = autoClickerActive and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.2, 0.6, 0.2)
    end)
    
    autoCollectorButton.MouseButton1Click:Connect(function()
        autoCollectorActive = not autoCollectorActive
        autoCollectorButton.Text = "🔄 Auto-Colector: " .. (autoCollectorActive and "ON" or "OFF")
        autoCollectorButton.BackgroundColor3 = autoCollectorActive and Color3.new(0.2, 0.2, 0.8) or Color3.new(0.2, 0.2, 0.6)
    end)
    
    soundButton.MouseButton1Click:Connect(function()
        soundEnabled = not soundEnabled
        soundButton.Text = "🔊 Sonido: " .. (soundEnabled and "ON" or "OFF")
        soundButton.BackgroundColor3 = soundEnabled and Color3.new(0.6, 0.8, 0.2) or Color3.new(0.6, 0.6, 0.2)
    end)
    
    -- Crear frames de contenido (negocios, mejoras, etc.)
    createContentFrames(mainFrame)
    
    -- Conectar eventos después de crear la UI
    connectUIEvents()
end

-- ===== CREACIÓN DE FRAMES DE CONTENIDO =====
local function createContentFrames(parent)
    -- Frame de negocios mejorado
    businessFrame = Instance.new("ScrollingFrame")
    businessFrame.Name = "BusinessFrame"
    businessFrame.Size = UDim2.new(0, 450, 0, 500)
    businessFrame.Position = UDim2.new(0, 20, 0, 100)
    businessFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    businessFrame.BackgroundTransparency = 0.1
    businessFrame.BorderSizePixel = 0
    businessFrame.ScrollBarThickness = 12
    businessFrame.ScrollBarImageColor3 = Color3.new(0.8, 0.8, 0.8)
    businessFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    businessFrame.Parent = parent
    
    local businessCorner = Instance.new("UICorner")
    businessCorner.CornerRadius = UDim.new(0, 15)
    businessCorner.Parent = businessFrame
    
    local businessGradient = Instance.new("UIGradient")
    businessGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.2, 0.2, 0.4)),
        ColorSequenceKeypoint.new(1, Color3.new(0.1, 0.1, 0.2))
    }
    businessGradient.Parent = businessFrame
    
    local businessTitle = Instance.new("TextLabel")
    businessTitle.Name = "BusinessTitle"
    businessTitle.Size = UDim2.new(1, 0, 0, 50)
    businessTitle.Position = UDim2.new(0, 0, 0, 0)
    businessTitle.BackgroundTransparency = 1
    businessTitle.Text = "🏪 NEGOCIOS"
    businessTitle.TextColor3 = Color3.new(1, 1, 1)
    businessTitle.TextScaled = true
    businessTitle.Font = Enum.Font.SourceSansBold
    businessTitle.TextStrokeTransparency = 0.5
    businessTitle.TextStrokeColor3 = Color3.new(0, 0, 0)
    businessTitle.Parent = businessFrame
    
    -- Frame de mejoras mejorado
    upgradeFrame = Instance.new("ScrollingFrame")
    upgradeFrame.Name = "UpgradeFrame"
    upgradeFrame.Size = UDim2.new(0, 350, 0, 500)
    upgradeFrame.Position = UDim2.new(1, -370, 0, 100)
    upgradeFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    upgradeFrame.BackgroundTransparency = 0.1
    upgradeFrame.BorderSizePixel = 0
    upgradeFrame.ScrollBarThickness = 12
    upgradeFrame.ScrollBarImageColor3 = Color3.new(0.8, 0.8, 0.8)
    upgradeFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    upgradeFrame.Parent = parent
    
    local upgradeCorner = Instance.new("UICorner")
    upgradeCorner.CornerRadius = UDim.new(0, 15)
    upgradeCorner.Parent = upgradeFrame
    
    local upgradeGradient = Instance.new("UIGradient")
    upgradeGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.2, 0.4, 0.2)),
        ColorSequenceKeypoint.new(1, Color3.new(0.1, 0.2, 0.1))
    }
    upgradeGradient.Parent = upgradeFrame
    
    local upgradeTitle = Instance.new("TextLabel")
    upgradeTitle.Name = "UpgradeTitle"
    upgradeTitle.Size = UDim2.new(1, 0, 0, 50)
    upgradeTitle.Position = UDim2.new(0, 0, 0, 0)
    upgradeTitle.BackgroundTransparency = 1
    upgradeTitle.Text = "⚡ MEJORAS"
    upgradeTitle.TextColor3 = Color3.new(1, 1, 1)
    upgradeTitle.TextScaled = true
    upgradeTitle.Font = Enum.Font.SourceSansBold
    upgradeTitle.TextStrokeTransparency = 0.5
    upgradeTitle.TextStrokeColor3 = Color3.new(0, 0, 0)
    upgradeTitle.Parent = upgradeFrame
    
    -- Frame de logros mejorado
    achievementFrame = Instance.new("ScrollingFrame")
    achievementFrame.Name = "AchievementFrame"
    achievementFrame.Size = UDim2.new(0, 300, 0, 200)
    achievementFrame.Position = UDim2.new(1, -320, 0, 620)
    achievementFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    achievementFrame.BackgroundTransparency = 0.1
    achievementFrame.BorderSizePixel = 0
    achievementFrame.ScrollBarThickness = 10
    achievementFrame.ScrollBarImageColor3 = Color3.new(0.8, 0.8, 0.8)
    achievementFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    achievementFrame.Parent = parent
    
    local achievementCorner = Instance.new("UICorner")
    achievementCorner.CornerRadius = UDim.new(0, 15)
    achievementCorner.Parent = achievementFrame
    
    local achievementGradient = Instance.new("UIGradient")
    achievementGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.4, 0.4, 0.2)),
        ColorSequenceKeypoint.new(1, ColorSequenceKeypoint.new(1, Color3.new(0.2, 0.2, 0.1)))
    }
    achievementGradient.Parent = achievementFrame
    
    local achievementTitle = Instance.new("TextLabel")
    achievementTitle.Name = "AchievementTitle"
    achievementTitle.Size = UDim2.new(1, 0, 0, 40)
    achievementTitle.Position = UDim2.new(0, 0, 0, 0)
    achievementTitle.BackgroundTransparency = 1
    achievementTitle.Text = "🏆 LOGROS"
    achievementTitle.TextColor3 = Color3.new(1, 1, 0)
    achievementTitle.TextScaled = true
    achievementTitle.Font = Enum.Font.SourceSansBold
    achievementTitle.TextStrokeTransparency = 0.5
    achievementTitle.TextStrokeColor3 = Color3.new(0, 0, 0)
    achievementTitle.Parent = achievementFrame
    
    -- Frame de recompensas diarias
    dailyRewardFrame = Instance.new("Frame")
    dailyRewardFrame.Name = "DailyRewardFrame"
    dailyRewardFrame.Size = UDim2.new(0, 300, 0, 150)
    dailyRewardFrame.Position = UDim2.new(0, 490, 0, 100)
    dailyRewardFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    dailyRewardFrame.BackgroundTransparency = 0.1
    dailyRewardFrame.BorderSizePixel = 0
    dailyRewardFrame.Parent = parent
    
    local dailyCorner = Instance.new("UICorner")
    dailyCorner.CornerRadius = UDim.new(0, 15)
    dailyCorner.Parent = dailyRewardFrame
    
    local dailyGradient = Instance.new("UIGradient")
    dailyGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.4, 0.2, 0.4)),
        ColorSequenceKeypoint.new(1, Color3.new(0.2, 0.1, 0.2))
    }
    dailyGradient.Parent = dailyRewardFrame
    
    local dailyTitle = Instance.new("TextLabel")
    dailyTitle.Name = "DailyTitle"
    dailyTitle.Size = UDim2.new(1, 0, 0, 40)
    dailyTitle.Position = UDim2.new(0, 0, 0, 0)
    dailyTitle.BackgroundTransparency = 1
    dailyTitle.Text = "🎁 RECOMPENSA DIARIA"
    dailyTitle.TextColor3 = Color3.new(1, 1, 0)
    dailyTitle.TextScaled = true
    dailyTitle.Font = Enum.Font.SourceSansBold
    dailyTitle.Parent = dailyRewardFrame
    
    local dailyButton = Instance.new("TextButton")
    dailyButton.Name = "DailyButton"
    dailyButton.Size = UDim2.new(1, -20, 0, 60)
    dailyButton.Position = UDim2.new(0, 10, 0, 50)
    dailyButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    dailyButton.BackgroundTransparency = 0.2
    dailyButton.BorderSizePixel = 0
    dailyButton.Text = "🎁 RECLAMAR"
    dailyButton.TextColor3 = Color3.new(1, 1, 1)
    dailyButton.TextScaled = true
    dailyButton.Font = Enum.Font.SourceSansBold
    dailyButton.Parent = dailyRewardFrame
    
    local dailyButtonCorner = Instance.new("UICorner")
    dailyButtonCorner.CornerRadius = UDim.new(0, 10)
    dailyButtonCorner.Parent = dailyButton
    
    local dailyStreakLabel = Instance.new("TextLabel")
    dailyStreakLabel.Name = "DailyStreakLabel"
    dailyStreakLabel.Size = UDim2.new(1, -20, 0, 30)
    dailyStreakLabel.Position = UDim2.new(0, 10, 0, 120)
    dailyStreakLabel.BackgroundTransparency = 1
    dailyStreakLabel.Text = "Racha: 0 días"
    dailyStreakLabel.TextColor3 = Color3.new(1, 1, 1)
    dailyStreakLabel.TextScaled = true
    dailyStreakLabel.Font = Enum.Font.SourceSans
    dailyStreakLabel.Parent = dailyRewardFrame
    
    -- Evento del botón de recompensa diaria
    dailyButton.MouseButton1Click:Connect(function()
        -- Aquí se manejará la lógica de recompensa diaria
        print("Reclamando recompensa diaria...")
    end)
end

-- ===== CREACIÓN DE ELEMENTOS DE NEGOCIOS =====
local function createBusinessElement(businessType, yPosition)
    local business = businessTypes[businessType]
    if not business then return end
    
    local businessElement = Instance.new("Frame")
    businessElement.Name = businessType
    businessElement.Size = UDim2.new(1, -20, 0, 80)
    businessElement.Position = UDim2.new(0, 10, 0, yPosition)
    businessElement.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
    businessElement.BackgroundTransparency = 0.3
    businessElement.BorderSizePixel = 0
    businessElement.Parent = businessFrame
    
    local businessCorner = Instance.new("UICorner")
    businessCorner.CornerRadius = UDim.new(0, 10)
    businessCorner.Parent = businessElement
    
    -- Icono del negocio
    local businessIcon = Instance.new("TextLabel")
    businessIcon.Name = "BusinessIcon"
    businessIcon.Size = UDim2.new(0, 60, 1, 0)
    businessIcon.Position = UDim2.new(0, 0, 0, 0)
    businessIcon.BackgroundTransparency = 1
    businessIcon.Text = business.icon
    businessIcon.TextColor3 = Color3.new(1, 1, 1)
    businessIcon.TextScaled = true
    businessIcon.Font = Enum.Font.SourceSansBold
    businessIcon.Parent = businessElement
    
    -- Información del negocio
    local businessInfo = Instance.new("TextLabel")
    businessInfo.Name = "BusinessInfo"
    businessInfo.Size = UDim2.new(1, -140, 0, 40)
    businessInfo.Position = UDim2.new(0, 70, 0, 5)
    businessInfo.BackgroundTransparency = 1
    businessInfo.Text = business.name .. "\n" .. business.description
    businessInfo.TextColor3 = Color3.new(1, 1, 1)
    businessInfo.TextScaled = true
    businessInfo.Font = Enum.Font.SourceSans
    businessInfo.TextXAlignment = Enum.TextXAlignment.Left
    businessInfo.TextYAlignment = Enum.TextYAlignment.Top
    businessInfo.Parent = businessElement
    
    -- Botón de compra
    local buyButton = Instance.new("TextButton")
    buyButton.Name = "BuyButton"
    buyButton.Size = UDim2.new(0, 60, 0, 60)
    buyButton.Position = UDim2.new(1, -70, 0, 10)
    buyButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    buyButton.BackgroundTransparency = 0.2
    buyButton.BorderSizePixel = 0
    buyButton.Text = "COMPRAR"
    buyButton.TextColor3 = Color3.new(1, 1, 1)
    buyButton.TextScaled = true
    buyButton.Font = Enum.Font.SourceSansBold
    buyButton.Parent = businessElement
    
    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 10)
    buyCorner.Parent = buyButton
    
    -- Botón de recolección
    local collectButton = Instance.new("TextButton")
    collectButton.Name = "CollectButton"
    collectButton.Size = UDim2.new(0, 60, 0, 60)
    collectButton.Position = UDim2.new(1, -140, 0, 10)
    collectButton.BackgroundColor3 = Color3.new(0.8, 0.8, 0.2)
    collectButton.BackgroundTransparency = 0.2
    collectButton.BorderSizePixel = 0
    collectButton.Text = "COBRAR"
    collectButton.TextColor3 = Color3.new(1, 1, 1)
    collectButton.TextScaled = true
    collectButton.Font = Enum.Font.SourceSansBold
    collectButton.Parent = businessElement
    
    local collectCorner = Instance.new("UICorner")
    collectCorner.CornerRadius = UDim.new(0, 10)
    collectCorner.Parent = collectButton
    
    -- Contador de negocios
    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "CountLabel"
    countLabel.Size = UDim2.new(1, -140, 0, 30)
    countLabel.Position = UDim2.new(0, 70, 0, 45)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "Cantidad: 0"
    countLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    countLabel.TextScaled = true
    countLabel.Font = Enum.Font.SourceSans
    countLabel.TextXAlignment = Enum.TextXAlignment.Left
    countLabel.Parent = businessElement
    
    -- Eventos de botones
    buyButton.MouseButton1Click:Connect(function()
        buyBusinessEvent:FireServer(businessType)
    end)
    
    collectButton.MouseButton1Click:Connect(function()
        collectBusinessEvent:FireServer(businessType)
    end)
    
    return businessElement
end

-- ===== CREACIÓN DE ELEMENTOS DE MEJORAS =====
local function createUpgradeElement(upgradeType, yPosition)
    local upgrade = upgradeTypes[upgradeType]
    if not upgrade then return end
    
    local upgradeElement = Instance.new("Frame")
    upgradeElement.Name = upgradeType
    upgradeElement.Size = UDim2.new(1, -20, 0, 100)
    upgradeElement.Position = UDim2.new(0, 10, 0, yPosition)
    upgradeElement.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
    upgradeElement.BackgroundTransparency = 0.3
    upgradeElement.BorderSizePixel = 0
    upgradeElement.Parent = upgradeFrame
    
    local upgradeCorner = Instance.new("UICorner")
    upgradeCorner.CornerRadius = UDim.new(0, 10)
    upgradeCorner.Parent = upgradeElement
    
    -- Icono de la mejora
    local upgradeIcon = Instance.new("TextLabel")
    upgradeIcon.Name = "UpgradeIcon"
    upgradeIcon.Size = UDim2.new(0, 60, 0, 60)
    upgradeIcon.Position = UDim2.new(0, 10, 0, 10)
    upgradeIcon.BackgroundTransparency = 1
    upgradeIcon.Text = upgrade.icon
    upgradeIcon.TextColor3 = Color3.new(1, 1, 1)
    upgradeIcon.TextScaled = true
    upgradeIcon.Font = Enum.Font.SourceSansBold
    upgradeIcon.Parent = upgradeElement
    
    -- Información de la mejora
    local upgradeInfo = Instance.new("TextLabel")
    upgradeInfo.Name = "UpgradeInfo"
    upgradeInfo.Size = UDim2.new(1, -90, 0, 40)
    upgradeInfo.Position = UDim2.new(0, 80, 0, 10)
    upgradeInfo.BackgroundTransparency = 1
    upgradeInfo.Text = upgrade.name .. "\n" .. upgrade.description
    upgradeInfo.TextColor3 = Color3.new(1, 1, 1)
    upgradeInfo.TextScaled = true
    upgradeInfo.Font = Enum.Font.SourceSans
    upgradeInfo.TextXAlignment = Enum.TextXAlignment.Left
    upgradeInfo.TextYAlignment = Enum.TextYAlignment.Top
    upgradeInfo.Parent = upgradeElement
    
    -- Botón de compra
    local buyButton = Instance.new("TextButton")
    buyButton.Name = "BuyButton"
    buyButton.Size = UDim2.new(0, 60, 0, 60)
    buyButton.Position = UDim2.new(1, -70, 0, 20)
    buyButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.8)
    buyButton.BackgroundTransparency = 0.2
    buyButton.BorderSizePixel = 0
    buyButton.Text = "COMPRAR"
    buyButton.TextColor3 = Color3.new(1, 1, 1)
    buyButton.TextScaled = true
    buyButton.Font = Enum.Font.SourceSansBold
    buyButton.Parent = upgradeElement
    
    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 10)
    buyCorner.Parent = buyButton
    
    -- Nivel de la mejora
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(1, -90, 0, 30)
    levelLabel.Position = UDim2.new(0, 80, 0, 50)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Nivel: 0"
    levelLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.SourceSans
    levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    levelLabel.Parent = upgradeElement
    
    -- Evento del botón
    buyButton.MouseButton1Click:Connect(function()
        buyUpgradeEvent:FireServer(upgradeType)
    end)
    
    return upgradeElement
end

-- ===== ACTUALIZACIÓN DE UI =====
local function updateMoneyDisplay(money)
    if moneyDisplay then
        moneyDisplay.Text = "$" .. SharedModule.formatNumber(money)
    end
end

local function updateBusinessUI()
    if not playerData or not businessFrame then return end
    
    -- Crear tabla ordenada por precio
    local sortedBusinesses = {}
    for businessType, business in pairs(businessTypes) do
        local owned = playerData.businesses[businessType] or 0
        local cost = SharedModule.calculateBusinessCost(businessType, owned)
        table.insert(sortedBusinesses, {
            type = businessType,
            business = business,
            owned = owned,
            cost = cost
        })
    end
    
    -- Ordenar por precio (menor a mayor)
    table.sort(sortedBusinesses, function(a, b)
        return a.cost < b.cost
    end)
    
    -- Actualizar UI en el orden correcto
    local yPosition = 50
    for i, businessData in ipairs(sortedBusinesses) do
        local businessType = businessData.type
        local owned = businessData.owned
        local cost = businessData.cost
        local canAfford = playerData.money >= cost
        
        local element = businessFrame:FindFirstChild(businessType)
        if not element then
            element = createBusinessElement(businessType, yPosition)
        end
        
        -- Actualizar contador
        local countLabel = element:FindFirstChild("CountLabel")
        if countLabel then
            countLabel.Text = "Cantidad: " .. owned
        end
        
        -- Actualizar botón de compra
        local buyButton = element:FindFirstChild("BuyButton")
        if buyButton then
            buyButton.Text = "$" .. SharedModule.formatNumber(cost)
            buyButton.BackgroundColor3 = canAfford and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.5, 0.5, 0.5)
        end
        
        -- Actualizar botón de recolección
        local collectButton = element:FindFirstChild("CollectButton")
        if collectButton then
            collectButton.Visible = owned > 0
        end
        
        -- Mover elemento a la posición correcta
        element.Position = UDim2.new(0, 0, 0, yPosition)
        
        yPosition = yPosition + 90
    end
    
    -- Actualizar tamaño del canvas
    businessFrame.CanvasSize = UDim2.new(0, 0, 0, yPosition)
end

local function updateUpgradeUI()
    if not playerData or not upgradeFrame then return end
    
    local yPosition = 50
    for upgradeType, upgrade in pairs(upgradeTypes) do
        local element = upgradeFrame:FindFirstChild(upgradeType)
        if not element then
            element = createUpgradeElement(upgradeType, yPosition)
        end
        
        local level = playerData.upgrades[upgradeType] or 0
        local cost = SharedModule.calculateUpgradeCost(upgradeType, level)
        local canAfford = playerData.money >= cost
        
        -- Actualizar nivel
        local levelLabel = element:FindFirstChild("LevelLabel")
        if levelLabel then
            levelLabel.Text = "Nivel: " .. level
        end
        
        -- Actualizar botón de compra
        local buyButton = element:FindFirstChild("BuyButton")
        if buyButton then
            buyButton.Text = "$" .. SharedModule.formatNumber(cost)
            buyButton.BackgroundColor3 = canAfford and Color3.new(0.2, 0.2, 0.8) or Color3.new(0.5, 0.5, 0.5)
        end
        
        yPosition = yPosition + 110
    end
    
    -- Actualizar tamaño del canvas
    upgradeFrame.CanvasSize = UDim2.new(0, 0, 0, yPosition)
end

-- ===== ANIMACIONES =====
local function createClickAnimation()
    if clickCooldown then return end
    clickCooldown = true
    
    -- Animar el botón
    local originalSize = clickButton.Size
    local smallerSize = UDim2.new(originalSize.X.Scale * 0.9, originalSize.X.Offset * 0.9, 
                                 originalSize.Y.Scale * 0.9, originalSize.Y.Offset * 0.9)
    
    local shrinkTween = TweenService:Create(
        clickButton,
        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = smallerSize}
    )
    
    local growTween = TweenService:Create(
        clickButton,
        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = originalSize}
    )
    
    shrinkTween:Play()
    shrinkTween.Completed:Connect(function()
        growTween:Play()
        growTween.Completed:Connect(function()
            clickCooldown = false
        end)
    end)
    
    -- Crear partículas de dinero
    local clickPosition = Vector3.new(0, 0, 0)
    for i = 1, 5 do
        local randomOffset = Vector3.new(
            math.random(-50, 50),
            math.random(0, 50),
            math.random(-50, 50)
        )
        SharedModule.createParticleEffect(clickPosition + randomOffset, "Bright yellow", 0.5)
    end
end

-- ===== EVENTOS =====
-- Los eventos se conectarán después de crear la UI

-- ===== CONEXIÓN DE EVENTOS DEL SERVIDOR =====
local function connectServerEvents()
    -- Eventos del servidor
    if clickEvent then
        clickEvent.OnClientEvent:Connect(function(money, moneyGained, newAchievements)
            updateMoneyDisplay(money)
            
            -- Mostrar logros nuevos
            if newAchievements and #newAchievements > 0 then
                for _, achievement in pairs(newAchievements) do
                    print("🏆 LOGRO DESBLOQUEADO: " .. achievement.name .. " (+$" .. SharedModule.formatNumber(achievement.reward) .. ")")
                    if soundEnabled then
                        SharedModule.playSound(soundIds.achievement, 0.5, 1, workspace)
                    end
                end
            end
        end)
        print("✅ Evento de click del servidor conectado")
    end

    if buyBusinessEvent then
        buyBusinessEvent.OnClientEvent:Connect(function(businessType, owned, money, newAchievements)
            updateMoneyDisplay(money)
            updateBusinessUI()
            
            if newAchievements and #newAchievements > 0 then
                for _, achievement in pairs(newAchievements) do
                    print("🏆 LOGRO DESBLOQUEADO: " .. achievement.name .. " (+$" .. SharedModule.formatNumber(achievement.reward) .. ")")
                    if soundEnabled then
                        SharedModule.playSound(soundIds.achievement, 0.5, 1, workspace)
                    end
                end
            end
            
            if soundEnabled then
                SharedModule.playSound(soundIds.purchase, 0.4, 1, workspace)
            end
        end)
        print("✅ Evento de compra de negocio conectado")
    end

    if buyUpgradeEvent then
        buyUpgradeEvent.OnClientEvent:Connect(function(upgradeType, level, money)
            updateMoneyDisplay(money)
            updateUpgradeUI()
            if soundEnabled then
                SharedModule.playSound(soundIds.purchase, 0.4, 1, workspace)
            end
        end)
        print("✅ Evento de compra de mejora conectado")
    end

    if collectBusinessEvent then
        collectBusinessEvent.OnClientEvent:Connect(function(businessType, income, money)
            updateMoneyDisplay(money)
            if soundEnabled then
                SharedModule.playSound(soundIds.businessComplete, 0.3, 1, workspace)
            end
        end)
        print("✅ Evento de recolección conectado")
    end

    if loadDataEvent then
        loadDataEvent.OnClientEvent:Connect(function(data)
            playerData = data
            updateMoneyDisplay(data.money)
            updateBusinessUI()
            updateUpgradeUI()
            print("💰 Datos cargados! Dinero: $" .. SharedModule.formatNumber(data.money))
        end)
        print("✅ Evento de carga de datos conectado")
    end
end

-- ===== INICIALIZACIÓN =====
player.CharacterAdded:Connect(function(character)
    print("=== SURVIVAL CAPITALIST ===")
    print("💰 ¡Bienvenido al mundo del capitalismo!")
    print("👆 Haz click para ganar dinero")
    print("🏪 Compra negocios para ganar automáticamente")
    print("⚡ Mejora tus habilidades")
    print("🏆 Desbloquea logros")
    print("========================")
    
    -- Esperar a que los RemoteEvents estén listos
    spawn(function()
        if waitForRemoteEvents() then
            print("✅ RemoteEvents cargados correctamente")
            
            -- Conectar eventos del servidor
            connectServerEvents()
            
            -- Crear UI
            createUI()
            
            -- Conectar eventos de la UI (después de crear la UI)
            connectUIEvents()
            
            -- Cargar datos
            if loadDataEvent then
                loadDataEvent:FireServer()
            end
        else
            print("❌ Error: No se pudieron cargar los RemoteEvents")
        end
    end)
end)
