#shader vertex
#version 450 core

layout(location = 0) in vec3 v_Position;
layout(location = 1) in vec3 v_Normal;
layout(location = 2) in vec2 v_TextureCoord;

layout(std140, binding = 0) uniform CameraData
{
    mat4 u_ViewProjection;
};

uniform mat4 u_Transform;

out vec2 TextureCoord;
out vec3 WorldNormal;
out vec3 WorldPosition;

void main()
{
    TextureCoord = v_TextureCoord;
    WorldNormal = mat3(u_Transform) * v_Normal;
    vec4 worldPos = u_Transform * vec4(v_Position, 1.0);
    WorldPosition = worldPos.xyz;
    gl_Position = u_ViewProjection * worldPos;
}

#shader fragment
#version 450 core

layout(location = 0) out vec4 OutColor;
layout(location = 1) out vec4 BrightColor;
layout(location = 2) out int EntityID;

in vec2 TextureCoord;
in vec3 WorldNormal;
in vec3 WorldPosition;

// @UIProperty(Name = "Reticle Texture", Type = Texture)
uniform sampler2D u_ReticleTexture;

// @UIProperty(Name = "Emission Intensity", Type = Float, Min = 0.0, Max = 50.0, Step = 0.05)
uniform float u_Emission;

uniform int u_EntityID;

void main()
{
	OutColor = texture(u_ReticleTexture, TextureCoord) * u_Emission;
    BrightColor = vec4(max(OutColor.rgb - vec3(1.0), vec3(0.0)), 1.0);
    EntityID = u_EntityID;
}
