//Unsharp Masking created by Taeho(Sam) Lee

#include "ReShade.fxh"

// Uniforms to control the unsharp mask
uniform float Radius <
    ui_type = "drag";
    ui_label = "Blur Radius";
    ui_min = 1.0; ui_max = 10.0;
> = 2.0;

uniform float Amount <
    ui_type = "drag";
    ui_label = "Sharpening Amount";
    ui_min = 0.0; ui_max = 2.0;
> = 1.0;

// Input texture
texture TexColor : COLOR;
sampler sTexColor { Texture = TexColor; SRGBTexture = true; };

// Gaussian blur kernel
float3 Blur(float2 texcoord, float radius)
{
    float2 pixel = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
    float3 color = 0.0;
    float weightSum = 0.0;

    [unroll]
    for (int x = -2; x <= 2; x++)
    {
        [unroll]
        for (int y = -2; y <= 2; y++)
        {
            float weight = exp(-0.5 * (x * x + y * y) / (radius * radius));
            color += tex2D(sTexColor, texcoord + float2(x, y) * pixel).rgb * weight;
            weightSum += weight;
        }
    }

    return color / weightSum;
}

// Unsharp mask pass
float3 UnsharpMaskPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    // Original image color
    float3 original = tex2D(sTexColor, texcoord).rgb;

    // Blurred image
    float3 blurred = Blur(texcoord, Radius);

    // Apply unsharp mask: sharpened = original + amount * (original - blurred)
    float3 sharpened = original + Amount * (original - blurred);

    // Clamp the result to maintain valid color range
    return saturate(sharpened);
}

technique UnsharpMask
<
    ui_label = "Unsharp Mask";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = UnsharpMaskPass;
        SRGBWriteEnable = true;
    }
}