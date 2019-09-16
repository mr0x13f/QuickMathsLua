local ffi
Vector4 = {}
setmetatable(Vector4, Vector4)

Vector4.keys = {
    x = 1, y = 2, z = 3, w = 4,
    r = 1, g = 2, b = 3, a = 4,
}

if jit and jit.status() then

    ffi = require"ffi"

    ffi.cdef([[
        typedef union Vector4
        {
            float components[4];
        } Vector4;
    ]])

    ffi.metatype("Vector4", Vector4)

else
    ffi = false
end

function isVector4(vector)

    if ffi then
        return ffi.istype("Vector4", vector)
    else
        return type(vector) == "table" and vector._isclass and vector._isclass(Vector4)
    end

end

function Vector4._isclass(c)
    return c == Vector4
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

function Vector4.new(...)

    local args = {...}
    local components = {}
    getComponents(args, components)

    if #components == 0 then components = {0,0,0,0} end

    assert(#components == 4, "4 components expected, got "..#components)

    local vector

    if ffi then
        vector = ffi.new("Vector4")
    else
        vector = setmetatable({}, Vector4)
    end
    
    for i=1,#components do
        vector.components[i-1] = components[i]
    end

    return vector

end

function Vector4.fromHex(hex, opacity)

    assert(type(hex) == "string", "Invalid arguments")

    if hex:sub(1,1) == "#" then hex = hex:sub(2,#hex) end

    local out = Vector4()

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

    out.a = opacity or 1

    return out

end

------------------------------------------------------------------------
--                                METHODS
------------------------------------------------------------------------

function Vector4.toHex(vector)

    local r = string.format("%x", vector.r * 255)
    local g = string.format("%x", vector.g * 255)
    local b = string.format("%x", vector.b * 255)

    if #r == 1 then r = "0"..r end
    if #g == 1 then g = "0"..g end
    if #b == 1 then b = "0"..b end

    return "#"..r..g..b

end

function Vector4.unpack(vec)

    return vec.x, vec.y, vec.z, vec.w

end

local tmp = {}
function Vector4.send(vec)

    for i=1,#vec do
        tmp[i] = vec[i]
    end

    return tmp

end

function Vector4.abs(vec)

    return Vector4(
        math.abs(vec.x),
        math.abs(vec.y),
        math.abs(vec.z),
        math.abs(vec.w)
    )

end

function Vector4.floor(vec)

    return Vector4(
        math.floor(vec.x),
        math.floor(vec.y),
        math.floor(vec.z),
        math.floor(vec.w)
    )

end

function Vector4.ceil(vec)

    return Vector4(
        math.ceil(vec.x),
        math.ceil(vec.y),
        math.ceil(vec.z),
        math.ceil(vec.w)
    )

end

function Vector4.clamp(vec, min, max)

    if not min then min = vec end
    if not max then max = vec end

    return Vector4(
        math.max(math.min(vec.x, max.x), min.x),
        math.max(math.min(vec.y, max.y), min.y),
        math.max(math.min(vec.z, max.z), min.z),
        math.max(math.min(vec.w, max.w), min.w)
    )

end

------------------------------------------------------------------------
--                                META
------------------------------------------------------------------------

function Vector4:__len()

    return 4

end

function Vector4:__index(key)

    if rawget(Vector4, key) then
        return rawget(Vector4, key)

    elseif type(key) == "number" or Vector4.keys[key] then

        if Vector4.keys[key] then key = Vector4.keys[key] end
        return self.components[key-1]

    else
        return rawget(self, key)
    end

end

function Vector4:__newindex(key, value)

    if type(key) == "number" or Vector4.keys[key] then

        if Vector4.keys[key] then key = Vector4.keys[key] end
        self.components[key-1] = value

    elseif self == Vector4 then
        rawset(self, key, value)

    else
        error("Vector4 has no attribute \""..tostring(key).."\"")
    end

end

function Vector4:__tostring()

    return "("..table.concat({self:unpack()}, ",")..")"

end

function Vector4.__concat(a,b)

    return tostring(a) .. tostring(b)

end

function Vector4:__call(...)

    return Vector4.new(...)

end

------------------------------------------------------------------------
--                                OPERATORS
------------------------------------------------------------------------

function Vector4.__add(a,b)

    if isVector4(b) and not isVector4(a) then a,b = b,a end

    if isVector4(b) then
        return a:addVector4(b)
    elseif isMatrix4(b) then
        return a:addMatrix4(b)
    else
        error("Attempt to perform arithmetic between Vector4 and "..type(b))
    end

end

function Vector4.addVector4(a,b)

    return Vector4(
        a.x + b.x,
        a.y + b.y,
        a.z + b.z,
        a.w + b.w
    )

end

function Vector4.addMatrix4(vec,mat)
    
    return Vector4(
        vec.x + mat.r1c1 + vec.y + mat.r2c1 + vec.z + mat.r3c1 + vec.w + mat.r4c1,
        vec.x + mat.r1c2 + vec.y + mat.r2c2 + vec.z + mat.r3c2 + vec.w + mat.r4c2,
        vec.x + mat.r1c3 + vec.y + mat.r2c3 + vec.z + mat.r3c3 + vec.w + mat.r4c3,
        vec.x + mat.r1c4 + vec.y + mat.r2c4 + vec.z + mat.r3c4 + vec.w + mat.r4c4
    )

end

function Vector4.__sub(a,b)

    if isVector4(b) and not isVector4(a) then a,b = b,a end

    if isVector4(b) then
        return a:subVector4(b)
    elseif isMatrix4(b) then
        return a:subMatrix4(b)
    else
        error("Attempt to perform arithmetic between Vector4 and "..type(b))
    end

end

function Vector4.subVector4(a,b)

    return Vector4(
        a.x - b.x,
        a.y - b.y,
        a.z - b.z,
        a.w - b.w
    )

end

function Vector4.subMatrix4(vec,mat)
    
    return Vector4(
        vec.x - mat.r1c1 + vec.y - mat.r2c1 + vec.z - mat.r3c1 + vec.w - mat.r4c1,
        vec.x - mat.r1c2 + vec.y - mat.r2c2 + vec.z - mat.r3c2 + vec.w - mat.r4c2,
        vec.x - mat.r1c3 + vec.y - mat.r2c3 + vec.z - mat.r3c3 + vec.w - mat.r4c3,
        vec.x - mat.r1c4 + vec.y - mat.r2c4 + vec.z - mat.r3c4 + vec.w - mat.r4c4
    )

end

function Vector4.__mul(a,b)

    if isVector4(b) and not isVector4(a) then a,b = b,a end

    if type(b) == "number" then
        return a:mulNumber(b)
    elseif isVector4(b) then
        return a:mulVector4(b)
    elseif isMatrix4(b) then
        return a:mulMatrix4(b)
    else
        error("Attempt to perform arithmetic between Vector4 and "..type(b))
    end

end

function Vector4.mulNumber(vec,scalar)

    return Vector4(
        vec.x * scalar,
        vec.y * scalar,
        vec.z * scalar,
        vec.w * scalar
    )

end

function Vector4.mulVector4(a,b)

    return Vector4(
        a.x * b.x,
        a.y * b.y,
        a.z * b.z,
        a.w * b.w
    )

end

function Vector4.mulMatrix4(vec,mat)
    
    return Vector4(
        vec.x * mat.r1c1 + vec.y * mat.r2c1 + vec.z * mat.r3c1 + vec.w * mat.r4c1,
        vec.x * mat.r1c2 + vec.y * mat.r2c2 + vec.z * mat.r3c2 + vec.w * mat.r4c2,
        vec.x * mat.r1c3 + vec.y * mat.r2c3 + vec.z * mat.r3c3 + vec.w * mat.r4c3,
        vec.x * mat.r1c4 + vec.y * mat.r2c4 + vec.z * mat.r3c4 + vec.w * mat.r4c4
    )

end

function Vector4.__div(a,b)

    if isVector4(b) and not isVector4(a) then a,b = b,a end

    if type(b) == "number" then
        return a:divNumber(b)
    elseif isVector4(b) then
        return a:divVector4(b)
    elseif isMatrix4(b) then
        return a:divMatrix4(b)
    else
        error("Attempt to perform arithmetic between Vector4 and "..type(b))
    end

end

function Vector4.divNumber(vec,scalar)

    return Vector4(
        vec.x / scalar,
        vec.y / scalar,
        vec.z / scalar,
        vec.w / scalar
    )

end

function Vector4.divVector4(a,b)

    return Vector4(
        a.x / b.x,
        a.y / b.y,
        a.z / b.z,
        a.w / b.w
    )

end

function Vector4.divMatrix4(vec,mat)
    
    return Vector4(
        vec.x / mat.r1c1 + vec.y / mat.r2c1 + vec.z / mat.r3c1 + vec.w / mat.r4c1,
        vec.x / mat.r1c2 + vec.y / mat.r2c2 + vec.z / mat.r3c2 + vec.w / mat.r4c2,
        vec.x / mat.r1c3 + vec.y / mat.r2c3 + vec.z / mat.r3c3 + vec.w / mat.r4c3,
        vec.x / mat.r1c4 + vec.y / mat.r2c4 + vec.z / mat.r3c4 + vec.w / mat.r4c4
    )

end

function Vector4.__mod(a,b)

    if isVector4(b) and not isVector4(a) then a,b = b,a end

    if type(b) == "number" then
        return a:modNumber(b)
    elseif isVector4(b) then
        return a:modVector4(b)
    elseif isMatrix4(b) then
        return a:modMatrix4(b)
    else
        error("Attempt to perform arithmetic between Vector4 and "..type(b))
    end

end

function Vector4.modNumber(vec,modulus)

    return Vector4(
        vec.x % modulus,
        vec.y % modulus,
        vec.z % modulus,
        vec.w % modulus
    )

end

function Vector4.modVector4(a,b)

    return Vector4(
        a.x % b.x,
        a.y % b.y,
        a.z % b.z,
        a.w % b.w
    )

end

function Vector4.modMatrix4(vec,mat)
    
    return Vector4(
        vec.x % mat.r1c1 + vec.y % mat.r2c1 + vec.z % mat.r3c1 + vec.w % mat.r4c1,
        vec.x % mat.r1c2 + vec.y % mat.r2c2 + vec.z % mat.r3c2 + vec.w % mat.r4c2,
        vec.x % mat.r1c3 + vec.y % mat.r2c3 + vec.z % mat.r3c3 + vec.w % mat.r4c3,
        vec.x % mat.r1c4 + vec.y % mat.r2c4 + vec.z % mat.r3c4 + vec.w % mat.r4c4
    )

end

function Vector4.__pow(a,b)

    if isVector4(b) and not isVector4(a) then a,b = b,a end

    if type(b) == "number" then
        return a:powNumber(b)
    elseif isVector4(b) then
        return a:powVector4(b)
    elseif isMatrix4(b) then
        return a:powMatrix4(b)
    else
        error("Attempt to perform arithmetic between Vector4 and "..type(b))
    end

end

function Vector4.powNumber(vec,factor)

    return Vector4(
        vec.x ^ factor,
        vec.y ^ factor,
        vec.z ^ factor,
        vec.w ^ factor
    )

end

function Vector4.powVector4(a,b)

    return Vector4(
        a.x ^ b.x,
        a.y ^ b.y,
        a.z ^ b.z,
        a.w ^ b.w
    )

end

function Vector4.powMatrix4(vec,mat)
    
    return Vector4(
        vec.x ^ mat.r1c1 + vec.y ^ mat.r2c1 + vec.z ^ mat.r3c1 + vec.w ^ mat.r4c1,
        vec.x ^ mat.r1c2 + vec.y ^ mat.r2c2 + vec.z ^ mat.r3c2 + vec.w ^ mat.r4c2,
        vec.x ^ mat.r1c3 + vec.y ^ mat.r2c3 + vec.z ^ mat.r3c3 + vec.w ^ mat.r4c3,
        vec.x ^ mat.r1c4 + vec.y ^ mat.r2c4 + vec.z ^ mat.r3c4 + vec.w ^ mat.r4c4
    )

end

function Vector4.__unm(vec)

    return Vector4(
        -vec.x,
        -vec.y,
        -vec.z,
        -vec.w
    )

end

function Vector4.__eq(a,b)

    return isVector4(a) and isVector4(b)
    and a.x == b.x
    and a.y == b.y
    and a.z == b.z
    and a.w == b.w

end