local ffi
Vector4 = {}
setmetatable(Vector4, Vector4)

Vector4.keys = {
    x = 1,
    y = 2,
    z = 3,
    w = 4,

    r = 1,
    g = 2,
    b = 3,
    a = 4,
}

if jit and jit.status() then

    ffi = require"ffi"

    ffi.cdef([[
        typedef union Vector4
        {
            double components[4];
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
        elseif type(args[i]) == "table" or isVector2(args[i]) or isVector4(args[i]) or isVector4(args[i]) then
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

function Vector4.fromHex(hex)

    assert(type(hex) == "string", "Invalid arguments")

    if hex:sub(1,1) == "#" then hex = hex:sub(2,#hex) end

    local out = Vector4(0,0,0,1)

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

function Vector4.toHex(vector)

    local r = string.format("%x", vector.r * 255)
    local g = string.format("%x", vector.g * 255)
    local b = string.format("%x", vector.b * 255)

    if #r == 1 then r = "0"..r end
    if #g == 1 then g = "0"..g end
    if #b == 1 then b = "0"..b end

    return "#"..r..g..b

end

function Vector4.unpack(v)

    return v[1], v[2], v[3], v[4]

end

function Vector4.clamp(vector, min, max)

    if not min then min = vector end
    if not max then max = vector end

    local out = Vector4()

    for i=1,#vector do
        out[i] = math.max(math.min(vector[i], max[i]), min[i])
    end

    return out

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
        return a:addVector(b)
    elseif isMatrix4(b) then
        return a:addMatrix(b)
    else
        error("Attempt to perform arithmetic between Vector4 and "..type(b))
    end

end

function Vector4.addVector(a,b)

    local out = Vector4()

    for i=1,#a do
        out[i] = a[i] + b[i]
    end

    return out

end

function Vector4.addMatrix(vector,matrix)
    
    local out = Vector4()

    for r=1,#vector do
        for c=1,#vector do
            out[i] = matrix:get(r,c) + vector[r]
        end
    end

    return out

end

function Vector4.__sub(a,b)

    if isVector4(b) and not isVector4(a) then a,b = b,a end

    if isVector4(b) then
        return a:subVector(b)
    elseif isMatrix4(b) then
        return a:subMatrix(b)
    else
        error("Attempt to perform arithmetic between Vector4 and "..type(b))
    end

end

function Vector4.subVector(a,b)

    local out = Vector4()

    for i=1,#a do
        out[i] = a[i] - b[i]
    end

    return out

end

function Vector4.subMatrix(vector,matrix)
    
    local out = Vector4()

    for r=1,#vector do
        for c=1,#vector do
            out[i] = matrix:get(r,c) - vector[r]
        end
    end

    return out

end

function Vector4.__mul(a,b)

    if isVector4(b) and not isVector4(a) then a,b = b,a end

    if type(b) == "number" then
        return a:mulNumber(b)
    elseif isVector4(b) then
        return a:mulVector(b)
    elseif isMatrix4(b) then
        return a:mulMatrix(b)
    else
        error("Attempt to perform arithmetic between Vector4 and "..type(b))
    end

end

function Vector4.mulNumber(vector,scalar)

    local out = Vector4()

    for i=1,#vector do
        out[i] = vector[i] * scalar
    end

    return out

end

function Vector4.mulVector(a,b)

    local out = Vector4()

    for i=1,#a do
        out[i] = a[i] * b[i]
    end

    return out

end

function Vector4.mulMatrix(vector,matrix)
    
    local out = Vector4()

    for r=1,#vector do
        for c=1,#vector do
            out[i] = matrix:get(r,c) * vector[r]
        end
    end

    return out

end

function Vector4.__div(a,b)

    if isVector4(b) and not isVector4(a) then a,b = b,a end

    if type(b) == "number" then
        return a:divNumber(b)
    elseif isVector4(b) then
        return a:divVector(b)
    elseif isMatrix4(b) then
        return a:divMatrix(b)
    else
        error("Attempt to perform arithmetic between Vector4 and "..type(b))
    end

end

function Vector4.divNumber(vector,scalar)

    local out = Vector4()

    for i=1,#vector do
        out[i] = vector[i] / scalar
    end

    return out

end

function Vector4.divVector(a,b)

    local out = Vector4()

    for i=1,#a do
        out[i] = a[i] / b[i]
    end

    return out

end

function Vector4.divMatrix(vector,matrix)
    
    local out = Vector4()

    for r=1,#vector do
        for c=1,#vector do
            out[i] = matrix:get(r,c) / vector[r]
        end
    end

    return out

end

function Vector4.__mod(a,b)

    if isVector4(b) and not isVector4(a) then a,b = b,a end

    if type(b) == "number" then
        return a:modNumber(b)
    elseif isVector4(b) then
        return a:modVector(b)
    elseif isMatrix4(b) then
        return a:modMatrix(b)
    else
        error("Attempt to perform arithmetic between Vector4 and "..type(b))
    end

end

function Vector4.modNumber(vector,modulus)

    local out = Vector4()

    for i=1,#vector do
        out[i] = vector[i] % modulus
    end

    return out

end

function Vector4.modVector(a,b)

    local out = Vector4()

    for i=1,#a do
        out[i] = a[i] % b[i]
    end

    return out

end

function Vector4.modMatrix(vector,matrix)
    
    local out = Vector4()

    for r=1,#vector do
        for c=1,#vector do
            out[i] = matrix:get(r,c) % vector[r]
        end
    end

    return out

end

function Vector4.__pow(a,b)

    if isVector4(b) and not isVector4(a) then a,b = b,a end

    if type(b) == "number" then
        return a:powNumber(b)
    elseif isVector4(b) then
        return a:powVector(b)
    elseif isMatrix4(b) then
        return a:powMatrix(b)
    else
        error("Attempt to perform arithmetic between Vector4 and "..type(b))
    end

end

function Vector4.powNumber(vector,factor)

    local out = Vector4()

    for i=1,#vector do
        out[i] = vector[i] ^ factor
    end

    return out

end

function Vector4.powVector(a,b)

    local out = Vector4()

    for i=1,#a do
        out[i] = a[i] ^ b[i]
    end

    return out

end

function Vector4.powMatrix(vector,matrix)
    
    local out = Vector4()

    for r=1,#vector do
        for c=1,#vector do
            out[i] = matrix:get(r,c) ^ vector[r]
        end
    end

    return out

end

function Vector4.__unm(vector)

    local out = Vector4()

    for i=1,#vector do
        out[i] = -vector[i]
    end

    return out

end

function Vector4.__eq(a,b)

    if not (isVector4(a) and isVector4(b)) then
        return false
    end

    for i=1,#a do
        if not (a[i] == b[i]) then
            return false
        end
    end

    return true

end