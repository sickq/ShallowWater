#ifndef ATMOSPHERE
#define ATMOSPHERE

#include "UnityCG.cginc"

#define kDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)
#define HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_Float_Formats
#define HALF_MIN_SQRT 0.0078125  // 2^-7 == sqrt(HALF_MIN), useful for ensuring HALF_MIN after x^2

float4 g_AtmosphereLightDirection;
float4 g_CameraAerialPerspectiveVolumeParam;
UNITY_DECLARE_TEX3D(AtmosphereCameraScatteringVolume);
sampler2D _SkyViewLutTextureL;


UNITY_DECLARE_TEX2D(_SkyCloudLowRes);
float4 _SkyCloudViewportScale;
float4 _blendCloudFogParam;

float4 CalculateAtmosphere(float3 camera2World)
{
    float3 normalizeViewDir = normalize(camera2World);
    float xz = sqrt(1 - normalizeViewDir.y * normalizeViewDir.y);

    float tempValue = sqrt(dot(camera2World.xz, camera2World.xz));
                
    float atmosTempValue = dot(float2(-normalizeViewDir.x, normalizeViewDir.z), g_AtmosphereLightDirection.xy);
    atmosTempValue = clamp(atmosTempValue / xz, -1, 1);

    atmosTempValue = acos(atmosTempValue);
    atmosTempValue = atmosTempValue / UNITY_PI;
    atmosTempValue = sqrt(atmosTempValue);

    float atmosUVTemp = saturate((camera2World.y + g_CameraAerialPerspectiveVolumeParam.x) * g_CameraAerialPerspectiveVolumeParam.z);
    float atmosUVTemp1 = saturate(tempValue * g_CameraAerialPerspectiveVolumeParam.y);

    float3 atmosUV = 0;
    atmosUV.yz = sqrt(float2(atmosUVTemp, atmosUVTemp1));
    atmosUV.x = atmosTempValue;
    
    float4 atmosphereColor = UNITY_SAMPLE_TEX3D_LOD(AtmosphereCameraScatteringVolume, atmosUV, 0);
    return atmosphereColor;
}

float2 CalculateAtmosphereVertex(float posY, float atmosUVX, float atmosUVZ)
{
    float atmosUVTemp = saturate((posY + g_CameraAerialPerspectiveVolumeParam.x) * g_CameraAerialPerspectiveVolumeParam.z);
    float atmosUVTemp1 = saturate(atmosUVZ * g_CameraAerialPerspectiveVolumeParam.y);
                
    float3 atmosUV = 0;
    atmosUV.yz = sqrt(float2(atmosUVTemp, atmosUVTemp1));
    atmosUV.x = atmosUVX;
    
    float4 atmosphereColor = UNITY_SAMPLE_TEX3D_LOD(AtmosphereCameraScatteringVolume, atmosUV, 0);
    return atmosphereColor;
}

float2 PrepareAtmosphereVertex(float3 camera2World)
{
    float2 resultValue = 0;
    float3 normalizeViewDir = normalize(camera2World.xyz);
    
    float xz = sqrt(1 - normalizeViewDir.y * normalizeViewDir.y);
    
    resultValue.x = sqrt(dot(camera2World.xz, camera2World.xz));
    
    float atmosTempValue = dot(float2(-normalizeViewDir.x, normalizeViewDir.z), g_AtmosphereLightDirection.xy);
    atmosTempValue = clamp(atmosTempValue / xz, -1, 1);
    
    atmosTempValue = acos(atmosTempValue);
    atmosTempValue = atmosTempValue / UNITY_PI;
    atmosTempValue = sqrt(atmosTempValue);
    resultValue.y = atmosTempValue;
    return resultValue;
}

// max absolute error 1.3x10^-3
// Eberly's odd polynomial degree 5 - respect bounds
// 4 VGPR, 14 FR (10 FR, 1 QR), 2 scalar
// input [0, infinity] and output [0, PI/2]
float FastATanPos(float x)
{
    float t0 = (x < 1.0) ? x : 1.0 / x;
    float t1 = t0 * t0;
    float poly = 0.0872929;
    poly = -0.301895 + poly * t1;
    poly = 1.0 + poly * t1;
    poly = poly * t0;
    return (x < 1.0) ? poly : UNITY_HALF_PI - poly;
}

// 4 VGPR, 16 FR (12 FR, 1 QR), 2 scalar
// input [-infinity, infinity] and output [-PI/2, PI/2]
float FastATan(float x)
{
    float t0 = FastATanPos(abs(x));
    return (x < 0.0) ? -t0 : t0;
}

float FastAtan2(float y, float x)
{
    return FastATan(y / x) + (y >= 0.0 ? UNITY_PI : -UNITY_PI) * (x < 0.0);
}

float4 CalculateSky(float3 uniformVertPos)
{
    float reverseY = (1 - uniformVertPos.y) * 0.5f;
            
    float xz = 1 - uniformVertPos.y * uniformVertPos.y;
    xz = sqrt(xz);

    float tempValue = dot(float2(-uniformVertPos.x, uniformVertPos.z), g_AtmosphereLightDirection.xy);
    tempValue = clamp(tempValue / xz, -1, 1);

    tempValue = acos(tempValue);
    tempValue = tempValue / UNITY_PI;
    tempValue = sqrt(tempValue);

    float2 tempUV = float2(tempValue, reverseY);
    tempUV = (tempUV + float2(0.00520833349, 0.00480769249)) * float2(0.989690721, 0.990476191);

    float maxXZ = max(abs(uniformVertPos.z), abs(uniformVertPos.x));
    float minXZ = min(abs(uniformVertPos.z), abs(uniformVertPos.x));

    float atan = FastAtan2(uniformVertPos.x, uniformVertPos.z);

    float4 col = tex2D(_SkyViewLutTextureL, tempUV);
    return col;
}

float4 AppendSkyCloud(float4 baseColor, float3 viewDir, float2 screenPos)
{
    float scaleY = viewDir.y * 250.0;
    scaleY = scaleY * scaleY + 2525.0;
    scaleY = sqrt(scaleY);
    float blendParam = max(-viewDir.y * 250.0 - scaleY, -viewDir.y * 250.0 + scaleY);
    float2 screenUV = min(screenPos * _SkyCloudViewportScale.xy, _SkyCloudViewportScale.zw);
    float4 skyCloud = UNITY_SAMPLE_TEX2D_LOD(_SkyCloudLowRes, screenUV, 0);

    blendParam = max(blendParam - _blendCloudFogParam.x, 0);
    blendParam = -blendParam * _blendCloudFogParam.y;
    blendParam = exp(blendParam);
    

    //srcAlpha OneMinusSrcAlpha
    baseColor.rgb = baseColor.rgb * (1 - blendParam * skyCloud.a) + blendParam * skyCloud.rgb;
    
    float alpha = blendParam * skyCloud.a - skyCloud.a;
    alpha = alpha + 1;
    alpha = lerp(skyCloud.a, alpha, _blendCloudFogParam.z);

    baseColor.a = alpha;
    return baseColor;
}

#endif
