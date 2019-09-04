local ffi
Matrix2 = {}
setmetatable(Matrix2, Matrix2)

Matrix2.keys = {
    r1c1 = 1, r1c2 = 2,
    r2c1 = 3, r2c2 = 4,
}

if jit and jit.status() then

    ffi = require"ffi"

    ffi.cdef([[
        typedef union Matrix2
        {
            double components[4];
        } Matrix2;
    ]])

    ffi.metatype("Matrix2", Matrix2)

else
    ffi = false
end

function isMatrix2(matrix)

    if ffi then
        return ffi.istype("Matrix2", matrix)
    else
        return type(matrix) == "table" and matrix._isclass and matrix._isclass(Matrix2)
    end

end

function Matrix2._isclass(c)
    return c == Matrix2
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

function Matrix2.new(...)

    local args = {...}
    local components = {}
    getComponents(args, components)

    if #components == 0 then
        components = {
            1,0,
            0,1
        }
    end

    assert(#components == 4, "4 components expected, got "..#components)

    local matrix

    if ffi then
        matrix = ffi.new("Matrix2")
    else
        matrix = setmetatable({}, Matrix2)
    end
    
    for i=1,#components do
        matrix.components[i-1] = components[i]
    end

    return matrix

end

function Matrix2.fromRotation(angle)

    return Matrix2(
        math.cos(angle), math.sin(angle),
        -math.sin(angle), math.cos(angle)
    )

end

------------------------------------------------------------------------
--                                METHODS
------------------------------------------------------------------------

function Matrix2.get(matrix, row, column)

    return matrix[(row-1)*2+column]

end

function Matrix2.set(matrix, row, column, value)

    matrix[(row-1)*2+column] = value

end

function Matrix2.unpack(m)

    return  m[1], m[2],
            m[3], m[4]

end

------------------------------------------------------------------------
--                                META
------------------------------------------------------------------------


function Matrix2:__len()

    return 4

end

function Matrix2:__index(key)

    if rawget(Matrix2, key) then
        return rawget(Matrix2, key)

    elseif type(key) == "number" or Matrix2.keys[key] then

        if Matrix2.keys[key] then key = Matrix2.keys[key] end
        return self.components[key-1]

    else
        return rawget(self, key)
    end

end

function Matrix2:__newindex(key, value)

    if type(key) == "number" or Matrix2.keys[key] then

        if Matrix2.keys[key] then key = Matrix2.keys[key] end
        self.components[key-1] = value

    elseif self == Matrix2 then
        rawset(self, key, value)

    else
        error("Matrix2 has no attribute \""..tostring(key).."\"")
    end

end

function Matrix2:__tostring()

    local out = ""

    for r=1,2 do
        if r > 1 then out = out .. "\n" end
        out = out .. "|"
        for c=1,2 do
            if c > 1 then out = out .. "," end
            out = out .. self:get(r,c)
        end
        out = out .. "|"
    end

    return out

end

function Matrix2.__concat(a,b)

    return tostring(a) .. tostring(b)

end

function Matrix2:__call(...)

    return Matrix2.new(...)

end

------------------------------------------------------------------------
--                                OPERATORS
------------------------------------------------------------------------

function Matrix2.__eq(a,b)

    if not (isMatrix2(a) and isMatrix2(b)) then
        return false
    end

    for i=1,#a do
        if not (a[i] == b[i]) then
            return false
        end
    end

    return true

end