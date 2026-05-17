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

layout(std140, binding = 0) uniform CameraData
{
    mat4 u_ViewProjection;
};

// We need the model transform in the fragment shader to convert vectors to local space
uniform mat4 u_Transform;
uniform vec3 u_CameraPos;

// @UIProperty(Name = "Reticle Texture", Type = Texture)
uniform sampler2D u_ReticleTexture;

// @UIProperty(Name = "Emission Intensity", Type = Float, Min = 0.0, Max = 50.0, Step = 0.05)
uniform float u_Emission;

// @UIProperty(Name = "Reticle Scale", Type = Float, Min = 0.1, Max = 10.0)
uniform float u_ReticleScale;

// @UIProperty(Name = "Projection Depth", Type = Float, Min = -3.0, Max = 3.0)
uniform float u_Depth; 
uniform int u_EntityID;

void main()
{
    // 1. Calculate the view direction in World Space
    vec3 viewDirWorld = normalize(u_CameraPos - WorldPosition);
    
    // 2. Convert the World View Direction into the Quad's Local Space
    // This makes the math act as if the Quad is sitting flat at (0,0,0) looking up
    vec3 viewDirLocal = normalize(inverse(mat3(u_Transform)) * viewDirWorld);
    
    // 3. Calculate the UV shift based on the angle and depth
    // Use abs() on Z so the formula works regardless of which way the quad's normal faces.
    // Without abs(), if the camera is behind the quad (local Z < 0), the clamp to 0.001
    // causes a divide-by-near-zero that blows the UV offset way outside [0,1].
    vec2 parallaxOffset = (viewDirLocal.xy / max(abs(viewDirLocal.z), 0.001)) * u_Depth;
    
    // 4. Scale UVs around the center to control reticle size, then apply parallax offset
    vec2 scaledUV = (TextureCoord - 0.5) * u_ReticleScale + 0.5;
    vec2 finalUV = scaledUV + parallaxOffset;
    
    // 5. Bounds Checking (The Masking Magic)
    vec4 reticleColor = vec4(0.0);
    
    // If the shifted UV is within the 0.0 to 1.0 bounds, sample the reticle!
    if(finalUV.x >= 0.0 && finalUV.x <= 1.0 && finalUV.y >= 0.0 && finalUV.y <= 1.0)
    {
        reticleColor = texture(u_ReticleTexture, finalUV) * u_Emission;
    }
    
    // 6. Final Compositing
    // We add the glowing reticle on top of the base glass tint
    OutColor = reticleColor;
    
    BrightColor = vec4(max(OutColor.rgb - vec3(1.0), vec3(0.0)), 1.0);
    EntityID = u_EntityID;
}