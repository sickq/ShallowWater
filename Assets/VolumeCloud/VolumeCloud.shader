Shader "Hidden/VolumeCloud"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    HLSLINCLUDE
    #include "UnityCG.cginc"

    #define SKYBOX_THREASHOLD_VALUE 0.9999

    struct VaryingsDefault
    {
        float4 vertex : SV_POSITION;
        float2 texcoord : TEXCOORD0;
    };

    sampler2D _MainTex;
    float4 _MainTex_TexelSize;

    uniform sampler2D _CameraDepthTexture;

    VaryingsDefault VertDefaultQuad(appdata_img v)
    {
        VaryingsDefault o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.texcoord = v.texcoord.xy;

        #if UNITY_UV_STARTS_AT_TOP
        if (_MainTex_TexelSize.y < 0.0)
            o.texcoord.y = 1.0 - o.texcoord.y;
        #endif

        return o;
    }

    float4 GetWorldPositionFromDepthValue(float2 uv, float linearDepth)
    {
        float camPosZ = _ProjectionParams.y + (_ProjectionParams.z - _ProjectionParams.y) * linearDepth;

        // unity_CameraProjection._m11 = near / t，其中t是视锥体near平面的高度的一半。
        // 投影矩阵的推导见：http://www.songho.ca/opengl/gl_projectionmatrix.html。
        // 这里求的height和width是坐标点所在的视锥体截面（与摄像机方向垂直）的高和宽，并且
        // 假设相机投影区域的宽高比和屏幕一致。
        float height = 2 * camPosZ / unity_CameraProjection._m11;
        float width = _ScreenParams.x / _ScreenParams.y * height;

        float camPosX = width * uv.x - width / 2;
        float camPosY = height * uv.y - height / 2;
        float4 camPos = float4(camPosX, camPosY, camPosZ, 1.0);
        return mul(unity_CameraToWorld, camPos);
    }

    float3 GetRay(float3 worldPos)
    {
        return normalize((worldPos - _WorldSpaceCameraPos).xyz);
    }

    uniform float4 _LightDir;
    uniform float4 _LightColor;
    float4 _VolumeCloudParamsOffset;
    float4 _VolumeDistanceParams;

    float4 fragmentParamsVolumeBoundPivot;
    float4 fragmentParamsVolumeBoundSize;

    float4 fragmentParamsRayData;
    
    float4 fragmentParamsVolumeColorLerp;
    float4 fragmentParamsVolumeFinalColorBlend;
    float4 fragmentParamsVolumeFinalColor;
    float4 fragmentParamsVolumeFinalAlpha;
    float4 fragmentParamsVolumeLight;

    float4 fragmentParamsColorFar;
    float4 fragmentParamsColorNear;

    float4 fragmentParamsRay;
    float4 fragmentParamsNoise;

    float4 _VolumeCloudNoiseIterParams;

    float4 fragmentParamsDitherNoise;
    float4 fragmentParamsRenderResolution;

    sampler2D fragmentTextures0;
    sampler2D fragmentTextures2;

    sampler2D _VolumeNoiseTexture;
    sampler2D _VolumeDitherNoiseTexture;
    float4 _VolumeDitherNoiseTexture_TexelSize;


    static const int KernelSize = 5;
    static const float3 NoiseKernel[KernelSize] =
    {
        float3(0., -1., 0.0),
        float3(-0.9, -1.1, 0.),
        float3(0.8, -1.2, 0.95),
        float3(0., -1.3, -0.84),
        float3(0., 1.5, 0.),
    };

    static const int NoiseOffset[KernelSize] =
    {
        1,
        2,
        4,
        8,
        12,
    };

    #define MinDist 100000000.0


    float4 sampleFow(float3 targetPoint)
    {
        float2 worldUV = (targetPoint.xz - fragmentParamsVolumeBoundPivot.xz) / fragmentParamsVolumeBoundSize.xz;
        return tex2D(fragmentTextures0, worldUV);
    }

    float val2(float3 targetPoint)
    {
        float4 curFow = sampleFow(targetPoint);
        float fogHeight = curFow.w;
        float d2 = (fragmentParamsRayData.x + fogHeight - targetPoint.y) * fragmentParamsRayData.y;
        
        d2 *= fragmentParamsRayData.z;
        return d2;
    }

    float sampleNoise(float3 targetPoint)
    {
        float3 targetPointInt = floor(targetPoint);
        float3 targetPointDecimal = frac(targetPoint);
        targetPointDecimal = targetPointDecimal * targetPointDecimal * (3. - 2. * targetPointDecimal);

        float2 noiseUV = (targetPointInt.xz + float2(37., 239.) * targetPointInt.y) + targetPointDecimal.xz;
        float2 noiseRG = tex2D(_VolumeNoiseTexture, (noiseUV + 0.5) / 256.).yx;
        return lerp(noiseRG.x, noiseRG.y, targetPointDecimal.y);
    }

    float sampleNoiseOffset(float3 tempPoint, int offset, float noiseTime)
    {
        float3 targetPoint = tempPoint * NoiseOffset[offset] + NoiseKernel[offset] * noiseTime;
        return sampleNoise(targetPoint) * 2. - 1.;
    }
    
    float VolumeCloudNoise(float3 targetPoint, float4 fowData, float3 noiseScale, float time)
    {
        float fogHeight = fowData.w;
        float d2 = (0. + fogHeight - targetPoint.y) * fragmentParamsRayData.y;
        
        float noiseTime = time * fragmentParamsNoise.y;
        float tnoise = 0.;
        float3 scalePoint = targetPoint * noiseScale;
        if (int(_VolumeCloudNoiseIterParams.x) >= 1) tnoise += sampleNoiseOffset(scalePoint, 0, noiseTime);
        if (int(_VolumeCloudNoiseIterParams.x) >= 2) tnoise += sampleNoiseOffset(scalePoint, 1, noiseTime) * 1. / _VolumeCloudParamsOffset.x;
        if (int(_VolumeCloudNoiseIterParams.x) >= 3) tnoise += sampleNoiseOffset(scalePoint, 2, noiseTime) * 1. / _VolumeCloudParamsOffset.y;
        if (int(_VolumeCloudNoiseIterParams.x) >= 4) tnoise += sampleNoiseOffset(scalePoint, 3, noiseTime) * 1. / _VolumeCloudParamsOffset.z;
        if (int(_VolumeCloudNoiseIterParams.x) >= 5) tnoise += sampleNoiseOffset(scalePoint, 4, noiseTime) * 1. / _VolumeCloudParamsOffset.w;

        d2 += tnoise * fragmentParamsNoise.x;
        d2 *= fragmentParamsRayData.z;
        return d2;
    }

    float sampleTerrainY(float3 targetPoint)
    {
        return tex2D(fragmentTextures2, (targetPoint.xz - fragmentParamsVolumeBoundPivot.xz) / fragmentParamsVolumeBoundSize.xz).x;
    }

    float CalculateDistFactor(float dist)
    {
        float dfactor = smoothstep(0., 1., (dist - _VolumeDistanceParams.y - _VolumeDistanceParams.z) / (_VolumeDistanceParams.x - _VolumeDistanceParams.z));
        return dfactor * dfactor;
    }

    float3 calculateVolumeCloudColor(float3 targetPoint, float terrainY, float distBlend, float3 fowColor)
    {
        float sampleHeight = clamp((targetPoint.y - terrainY) / fragmentParamsVolumeColorLerp.x, 0., 1.);
        float3 col2 = fowColor.xyz;
        col2 = lerp(col2 * fragmentParamsColorNear, col2, clamp(sampleHeight, 0., 1.));
        col2 *= fragmentParamsColorNear.w;
        col2 = lerp(col2, fragmentParamsColorFar, distBlend);
        return col2;
    }

    float sampleLightNoise(float3 targetPoint, float3 lightStep, float3 noiseScale, float time)
    {
        targetPoint = targetPoint + lightStep;
        float4 curFow = sampleFow(targetPoint);
        float fogHeight = curFow.w;
        float d2 = (0. + fogHeight - targetPoint.y) * fragmentParamsRayData.y;
        float noiseTime = time * fragmentParamsNoise.y;
        float tnoise = 0.;
        float3 scalePoint = targetPoint * noiseScale;
        if (int(_VolumeCloudNoiseIterParams.y) >= 1) tnoise += sampleNoiseOffset(scalePoint, 0, noiseTime);
        if (int(_VolumeCloudNoiseIterParams.y) >= 2) tnoise += sampleNoiseOffset(scalePoint, 1, noiseTime) * 1. / _VolumeCloudParamsOffset.x;
        if (int(_VolumeCloudNoiseIterParams.y) >= 3) tnoise += sampleNoiseOffset(scalePoint, 2, noiseTime) * 1. / _VolumeCloudParamsOffset.y;
        if (int(_VolumeCloudNoiseIterParams.y) >= 4) tnoise += sampleNoiseOffset(scalePoint, 3, noiseTime) * 1. / _VolumeCloudParamsOffset.z;
        if (int(_VolumeCloudNoiseIterParams.y) >= 5) tnoise += sampleNoiseOffset(scalePoint, 4, noiseTime) * 1. / _VolumeCloudParamsOffset.w;
        
        d2 += tnoise * fragmentParamsNoise.x;
        d2 *= fragmentParamsRayData.z;
        return d2;
    }

    float4 calculateColorBlend(float3 targetPoint, float terrainY, float distBlend, float volumeShape, float3 fowColor, float time, float3 lightStep, float3 noiseScale)
    {
        float3 color = calculateVolumeCloudColor(targetPoint, terrainY, distBlend, fowColor);
        float dirLight = max(0., volumeShape - sampleLightNoise(targetPoint, lightStep, noiseScale, time));
        color += clamp(dirLight * _LightColor * fragmentParamsVolumeLight.x, 0., 1.);
        float a = clamp(volumeShape, 0., 1.);
        float4 colBlend = float4(color.xyz * a, a);
        return colBlend;
    }

    float3 GammaToLinearSimple(float3 sRGB)
    {
        return sRGB * sRGB;
    }

    float3 remap01(half3 x, half t1, half t2)
    {
        return (x - t1) / (t2 - t1);
    }

    half4 frag(VaryingsDefault input) : SV_Target
    {
        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, input.texcoord);
        float linearDepth = Linear01Depth(depth);
        //是否为天空盒
        if (linearDepth > SKYBOX_THREASHOLD_VALUE)
        {
            linearDepth = 1;
        }
        float4 worldPos = GetWorldPositionFromDepthValue(input.texcoord, linearDepth);

        float curTime = _Time.y;
        float3 noiseScale = fragmentParamsNoise.z;
        noiseScale.y *= fragmentParamsNoise.w;
        
        float4 volumePixelColor = float4(tex2D(_MainTex, input.texcoord).xyz, 0.);
        float3 camRay = GetRay(worldPos.xyz);

        float depthDist = min(_VolumeDistanceParams.x + _VolumeDistanceParams.y, length((worldPos - _WorldSpaceCameraPos.xyz)));
        
        float2 nuv = input.texcoord * fragmentParamsRenderResolution.xy / _VolumeDitherNoiseTexture_TexelSize.zw;
        float ditherNoise = tex2D(_VolumeDitherNoiseTexture, nuv).x;
        ditherNoise = frac(ditherNoise + float(int(fragmentParamsDitherNoise.z)) * 0.61803398875);
        
        float3 lightStep = -_LightDir.xyz * fragmentParamsRay.x;
        float minDist = MinDist;

        //RayMarching到接触体积云的位置
        float startD = -1.0;
        
        float d = ditherNoise * fragmentParamsRay.y;
        int numSteps = int(depthDist / fragmentParamsRay.y) + 1;
        UNITY_LOOP
        for (int i = 0; i < numSteps; i++)
        {
            float3 samplePt = _WorldSpaceCameraPos.xyz + camRay * d;
            float dens = val2(samplePt);
            if (dens > fragmentParamsRay.z)
            {
                startD = max(0., d - fragmentParamsRay.y);
                break;
            }
            d += fragmentParamsRay.y;
        }

        //已经接触到体积云，计算颜色
        if (startD >= 0.)
        {
            float4 colorAcc = 0.0;
            float alpha = 0.0;
            //云内部的步进距离
            float stepSizeInVolume = fragmentParamsRay.w;
            float curDist = startD;
            numSteps = int((depthDist - startD) / stepSizeInVolume) + 1;
            UNITY_LOOP
            for (int i2 = 0; i2 < numSteps; i2++)
            {
                float3 samplePt2 = _WorldSpaceCameraPos + camRay * curDist;
                float4 curFow = sampleFow(samplePt2);
                float d3 = VolumeCloudNoise(samplePt2, curFow, noiseScale, curTime);
                if (d3 > fragmentParamsRay.z)
                {
                    float terrainY = sampleTerrainY(samplePt2);
                    float distBlend = CalculateDistFactor(curDist);
                    float4 colBlend = calculateColorBlend(samplePt2, terrainY, distBlend, d3, curFow.xyz, curTime, lightStep, noiseScale);
                    alpha = 1.;
                    alpha *= clamp(abs(depthDist - curDist) / fragmentParamsVolumeFinalAlpha.x, 0., 1.);
                    alpha *= 1. - distBlend;
                    colorAcc += colBlend * (1. - colorAcc.w) * alpha * stepSizeInVolume;
                    minDist = min(minDist, curDist);
                }
                if (colorAcc.w > 0.99) break;
                curDist += stepSizeInVolume;
            }
            colorAcc.xyz /= (0.001 + colorAcc.w);
            colorAcc.xyz = remap01(colorAcc.xyz, fragmentParamsVolumeFinalColor.y, fragmentParamsVolumeFinalColor.z);
            colorAcc.xyz = pow(colorAcc.xyz, fragmentParamsVolumeFinalColor.x);
            colorAcc.xyz = GammaToLinearSimple(colorAcc.xyz);
            colorAcc.w = clamp(pow(colorAcc.w, fragmentParamsVolumeFinalColorBlend.x) * fragmentParamsVolumeFinalColorBlend.y, 0., 1.);
            volumePixelColor = colorAcc;
        }

        //TODO 需要注意这里，如果需要雾效的深度，需要处理一下
        float outputDist = minDist;

        return volumePixelColor;
    }

    #define VolumeBlurParam float4(0.46584, 0.26708, 1.32082, 0)
    
    half4 fragBlurX(VaryingsDefault input) : SV_Target
    {
        float4 uvOffset = _MainTex_TexelSize.xyxy * float4(1, 0, -1, 0);
        half4 color = tex2D(_MainTex, input.texcoord) * VolumeBlurParam.x;
        color += tex2D(_MainTex, input.texcoord + uvOffset.xy * VolumeBlurParam.z) * VolumeBlurParam.y;
        color += tex2D(_MainTex, input.texcoord + uvOffset.zw * VolumeBlurParam.z) * VolumeBlurParam.y;
        return color;
    }

    half4 fragBlurY(VaryingsDefault input) : SV_Target
    {
        float4 uvOffset = _MainTex_TexelSize.xyxy * float4(0, 1, 0, -1);
        half4 color = tex2D(_MainTex, input.texcoord) * VolumeBlurParam.x;
        color += tex2D(_MainTex, input.texcoord + uvOffset.xy * VolumeBlurParam.z) * VolumeBlurParam.y;
        color += tex2D(_MainTex, input.texcoord + uvOffset.zw * VolumeBlurParam.z) * VolumeBlurParam.y;
        return color;
    }

    sampler2D _VolumeCloudTempRT;
    half4 fragCombine(VaryingsDefault input) : SV_Target
    {
        half4 pixelColor = tex2D(_MainTex, input.texcoord);
        half4 volumeColor = tex2D(_VolumeCloudTempRT, input.texcoord);
        pixelColor.rgb = lerp(pixelColor.rgb, volumeColor.rgb, volumeColor.a * volumeColor.a);
        return pixelColor;
    }
    
    ENDHLSL

    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefaultQuad
            #pragma fragment frag

            #pragma exclude_renderers d3d11_9x
            ENDHLSL
        }
        
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefaultQuad
            #pragma fragment fragBlurX

            #pragma exclude_renderers d3d11_9x
            ENDHLSL
        }
        
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefaultQuad
            #pragma fragment fragBlurY

            #pragma exclude_renderers d3d11_9x
            ENDHLSL
        }
        
        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefaultQuad
            #pragma fragment fragCombine

            #pragma exclude_renderers d3d11_9x
            ENDHLSL
        }
    }
}