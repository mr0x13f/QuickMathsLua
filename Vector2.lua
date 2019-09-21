local ffi
Vector2 = {}
setmetatable(Vector2, Vector2)

Vector2.keys = {
    x = 1, y = 2,
}

if jit and jit.status() then

    ffi = require"ffi"

    ffi.cdef([[
        typedef union Vector2
        {
            float components[2];
        } Vector2;
    ]])

    ffi.metatype("Vector2", Vector2)

end

function isVector2(vector)

    if ffi then
        return ffi.istype("Vector2", vector)
    else
        return type(vector) == "table" and vector._isclass and vector._isclass(Vector2)
    end

end

function Vector2._isclass(c)
    return c == Vector2
end

local function getComponents(args, components)
    for i=1,#args do
        if type(args[i]) == "number" then
            table.insert(components, args[i])
        elseif type(args[i]) == "table" or isVector2(args[i]) or isVector3(args[i]) or isVector4(args[i]) then
            getComponents(args[i], components)
        else
            error("Invalid component #"..(#components+1).." \""..tostring(args[i]).."\"")
        end
    end
end

------------------------------------------------------------------------
--                                CONSTRUCTORS
------------------------------------------------------------------------

function Vector2.new(...)

    local args = {...}
    local components = {}
    getComponents(args, components)

    if #components == 0 then components = {0,0} end

    assert(#components == 2, "2 components expected, got "..#components)

    local vector

    if ffi then
        vector = ffi.new("Vector2")
    else
        vector = setmetatable({components={}}, Vector2)
    end
    
    for i=1,#components do
        vector.components[i-1] = components[i]
    end

    return vector

end

------------------------------------------------------------------------
--                                METHODS
------------------------------------------------------------------------

function Vector2.unpack(vec)

    return vec.x, vec.y

end

local tmp = {}
function Vector2.send(vec)

    for i=1,2 do
        tmp[i] = vec[i]
    end

    return tmp

end

function Vector2.abs(vec)

    return Vector2(
        math.abs(vec.x),
        math.abs(vec.y)
    )

end

function Vector2.floor(vec)

    return Vector2(
        math.floor(vec.x),
        math.floor(vec.y)
    )

end

function Vector2.ceil(vec)

    return Vector2(
        math.ceil(vec.x),
        math.ceil(vec.y)
    )

end

function Vector2.clamp(vec, min, max)

    if not min then min = vec end
    if not max then max = vec end

    return Vector2(
        math.max(math.min(vec.x, max.x), min.x),
        math.max(math.min(vec.y, max.y), min.y)
    )

end

function Vector2.angle(vec)

    return math.atan2(vec.y, vec.x)
    
end

function Vector2.rotate(vec, angle)

    return vec * Matrix2.fromRotation(angle)

end

function Vector2.magnitude(vec)

    return math.sqrt(vec.x^2 + vec.y^2)

end

function Vector2.magnitude2(vec)

    return vec.x^2 + vec.y^2

end

function Vector2.distance(a,b)

    return (a-b):magnitude()

end

function Vector2.distance2(a,b)

    return (a-b):magnitude2()

end

function Vector2.normalize(vec)

    if vec:magnitude2() == 0 then return vec end

    return 1/vec:magnitude() * vec

end

function Vector2.trim(vec, len)

    if vec:magnitude2() == 0 then return vec end
    if len < 0 then len = -len end

    return len / math.max(vec:magnitude(),len) * vec

end

function Vector2.dot(a,b)

    return a.x*b.x + a.y+b.y

end

function Vector2.cross(a,b)

    return a.x*b.y - a.y*b.x

end

------------------------------------------------------------------------
--                                META
------------------------------------------------------------------------

function Vector2:__len()

    return 2

end

function Vector2:__index(key)

    if rawget(Vector2, key) then
        return rawget(Vector2, key)

    elseif type(key) == "number" or Vector2.keys[key] then

        if Vector2.keys[key] then key = Vector2.keys[key] end
        return self.components[key-1]

    else
        return rawget(self, key)
    end

end

function Vector2:__newindex(key, value)

    if type(key) == "number" or Vector2.keys[key] then

        if Vector2.keys[key] then key = Vector2.keys[key] end
        self.components[key-1] = value

    elseif self == Vector2 then
        rawset(self, key, value)

    else
        error("Vector2 has no attribute \""..tostring(key).."\"")
    end

end

function Vector2:__tostring()

    return "("..table.concat({self:unpack()}, ",")..")"

end

function Vector2.__concat(a,b)

    return tostring(a) .. tostring(b)

end

function Vector2:__call(...)

    return Vector2.new(...)

end

------------------------------------------------------------------------
--                                OPERATORS
------------------------------------------------------------------------

function Vector2.__add(a,b)

    if isVector2(b) and not isVector2(a) then a,b = b,a end

    if isVector2(b) then
        return a:addVector2(b)
    elseif isMatrix2(b) then
        return a:addMatrix2(b)
    else
        error("Attempt to perform arithmetic between Vector2 and "..type(b))
    end

end

function Vector2.addVector2(a,b)

    return Vector2(
        a.x + b.x,
        a.y + b.y
    )

end

function Vector2.addMatrix2(vec,mat)
    
    return Vector2(
        vec.x + mat.r1c1 + vec.y + mat.r2c1,
        vec.x + mat.r1c2 + vec.y + mat.r2c2
    )

end

function Vector2.__sub(a,b)

    if isVector2(b) and not isVector2(a) then a,b = b,a end

    if isVector2(b) then
        return a:subVector2(b)
    elseif isMatrix2(b) then
        return a:subMatrix2(b)
    else
        error("Attempt to perform arithmetic between Vector2 and "..type(b))
    end

end

function Vector2.subVector2(a,b)

    return Vector2(
        a.x - b.x,
        a.y - b.y
    )

end

function Vector2.subMatrix2(vec,mat)
    
    return Vector2(
        vec.x - mat.r1c1 + vec.y - mat.r2c1,
        vec.x - mat.r1c2 + vec.y - mat.r2c2
    )

end

function Vector2.__mul(a,b)

    if isVector2(b) and not isVector2(a) then a,b = b,a end

    if type(b) == "number" then
        return a:mulNumber(b)
    elseif isVector2(b) then
        return a:mulVector2(b)
    elseif isMatrix2(b) then
        return a:mulMatrix2(b)
    else
        error("Attempt to perform arithmetic between Vector2 and "..type(b))
    end

end

function Vector2.mulNumber(vec,scalar)

    return Vector2(
        vec.x * scalar,
        vec.y * scalar
    )

end

function Vector2.mulVector2(a,b)

    return Vector2(
        a.x * b.x,
        a.y * b.y
    )

end

function Vector2.mulMatrix2(vec,mat)
    
    return Vector2(
        vec.x * mat.r1c1 + vec.y * mat.r2c1,
        vec.x * mat.r1c2 + vec.y * mat.r2c2
    )

end

function Vector2.__div(a,b)

    if isVector2(b) and not isVector2(a) then a,b = b,a end

    if type(b) == "number" then
        return a:divNumber(b)
    elseif isVector2(b) then
        return a:divVector2(b)
    elseif isMatrix2(b) then
        return a:divMatrix2(b)
    else
        error("Attempt to perform arithmetic between Vector2 and "..type(b))
    end

end

function Vector2.divNumber(vec,scalar)

    return Vector2(
        vec.x / scalar,
        vec.y / scalar
    )

end

function Vector2.divVector2(a,b)

    return Vector2(
        a.x / b.x,
        a.y / b.y
    )

end

function Vector2.divMatrix2(vec,mat)
    
    return Vector2(
        vec.x / mat.r1c1 + vec.y / mat.r2c1,
        vec.x / mat.r1c2 + vec.y / mat.r2c2
    )

end

function Vector2.__mod(a,b)

    if isVector2(b) and not isVector2(a) then a,b = b,a end

    if type(b) == "number" then
        return a:modNumber(b)
    elseif isVector2(b) then
        return a:modVector2(b)
    elseif isMatrix2(b) then
        return a:modMatrix2(b)
    else
        error("Attempt to perform arithmetic between Vector2 and "..type(b))
    end

end

function Vector2.modNumber(vec,modulus)

    return Vector2(
        vec.x % modulus,
        vec.y % modulus
    )

end

function Vector2.modVector2(a,b)

    return Vector2(
        a.x % b.x,
        a.y % b.y
    )

end

function Vector2.modMatrix2(vec,mat)
    
    return Vector2(
        vec.x % mat.r1c1 + vec.y % mat.r2c1,
        vec.x % mat.r1c2 + vec.y % mat.r2c2
    )

end

function Vector2.__pow(a,b)

    if isVector2(b) and not isVector2(a) then a,b = b,a end

    if type(b) == "number" then
        return a:powNumber(b)
    elseif isVector2(b) then
        return a:powVector2(b)
    elseif isMatrix2(b) then
        return a:powMatrix2(b)
    else
        error("Attempt to perform arithmetic between Vector2 and "..type(b))
    end

end

function Vector2.powNumber(vec,factor)

    return Vector2(
        vec.x ^ factor,
        vec.y ^ factor
    )

end

function Vector2.powVector2(a,b)

    return Vector2(
        a.x ^ b.x,
        a.y ^ b.y
    )

end

function Vector2.powMatrix2(vec,mat)

    return Vector2(
        vec.x ^ mat.r1c1 + vec.y ^ mat.r2c1,
        vec.x ^ mat.r1c2 + vec.y ^ mat.r2c2
    )

end

function Vector2.__unm(vev)

    return Vector2(
        -vec.x,
        -vec.y
    )

end

function Vector2.__eq(a,b)

    return isVector2(a) and isVector2(b)
    and a.x == b.x
    and a.y == b.y

end