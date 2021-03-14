#define GPI 3.14159265359f

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

float3 FresnelSchlick(float HoV, float3 F0)
{
    return F0 + (float3(1.0f, 1.0f, 1.0f) - F0) * pow(1.0f - HoV, 5.0f);
}