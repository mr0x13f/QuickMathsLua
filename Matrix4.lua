local ffi
Matrix4 = {}
setmetatable(Matrix4, Matrix4)

Matrix4.keys = {
    r1c1 = 1, r1c2 = 2, r1c3 = 3, r1c4 = 4,
    r2c1 = 5, r2c2 = 6, r2c3 = 7, r2c4 = 8,
    r3c1 = 9, r3c2 = 10, r3c3 = 11, r3c4 = 12,
    r4c1 = 13, r4c2 = 14, r4c3 = 15, r4c4 = 16,
}

if jit and jit.status() then

    ffi = require"ffi"

    ffi.cdef([[
        typedef union Matrix4
        {
            float components[16];
        } Matrix4;
    ]])

    ffi.metatype("Matrix4", Matrix4)

else
    ffi = false
end

function isMatrix4(matrix)

    if ffi then
        return ffi.istype("Matrix4", matrix)
    else
        return type(matrix) == "table" and matrix._isclass and matrix._isclass(Matrix4)
    end

end

function Matrix4._isclass(c)
    return c == Matrix4
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

function Matrix4.new(...)

    local args = {...}
    local components = {}
    getComponents(args, components)

    if #components == 0 then
        components = {
            1,0,0,0,
            0,1,0,0,
            0,0,1,0,
            0,0,0,1,
        }
    end

    assert(#components == 16, "16 components expected, got "..#components)

    local matrix

    if ffi then
        matrix = ffi.new("Matrix4")
    else
        matrix = setmetatable({}, Matrix4)
    end
    
    for i=1,#components do
        matrix.components[i-1] = components[i]
    end

    return matrix

end

function Matrix4.fromPosition(pos)

    return Matrix4(
        1,0,0,pos.x,
        0,1,0,pos.y,
        0,0,1,pos.z,
        0,0,0,1
    )

end

function Matrix4.fromScale(scale)

    return Matrix4(
        scale.x,0,0,0,
        0,scale.y,0,0,
        0,0,scale.z,0,
        0,0,0,1
    )

end

function Matrix4.fromRotationX(angle)

    local c = math.cos(angle)
    local s = math.sin(angle)

    return Matrix4(
        1, 0, 0, 0,
        0, c,-s, 0,
        0, s, c, 0,
        0, 0, 0, 1
    )

end

function Matrix4.fromRotationY(angle)

    local c = math.cos(angle)
    local s = math.sin(angle)

    return Matrix4(
        c, 0, s, 0,
        0, 1, 0, 0,
       -s, 0, c, 0,
        0, 0, 0, 1
    )

end

function Matrix4.fromRotationZ(angle)

    local c = math.cos(angle)
    local s = math.sin(angle)

    return Matrix4(
        c,-s, 0, 0,
        s, c, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    )

end

function Matrix4.fromRotation(rot)

    return Matrix4.fromRotationX(rot.x) * Matrix4.fromRotationY(rot.y) * Matrix4.fromRotationZ(rot.z)

end

function Matrix4.fromTransform(pos, rot, scale)

    local out = Matrix4()

    if pos then out = out * Matrix4.fromPosition(pos) end
    if scale then out = out * Matrix4.fromScale(scale) end
    if rot then out = out * Matrix4.fromRotation(rot) end

    return out

end

function Matrix4.fromView(pos, rot)

    local out = Matrix4()

    if rot then out = out * Matrix4.fromRotation(rot) end
    if pos then out = out * Matrix4.fromPosition(-pos) end

    return out
    
end

function Matrix4.fromPerspective(fov, ratio, near, far)
    
    local out = Matrix4()

    local t = math.tan(math.rad(fov)/2)
    out:set(1,1, 1 / (ratio * t) )
    out:set(2,2, 1 / t )
    out:set(3,3, -(far + near) / (far - near) )
    out:set(3,4, -(2 * far * near) / (far - near) )
    out:set(4,3, -1 )
    out:set(4,4, 0 )

    return out

end

function Matrix4.fromOrthographic(left, right, top, bottom, near, far)

    local out = Matrix4()
	out:set(1,1, 2 / (right - left) )
	out:set(2,2,  2 / (top - bottom) )
	out:set(3,3, -2 / (far - near) )
	out:set(4,1, -((right + left) / (right - left)) )
	out:set(4,2, -((top + bottom) / (top - bottom)) )
	out:set(4,3, -((far + near) / (far - near)) )
    out:set(4,4, 0 )
    
    return out

end

------------------------------------------------------------------------
--                                METHODS
------------------------------------------------------------------------

function Matrix4.get(matrix, row, column)

    return matrix[(row-1)*4+column]

end

function Matrix4.set(matrix, row, column, value)

    matrix[(row-1)*4+column] = value

end

function Matrix4.unpack(m)

    return  m[1], m[2], m[3], m[4],
            m[5], m[6], m[7], m[8],
            m[9], m[10], m[11], m[12],
            m[13], m[14], m[15], m[16]

end

local tmp = {}
function Matrix4.send(mat)

    for i=1,#mat do
        tmp[i] = mat[i]
    end

    return tmp

end

function Matrix4.invert(matrix)

    local out = Matrix4()

    out[1] = matrix[6] * matrix[11] * matrix[16] - matrix[6] * matrix[15] * matrix[12] - matrix[7] * matrix[10] * matrix[16] + matrix[7] * matrix[14] * matrix[12] + matrix[8] * matrix[10] * matrix[15] - matrix[8] * matrix[14] * matrix[11]
	out[5] = -matrix[5] * matrix[11] * matrix[16] + matrix[5] * matrix[15] * matrix[12] + matrix[7] * matrix[9] * matrix[16] - matrix[7] * matrix[13] * matrix[12] - matrix[8] * matrix[9] * matrix[15] + matrix[8] * matrix[13] * matrix[11]
	out[9] = matrix[5] * matrix[10] * matrix[16] - matrix[5] * matrix[14] * matrix[12] - matrix[6] * matrix[9] * matrix[16] + matrix[6] * matrix[13] * matrix[12] + matrix[8] * matrix[9] * matrix[14] - matrix[8] * matrix[13] * matrix[10]
	out[13] = -matrix[5] * matrix[10] * matrix[15] + matrix[5] * matrix[14] * matrix[11] + matrix[6] * matrix[9] * matrix[15] - matrix[6] * matrix[13] * matrix[11] - matrix[7] * matrix[9] * matrix[14] + matrix[7] * matrix[13] * matrix[10]
	out[2] = -matrix[2] * matrix[11] * matrix[16] + matrix[2] * matrix[15] * matrix[12] + matrix[3] * matrix[10] * matrix[16] - matrix[3] * matrix[14] * matrix[12] - matrix[4] * matrix[10] * matrix[15] + matrix[4] * matrix[14] * matrix[11]
	out[6] = matrix[1] * matrix[11] * matrix[16] - matrix[1] * matrix[15] * matrix[12] - matrix[3] * matrix[9] * matrix[16] + matrix[3] * matrix[13] * matrix[12] + matrix[4] * matrix[9] * matrix[15] - matrix[4] * matrix[13] * matrix[11]
	out[10] = -matrix[1] * matrix[10] * matrix[16] + matrix[1] * matrix[14] * matrix[12] + matrix[2] * matrix[9] * matrix[16] - matrix[2] * matrix[13] * matrix[12] - matrix[4] * matrix[9] * matrix[14] + matrix[4] * matrix[13] * matrix[10]
	out[14] = matrix[1] * matrix[10] * matrix[15] - matrix[1] * matrix[14] * matrix[11] - matrix[2] * matrix[9] * matrix[15] + matrix[2] * matrix[13] * matrix[11] + matrix[3] * matrix[9] * matrix[14] - matrix[3] * matrix[13] * matrix[10]
	out[3] = matrix[2] * matrix[7] * matrix[16] - matrix[2] * matrix[15] * matrix[8] - matrix[3] * matrix[6] * matrix[16] + matrix[3] * matrix[14] * matrix[8] + matrix[4] * matrix[6] * matrix[15] - matrix[4] * matrix[14] * matrix[7]
	out[7] = -matrix[1] * matrix[7] * matrix[16] + matrix[1] * matrix[15] * matrix[8] + matrix[3] * matrix[5] * matrix[16] - matrix[3] * matrix[13] * matrix[8] - matrix[4] * matrix[5] * matrix[15] + matrix[4] * matrix[13] * matrix[7]
	out[11] = matrix[1] * matrix[6] * matrix[16] - matrix[1] * matrix[14] * matrix[8] - matrix[2] * matrix[5] * matrix[16] + matrix[2] * matrix[13] * matrix[8] + matrix[4] * matrix[5] * matrix[14] - matrix[4] * matrix[13] * matrix[6]
	out[15] = -matrix[1] * matrix[6] * matrix[15] + matrix[1] * matrix[14] * matrix[7] + matrix[2] * matrix[5] * matrix[15] - matrix[2] * matrix[13] * matrix[7] - matrix[3] * matrix[5] * matrix[14] + matrix[3] * matrix[13] * matrix[6]
	out[4] = -matrix[2] * matrix[7] * matrix[12] + matrix[2] * matrix[11] * matrix[8] + matrix[3] * matrix[6] * matrix[12] - matrix[3] * matrix[10] * matrix[8] - matrix[4] * matrix[6] * matrix[11] + matrix[4] * matrix[10] * matrix[7]
	out[8] = matrix[1] * matrix[7] * matrix[12] - matrix[1] * matrix[11] * matrix[8] - matrix[3] * matrix[5] * matrix[12] + matrix[3] * matrix[9] * matrix[8] + matrix[4] * matrix[5] * matrix[11] - matrix[4] * matrix[9] * matrix[7]
	out[12] = -matrix[1] * matrix[6] * matrix[12] + matrix[1] * matrix[10] * matrix[8] + matrix[2] * matrix[5] * matrix[12] - matrix[2] * matrix[9] * matrix[8] - matrix[4] * matrix[5] * matrix[10] + matrix[4] * matrix[9] * matrix[6]
	out[16] = matrix[1] * matrix[6] * matrix[11] - matrix[1] * matrix[10] * matrix[7] - matrix[2] * matrix[5] * matrix[11] + matrix[2] * matrix[9] * matrix[7] + matrix[3] * matrix[5] * matrix[10] - matrix[3] * matrix[9] * matrix[6]

	local det = matrix[1] * out[1] + matrix[5] * out[2] + matrix[9] * out[3] + matrix[13] * out[4]

	if det == 0 then return matrix end

	det = 1/det

	for i=1,#matrix do
		out[i] = out[i] * det
	end

	return out

end

function Matrix4.transpose(matrix)

    local out = Matrix4()

    for r=1,4 do
        for c=1,4 do
            out:set(r,c, matrix:get(c,r))
        end
    end

    return out

end

function Matrix4.normal(matrix)

    return matrix:invert():transpose()

end

------------------------------------------------------------------------
--                                META
------------------------------------------------------------------------


function Matrix4:__len()

    return 16

end

function Matrix4:__index(key)

    if rawget(Matrix4, key) then
        return rawget(Matrix4, key)

    elseif type(key) == "number" or Matrix4.keys[key] then

        if Matrix4.keys[key] then key = Matrix4.keys[key] end
        return self.components[key-1]

    else
        return rawget(self, key)
    end

end

function Matrix4:__newindex(key, value)

    if type(key) == "number" or Matrix4.keys[key] then

        if Matrix4.keys[key] then key = Matrix4.keys[key] end
        self.components[key-1] = value

    elseif self == Matrix4 then
        rawset(self, key, value)

    else
        error("Matrix4 has no attribute \""..tostring(key).."\"")
    end

end

function Matrix4:__tostring()

    local out = ""

    for r=1,4 do
        if r > 1 then out = out .. "\n" end
        out = out .. "|"
        for c=1,4 do
            if c > 1 then out = out .. "," end
            out = out .. self:get(r,c)
        end
        out = out .. "|"
    end

    return out

end

function Matrix4.__concat(a,b)

    return tostring(a) .. tostring(b)

end

function Matrix4:__call(...)

    return Matrix4.new(...)

end

------------------------------------------------------------------------
--                                OPERATORS
------------------------------------------------------------------------

function Matrix4.__mul(a,b)

    if isMatrix4(b) and not isMatrix4(a) then a,b = b,a end

    if isMatrix4(b) then
        return a:mulMatrix4(b)
    elseif isVector4(b) then
        return Vector4.mulMatrix4(b,a)
    else
        error("Attempt to perform arithmetic between Matrix4 and "..type(b))
    end

end

function Matrix4.mulMatrix4(a,b)
    
    return Matrix4(
        a.r1c1*b.r1c1 + a.r1c2*b.r2c1 + a.r1c3*b.r3c1 + a.r1c4*b.r4c1,
        a.r1c1*b.r1c2 + a.r1c2*b.r2c2 + a.r1c3*b.r3c2 + a.r1c4*b.r4c2,
        a.r1c1*b.r1c3 + a.r1c2*b.r2c3 + a.r1c3*b.r3c3 + a.r1c4*b.r4c3,
        a.r1c1*b.r1c4 + a.r1c2*b.r2c4 + a.r1c3*b.r3c4 + a.r1c4*b.r4c4,

        a.r2c1*b.r1c1 + a.r2c2*b.r2c1 + a.r2c3*b.r3c1 + a.r2c4*b.r4c1,
        a.r2c1*b.r1c2 + a.r2c2*b.r2c2 + a.r2c3*b.r3c2 + a.r2c4*b.r4c2,
        a.r2c1*b.r1c3 + a.r2c2*b.r2c3 + a.r2c3*b.r3c3 + a.r2c4*b.r4c3,
        a.r2c1*b.r1c4 + a.r2c2*b.r2c4 + a.r2c3*b.r3c4 + a.r2c4*b.r4c4,

        a.r3c1*b.r1c1 + a.r3c2*b.r2c1 + a.r3c3*b.r3c1 + a.r3c4*b.r4c1,
        a.r3c1*b.r1c2 + a.r3c2*b.r2c2 + a.r3c3*b.r3c2 + a.r3c4*b.r4c2,
        a.r3c1*b.r1c3 + a.r3c2*b.r2c3 + a.r3c3*b.r3c3 + a.r3c4*b.r4c3,
        a.r3c1*b.r1c4 + a.r3c2*b.r2c4 + a.r3c3*b.r3c4 + a.r3c4*b.r4c4,

        a.r4c1*b.r1c1 + a.r4c2*b.r2c1 + a.r4c3*b.r3c1 + a.r4c4*b.r4c1,
        a.r4c1*b.r1c2 + a.r4c2*b.r2c2 + a.r4c3*b.r3c2 + a.r4c4*b.r4c2,
        a.r4c1*b.r1c3 + a.r4c2*b.r2c3 + a.r4c3*b.r3c3 + a.r4c4*b.r4c3,
        a.r4c1*b.r1c4 + a.r4c2*b.r2c4 + a.r4c3*b.r3c4 + a.r4c4*b.r4c4
    )

end

function Matrix4.__eq(a,b)

    if not (isMatrix4(a) and isMatrix4(b)) then
        return false
    end

    for i=1,#a do
        if not (a[i] == b[i]) then
            return false
        end
    end

    return true

end