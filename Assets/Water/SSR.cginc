#ifndef WATER_SSR
#define WATER_SSR

    #include "UnityCG.cginc"

    void SSRRayConvert(float3 worldPos, out float4 clipPos, out float3 screenPos, out float2 grabPos)
    {
        clipPos = UnityWorldToClipPos(worldPos);
        float k = ((1.0) / (clipPos.w));

        screenPos.xy = ComputeScreenPos(clipPos).xy * k;
        screenPos.z = k;

        grabPos = ComputeGrabScreenPos(clipPos).xy * k;
    }

    float3 SSRRayMarch(float4 pos, float3 worldPos, half3 R)
    {
        float4 farClipPos;
        float3 farScreenPos;
        float2 farGrabPos;

        SSRRayConvert(worldPos + R * 10000, farClipPos, farScreenPos, farGrabPos);
        half value = step(farScreenPos.y, 1);
        return  float3(farGrabPos, 1) * value;
    }

    float3 GetSSRUVZ(float4 pos, float3 worldPos, half3 R, half NoV1)
    {
        half ssrWeight = 1;

        half NoV = NoV1 * 2;
        ssrWeight *= (1 - NoV * NoV);

        float3 uvz = SSRRayMarch(pos, worldPos, R);
        uvz.z *= ssrWeight;
        uvz.z = 1 - step(uvz.z, 0.1);
        return uvz;
    }

#endif

