local ffi
Matrix3 = {}
setmetatable(Matrix3, Matrix3)

if jit and jit.status() then

    ffi = require"ffi"

    ffi.cdef([[
        typedef union Matrix3
        {
            double components[9];
        } Matrix3;
    ]])

    ffi.metatype("Matrix3", Matrix3)

else
    ffi = false
end

function isMatrix3(matrix)

    if ffi then
        return ffi.istype("Matrix3", matrix)
    else
        return type(matrix) == "table" and matrix._isclass and matrix._isclass(Matrix3)
    end

end

function Matrix3._isclass(c)
    return c == Matrix3
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

function Matrix3.new(...)

    local args = {...}
    local components = {}
    getComponents(args, components)

    if #components == 0 then
        components = {
            1,0,0,
            0,1,0,
            0,0,1,
        }
    end

    assert(#components == 9, "9 components expected, got "..#components)

    local matrix

    if ffi then
        matrix = ffi.new("Matrix3")
    else
        matrix = setmetatable({}, Matrix3)
    end
    
    for i=1,#components do
        matrix.components[i-1] = components[i]
    end

    return matrix

end

function Matrix3.fromRotationX(angle)

    local c = math.cos(angle)
    local s = math.sin(angle)

    return Matrix3(
        1, 0, 0,
        0, c,-s,
        0, s, c
    )

end

function Matrix3.fromRotationY(angle)

    local c = math.cos(angle)
    local s = math.sin(angle)

    return Matrix3(
        c, 0, s,
        0, 1, 0,
       -s, 0, c
    )

end

function Matrix3.fromRotationZ(angle)

    local c = math.cos(angle)
    local s = math.sin(angle)

    return Matrix3(
        c,-s, 0,
        s, c, 0,
        0, 0, 1
    )

end

------------------------------------------------------------------------
--                                METHODS
------------------------------------------------------------------------

function Matrix3.get(matrix, row, column)

    return matrix[(row-1)*3+column]

end

function Matrix3.set(matrix, row, column, value)

    matrix[(row-1)*3+column] = value

end

function Matrix3.unpack(matrix)

    local out = {}

    for i=1,#matrix do
        table.insert(out, matrix[i])
    end

    return unpack(out)

end

------------------------------------------------------------------------
--                                META
------------------------------------------------------------------------


function Matrix3:__len()

    return 9

end

function Matrix3:__index(key)

    if rawget(Matrix3, key) then
        return rawget(Matrix3, key)

    elseif type(key) == "number" then

        return self.components[key-1]

    else
        return rawget(self, key)
    end

end

function Matrix3:__newindex(key, value)

    if type(key) == "number"then

        self.components[key-1] = value

    elseif self == Matrix3 then
        rawset(self, key, value)

    else
        error("Matrix3 has no attribute \""..key.."\"")
    end

end

function Matrix3:__tostring()

    local out = ""

    for r=1,3 do
        if r > 1 then out = out .. "\n" end
        out = out .. "|"
        for c=1,3 do
            if c > 1 then out = out .. "," end
            out = out .. self:get(r,c)
        end
        out = out .. "|"
    end

    return out

end

function Matrix3.__concat(a,b)

    return tostring(a) .. tostring(b)

end

function Matrix3:__call(...)

    return Matrix3.new(...)

end

------------------------------------------------------------------------
--                                OPERATORS
------------------------------------------------------------------------

function Matrix3.__eq(a,b)

    if not (isMatrix3(a) and isMatrix3(b)) then
        return false
    end

    for i=1,#a do
        if not (a[i] == b[i]) then
            return false
        end
    end

    return true

end