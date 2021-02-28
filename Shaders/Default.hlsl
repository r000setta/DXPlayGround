//***************************************************************************************
// Default.hlsl by Frank Luna (C) 2015 All Rights Reserved.
//***************************************************************************************

// Defaults for number of lights.
#ifndef NUM_DIR_LIGHTS
    #define NUM_DIR_LIGHTS 3
#endif

#ifndef NUM_POINT_LIGHTS
    #define NUM_POINT_LIGHTS 0
#endif

#ifndef NUM_SPOT_LIGHTS
    #define NUM_SPOT_LIGHTS 0
#endif

// Include common HLSL code.
#include "Common.hlsl"



struct VertexIn
{
	float3 PosL    : POSITION;
    float3 NormalL : NORMAL;
	float2 TexC    : TEXCOORD;
};

struct VertexOut
{
	float4 PosH    : SV_POSITION;
    float3 PosW    : POSITION;
    float3 NormalW : NORMAL;
	float2 TexC    : TEXCOORD;
};

VertexOut VS(VertexIn vin)
{
	VertexOut vout = (VertexOut)0.0f;

	// Fetch the material data.
	MaterialData matData = gMaterialData[gMaterialIndex];
	
    // Transform to world space.
    float4 posW = mul(float4(vin.PosL, 1.0f), gWorld);
    vout.PosW = posW.xyz;

    // Assumes nonuniform scaling; otherwise, need to use inverse-transpose of world matrix.
    vout.NormalW = mul(vin.NormalL, (float3x3)gWorld);

    // Transform to homogeneous clip space.
    vout.PosH = mul(posW, gViewProj);
	
	// Output vertex attributes for interpolation across triangle.
	float4 texC = mul(float4(vin.TexC, 0.0f, 1.0f), gTexTransform);
	vout.TexC = mul(texC, matData.MatTransform).xy;
	
    return vout;
}

float3 BoxCubeMapLookup(float3 rayOrigin,float3 rayDir,float3 boxCenter,float3 boxExtents)
{
	float3 p=rayOrigin-boxCenter;
	float3 t1=(-p+boxExtents)/rayDir;
	float3 t2=(-p-boxExtents)/rayDir;
	float3 tmax=max(t1,t2);
	float t=min(min(tmax.x,tmax.y),tmax.z);
	return p+t*rayDir;
}

float4 PS(VertexOut pin) : SV_Target
{
	//float3 irradiance = float3(0.0f, 0.0f, 0.0f);

 //   float3 normal = normalize(pin.NormalW);
 //   float3 up = float3(0.0, 1.0, 0.0);
 //   float3 right = cross(up, normal);
 //   up = cross(normal, right);

 //   float sampleDelta = 0.025f;
 //   float numSamples = 0.0f;
 //   for (float phi = 0.0f; phi < 2.0f * PI; phi += sampleDelta)
 //   {
 //       for (float theta = 0.0; theta < 0.5 * PI; theta += sampleDelta)
 //       {
 //           // spherical to cartesian (in tangent space)
 //           float3 tangentSample = float3(sin(theta) * cos(phi),  sin(theta) * sin(phi), cos(theta));
 //           // tangent space to world
 //           float3 sampleVec = tangentSample.x * right + tangentSample.y * up + tangentSample.z * normal;

 //           irradiance += gCubeMap.Sample(gsamLinearWrap, sampleVec).rgb * cos(theta) * sin(theta);
 //           numSamples++;
 //       }
 //   }
 //   irradiance = PI * irradiance * (1.0f / numSamples);

 //   return float4(irradiance, 1.0f);
   
    //float roughness = 0.1f;      
    //const uint NumSamples = 1024u;
    //float3 N = normalize(pin.NormalW);
    //float3 R = N;
    //float3 V = R;

    //float3 prefilteredColor = float3(0.1f, 0.1f, 0.1f);
    //float totalWeight = 0.1f;
    //for (uint i = 0u; i < NumSamples; ++i)
    //{
    //    float2 Xi = Hammersley(i, NumSamples);
    //    float3 H = ImportanceSampleGGX(Xi, N, roughness);
    //    float3 L = normalize(2.0f * dot(V, H) * H - V);
    //    float NdotL = max(dot(N, L), 0.0f);
    //    if (NdotL > 0.f)
    //    {
    //        prefilteredColor += gCubeMap.Sample(gsamLinearWrap, L).rgb * NdotL;
    //        totalWeight += NdotL;
    //    }
    //}

    //prefilteredColor = prefilteredColor / totalWeight;

    //return float4(prefilteredColor, 1.0f);

	// Fetch the material data.
	MaterialData matData = gMaterialData[gMaterialIndex];
	float4 diffuseAlbedo = matData.DiffuseAlbedo;
	float3 fresnelR0 = matData.FresnelR0;
	float  roughness = matData.Roughness;
	uint diffuseTexIndex = matData.DiffuseMapIndex;

	// Dynamically look up the texture in the array.
	diffuseAlbedo *= gDiffuseMap[diffuseTexIndex].Sample(gsamAnisotropicWrap, pin.TexC);
	
    // Interpolating normal can unnormalize it, so renormalize it.
    pin.NormalW = normalize(pin.NormalW);

    // Vector from point being lit to eye. 
    float3 toEyeW = normalize(gEyePosW - pin.PosW);

    // Light terms.
    float4 ambient = gAmbientLight*diffuseAlbedo;

	const float shininess = 1.0f - roughness;
    Material mat = { diffuseAlbedo, fresnelR0, shininess };
    float3 shadowFactor = 1.0f;
    float4 directLight = ComputeLighting(gLights, mat, pin.PosW,
        pin.NormalW, toEyeW, shadowFactor);

    float4 litColor = ambient + directLight;

	// Add in specular reflections.
	float3 center=float3(0.0,0.0,0.0);
	float3 extents=float3(2500,2500,2500);
	float3 r = reflect(-toEyeW, pin.NormalW);
	//r=BoxCubeMapLookup(pin.PosW,r,center,extents);
	float4 reflectionColor = gCubeMap.Sample(gsamLinearWrap, r);
	float3 fresnelFactor = SchlickFresnel(fresnelR0, pin.NormalW, r);
	litColor.rgb += shininess * fresnelFactor * reflectionColor.rgb;

    // Common convention to take alpha from diffuse albedo.
    litColor.a = diffuseAlbedo.a;

    return litColor;
}


