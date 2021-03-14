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

float DistributionGGX(float3 N, float3 H, float roughness)
{
    float Alpha = roughness * roughness;
    float Alpha2 = Alpha * Alpha;
    float NdotH = saturate(dot(N, H));
    float NdotH2 = NdotH * NdotH;

    float Nom =  Alpha2;
    float Denom = (NdotH2 * (Alpha2 - 1.0) + 1.0);
    Denom = PI * Denom * Denom;
    return Nom / max(Denom,0.001);
}

float GeometrySchlickGGX(float NDotV, float roughness)
{
    float R = (roughness + 1.0);
    float K = (R * R) / 8.0;

    float Nom = NDotV;
    float Denom = NDotV * (1.0 - K) + K;

    return Nom / Denom;
}

float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
{
    float NdotV = saturate(dot(N, V));
    float NdotL = saturate(dot(N, L));
    
    float ggx2= GeometrySchlickGGX(NdotV,roughness);
    float ggx1= GeometrySchlickGGX(NdotL,roughness);

    return ggx1 * ggx2;
}

float3 FresnelSchlick(float cosTheta, float3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

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

float3 ComputeDirectionalLight(Light L, Material mat, float3 normal, float3 toEye, float roughness)
{
    roughness = 0.8f;
    float3 lightVec = -L.Direction;
    float3 H = normalize(lightVec + toEye);

    float3 Lo = float3(0.0f,0.0f,0.0f);

    float Distance = length(lightVec);
    float Attenuation = CalcAttenuation(Distance,L.FalloffStart, L.FalloffEnd);
    float3 Radiance = float3(1.0f,1.0f,1.0f);

    float NDF = DistributionGGX(normal, H, roughness);
    float G = GeometrySmith(normal, toEye, lightVec, roughness);
    float3 F = mat.FresnelR0;
    float3 Numerator = NDF * G * F;
    float Denominator = 4.0f * saturate(dot(normal, toEye)) * saturate(dot(normal, lightVec));
    
    float3 Specular = Numerator / max(Denominator, 0.001f);
    
    float3 KS = F;
    float3 KD = float3(1.0f, 1.0f, 1.0f) - KS;

    KD *= 1.0f - 0.8f;

    float NoL = saturate(dot(lightVec, normal));

    Lo += (KD * mat.DiffuseAlbedo.rgb / PI + Specular) * Radiance * NoL;

    return Lo;
    //float3 lightStrength = L.Strength * ndotl;

    //return BlinnPhong(lightStrength, lightVec, normal, toEye, mat);
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
                       float3 shadowFactor, float roughness)
{
    float3 Lo = float3(0.0f,0.0f,0.0f);

    int i = 0;

#if (NUM_DIR_LIGHTS > 0)
    for(i = 0; i < NUM_DIR_LIGHTS; ++i)
    {
        Lo += shadowFactor[i] * ComputeDirectionalLight(gLights[i], mat, normal, toEye, roughness);
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

    return float4(Lo, 0.0f);
}


