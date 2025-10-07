-- Módulo compartido para Survival Capitalist Clicker
local SharedModule = {}

-- ===== CONFIGURACIÓN DEL JUEGO =====
function SharedModule.getGameConfig()
    return {
        gameName = "Survival Capitalist",
        version = "1.0.0",
        saveInterval = 30, -- segundos
        autoSaveEnabled = true
    }
end

-- ===== CONFIGURACIÓN DE NEGOCIOS =====
function SharedModule.getBusinessTypes()
    return {
        lemonadeStand = {
            name = "Puesto de Limonada",
            baseCost = 4,
            baseIncome = 1,
            baseTime = 1.0,
            icon = "🍋",
            description = "Un simple puesto de limonada",
            unlockLevel = 0
        },
        newspaperDelivery = {
            name = "Reparto de Periódicos",
            baseCost = 60,
            baseIncome = 60,
            baseTime = 3.0,
            icon = "📰",
            description = "Entrega periódicos por el vecindario",
            unlockLevel = 1
        },
        carWash = {
            name = "Lavado de Autos",
            baseCost = 720,
            baseIncome = 540,
            baseTime = 6.0,
            icon = "🚗",
            description = "Lava autos y gana dinero",
            unlockLevel = 2
        },
        pizzaDelivery = {
            name = "Reparto de Pizza",
            baseCost = 8640,
            baseIncome = 4320,
            baseTime = 12.0,
            icon = "🍕",
            description = "Entrega pizzas a domicilio",
            unlockLevel = 3
        },
        donutShop = {
            name = "Tienda de Donas",
            baseCost = 103680,
            baseIncome = 51840,
            baseTime = 24.0,
            icon = "🍩",
            description = "Vende donas frescas",
            unlockLevel = 4
        },
        shrimpBoat = {
            name = "Barco Camaronero",
            baseCost = 1244160,
            baseIncome = 622080,
            baseTime = 96.0,
            icon = "🦐",
            description = "Pesca camarones en el mar",
            unlockLevel = 5
        },
        hockeyTeam = {
            name = "Equipo de Hockey",
            baseCost = 14929920,
            baseIncome = 7464960,
            baseTime = 384.0,
            icon = "🏒",
            description = "Equipo profesional de hockey",
            unlockLevel = 6
        },
        movieStudio = {
            name = "Estudio de Cine",
            baseCost = 179159040,
            baseIncome = 89579520,
            baseTime = 1536.0,
            icon = "🎬",
            description = "Produce películas de Hollywood",
            unlockLevel = 7
        },
        bank = {
            name = "Banco",
            baseCost = 2149908480,
            baseIncome = 1074954240,
            baseTime = 6144.0,
            icon = "🏦",
            description = "Banco con inversiones",
            unlockLevel = 8
        },
        oilCompany = {
            name = "Compañía Petrolera",
            baseCost = 25798901760,
            baseIncome = 12899450880,
            baseTime = 24576.0,
            icon = "🛢️",
            description = "Extrae y vende petróleo",
            unlockLevel = 9
        }
    }
end

-- ===== CONFIGURACIÓN DE MEJORAS =====
function SharedModule.getUpgradeTypes()
    return {
        clickPower = {
            name = "Poder de Click",
            description = "Aumenta el dinero por click",
            baseCost = 10,
            costMultiplier = 1.15,
            effect = "multiplyClickPower",
            icon = "👆"
        },
        businessMultiplier = {
            name = "Multiplicador de Negocios",
            description = "Aumenta los ingresos de todos los negocios",
            baseCost = 100,
            costMultiplier = 1.2,
            effect = "multiplyBusinessIncome",
            icon = "📈"
        },
        businessSpeed = {
            name = "Velocidad de Negocios",
            description = "Reduce el tiempo de todos los negocios",
            baseCost = 1000,
            costMultiplier = 1.25,
            effect = "multiplyBusinessSpeed",
            icon = "⚡"
        },
        offlineEarnings = {
            name = "Ganancias Offline",
            description = "Gana dinero mientras no juegas",
            baseCost = 10000,
            costMultiplier = 1.3,
            effect = "enableOfflineEarnings",
            icon = "💤"
        }
    }
end

-- ===== CONFIGURACIÓN DE LOGROS =====
function SharedModule.getAchievements()
    return {
        firstClick = {
            name = "Primer Click",
            description = "Haz tu primer click",
            reward = 10,
            condition = "totalClicks >= 1",
            icon = "🎯"
        },
        firstBusiness = {
            name = "Primer Negocio",
            description = "Compra tu primer negocio",
            reward = 100,
            condition = "totalBusinesses >= 1",
            icon = "🏪"
        },
        millionaire = {
            name = "Millonario",
            description = "Acumula $1,000,000",
            reward = 10000,
            condition = "totalMoney >= 1000000",
            icon = "💰"
        },
        businessMogul = {
            name = "Magnate de Negocios",
            description = "Compra 10 negocios",
            reward = 50000,
            condition = "totalBusinesses >= 10",
            icon = "👑"
        },
        clickMaster = {
            name = "Maestro del Click",
            description = "Haz 1000 clicks",
            reward = 25000,
            condition = "totalClicks >= 1000",
            icon = "👆"
        },
        speedClicker = {
            name = "Clicker Veloz",
            description = "Haz 100 clicks en 10 segundos",
            reward = 5000,
            condition = "speedClicks >= 100",
            icon = "⚡"
        },
        businessTycoon = {
            name = "Magnate Empresarial",
            description = "Compra 50 negocios",
            reward = 100000,
            condition = "totalBusinesses >= 50",
            icon = "🏢"
        },
        billionaire = {
            name = "Multimillonario",
            description = "Acumula $1,000,000,000",
            reward = 500000,
            condition = "totalMoney >= 1000000000",
            icon = "💎"
        },
        prestigeMaster = {
            name = "Maestro del Prestige",
            description = "Alcanza nivel 10 de prestige",
            reward = 1000000,
            condition = "prestigeLevel >= 10",
            icon = "🌟"
        },
        dailyPlayer = {
            name = "Jugador Diario",
            description = "Reclama 7 recompensas diarias seguidas",
            reward = 50000,
            condition = "dailyStreak >= 7",
            icon = "📅"
        }
    }
end

-- ===== CONFIGURACIÓN DE EVENTOS ESPECIALES =====
function SharedModule.getSpecialEvents()
    return {
        doubleMoney = {
            name = "Doble Dinero",
            description = "¡Gana el doble de dinero por 5 minutos!",
            duration = 300, -- 5 minutos
            multiplier = 2,
            icon = "💰💰"
        },
        speedBoost = {
            name = "Boost de Velocidad",
            description = "¡Los negocios trabajan 3x más rápido por 10 minutos!",
            duration = 600, -- 10 minutos
            multiplier = 3,
            icon = "⚡⚡⚡"
        },
        luckyDay = {
            name = "Día de Suerte",
            description = "¡10% de probabilidad de ganar 10x dinero por 15 minutos!",
            duration = 900, -- 15 minutos
            multiplier = 10,
            chance = 0.1,
            icon = "🍀"
        }
    }
end

-- ===== CONFIGURACIÓN DE MISIONES DIARIAS =====
function SharedModule.getDailyMissions()
    return {
        clickMission = {
            name = "Clicker Diario",
            description = "Haz 500 clicks",
            target = 500,
            reward = 10000,
            type = "clicks",
            icon = "👆"
        },
        businessMission = {
            name = "Comprador Diario",
            description = "Compra 5 negocios",
            target = 5,
            reward = 15000,
            type = "businesses",
            icon = "🏪"
        },
        moneyMission = {
            name = "Recolector Diario",
            description = "Gana $100,000",
            target = 100000,
            reward = 20000,
            type = "money",
            icon = "💰"
        }
    }
end

-- ===== FUNCIONES UTILITARIAS =====
function SharedModule.formatNumber(number)
    if number < 1000 then
        return tostring(math.floor(number))
    elseif number < 1000000 then
        return string.format("%.1fK", number / 1000)
    elseif number < 1000000000 then
        return string.format("%.1fM", number / 1000000)
    elseif number < 1000000000000 then
        return string.format("%.1fB", number / 1000000000)
    else
        return string.format("%.1fT", number / 1000000000000)
    end
end

function SharedModule.calculateBusinessCost(businessType, owned)
    local business = SharedModule.getBusinessTypes()[businessType]
    if not business then return 0 end
    
    return math.floor(business.baseCost * math.pow(1.15, owned))
end

function SharedModule.calculateBusinessIncome(businessType, owned, multipliers)
    local business = SharedModule.getBusinessTypes()[businessType]
    if not business or owned == 0 then return 0 end
    
    local baseIncome = business.baseIncome * owned
    local multiplier = multipliers.businessMultiplier or 1
    local managerBonus = multipliers.managerBonus or 1
    
    return math.floor(baseIncome * multiplier * managerBonus)
end

function SharedModule.calculateBusinessTime(businessType, owned, multipliers)
    local business = SharedModule.getBusinessTypes()[businessType]
    if not business then return 0 end
    
    local baseTime = business.baseTime
    local speedMultiplier = multipliers.businessSpeed or 1
    
    return baseTime / speedMultiplier
end

function SharedModule.calculateUpgradeCost(upgradeType, level)
    local upgrade = SharedModule.getUpgradeTypes()[upgradeType]
    if not upgrade then return 0 end
    
    return math.floor(upgrade.baseCost * math.pow(upgrade.costMultiplier, level))
end

function SharedModule.getUnlockedBusinesses(level)
    local businesses = SharedModule.getBusinessTypes()
    local unlocked = {}
    
    for businessType, business in pairs(businesses) do
        if business.unlockLevel <= level then
            table.insert(unlocked, businessType)
        end
    end
    
    return unlocked
end

function SharedModule.calculateOfflineEarnings(playerData, offlineTime)
    if not playerData.upgrades.offlineEarnings or offlineTime < 60 then
        return 0
    end
    
    local totalEarnings = 0
    local businesses = SharedModule.getBusinessTypes()
    
    for businessType, owned in pairs(playerData.businesses) do
        if owned > 0 then
            local business = businesses[businessType]
            local cycles = math.floor(offlineTime / business.baseTime)
            local earnings = cycles * business.baseIncome * owned
            totalEarnings = totalEarnings + earnings
        end
    end
    
    return math.floor(totalEarnings * (playerData.upgrades.businessMultiplier or 1))
end

function SharedModule.checkAchievements(playerData)
    local achievements = SharedModule.getAchievements()
    local newAchievements = {}
    
    for achievementId, achievement in pairs(achievements) do
        if not playerData.achievements[achievementId] then
            local condition = achievement.condition
            local unlocked = false
            
            if condition == "totalClicks >= 1" then
                unlocked = playerData.stats.totalClicks >= 1
            elseif condition == "totalBusinesses >= 1" then
                unlocked = playerData.stats.totalBusinesses >= 1
            elseif condition == "totalMoney >= 1000000" then
                unlocked = playerData.stats.totalMoney >= 1000000
            elseif condition == "totalBusinesses >= 10" then
                unlocked = playerData.stats.totalBusinesses >= 10
            elseif condition == "totalClicks >= 1000" then
                unlocked = playerData.stats.totalClicks >= 1000
            end
            
            if unlocked then
                playerData.achievements[achievementId] = true
                playerData.money = playerData.money + achievement.reward
                table.insert(newAchievements, {
                    id = achievementId,
                    name = achievement.name,
                    reward = achievement.reward
                })
            end
        end
    end
    
    return newAchievements
end

function SharedModule.createParticleEffect(position, color, size)
    local particle = Instance.new("Part")
    particle.Name = "MoneyParticle"
    particle.Size = Vector3.new(size, size, size)
    particle.Material = Enum.Material.Neon
    particle.BrickColor = BrickColor.new(color)
    particle.Shape = Enum.PartType.Ball
    particle.Anchored = true
    particle.CanCollide = false
    particle.Position = position
    particle.Parent = workspace
    
    -- Animar la partícula
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local moveTween = game:GetService("TweenService"):Create(
        particle,
        tweenInfo,
        {
            Position = position + Vector3.new(0, 10, 0),
            Transparency = 1,
            Size = Vector3.new(size * 2, size * 2, size * 2)
        }
    )
    
    moveTween:Play()
    moveTween.Completed:Connect(function()
        particle:Destroy()
    end)
end

function SharedModule.playSound(soundId, volume, pitch, parent)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.5
    sound.Pitch = pitch or 1
    sound.Parent = parent or workspace
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- ===== CONFIGURACIÓN DE SONIDOS =====
function SharedModule.getSoundIds()
    return {
        click = "rbxasset://sounds/button.wav",
        purchase = "rbxasset://sounds/electronicpingsharp_loud.wav",
        achievement = "rbxasset://sounds/impact_generic.mp3",
        businessComplete = "rbxasset://sounds/impact_water.mp3"
    }
end

return SharedModule
