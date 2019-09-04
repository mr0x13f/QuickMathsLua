# QuickMaths
An FFI-supercharged vector library for Lua.

## Usage

```lua
require"quickmaths"

-- Constructors
vec2 = Vector2()
vec3 = Vector3()
vec4 = Vector4()
mat2 = Matrix2()
mat3 = Matrix3()
mat4 = Matrix4()

-- Nested component arguments
vec3 = Vecor3(Vector2(1,2), 3)
print(vec3) --> (1,2,3)
mat3 = Matrix3({{1,2,3}, {4,5,6}, {7,8,9}})
print(mat3) -->
--|1,2,3|
--|4,5,6|
--|7,8,9|

-- Identity vectors/matrices
vec3 = Vector3()
print(vec3) --> (0,0,0)
mat3 = Matrix3()
print(mat3) -->
--|1,0,0|
--|0,1,0|
--|0,0,1|

-- Operator overloading
v1 = Vector3(1,2,3)
v2 = Vector3(1,1,1)
v3 = v1 + v2
print(v3) --> (2,3,4)

-- Synonymous indexes
print( vec4.x == vec4.r == vec4[1] ) --> true
print( vec4.y == vec4.g == vec4[2] ) --> true
print( vec4.z == vec4.b == vec4[3] ) --> true
print( vec4.w == vec4.a == vec4[4] ) --> true
print( mat3[2] == mat3.r1c2 == mat3:get(1,2) ) --> true

-- 0-1 colors from web color
color = Vector3.fromHex("#FF8000")
print(color) --> (1,0.5,0)
color = Vector4.fromHex("#FF8000", 0.5)
print(color) --> (1,0.5,0,0.5)

-- Transform/projection matrices
pos = Vector3()
rot = Vector3()
scale = Vector3(1,1,1)
transform = Matrix4.fromTransform(pos, rot, scale)
perspective = Matrix4.fromPerspective(90, 16/9, 0.1, 1000)
```

## Usage with LÖVE
```lua
-- Using web colors
color = Vector3.fromHex("#DE2A6E")
love.graphics.setColor(color:unpack())

-- Sending matrices to a shader
perspective = Matrix4.fromPerspective(90, 16/9, 0.1, 1000)
shader:send("projection", {projection:unpack()})
```