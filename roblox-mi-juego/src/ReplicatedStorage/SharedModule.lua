-- Modulo compartido
local SharedModule = {}

-- Funciones compartidas que pueden usar tanto el cliente como el servidor
function SharedModule.sayHello(name)
    return "Hola, " .. name .. "!"
end

function SharedModule.calculateDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

-- Funciones para el sistema de golpe
function SharedModule.getPunchDamage(level)
    -- Calcular daño basado en el nivel (opcional para futuras mejoras)
    level = level or 1
    return math.random(10, 15) * level
end

function SharedModule.getPunchRange()
    -- Rango máximo para detectar objetivos
    return 10
end

function SharedModule.calculateKnockback(distance, maxDistance)
    -- Calcular fuerza de empuje basada en la distancia
    maxDistance = maxDistance or SharedModule.getPunchRange()
    if distance > maxDistance then
        return 0
    end
    
    -- Fuerza inversamente proporcional a la distancia
    return math.max(0, (maxDistance - distance) / maxDistance * 50)
end

function SharedModule.isInPunchRange(attacker, target, range)
    range = range or SharedModule.getPunchRange()
    
    if not attacker or not target then
        return false
    end
    
    local attackerPos = attacker.Position
    local targetPos = target.Position
    
    return SharedModule.calculateDistance(attackerPos, targetPos) <= range
end

function SharedModule.getRandomPunchMessage()
    local messages = {
        "¡Golpe devastador!",
        "¡POW!",
        "¡Impacto crítico!",
        "¡BAM!",
        "¡Golpe perfecto!",
        "¡WHAM!",
        "¡BOOM!",
        "¡KO!",
        "¡Súper golpe!"
    }
    
    return messages[math.random(1, #messages)]
end

-- Funciones para el sistema de enemigos
function SharedModule.getEnemySpawnHeight()
    return 100  -- Altura desde la que caen los enemigos
end

function SharedModule.getEnemyFallSpeed()
    return -20  -- Velocidad de caída (negativa = hacia abajo)
end

function SharedModule.getEnemyHealth()
    return math.random(20, 40)  -- Salud aleatoria para enemigos
end

function SharedModule.getEnemySize()
    return Vector3.new(4, 4, 4)  -- Tamaño de los enemigos
end

function SharedModule.getCoinReward()
    return math.random(5, 15)  -- Monedas que da cada enemigo
end

function SharedModule.getSpawnRange()
    return 50  -- Rango en X y Z donde pueden aparecer enemigos
end

-- Funciones para el sistema de doble salto
function SharedModule.getJumpPower()
    return 50  -- Fuerza del salto normal
end

function SharedModule.getDoubleJumpPower()
    return 45  -- Fuerza del doble salto (ligeramente menor)
end

function SharedModule.getMaxJumps()
    return 2  -- Número máximo de saltos permitidos
end

function SharedModule.getJumpCooldown()
    return 0.1  -- Tiempo mínimo entre saltos para evitar spam
end

-- Funciones para el sistema de sprint estilo Naruto
function SharedModule.getSprintActivationTime()
    return 1.5  -- Segundos de caminar antes de activar sprint
end

function SharedModule.getNormalWalkSpeed()
    return 16  -- Velocidad normal de caminar
end

function SharedModule.getSprintSpeed()
    return 35  -- Velocidad en modo sprint (más del doble)
end

function SharedModule.getSprintEffectDuration()
    return 0.1  -- Duración de cada efecto de partícula
end

function SharedModule.getMovementThreshold()
    return 0.5  -- Mínima velocidad para considerar que se está moviendo
end

return SharedModule
