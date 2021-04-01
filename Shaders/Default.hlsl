#ifndef NUM_DIR_LIGHTS
    #define NUM_DIR_LIGHTS 3
#endif

#ifndef NUM_POINT_LIGHTS
    #define NUM_POINT_LIGHTS 0
#endif

#ifndef NUM_SPOT_LIGHTS
    #define NUM_SPOT_LIGHTS 0
#endif

#include "Common.hlsl"

struct VertexIn
{
	float3 PosL    : POSITION;
    float3 NormalL : NORMAL;
	float2 TexC    : TEXCOORD;
	float3 TangentU : TANGENT;
};

struct VertexOut
{
	float4 PosH    : SV_POSITION;
    float4 ShadowPosH : POSITION0;
    float4 SsaoPosH   : POSITION1;
    float3 PosW  : POSITION2;
    //float4 TtoW0 : POSITION3;
    //float4 TtoW1 : POSITION4;
    //float4 TtoW2 : POSITION5;
    float3 NormalW : NORMAL;
	float3 TangentW : TANGENT;
	float2 TexC    : TEXCOORD;
};

VertexOut VS(VertexIn vin)
{
	VertexOut vout = (VertexOut)0.0f;

	MaterialData matData = gMaterialData[gMaterialIndex];
	
    float4 posW = mul(float4(vin.PosL, 1.0f), gWorld);
    vout.PosW = posW.xyz;

    vout.NormalW = mul(vin.NormalL, (float3x3)gWorld);
	
	vout.TangentW = mul(vin.TangentU, (float3x3)gWorld);

    vout.PosH = mul(posW, gViewProj);

    vout.SsaoPosH = mul(posW, gViewProjTex);
	
	float4 texC = mul(float4(vin.TexC, 0.0f, 1.0f), gTexTransform);
	vout.TexC = mul(texC, matData.MatTransform).xy;

    vout.ShadowPosH = mul(posW, gShadowTransform);
	
    return vout;
}

float4 PS(VertexOut pin) : SV_Target
{
	MaterialData matData = gMaterialData[gMaterialIndex];
	float4 diffuseAlbedo = matData.DiffuseAlbedo;
    float  smoothness = matData.Smoothness;
	float3 fresnelR0 = matData.FresnelR0;
	float  roughness = matData.Roughness;
	uint diffuseMapIndex = matData.DiffuseMapIndex;
	uint normalMapIndex = matData.NormalMapIndex;
    uint metallicMapIndex = matData.MetallicMapIndex;
	
    diffuseAlbedo *= gTextureMaps[diffuseMapIndex].Sample(gsamAnisotropicWrap, pin.TexC);

#ifdef ALPHA_TEST
    clip(diffuseAlbedo.a - 0.1f);
#endif

    pin.NormalW = normalize(pin.NormalW);

    //return diffuseAlbedo;
    //return float4(roughness,0.0,0.0,1.0);
	
    float4 normalMapSample = gTextureMaps[normalMapIndex].Sample(gsamAnisotropicWrap, pin.TexC);
	float3 bumpedNormalW = NormalSampleToWorldSpace(normalMapSample.rgb, pin.NormalW, pin.TangentW);

    //return float4(bumpedNormalW,1.0f);

    float metallic = gTextureMaps[metallicMapIndex].Sample(gsamAnisotropicWrap,pin.TexC).r;

    //return float4(metallic,0.0,0.0,1.0);
    
    float3 toEyeW = gEyePosW - pin.PosW;

    float distToEye = length(toEyeW);
    toEyeW /= distToEye;

    pin.SsaoPosH /= pin.SsaoPosH.w;
    float ambientAccess = gSsaoMap.Sample(gsamLinearClamp, pin.SsaoPosH.xy, 0.0f).r;

    float4 ambient = ambientAccess*gAmbientLight*diffuseAlbedo;

    float3 shadowFactor = float3(1.0f, 1.0f, 1.0f);
    shadowFactor[0] = CalcShadowFactor(pin.ShadowPosH);

    const float shininess = (1.0f - roughness) * normalMapSample.a;
    Material mat = { diffuseAlbedo, fresnelR0, shininess };
    float4 Lo = ComputeLighting(gLights, mat, pin.PosW,
        bumpedNormalW, toEyeW, shadowFactor, roughness, metallic);


    float3 litColor = ambient.rgb + Lo.rgb;
    //float3 litColor = Lo.rgb;

    float Gamma = 1.0f / 2.2f;

    //float3 r = reflect(-toEyeW, bumpedNormalW);
    //float4 reflectionColor = gCubeMap.Sample(gsamLinearWrap, r);
    //float3 fresnelFactor = SchlickFresnel(fresnelR0, bumpedNormalW, r);
    //litColor.rgb += fresnelFactor * reflectionColor.rgb;

#ifdef FOG
    float3 fogColor = float3(0.0,1.0,0.0);
    float b = 0.02;
    float fogAmount = saturate(1.0 - exp(-distToEye * b));
    float2 uv = float2(pin.TexC.x+sin(gTotalTime),pin.TexC.y+sin(gTotalTime));
    float noise = saturate(gTextureMaps[diffuseMapIndex].Sample(gsamAnisotropicWrap,uv).r);
    fogAmount *= noise;
    litColor = lerp(litColor, fogColor, fogAmount);
#endif

    litColor = litColor / (litColor +float3(1.0f,1.0f,1.0f));
    litColor = pow(litColor,float3(Gamma,Gamma,Gamma));

    return float4(litColor,1.0);
}


