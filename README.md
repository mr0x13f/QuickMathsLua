
# QuickMaths

An FFI-supercharged vector library for Lua.
Made with LÖVE in mind, but should work perfectly fine on other frameworks running a similar-enough version of Lua.

## Post mortem

I don't use Lua anymore for game development because of how much of a pain OOP is, so this whole thing will probably never be updated. This post mortem will serve as some reflection on how this library could have been improved.

The reason this was made was because I wasn't happy with existing vector libraries for lua (CPML to be precise). The goals I had with this library was speed and ease of use. The ease of use was achieved by treating vector objects as throwaway primitives or stack-allocted objects, instead of reusing them. This sacrifices performance but is, in my opinion, much nicer to work with. To make this even slightly feasible memory-wise with how Lua objects work, JIT's C FFI was used to make the vectors C objects.

I'm happy with the ease of use aspect, but the performance was held back by the use of assert(), which I used to enforce some level of strict typing. This might help with debugging, but it sacrifices performance. If I were to remake this, I would leave out the assertions, as performance is very important with vectors. Some of the matrix math might also be wrong, since I'm not good with matrices. I should have written unit tests to make sure the math was right. The library also assumes the use of euler angles for rotation. This is fine for simple 3D stuff, but it would become a problem when implementing a proper physics engine.

Possible improvements:
- Remove assert()
- Add quaternions
- Unit tests
- Documentation

As of writing I'm trying out 3D game development in C#. I'm in a similar position as before, where the vector library I'm using is giving me a lot of problems. I'll probably have to make my own vector library again, which would be a good opportunity to use what I learned from this project and to put the improvements listed above into practice.

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
vec3 = Vector3(Vector2(1,2), 3)
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
shader:send("projection", projection:send())
```
