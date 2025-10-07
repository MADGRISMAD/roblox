-- Servidor mejorado para Survival Capitalist Clicker
local SharedModule = require(game.ReplicatedStorage.SharedModule)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Variables del juego
local playerData = {}
local gameConfig = SharedModule.getGameConfig()
local businessTypes = SharedModule.getBusinessTypes()
local upgradeTypes = SharedModule.getUpgradeTypes()

-- DataStore para guardar progreso (solo funciona en juegos publicados)
local playerDataStore = nil
if game:GetService("RunService"):IsStudio() then
    print("⚠️ Modo Studio: DataStore deshabilitado")
else
    playerDataStore = DataStoreService:GetDataStore("SurvivalCapitalist_PlayerData")
end

-- ===== CREACIÓN DE REMOTEEVENTS =====
local function createRemoteEvents()
    local remoteEvents = Instance.new("Folder")
    remoteEvents.Name = "RemoteEvents"
    remoteEvents.Parent = ReplicatedStorage
    
    local clickEvent = Instance.new("RemoteEvent")
    clickEvent.Name = "Click"
    clickEvent.Parent = remoteEvents
    
    local buyBusinessEvent = Instance.new("RemoteEvent")
    buyBusinessEvent.Name = "BuyBusiness"
    buyBusinessEvent.Parent = remoteEvents
    
    local buyUpgradeEvent = Instance.new("RemoteEvent")
    buyUpgradeEvent.Name = "BuyUpgrade"
    buyUpgradeEvent.Parent = remoteEvents
    
    local collectBusinessEvent = Instance.new("RemoteEvent")
    collectBusinessEvent.Name = "CollectBusiness"
    collectBusinessEvent.Parent = remoteEvents
    
    local saveDataEvent = Instance.new("RemoteEvent")
    saveDataEvent.Name = "SaveData"
    saveDataEvent.Parent = remoteEvents
    
    local loadDataEvent = Instance.new("RemoteEvent")
    loadDataEvent.Name = "LoadData"
    loadDataEvent.Parent = remoteEvents
    
    local prestigeEvent = Instance.new("RemoteEvent")
    prestigeEvent.Name = "Prestige"
    prestigeEvent.Parent = remoteEvents
    
    local dailyRewardEvent = Instance.new("RemoteEvent")
    dailyRewardEvent.Name = "DailyReward"
    dailyRewardEvent.Parent = remoteEvents
    
    return {
        click = clickEvent,
        buyBusiness = buyBusinessEvent,
        buyUpgrade = buyUpgradeEvent,
        collectBusiness = collectBusinessEvent,
        saveData = saveDataEvent,
        loadData = loadDataEvent,
        prestige = prestigeEvent,
        dailyReward = dailyRewardEvent
    }
end

local remoteEvents = createRemoteEvents()

-- ===== INICIALIZACIÓN DE DATOS DEL JUGADOR =====
local function initializePlayerData(player)
    return {
        money = 0,
        businesses = {},
        upgrades = {
            clickPower = 0,
            businessMultiplier = 0,
            businessSpeed = 0,
            offlineEarnings = 0
        },
        achievements = {},
        stats = {
            totalClicks = 0,
            totalMoney = 0,
            totalBusinesses = 0,
            playTime = 0,
            prestigeLevel = 0,
            prestigePoints = 0
        },
        dailyRewards = {
            lastClaimed = 0,
            streak = 0
        },
        lastSaveTime = tick(),
        lastActiveTime = tick(),
        sessionStartTime = tick()
    }
end

-- ===== SISTEMA DE CLICK MEJORADO =====
local function handleClick(player)
    local data = playerData[player.UserId]
    if not data then return end
    
    local clickPower = 1 + data.upgrades.clickPower
    local prestigeMultiplier = 1 + (data.stats.prestigeLevel * 0.1)
    local moneyGained = math.floor(clickPower * prestigeMultiplier)
    
    data.money = data.money + moneyGained
    data.stats.totalClicks = data.stats.totalClicks + 1
    data.stats.totalMoney = data.stats.totalMoney + moneyGained
    data.lastActiveTime = tick()
    
    -- Verificar logros
    local newAchievements = SharedModule.checkAchievements(data)
    
    -- Enviar actualización al cliente
    remoteEvents.click:FireClient(player, data.money, moneyGained, newAchievements)
    
    return data.money, moneyGained
end

-- ===== SISTEMA DE COMPRA DE NEGOCIOS MEJORADO =====
local function handleBuyBusiness(player, businessType)
    local data = playerData[player.UserId]
    if not data then return false end
    
    local business = businessTypes[businessType]
    if not business then return false end
    
    local owned = data.businesses[businessType] or 0
    local cost = SharedModule.calculateBusinessCost(businessType, owned)
    
    if data.money >= cost then
        data.money = data.money - cost
        data.businesses[businessType] = owned + 1
        data.stats.totalBusinesses = data.stats.totalBusinesses + 1
        data.lastActiveTime = tick()
        
        -- Verificar logros
        local newAchievements = SharedModule.checkAchievements(data)
        
        -- Enviar actualización al cliente
        remoteEvents.buyBusiness:FireClient(player, businessType, data.businesses[businessType], data.money, newAchievements)
        
        return true
    end
    
    return false
end

-- ===== SISTEMA DE COMPRA DE MEJORAS MEJORADO =====
local function handleBuyUpgrade(player, upgradeType)
    local data = playerData[player.UserId]
    if not data then return false end
    
    local upgrade = upgradeTypes[upgradeType]
    if not upgrade then return false end
    
    local level = data.upgrades[upgradeType] or 0
    local cost = SharedModule.calculateUpgradeCost(upgradeType, level)
    
    if data.money >= cost then
        data.money = data.money - cost
        data.upgrades[upgradeType] = level + 1
        data.lastActiveTime = tick()
        
        -- Enviar actualización al cliente
        remoteEvents.buyUpgrade:FireClient(player, upgradeType, data.upgrades[upgradeType], data.money)
        
        return true
    end
    
    return false
end

-- ===== SISTEMA DE RECOLECCIÓN DE NEGOCIOS MEJORADO =====
local function handleCollectBusiness(player, businessType)
    local data = playerData[player.UserId]
    if not data then return 0 end
    
    local owned = data.businesses[businessType] or 0
    if owned == 0 then return 0 end
    
    local multipliers = {
        businessMultiplier = 1 + (data.upgrades.businessMultiplier or 0),
        businessSpeed = 1 + (data.upgrades.businessSpeed or 0)
    }
    
    local income = SharedModule.calculateBusinessIncome(businessType, owned, multipliers)
    local prestigeMultiplier = 1 + (data.stats.prestigeLevel * 0.1)
    income = math.floor(income * prestigeMultiplier)
    
    if income > 0 then
        data.money = data.money + income
        data.stats.totalMoney = data.stats.totalMoney + income
        data.lastActiveTime = tick()
        
        -- Enviar actualización al cliente
        remoteEvents.collectBusiness:FireClient(player, businessType, income, data.money)
    end
    
    return income
end

-- ===== SISTEMA DE PRESTIGE =====
local function handlePrestige(player)
    local data = playerData[player.UserId]
    if not data then return false end
    
    -- Requisito mínimo para hacer prestige
    local minMoney = 1000000 -- $1M
    if data.money < minMoney then return false end
    
    -- Calcular puntos de prestige
    local prestigePoints = math.floor(data.money / 1000000)
    
    -- Resetear progreso
    data.money = 0
    data.businesses = {}
    data.upgrades = {
        clickPower = 0,
        businessMultiplier = 0,
        businessSpeed = 0,
        offlineEarnings = 0
    }
    
    -- Aumentar nivel de prestige
    data.stats.prestigeLevel = data.stats.prestigeLevel + 1
    data.stats.prestigePoints = data.stats.prestigePoints + prestigePoints
    
    -- Enviar actualización al cliente
    remoteEvents.prestige:FireClient(player, data.stats.prestigeLevel, data.stats.prestigePoints)
    
    return true
end

-- ===== SISTEMA DE RECOMPENSAS DIARIAS =====
local function handleDailyReward(player)
    local data = playerData[player.UserId]
    if not data then return false end
    
    local currentTime = tick()
    local lastClaimed = data.dailyRewards.lastClaimed
    local timeSinceLastClaim = currentTime - lastClaimed
    
    -- Verificar si puede reclamar (24 horas = 86400 segundos)
    if timeSinceLastClaim < 86400 then
        return false
    end
    
    -- Calcular recompensa
    local baseReward = 10000
    local streakBonus = data.dailyRewards.streak * 1000
    local reward = baseReward + streakBonus
    
    data.money = data.money + reward
    data.dailyRewards.lastClaimed = currentTime
    data.dailyRewards.streak = data.dailyRewards.streak + 1
    
    -- Enviar actualización al cliente
    remoteEvents.dailyReward:FireClient(player, reward, data.dailyRewards.streak)
    
    return true
end

-- ===== SISTEMA DE GUARDADO MEJORADO =====
local function savePlayerData(player)
    local data = playerData[player.UserId]
    if not data then return false end
    
    data.lastSaveTime = tick()
    
    -- Solo guardar si DataStore está disponible
    if playerDataStore then
        local success, errorMessage = pcall(function()
            playerDataStore:SetAsync(player.UserId, data)
        end)
        
        if success then
            print("Datos guardados para " .. player.Name)
            return true
        else
            warn("Error al guardar datos para " .. player.Name .. ": " .. errorMessage)
            return false
        end
    else
        print("⚠️ Modo Studio: Datos no guardados (DataStore no disponible)")
        return true
    end
end

-- ===== SISTEMA DE CARGA MEJORADO =====
local function loadPlayerData(player)
    -- Solo cargar si DataStore está disponible
    if playerDataStore then
        local success, data = pcall(function()
            return playerDataStore:GetAsync(player.UserId)
        end)
        
        if success and data then
            -- Calcular ganancias offline
            local offlineTime = tick() - (data.lastActiveTime or tick())
            if offlineTime > 60 and data.upgrades.offlineEarnings > 0 then
                local offlineEarnings = SharedModule.calculateOfflineEarnings(data, offlineTime)
                if offlineEarnings > 0 then
                    data.money = data.money + offlineEarnings
                    print(player.Name .. " ganó $" .. SharedModule.formatNumber(offlineEarnings) .. " offline")
                end
            end
            
            -- Inicializar campos nuevos si no existen
            data.dailyRewards = data.dailyRewards or {lastClaimed = 0, streak = 0}
            data.stats.prestigeLevel = data.stats.prestigeLevel or 0
            data.stats.prestigePoints = data.stats.prestigePoints or 0
            
            playerData[player.UserId] = data
            print("Datos cargados para " .. player.Name)
            return data
        end
    end
    
    -- Crear datos nuevos (modo Studio o sin datos guardados)
    local newData = initializePlayerData(player)
    playerData[player.UserId] = newData
    print("Datos nuevos creados para " .. player.Name)
    return newData
end

-- ===== EVENTOS =====
remoteEvents.click.OnServerEvent:Connect(function(player)
    handleClick(player)
end)

remoteEvents.buyBusiness.OnServerEvent:Connect(function(player, businessType)
    handleBuyBusiness(player, businessType)
end)

remoteEvents.buyUpgrade.OnServerEvent:Connect(function(player, upgradeType)
    handleBuyUpgrade(player, upgradeType)
end)

remoteEvents.collectBusiness.OnServerEvent:Connect(function(player, businessType)
    handleCollectBusiness(player, businessType)
end)

remoteEvents.prestige.OnServerEvent:Connect(function(player)
    handlePrestige(player)
end)

remoteEvents.dailyReward.OnServerEvent:Connect(function(player)
    handleDailyReward(player)
end)

remoteEvents.saveData.OnServerEvent:Connect(function(player)
    savePlayerData(player)
end)

remoteEvents.loadData.OnServerEvent:Connect(function(player)
    local data = loadPlayerData(player)
    remoteEvents.loadData:FireClient(player, data)
end)

-- ===== BUCLE PRINCIPAL MEJORADO =====
local lastSaveTime = 0
local lastBusinessUpdate = 0

RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    
    -- Guardado automático cada cierto tiempo
    if currentTime - lastSaveTime >= gameConfig.saveInterval then
        for _, player in pairs(Players:GetPlayers()) do
            if playerData[player.UserId] then
                savePlayerData(player)
            end
        end
        lastSaveTime = currentTime
    end
    
    -- Actualizar tiempo de juego y enviar actualizaciones
    for _, player in pairs(Players:GetPlayers()) do
        local data = playerData[player.UserId]
        if data then
            data.stats.playTime = data.stats.playTime + 1/60 -- 60 FPS
            
            -- Enviar actualizaciones periódicas al cliente
            if currentTime - lastBusinessUpdate >= 1 then -- Cada segundo
                remoteEvents.loadData:FireClient(player, data)
            end
        end
    end
    
    if currentTime - lastBusinessUpdate >= 1 then
        lastBusinessUpdate = currentTime
    end
end)

-- ===== INICIALIZACIÓN =====
print("=== SURVIVAL CAPITALIST SERVER MEJORADO ===")
print("💰 Sistema de clicker mejorado iniciado")
print("💾 Sistema de guardado avanzado activado")
print("🏆 Sistema de prestige implementado")
print("🎁 Recompensas diarias activadas")

Players.PlayerAdded:Connect(function(player)
    print("Jugador conectado: " .. player.Name)
    
    -- Cargar datos del jugador
    local data = loadPlayerData(player)
    
    -- Enviar datos iniciales al cliente
    wait(1) -- Esperar a que el cliente esté listo
    remoteEvents.loadData:FireClient(player, data)
end)

Players.PlayerRemoving:Connect(function(player)
    print("Jugador desconectado: " .. player.Name)
    
    -- Guardar datos antes de que se vaya
    if playerData[player.UserId] then
        savePlayerData(player)
        playerData[player.UserId] = nil
    end
end)
