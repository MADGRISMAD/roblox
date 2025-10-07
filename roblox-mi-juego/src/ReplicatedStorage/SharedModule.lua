-- Módulo compartido para Enter the Gungeon
local SharedModule = {}

-- ===== CONFIGURACIÓN DEL JUGADOR =====
function SharedModule.getPlayerStats()
    return {
        maxHealth = 6,
        moveSpeed = 16,
        rollSpeed = 30,
        rollDuration = 0.3,
        rollCooldown = 0.5,
        invulnerabilityTime = 1.0
    }
end

-- ===== CONFIGURACIÓN DE ARMAS =====
function SharedModule.getWeaponStats()
    return {
        pistol = {
            damage = 1,
            fireRate = 0.5,
            ammo = 999,
            spread = 0,
            bulletSpeed = 50,
            bulletSize = 0.2
        },
        shotgun = {
            damage = 1,
            fireRate = 1.0,
            ammo = 30,
            spread = 15,
            bulletSpeed = 40,
            bulletSize = 0.3,
            pellets = 5
        },
        rifle = {
            damage = 1,
            fireRate = 0.2,
            ammo = 100,
            spread = 2,
            bulletSpeed = 60,
            bulletSize = 0.15
        }
    }
end

-- ===== CONFIGURACIÓN DE ENEMIGOS =====
function SharedModule.getEnemyTypes()
    return {
        bulletKin = {
            health = 1,
            speed = 8,
            damage = 1,
            fireRate = 2.0,
            bulletSpeed = 20,
            size = Vector3.new(2, 2, 2),
            color = Color3.new(1, 0, 0),
            points = 10
        },
        shotgunKin = {
            health = 2,
            speed = 6,
            damage = 1,
            fireRate = 3.0,
            bulletSpeed = 15,
            size = Vector3.new(2.5, 2.5, 2.5),
            color = Color3.new(1, 0.5, 0),
            points = 20,
            pellets = 3
        },
        veteranBulletKin = {
            health = 3,
            speed = 10,
            damage = 1,
            fireRate = 1.5,
            bulletSpeed = 25,
            size = Vector3.new(2.2, 2.2, 2.2),
            color = Color3.new(0.8, 0, 0.8),
            points = 30
        }
    }
end

-- ===== CONFIGURACIÓN DE BALAS =====
function SharedModule.getBulletStats()
    return {
        playerBullet = {
            speed = 50,
            size = Vector3.new(0.2, 0.2, 0.2),
            color = Color3.new(1, 1, 0),
            lifetime = 3.0
        },
        enemyBullet = {
            speed = 20,
            size = Vector3.new(0.3, 0.3, 0.3),
            color = Color3.new(1, 0, 0),
            lifetime = 5.0
        }
    }
end

-- ===== CONFIGURACIÓN DE HABITACIONES =====
function SharedModule.getRoomConfig()
    return {
        roomSize = Vector3.new(40, 20, 40),
        wallThickness = 2,
        doorSize = Vector3.new(4, 8, 2),
        spawnDistance = 15,
        enemySpawnDelay = 2.0
    }
end

-- ===== CONFIGURACIÓN DE OBJETOS =====
function SharedModule.getItemStats()
    return {
        healthPickup = {
            healAmount = 1,
            size = Vector3.new(1, 1, 1),
            color = Color3.new(0, 1, 0)
        },
        ammoPickup = {
            ammoAmount = 20,
            size = Vector3.new(0.8, 0.8, 0.8),
            color = Color3.new(0, 0, 1)
        },
        keyPickup = {
            size = Vector3.new(0.5, 0.5, 0.5),
            color = Color3.new(1, 1, 0)
        }
    }
end

-- ===== FUNCIONES UTILITARIAS =====
function SharedModule.calculateDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function SharedModule.getRandomPositionInRoom(roomCenter, roomSize)
    local halfX = roomSize.X / 2 - 5
    local halfZ = roomSize.Z / 2 - 5
    
    return Vector3.new(
        roomCenter.X + math.random(-halfX, halfX),
        roomCenter.Y + 2,
        roomCenter.Z + math.random(-halfZ, halfZ)
    )
end

function SharedModule.isPositionInRoom(position, roomCenter, roomSize)
    local halfX = roomSize.X / 2
    local halfZ = roomSize.Z / 2
    
    return math.abs(position.X - roomCenter.X) < halfX and
           math.abs(position.Z - roomCenter.Z) < halfZ
end

function SharedModule.getDirectionToTarget(from, to)
    return (to - from).Unit
end

function SharedModule.addSpreadToDirection(direction, spreadDegrees)
    local spreadRadians = math.rad(spreadDegrees)
    local randomSpread = math.random(-spreadRadians, spreadRadians)
    
    local rotation = CFrame.Angles(0, randomSpread, 0)
    return (rotation * direction).Unit
end

function SharedModule.createExplosionEffect(position, size, color)
    local explosion = Instance.new("Explosion")
    explosion.Position = position
    explosion.BlastRadius = size
    explosion.BlastPressure = 0
    explosion.Visible = true
    explosion.Parent = workspace
    
    -- Crear partículas adicionales
    local attachment = Instance.new("Attachment")
    attachment.Parent = workspace.Terrain
    
    local particles = Instance.new("ParticleEmitter")
    particles.Parent = attachment
    particles.Texture = "rbxasset://textures/particles/fire_main.dds"
    particles.Lifetime = NumberRange.new(0.5, 1.0)
    particles.Rate = 100
    particles.SpreadAngle = Vector2.new(45, 45)
    particles.Speed = NumberRange.new(5, 15)
    particles.Color = ColorSequence.new(color)
    particles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0)
    }
    
    attachment.Position = position
    particles:Emit(50)
    
    game:GetService("Debris"):AddItem(attachment, 2)
end

function SharedModule.createDamageNumber(position, damage, isCritical)
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0, 100, 0, 50)
    gui.StudsOffset = Vector3.new(0, 2, 0)
    gui.Parent = workspace.Terrain
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = tostring(damage)
    textLabel.TextColor3 = isCritical and Color3.new(1, 1, 0) or Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = gui
    
    gui.Position = position
    
    -- Animar hacia arriba
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local moveTween = game:GetService("TweenService"):Create(
        gui,
        tweenInfo,
        {StudsOffset = Vector3.new(0, 5, 0)}
    )
    
    local fadeTween = game:GetService("TweenService"):Create(
        textLabel,
        tweenInfo,
        {TextTransparency = 1}
    )
    
    moveTween:Play()
    fadeTween:Play()
    
    moveTween.Completed:Connect(function()
        gui:Destroy()
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
        shoot = "rbxasset://sounds/electronicpingsharp_loud.wav",
        hit = "rbxasset://sounds/impact_generic.mp3",
        enemyDeath = "rbxasset://sounds/impact_water.mp3",
        playerHurt = "rbxasset://sounds/impact_water.mp3",
        roll = "rbxasset://sounds/button.wav",
        pickup = "rbxasset://sounds/button.wav",
        doorOpen = "rbxasset://sounds/button.wav"
    }
end

-- ===== CONFIGURACIÓN DE EFECTOS VISUALES =====
function SharedModule.createMuzzleFlash(position, direction)
    local flash = Instance.new("Part")
    flash.Name = "MuzzleFlash"
    flash.Size = Vector3.new(0.5, 0.5, 1)
    flash.Material = Enum.Material.Neon
    flash.BrickColor = BrickColor.new("Bright yellow")
    flash.Anchored = true
    flash.CanCollide = false
    flash.Parent = workspace
    
    flash.CFrame = CFrame.lookAt(position, position + direction)
    
    -- Animar el flash
    local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local flashTween = game:GetService("TweenService"):Create(
        flash,
        tweenInfo,
        {Transparency = 1, Size = Vector3.new(1, 1, 2)}
    )
    
    flashTween:Play()
    flashTween.Completed:Connect(function()
        flash:Destroy()
    end)
end

function SharedModule.createRollEffect(position, direction)
    local effect = Instance.new("Part")
    effect.Name = "RollEffect"
    effect.Size = Vector3.new(2, 0.2, 2)
    effect.Material = Enum.Material.Neon
    effect.BrickColor = BrickColor.new("Cyan")
    effect.Anchored = true
    effect.CanCollide = false
    effect.Transparency = 0.5
    effect.Parent = workspace
    
    effect.Position = position
    effect.CFrame = CFrame.lookAt(position, position + direction)
    
    -- Animar el efecto
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local effectTween = game:GetService("TweenService"):Create(
        effect,
        tweenInfo,
        {Transparency = 1, Size = Vector3.new(4, 0.1, 4)}
    )
    
    effectTween:Play()
    effectTween.Completed:Connect(function()
        effect:Destroy()
    end)
end

return SharedModule
