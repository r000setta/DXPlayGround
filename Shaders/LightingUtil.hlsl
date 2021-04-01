#define MaxLights 16

struct Light
{
    float3 Strength;
    float FalloffStart; // point/spot light only
    float3 Direction;   // directional/spot light only
    float FalloffEnd;   // point/spot light only
    float3 Position;    // point light only
    float SpotPower;    // spot light only
};

struct Material
{
    float4 DiffuseAlbedo;
    float3 FresnelR0;
    float Shininess;
};

#define PI 3.14159265359f

//float DistributionGGX(float3 N, float3 H, float roughness)
//{
//    float Alpha = roughness * roughness;
//    float Alpha2 = Alpha * Alpha;
//    float NdotH = saturate(dot(N, H));
//    float NdotH2 = NdotH * NdotH;

//    float Nom =  Alpha2;
//    float Denom = (NdotH2 * (Alpha2 - 1.0) + 1.0);
//    Denom = PI * Denom * Denom;
//    return Nom / max(Denom,0.001);
//}

//float GeometrySchlickGGX(float NDotV, float roughness)
//{
//    float R = (roughness + 1.0);
//    float K = (R * R) / 8.0;

//    float Nom = NDotV;
//    float Denom = NDotV * (1.0 - K) + K;

//    return Nom / Denom;
//}

//float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
//{
//    float NdotV = saturate(dot(N, V));
//    float NdotL = saturate(dot(N, L));
    
//    float ggx2= GeometrySchlickGGX(NdotV,roughness);
//    float ggx1= GeometrySchlickGGX(NdotL,roughness);

//    return ggx1 * ggx2;
//}

float CalcAttenuation(float d, float falloffStart, float falloffEnd)
{
    return saturate((falloffEnd-d) / (falloffEnd - falloffStart));
}

float3 SchlickFresnel(float3 R0, float3 normal, float3 lightVec)
{
    float cosIncidentAngle = saturate(dot(normal, lightVec));

    float f0 = 1.0f - cosIncidentAngle;
    float3 reflectPercent = R0 + (1.0f - R0)*(f0*f0*f0*f0*f0);

    return reflectPercent;
}

float3 FresnelSchlick(float HdotV, float3 F0)
{
    return F0 + (float3(1.0f, 1.0f, 1.0f) - F0) * pow(1.0f - HdotV, 5.0f);
}

float3 BlinnPhong(float3 lightStrength, float3 lightVec, float3 normal, float3 toEye, Material mat)
{
    const float m = mat.Shininess * 256.0f;
    float3 halfVec = normalize(toEye + lightVec);

    float roughnessFactor = (m + 8.0f)*pow(max(dot(halfVec, normal), 0.0f), m) / 8.0f;
    float3 fresnelFactor = SchlickFresnel(mat.FresnelR0, halfVec, lightVec);

    float3 specAlbedo = fresnelFactor*roughnessFactor;

    specAlbedo = specAlbedo / (specAlbedo + 1.0f);

    return (mat.DiffuseAlbedo.rgb + specAlbedo) * lightStrength;
}

float DistributionGGX(float3 N, float3 H, float Alpha)
{
    float Alpha2 = Alpha * Alpha;
    float NoH = saturate(dot(N, H));
    float K = NoH * NoH * (Alpha2 - 1.0f) + 1.0f;
    return Alpha2 / (PI * K * K);
}

float GeometrySchlickGGX(float X, float K)
{
    return X / (X * (1.0f - K) + K);
}

float GeometrySmith(float3 N, float3 V, float3 L, float K)
{
    float NoV = saturate(dot(N, V));
    float NoL = saturate(dot(N, L));
    return GeometrySchlickGGX(NoV, K) * GeometrySchlickGGX(NoL, K);
}

float3 ComputeDirectionalLight(Light light, Material mat, float3 N, float3 V, float roughness, float metallic)
{
    float3 L = -light.Direction;
    L = normalize(L);
    float3 H = normalize(L + V);

    float Alpha = roughness * roughness;
    float K = Alpha + 1.0f;
    K = (K * K) / 8.0f;
    float3 F0 = mat.FresnelR0;

    float3 Lo = float3(0.0f,0.0f,0.0f);

    float Distance = length(light.Direction);
    float Attenuation = 1.0 / Distance * Distance;
    float3 Radiance = float3(1.0f,1.0f,1.0f) * Attenuation;

    float NDF = DistributionGGX(N, H, Alpha);
    float G = GeometrySmith(N, V, L, K);
    float3 F = FresnelSchlick(saturate(dot(H, V)), F0);
    float3 Numerator = NDF * G * F;
    float Denominator = 4.0f * saturate(dot(N, V)) * saturate(dot(N, L));
    
    float3 Specular = Numerator / max(Denominator, 0.001f);
    
    float3 KS = F;
    float3 KD = float3(1.0f, 1.0f, 1.0f) - KS;

    KD *= 1.0f - metallic;

    //return float4(KD,1.0f);

    float NdotL = saturate(dot(L, N));

    Lo += (KD * mat.DiffuseAlbedo.rgb / PI + Specular) * Radiance * NdotL;

    return Lo;
    //float3 lightStrength = light.Strength * NdotL;

    //return BlinnPhong(lightStrength, L, N, V, mat);
}

float3 ComputePointLight(Light L, Material mat, float3 pos, float3 normal, float3 toEye)
{
    // The vector from the surface to the light.
    float3 lightVec = L.Position - pos;

    // The distance from surface to light.
    float d = length(lightVec);

    // Range test.
    if(d > L.FalloffEnd)
        return 0.0f;

    // Normalize the light vector.
    lightVec /= d;

    // Scale light down by Lambert's cosine law.
    float ndotl = max(dot(lightVec, normal), 0.0f);
    float3 lightStrength = L.Strength * ndotl;

    // Attenuate light by distance.
    float att = CalcAttenuation(d, L.FalloffStart, L.FalloffEnd);
    lightStrength *= att;

    return BlinnPhong(lightStrength, lightVec, normal, toEye, mat);
}

float3 ComputeSpotLight(Light L, Material mat, float3 pos, float3 normal, float3 toEye)
{
    float3 lightVec = L.Position - pos;

    float d = length(lightVec);

    // Range test.
    if(d > L.FalloffEnd)
        return 0.0f;

    // Normalize the light vector.
    lightVec /= d;

    // Scale light down by Lambert's cosine law.
    float ndotl = max(dot(lightVec, normal), 0.0f);
    float3 lightStrength = L.Strength * ndotl;

    // Attenuate light by distance.
    float att = CalcAttenuation(d, L.FalloffStart, L.FalloffEnd);
    lightStrength *= att;

    // Scale by spotlight
    float spotFactor = pow(max(dot(-lightVec, L.Direction), 0.0f), L.SpotPower);
    lightStrength *= spotFactor;

    return BlinnPhong(lightStrength, lightVec, normal, toEye, mat);
}

float4 ComputeLighting(Light gLights[MaxLights], Material mat,
                       float3 pos, float3 normal, float3 toEye,
                       float3 shadowFactor, float roughness, float metallic)
{
    float3 Lo = float3(0.0f,0.0f,0.0f);

    int i = 0;

#if (NUM_DIR_LIGHTS > 0)
    for(i = 0; i < NUM_DIR_LIGHTS; ++i)
    {
        //Lo += shadowFactor[i] * ComputeDirectionalLight(gLights[i], mat, normal, toEye, roughness, metallic);
        Lo += ComputeDirectionalLight(gLights[i], mat, normal, toEye, roughness, metallic);
    }
#endif

#if (NUM_POINT_LIGHTS > 0)
    for(i = NUM_DIR_LIGHTS; i < NUM_DIR_LIGHTS+NUM_POINT_LIGHTS; ++i)
    {
        Lo += ComputePointLight(gLights[i], mat, pos, normal, toEye);
    }
#endif

#if (NUM_SPOT_LIGHTS > 0)
    for(i = NUM_DIR_LIGHTS + NUM_POINT_LIGHTS; i < NUM_DIR_LIGHTS + NUM_POINT_LIGHTS + NUM_SPOT_LIGHTS; ++i)
    {
        Lo += ComputeSpotLight(gLights[i], mat, pos, normal, toEye);
    }
#endif 

    return float4(Lo, 1.0f);
}


