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
    TextureCoord = vec2(v_TextureCoord.x, 1.0 - v_TextureCoord.y);
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

// @UIProperty(Name = "Color", Type = Color3)
uniform vec3 u_Color;
// @UIProperty(Name = "Tail Fade", Type = Float, Min = 0.0, Max = 10.0)
uniform float u_TailFade;
// @UIProperty(Name = "Emission Intensity", Type = Float, Min = 0.0, Max = 50.0, Step = 0.05)
uniform float u_Emission;

uniform int u_EntityID;

void main()
{
    // Calculate the Gradient
    // We take the Y coordinate (0.0 at the back, 1.0 at the front)
    // pow() makes it an exponential curve instead of a linear line, 
    // giving us a bright, sharp tip and a long, faint tail.
    float alpha = pow(TextureCoord.y, u_TailFade);
    
    // 2. Optional: Soften the edges
    // If you want the sides of the quad to fade out so they aren't sharp lines,
    // you can multiply the alpha by a sine wave on the X axis.
    float edgeSoften = sin(TextureCoord.x * 3.14159);
    alpha *= edgeSoften;

    // 3. Final Output
    // Multiply the base color by the emission strength to trigger your Bloom pass
    vec3 finalColor = u_Color * u_Emission;
    
    OutColor = vec4(finalColor, alpha);
    
    // Write to the HDR Brightness buffer so your Bloom post-processing catches it
    BrightColor = vec4(max(OutColor.rgb - vec3(1.0), vec3(0.0)), 1.0);
    
    EntityID = u_EntityID;
}
