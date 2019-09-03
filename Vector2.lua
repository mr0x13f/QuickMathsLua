local ffi
Vector2 = {}
setmetatable(Vector2, Vector2)

Vector2.keys = {
    x = 1,
    y = 2,
}

if jit and jit.status() then

    ffi = require"ffi"

    ffi.cdef([[
        typedef union Vector2
        {
            double components[2];
        } Vector2;
    ]])

    ffi.metatype("Vector2", Vector2)

else
    ffi = false
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
        vector = setmetatable({}, Vector2)
    end
    
    for i=1,#components do
        vector.components[i-1] = components[i]
    end

    return vector

end

------------------------------------------------------------------------
--                                METHODS
------------------------------------------------------------------------

function Vector2.unpack(v)

    return v[1], v[2]

end

function Vector2.floor(vector)

    local out = Vector2()

    for i=1,#vector do
        out[i] = math.floor(vector[i])
    end

    return out

end

function Vector2.ceil(vector)

    local out = Vector2()

    for i=1,#vector do
        out[i] = math.ceil(vector[i])
    end

    return out

end

function Vector2.clamp(vector, min, max)

    if not min then min = vector end
    if not max then max = vector end

    local out = Vector2()

    for i=1,#vector do
        out[i] = math.max(math.min(vector[i], max[i]), min[i])
    end

    return out

end

function Vector2.angle(vector)

    return math.atan2(vector.y, vector.x)
    
end

function Vector2.rotate(vector, angle)

    return vector * Matrix2.fromRotation(angle)

end

function Vector2.magnitude(vector)

    return math.sqrt(vector.x^2 + vector.y^2)

end

function Vector2.magnitude2(vector)

    return vector.x^2 + vector.y^2

end

function Vector2.distance(a,b)

    return (a-b):magnitude()

end

function Vector2.distance2(a,b)

    return (a-b):magnitude2()

end

function Vector2.normalize(vector)

    if vector:magnitude2() == 0 then return vector end

    return 1/vector:magnitude() * vector

end

function Vector2.trim(vector, len)

    if vector:magnitude2() == 0 then return vector end
    if len < 0 then len = -len end

    return len / math.max(vector:magnitude(),len) * vector

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
        return a:addVector(b)
    elseif isMatrix2(b) then
        return a:addMatrix(b)
    else
        error("Attempt to perform arithmetic between Vector2 and "..type(b))
    end

end

function Vector2.addVector(a,b)

    local out = Vector2()

    for i=1,#a do
        out[i] = a[i] + b[i]
    end

    return out

end

function Vector2.addMatrix(vector,matrix)
    
    local out = Vector2()

    for r=1,#vector do
        for c=1,#vector do
            out[r] = b[r][c] + a[r]
        end
    end

    return out

end

function Vector2.__sub(a,b)

    if isVector2(b) and not isVector2(a) then a,b = b,a end

    if isVector2(b) then
        return a:subVector(b)
    elseif isMatrix2(b) then
        return a:subMatrix(b)
    else
        error("Attempt to perform arithmetic between Vector2 and "..type(b))
    end

end

function Vector2.subVector(a,b)

    local out = Vector2()

    for i=1,#a do
        out[i] = a[i] - b[i]
    end

    return out

end

function Vector2.subMatrix(vector,matrix)
    
    local out = Vector2()

    for r=1,#vector do
        for c=1,#vector do
            out[r] = b[r][c] - a[r]
        end
    end

    return out

end

function Vector2.__mul(a,b)

    if isVector2(b) and not isVector2(a) then a,b = b,a end

    if type(b) == "number" then
        return a:mulNumber(b)
    elseif isVector2(b) then
        return a:mulVector(b)
    elseif isMatrix2(b) then
        return a:mulMatrix(b)
    else
        error("Attempt to perform arithmetic between Vector2 and "..type(b))
    end

end

function Vector2.mulNumber(vector,scalar)

    local out = Vector2()

    for i=1,#vector do
        out[i] = vector[i] * scalar
    end

    return out

end

function Vector2.mulVector(a,b)

    local out = Vector2()

    for i=1,#a do
        out[i] = a[i] * b[i]
    end

    return out

end

function Vector2.mulMatrix(vector,matrix)
    
    local out = Vector2()

    for r=1,#vector do
        for c=1,#vector do
            out[r] = matrix:get(r,c) * vector[r]
        end
    end

    return out

end

function Vector2.__div(a,b)

    if isVector2(b) and not isVector2(a) then a,b = b,a end

    if type(b) == "number" then
        return a:divNumber(b)
    elseif isVector2(b) then
        return a:divVector(b)
    elseif isMatrix2(b) then
        return a:divMatrix(b)
    else
        error("Attempt to perform arithmetic between Vector2 and "..type(b))
    end

end

function Vector2.divNumber(vector,scalar)

    local out = Vector2()

    for i=1,#vector do
        out[i] = vector[i] / scalar
    end

    return out

end

function Vector2.divVector(a,b)

    local out = Vector2()

    for i=1,#a do
        out[i] = a[i] / b[i]
    end

    return out

end

function Vector2.divMatrix(vector,matrix)
    
    local out = Vector2()

    for r=1,#vector do
        for c=1,#vector do
            out[r] = matrix:get(r,c) / vector[r]
        end
    end

    return out

end

function Vector2.__mod(a,b)

    if isVector2(b) and not isVector2(a) then a,b = b,a end

    if type(b) == "number" then
        return a:modNumber(b)
    elseif isVector2(b) then
        return a:modVector(b)
    elseif isMatrix2(b) then
        return a:modMatrix(b)
    else
        error("Attempt to perform arithmetic between Vector2 and "..type(b))
    end

end

function Vector2.modNumber(vector,modulus)

    local out = Vector2()

    for i=1,#vector do
        out[i] = vector[i] % modulus
    end

    return out

end

function Vector2.modVector(a,b)

    local out = Vector2()

    for i=1,#a do
        out[i] = a[i] % b[i]
    end

    return out

end

function Vector2.modMatrix(vector,matrix)
    
    local out = Vector2()

    for r=1,#vector do
        for c=1,#vector do
            out[r] = matrix:get(r,c) % vector[r]
        end
    end

    return out

end

function Vector2.__pow(a,b)

    if isVector2(b) and not isVector2(a) then a,b = b,a end

    if type(b) == "number" then
        return a:powNumber(b)
    elseif isVector2(b) then
        return a:powVector(b)
    elseif isMatrix2(b) then
        return a:powMatrix(b)
    else
        error("Attempt to perform arithmetic between Vector2 and "..type(b))
    end

end

function Vector2.powNumber(vector,factor)

    local out = Vector2()

    for i=1,#vector do
        out[i] = vector[i] ^ factor
    end

    return out

end

function Vector2.powVector(a,b)

    local out = Vector2()

    for i=1,#a do
        out[i] = a[i] ^ b[i]
    end

    return out

end

function Vector2.powMatrix(vector,matrix)
    
    local out = Vector2()

    for r=1,#vector do
        for c=1,#vector do
            out[r] = matrix:get(r,c) ^ vector[r]
        end
    end

    return out

end

function Vector2.__unm(vector)

    local out = Vector2()

    for i=1,#vector do
        out[i] = -vector[i]
    end

    return out

end

function Vector2.__eq(a,b)

    if not (isVector2(a) and isVector2(b)) then
        return false
    end

    for i=1,#a do
        if not (a[i] == b[i]) then
            return false
        end
    end

    return true

end