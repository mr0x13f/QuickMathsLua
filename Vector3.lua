local ffi
Vector3 = {}
setmetatable(Vector3, Vector3)

Vector3.keys = {
    x = 1,
    y = 2,
    z = 3,

    r = 1,
    g = 2,
    b = 3,
}

if jit and jit.status() then

    ffi = require"ffi"

    ffi.cdef([[
        typedef union Vector3
        {
            double components[3];
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

function Vector3.unpack(v)

    return v[1], v[2], v[3]

end

function Vector3.clamp(vector, min, max)

    if not min then min = vector end
    if not max then max = vector end

    local out = Vector3()

    for i=1,#vector do
        out[i] = math.max(math.min(vector[i], max[i]), min[i])
    end

    return out

end

function Vector3.angle(vector)

    local out = Vector3()

    out.x = math.atan2(math.sqrt(vector.y^2+vector.z^2),vector.x)
    out.y = math.atan2(math.sqrt(vector.z^2+vector.x^2),vector.y)
    out.z = math.atan2(math.sqrt(vector.x^2+vector.y^2),vector.z)

    return out
    
end

function Vector3.rotate(vector, angle)

    return vector * Matrix3.fromRotationZ(angle.z) * Matrix3.fromRotationY(angle.y) * Matrix3.fromRotationX(angle.x)

end

function Vector3.magnitude(vector)

    return math.sqrt(vector.x^2 + vector.y^2 + vector.z^2)

end

function Vector3.magnitude2(vector)

    return vector.x^2 + vector.y^2 + vector.z^2

end

function Vector3.distance(a,b)

    return (a-b):magnitude()

end

function Vector3.distance2(a,b)

    return (a-b):magnitude2()

end

function Vector3.normalize(vector)

    return 1/vector:magnitude() * vector

end

function Vector3.trim(vector, len)

    return len/vector:magnitude() * vector

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
        error("Vector3 has no attribute \""..key.."\"")
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
        return a:addVector(b)
    elseif isMatrix3(b) then
        return a:addMatrix(b)
    else
        error("Attempt to perform arithmetic between Vector3 and "..type(b))
    end

end

function Vector3.addVector(a,b)

    local out = Vector3()

    for i=1,#a do
        out[i] = a[i] + b[i]
    end

    return out

end

function Vector3.addMatrix(vector,matrix)
    
    local out = Vector3()

    for r=1,#vector do
        for c=1,#vector do
            out[i] = matrix:get(r,c) + vector[r]
        end
    end

    return out

end

function Vector3.__sub(a,b)

    if isVector3(b) and not isVector3(a) then a,b = b,a end

    if isVector3(b) then
        return a:subVector(b)
    elseif isMatrix3(b) then
        return a:subMatrix(b)
    else
        error("Attempt to perform arithmetic between Vector3 and "..type(b))
    end

end

function Vector3.subVector(a,b)

    local out = Vector3()

    for i=1,#a do
        out[i] = a[i] - b[i]
    end

    return out

end

function Vector3.subMatrix(vector,matrix)
    
    local out = Vector3()

    for r=1,#vector do
        for c=1,#vector do
            out[i] = matrix:get(r,c) - vector[r]
        end
    end

    return out

end

function Vector3.__mul(a,b)

    if isVector3(b) and not isVector3(a) then a,b = b,a end

    if type(b) == "number" then
        return a:mulNumber(b)
    elseif isVector3(b) then
        return a:mulVector(b)
    elseif isMatrix3(b) then
        return a:mulMatrix(b)
    else
        error("Attempt to perform arithmetic between Vector3 and "..type(b))
    end

end

function Vector3.mulNumber(vector,scalar)

    local out = Vector3()

    for i=1,#a do
        out[i] = vector[i] * scalar
    end

    return out

end

function Vector3.mulVector(a,b)

    local out = Vector3()

    for i=1,#a do
        out[i] = a[i] * b[i]
    end

    return out

end

function Vector3.mulMatrix(vector,matrix)
    
    local out = Vector3()

    for r=1,#vector do
        for c=1,#vector do
            out[i] = matrix:get(r,c) * vector[r]
        end
    end

    return out

end

function Vector3.__div(a,b)

    if isVector3(b) and not isVector3(a) then a,b = b,a end

    if type(b) == "number" then
        return a:divNumber(b)
    elseif isVector3(b) then
        return a:divVector(b)
    elseif isMatrix3(b) then
        return a:divMatrix(b)
    else
        error("Attempt to perform arithmetic between Vector3 and "..type(b))
    end

end

function Vector3.divNumber(vector,scalar)

    local out = Vector3()

    for i=1,#a do
        out[i] = vector[i] / scalar
    end

    return out

end

function Vector3.divVector(a,b)

    local out = Vector3()

    for i=1,#a do
        out[i] = a[i] / b[i]
    end

    return out

end

function Vector3.divMatrix(vector,matrix)
    
    local out = Vector3()

    for r=1,#vector do
        for c=1,#vector do
            out[i] = matrix:get(r,c) / vector[r]
        end
    end

    return out

end

function Vector3.__mod(a,b)

    if isVector3(b) and not isVector3(a) then a,b = b,a end

    if type(b) == "number" then
        return a:modNumber(b)
    elseif isVector3(b) then
        return a:modVector(b)
    elseif isMatrix3(b) then
        return a:modMatrix(b)
    else
        error("Attempt to perform arithmetic between Vector3 and "..type(b))
    end

end

function Vector3.modNumber(vector,modulus)

    local out = Vector3()

    for i=1,#a do
        out[i] = vector[i] % modulus
    end

    return out

end

function Vector3.modVector(a,b)

    local out = Vector3()

    for i=1,#a do
        out[i] = a[i] % b[i]
    end

    return out

end

function Vector3.modMatrix(vector,matrix)
    
    local out = Vector3()

    for r=1,#vector do
        for c=1,#vector do
            out[i] = matrix:get(r,c) % vector[r]
        end
    end

    return out

end

function Vector3.__pow(a,b)

    if isVector3(b) and not isVector3(a) then a,b = b,a end

    if type(b) == "number" then
        return a:powNumber(b)
    elseif isVector3(b) then
        return a:powVector(b)
    elseif isMatrix3(b) then
        return a:powMatrix(b)
    else
        error("Attempt to perform arithmetic between Vector3 and "..type(b))
    end

end

function Vector3.powNumber(vector,factor)

    local out = Vector3()

    for i=1,#a do
        out[i] = vector[i] ^ factor
    end

    return out

end

function Vector3.powVector(a,b)

    local out = Vector3()

    for i=1,#a do
        out[i] = a[i] ^ b[i]
    end

    return out

end

function Vector3.powMatrix(vector,matrix)
    
    local out = Vector3()

    for r=1,#vector do
        for c=1,#vector do
            out[i] = matrix:get(r,c) ^ vector[r]
        end
    end

    return out

end

function Vector3.__unm(vector)

    local out = Vector3()

    for i=1,#a do
        out[i] = -vector[i]
    end

    return out

end

function Vector3.__eq(a,b)

    if not (isVector3(a) and isVector3(b)) then
        return false
    end

    for i=1,#a do
        if not (a[i] == b[i]) then
            return false
        end
    end

    return true

end