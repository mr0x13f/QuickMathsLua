local ffi
Vector3 = {}
setmetatable(Vector3, Vector3)

Vector3.keys = {
    x = 1, y = 2, z = 3,
    r = 1, g = 2, b = 3,
}

if jit and jit.status() then

    ffi = require"ffi"

    ffi.cdef([[
        typedef union Vector3
        {
            float components[3];
        } Vector3;
    ]])

    ffi.metatype("Vector3", Vector3)

else
    ffi = false
end

function isVector3(vector)

    if ffi then
        return ffi.istype("Vector3", vector)
    else
        return type(vector) == "table" and vector._isclass and vector._isclass(Vector3)
    end

end

function Vector3._isclass(c)
    return c == Vector3
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

function Vector3.new(...)

    local args = {...}
    local components = {}
    getComponents(args, components)

    if #components == 0 then components = {0,0,0} end

    assert(#components == 3, "3 components expected, got "..#components)

    local vector

    if ffi then
        vector = ffi.new("Vector3")
    else
        vector = setmetatable({}, Vector3)
    end
    
    for i=1,#components do
        vector.components[i-1] = components[i]
    end

    return vector

end

function Vector3.fromHex(hex)

    assert(type(hex) == "string", "Invalid arguments")

    if hex:sub(1,1) == "#" then hex = hex:sub(2,#hex) end

    local out = Vector3()

    if #hex == 3 then

        for i=1,3 do
            local dec = tonumber( hex:sub(i,i) .. hex:sub(i,i), 16 )/255
            assert(type(dec) == "number", "Invalid hex string")
            out[i] = dec
        end

    elseif #hex == 6 then

        for i=1,3 do
            local dec = tonumber( hex:sub(i*2-1,i*2), 16 )/255
            assert(type(dec) == "number", "Invalid hex string")
            out[i] = dec
        end

    else
        error("Invalid hex string")
    end

    return out

end

------------------------------------------------------------------------
--                                METHODS
------------------------------------------------------------------------

function Vector3.toHex(vector)

    local r = string.format("%x", vector.r * 255)
    local g = string.format("%x", vector.g * 255)
    local b = string.format("%x", vector.b * 255)

    if #r == 1 then r = "0"..r end
    if #g == 1 then g = "0"..g end
    if #b == 1 then b = "0"..b end

    return "#"..r..g..b

end

function Vector3.unpack(vec)

    return vec.x, vec.y, vec.z

end

local tmp = {}
function Vector3.send(vec)

    for i=1,#vec do
        tmp[i] = vec[i]
    end

    return tmp

end

function Vector3.abs(vec)

    return Vector3(
        math.abs(vec.x),
        math.abs(vec.y),
        math.abs(vec.z)
    )

end

function Vector3.floor(vec)

    return Vector3(
        math.floor(vec.x),
        math.floor(vec.y),
        math.floor(vec.z)
    )

end

function Vector3.ceil(vec)

    return Vector3(
        math.ceil(vec.x),
        math.ceil(vec.y),
        math.ceil(vec.z)
    )

end

function Vector3.clamp(vec, min, max)

    if not min then min = vec end
    if not max then max = vec end

    return Vector3(
        math.max(math.min(vec.x, max.x), min.x),
        math.max(math.min(vec.y, max.y), min.y),
        math.max(math.min(vec.z, max.z), min.z)
    )

end

function Vector3.angle(vec)

    local out = Vector3()

    out.x = math.atan2(math.sqrt(vec.y^2+vec.z^2),vec.x)
    out.y = math.atan2(math.sqrt(vec.z^2+vec.x^2),vec.y)
    out.z = math.atan2(math.sqrt(vec.x^2+vec.y^2),vec.z)

    return out
    
end

function Vector3.rotate(vec, angle)

    return vec * Matrix3.fromRotationZ(angle.z) * Matrix3.fromRotationY(angle.y) * Matrix3.fromRotationX(angle.x)

end

function Vector3.magnitude(vec)

    return math.sqrt(vec.x^2 + vec.y^2 + vec.z^2)

end

function Vector3.magnitude2(vec)

    return vec.x^2 + vec.y^2 + vec.z^2

end

function Vector3.distance(a,b)

    return (a-b):magnitude()

end

function Vector3.distance2(a,b)

    return (a-b):magnitude2()

end

function Vector3.normalize(vec)

    if vec:magnitude2() == 0 then return vec end

    return 1/vec:magnitude() * vec

end

function Vector3.trim(vec, len)

    if vec:magnitude2() == 0 then return vec end
    if len < 0 then len = -len end

    return len / math.max(vec:magnitude(),len) * vec

end

function Vector3.dot(a,b)

    return a.x*b.x + a.y+b.y + a.z*b.z

end

function Vector3.cross(a,b)

    local c = Vector3()

    c.x = a.y*b.z - a.z*b.y
    c.y = a.z*b.x - a.x*b.z
    c.z = a.x*b.y - a.y*b.x

    return c

end

------------------------------------------------------------------------
--                                META
------------------------------------------------------------------------

function Vector3:__len()

    return 3

end

function Vector3:__index(key)

    if rawget(Vector3, key) then
        return rawget(Vector3, key)

    elseif type(key) == "number" or Vector3.keys[key] then

        if Vector3.keys[key] then key = Vector3.keys[key] end
        return self.components[key-1]

    else
        return rawget(self, key)
    end

end

function Vector3:__newindex(key, value)

    if type(key) == "number" or Vector3.keys[key] then

        if Vector3.keys[key] then key = Vector3.keys[key] end
        self.components[key-1] = value

    elseif self == Vector3 then
        rawset(self, key, value)

    else
        error("Vector3 has no attribute \""..tostring(key).."\"")
    end

end

function Vector3:__tostring()

    return "("..table.concat({self:unpack()}, ",")..")"

end

function Vector3.__concat(a,b)

    return tostring(a) .. tostring(b)

end

function Vector3:__call(...)

    return Vector3.new(...)

end

------------------------------------------------------------------------
--                                OPERATORS
------------------------------------------------------------------------

function Vector3.__add(a,b)

    if isVector3(b) and not isVector3(a) then a,b = b,a end

    if isVector3(b) then
        return a:addVector3(b)
    elseif isMatrix3(b) then
        return a:addMatrix3(b)
    else
        error("Attempt to perform arithmetic between Vector3 and "..type(b))
    end

end

function Vector3.addVector3(a,b)

    return Vector3(
        a.x + b.x,
        a.y + b.y,
        a.z + b.z
    )

end

function Vector3.addMatrix3(vec,mat)
    
    return Vector3(
        vec.x + mat.r1c1 + vec.y + mat.r2c1 + vec.z + mat.r3c1,
        vec.x + mat.r1c2 + vec.y + mat.r2c2 + vec.z + mat.r3c2,
        vec.x + mat.r1c3 + vec.y + mat.r2c3 + vec.z + mat.r3c3
    )

end

function Vector3.__sub(a,b)

    if isVector3(b) and not isVector3(a) then a,b = b,a end

    if isVector3(b) then
        return a:subVector3(b)
    elseif isMatrix3(b) then
        return a:subMatrix3(b)
    else
        error("Attempt to perform arithmetic between Vector3 and "..type(b))
    end

end

function Vector3.subVector3(a,b)

    return Vector3(
        a.x - b.x,
        a.y - b.y,
        a.z - b.z
    )

end

function Vector3.subMatrix3(vec,mat)
    
    return Vector3(
        vec.x - mat.r1c1 + vec.y - mat.r2c1 + vec.z - mat.r3c1,
        vec.x - mat.r1c2 + vec.y - mat.r2c2 + vec.z - mat.r3c2,
        vec.x - mat.r1c3 + vec.y - mat.r2c3 + vec.z - mat.r3c3
    )

end

function Vector3.__mul(a,b)

    if isVector3(b) and not isVector3(a) then a,b = b,a end

    if type(b) == "number" then
        return a:mulNumber(b)
    elseif isVector3(b) then
        return a:mulVector3(b)
    elseif isMatrix3(b) then
        return a:mulMatrix3(b)
    else
        error("Attempt to perform arithmetic between Vector3 and "..type(b))
    end

end

function Vector3.mulNumber(vec,scalar)

    return Vector3(
        vec.x * scalar,
        vec.y * scalar,
        vec.z * scalar
    )

end

function Vector3.mulVector3(a,b)

    return Vector3(
        a.x * b.x,
        a.y * b.y,
        a.z * b.z
    )

end

function Vector3.mulMatrix3(vec,mat)

    return Vector3(
        vec.x * mat.r1c1 + vec.y * mat.r2c1 + vec.z * mat.r3c1,
        vec.x * mat.r1c2 + vec.y * mat.r2c2 + vec.z * mat.r3c2,
        vec.x * mat.r1c3 + vec.y * mat.r2c3 + vec.z * mat.r3c3
    )

end

function Vector3.__div(a,b)

    if isVector3(b) and not isVector3(a) then a,b = b,a end

    if type(b) == "number" then
        return a:divNumber(b)
    elseif isVector3(b) then
        return a:divVector3(b)
    elseif isMatrix3(b) then
        return a:divMatrix3(b)
    else
        error("Attempt to perform arithmetic between Vector3 and "..type(b))
    end

end

function Vector3.divNumber(vec,scalar)

    return Vector3(
        vec.x / scalar,
        vec.y / scalar,
        vec.z / scalar
    )

end

function Vector3.divVector3(a,b)

    return Vector3(
        a.x / b.x,
        a.y / b.y,
        a.z / b.z
    )

end

function Vector3.divMatrix3(vec,mat)
    
    return Vector3(
        vec.x / mat.r1c1 + vec.y / mat.r2c1 + vec.z / mat.r3c1,
        vec.x / mat.r1c2 + vec.y / mat.r2c2 + vec.z / mat.r3c2,
        vec.x / mat.r1c3 + vec.y / mat.r2c3 + vec.z / mat.r3c3
    )

end

function Vector3.__mod(a,b)

    if isVector3(b) and not isVector3(a) then a,b = b,a end

    if type(b) == "number" then
        return a:modNumber(b)
    elseif isVector3(b) then
        return a:modVector3(b)
    elseif isMatrix3(b) then
        return a:modMatrix3(b)
    else
        error("Attempt to perform arithmetic between Vector3 and "..type(b))
    end

end

function Vector3.modNumber(vec,modulus)

    return Vector3(
        vec.x % modulus,
        vec.y % modulus,
        vec.z % modulus
    )

end

function Vector3.modVector3(a,b)

    return Vector3(
        a.x % b.x,
        a.y % b.y,
        a.z % b.z
    )

end

function Vector3.modMatrix3(vec,mat)
    
    return Vector3(
        vec.x % mat.r1c1 + vec.y % mat.r2c1 + vec.z % mat.r3c1,
        vec.x % mat.r1c2 + vec.y % mat.r2c2 + vec.z % mat.r3c2,
        vec.x % mat.r1c3 + vec.y % mat.r2c3 + vec.z % mat.r3c3
    )

end

function Vector3.__pow(a,b)

    if isVector3(b) and not isVector3(a) then a,b = b,a end

    if type(b) == "number" then
        return a:powNumber(b)
    elseif isVector3(b) then
        return a:powVector3(b)
    elseif isMatrix3(b) then
        return a:powMatrix3(b)
    else
        error("Attempt to perform arithmetic between Vector3 and "..type(b))
    end

end

function Vector3.powNumber(vec,factor)

    return Vector3(
        vec.x ^ factor,
        vec.y ^ factor,
        vec.z ^ factor
    )

end

function Vector3.powVector3(a,b)

    return Vector3(
        a.x ^ b.x,
        a.y ^ b.y,
        a.z ^ b.z
    )

end

function Vector3.powMatrix3(vec,mat)
    
    return Vector3(
        vec.x ^ mat.r1c1 + vec.y ^ mat.r2c1 + vec.z ^ mat.r3c1,
        vec.x ^ mat.r1c2 + vec.y ^ mat.r2c2 + vec.z ^ mat.r3c2,
        vec.x ^ mat.r1c3 + vec.y ^ mat.r2c3 + vec.z ^ mat.r3c3
    )

end

function Vector3.__unm(vec)

    return Vector3(
        -vec.x,
        -vec.y,
        -vec.z
    )

end

function Vector3.__eq(a,b)

    return isVector3(a) and isVector3(b)
    and a.x == b.x
    and a.y == b.y
    and a.z == b.z

end