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

    uniform float4 fragmentGlobals[5];
    uniform float4 fragmentParams[13];

    uniform float4 _LightDir;
    uniform float4 _LightColor;
    float4 _VolumeCloudParamsOffset;
    float4 _VolumeDistanceParams;

    float4 fragmentParamsVolumeBoundPivot;
    float4 fragmentParamsVolumeBoundSize;

    float4 fragmentParamsVolumeColorLerp;
    float4 fragmentParamsVolumeFinalColorBlend;
    float4 fragmentParamsVolumeFinalColor;
    float4 fragmentParamsVolumeLight;

    float4 fragmentParamsColorFar;
    float4 fragmentParamsColorNear;

    float4 fragmentParamsRay;
    float4 fragmentParamsNoise;

    float4 fragmentParamsDitherNoise;
    float4 fragmentParamsRenderResolution;

    sampler2D fragmentTextures0;
    sampler2D fragmentTextures1;
    sampler2D fragmentTextures2;
    sampler2D fragmentTextures5;

    float2 uvToScreen(float2 v) { return v * float2(2., -2.) + float2(-1., 1.); }
    float4 color;
    float4 pixelColor;
    float curTime;
    float3 nscale;
    float4 outputDist;
    float3 lightStep;
    float4 curFow;

    float a;
    float alpha;
    float3 col;
    float3 col2;
    float3 col3;
    float4 colBlend;
    float4 colBlend2;
    float4 colorAcc;
    float curDist;
    float d2;
    float d3;
    float d4;
    float dblend;
    float dblend2;
    float dens;
    float depth;
    float depthDist;
    float dfactor;
    float dirLight;
    float dist;
    float distBlend;
    float3 f;
    float fogHeight;
    int i;
    int i2;
    float3 i3;
    float minDist;
    float noiseTime;
    int numSteps;
    int numSteps2;
    float2 nuv;
    float3 originWS;
    float3 p;
    float3 p10;
    float3 p2;
    float3 p3;
    float3 p4;
    float3 p5;
    float3 p6;
    float3 p7;
    float3 p8;
    float3 p9;
    float3 pixelPos;
    float3 pt;
    float2 rg;
    float sampleHeight;
    float3 samplePt;
    float3 samplePt2;
    float3 samplePt3;
    float3 samplePt4;
    float2 screen;
    float startD;
    float stepSize;
    float4 temp;
    float terrainZ;
    float terrainZ2;
    float terrainZ3;
    float tnoise;
    float2 uv_2;
    float2 uv2;
    float2 uv3;
    float3 v;
    float3 v2;
    float2 v3;
    float3 v4;
    float2 worldUV;
    float2 worldUV2;
    float2 worldUV3;
    float3 x;
    float3 x10;
    float3 x2;
    float3 x3;
    float3 x4;
    float3 x5;
    float3 x6;
    float3 x7;
    float3 x8;
    float3 x9;

    float4 val3(void)
    {
        worldUV = (v.xz - fragmentParamsVolumeBoundPivot.xz) / fragmentParamsVolumeBoundSize.xz;
        return tex2D(fragmentTextures0, worldUV);
    }

    float val2(void)
    {
        v = samplePt;
        curFow = val3();
        fogHeight = curFow.w;
        d2 = (fragmentParams[2].z + fogHeight - v.y) * fragmentParams[5].z;
        {
            noiseTime = curTime * fragmentParamsNoise.y;
            tnoise = 0.;
            pt = v * nscale;
            d2 += tnoise * fragmentParamsNoise.x;
        }
        d2 *= fragmentParams[6].x;
        return d2;
    }

    float4 val5(void)
    {
        worldUV2 = (v2.xz - fragmentParamsVolumeBoundPivot.xz) / fragmentParamsVolumeBoundSize.xz;
        return tex2D(fragmentTextures0, worldUV2);
    }

    float val7(void)
    {
        x = p;
        i3 = floor(x);
        f = frac(x);
        f = f * f * (3. - 2. * f);
        uv3 = (i3.xz + float2(37., 239.) * i3.y) + f.xz;
        rg = tex2D(fragmentTextures1, (uv3 + 0.5) / 256.).yx;
        return lerp(rg.x, rg.y, f.y);
    }

    float val6(void)
    {
        p = pt + float3(0., -1., 0.0) * noiseTime;
        return val7() * 2. - 1.;
    }

    float val9(void)
    {
        x2 = p2;
        i3 = floor(x2);
        f = frac(x2);
        f = f * f * (3. - 2. * f);
        uv3 = (i3.xz + float2(37., 239.) * i3.y) + f.xz;
        rg = tex2D(fragmentTextures1, (uv3 + 0.5) / 256.).yx;
        return lerp(rg.x, rg.y, f.y);
    }

    float val8(void)
    {
        p2 = pt * 2. + float3(-0.9, -1.1, 0.) * noiseTime;
        return val9() * 2. - 1.;
    }

    float val11(void)
    {
        x3 = p3;
        i3 = floor(x3);
        f = frac(x3);
        f = f * f * (3. - 2. * f);
        uv3 = (i3.xz + float2(37., 239.) * i3.y) + f.xz;
        rg = tex2D(fragmentTextures1, (uv3 + 0.5) / 256.).yx;
        return lerp(rg.x, rg.y, f.y);
    }

    float val10(void)
    {
        p3 = pt * 4. + float3(0.8, -1.2, 0.95) * noiseTime;
        return val11() * 2. - 1.;
    }

    float val13(void)
    {
        x4 = p4;
        i3 = floor(x4);
        f = frac(x4);
        f = f * f * (3. - 2. * f);
        uv3 = (i3.xz + float2(37., 239.) * i3.y) + f.xz;
        rg = tex2D(fragmentTextures1, (uv3 + 0.5) / 256.).yx;
        return lerp(rg.x, rg.y, f.y);
    }

    float val12(void)
    {
        p4 = pt * 8. + float3(0., -1.3, -0.84) * noiseTime;
        return val13() * 2. - 1.;
    }

    float val15(void)
    {
        x5 = p5;
        i3 = floor(x5);
        f = frac(x5);
        f = f * f * (3. - 2. * f);
        uv3 = (i3.xz + float2(37., 239.) * i3.y) + f.xz;
        rg = tex2D(fragmentTextures1, (uv3 + 0.5) / 256.).yx;
        return lerp(rg.x, rg.y, f.y);
    }

    float val14(void)
    {
        p5 = pt * 12. + float3(0., 1.5, 0.) * noiseTime;
        return val15() * 2. - 1.;
    }

    float val4(void)
    {
        v2 = samplePt2;
        curFow = val5();
        fogHeight = curFow.w;
        d2 = (0. + fogHeight - v2.y) * fragmentParams[5].z;
        {
            noiseTime = curTime * fragmentParamsNoise.y;
            tnoise = 0.;
            pt = v2 * nscale;
            if (int(fragmentParams[4].w) >= 1) tnoise += val6() * 1.;
            if (int(fragmentParams[4].w) >= 2) tnoise += val8() * 1. / _VolumeCloudParamsOffset.x;
            if (int(fragmentParams[4].w) >= 3) tnoise += val10() * 1. / _VolumeCloudParamsOffset.y;
            if (int(fragmentParams[4].w) >= 4) tnoise += val12() * 1. / _VolumeCloudParamsOffset.z;
            if (int(fragmentParams[4].w) >= 5) tnoise += val14() * 1. / _VolumeCloudParamsOffset.w;
            d2 += tnoise * fragmentParamsNoise.x;
        }
        d2 *= fragmentParams[6].x;
        return d2;
    }

    float val16(void)
    {
        v3 = samplePt2.xz;
        return tex2D(fragmentTextures2, v3 / fragmentParams[1].xy).x;
    }

    float val17(void)
    {
        dist = curDist;
        dfactor = smoothstep(
            0., 1., (dist - _VolumeDistanceParams.y - _VolumeDistanceParams.z) / (_VolumeDistanceParams.x - _VolumeDistanceParams.z));
        return dfactor * dfactor;
    }

    float3 val19(void)
    {
        samplePt4 = samplePt3;
        terrainZ3 = terrainZ2;
        dblend2 = dblend;
        sampleHeight = clamp((samplePt4.y - terrainZ3) / fragmentParams[5].w, 0., 1.);
        col2 = curFow.xyz;
        col2 = lerp(col2 * fragmentParams[4].xyz, col2, clamp(sampleHeight, 0., 1.));
        col2 *= fragmentParams[3].w;
        col2 = lerp(col2, fragmentParams[0].xyz, dblend2);
        return col2;
    }

    // float3 val19(void)
    // {
    //     samplePt4 = samplePt3;
    //     terrainZ3 = terrainZ2;
    //     dblend2 = dblend;
    //     sampleHeight = clamp((samplePt4.y - terrainZ3) / fragmentParamsVolumeColorLerp.x, 0., 1.);
    //     col2 = curFow.xyz;
    //     col2 = lerp(col2 * fragmentParamsColorNear, col2, clamp(sampleHeight, 0., 1.));
    //     col2 *= fragmentParamsColorNear.w;
    //     col2 = lerp(col2, fragmentParamsColorFar, dblend2);
    //     return col2;
    // }

    float4 val21(void)
    {
        worldUV3 = (v4.xz - fragmentParamsVolumeBoundPivot.xz) / fragmentParamsVolumeBoundSize.xz;;
        return tex2D(fragmentTextures0, worldUV3);
    }

    float val23(void)
    {
        x6 = p6;
        i3 = floor(x6);
        f = frac(x6);
        f = f * f * (3. - 2. * f);
        uv3 = (i3.xz + float2(37., 239.) * i3.y) + f.xz;
        rg = tex2D(fragmentTextures1, (uv3 + 0.5) / 256.).yx;
        return lerp(rg.x, rg.y, f.y);
    }

    float val22(void)
    {
        p6 = pt + float3(0., -1., 0.0) * noiseTime;
        return val23() * 2. - 1.;
    }

    float val25(void)
    {
        x7 = p7;
        i3 = floor(x7);
        f = frac(x7);
        f = f * f * (3. - 2. * f);
        uv3 = (i3.xz + float2(37., 239.) * i3.y) + f.xz;
        rg = tex2D(fragmentTextures1, (uv3 + 0.5) / 256.).yx;
        return lerp(rg.x, rg.y, f.y);
    }

    float val24(void)
    {
        p7 = pt * 2. + float3(-0.9, -1.1, 0.) * noiseTime;
        return val25() * 2. - 1.;
    }

    float val27(void)
    {
        x8 = p8;
        i3 = floor(x8);
        f = frac(x8);
        f = f * f * (3. - 2. * f);
        uv3 = (i3.xz + float2(37., 239.) * i3.y) + f.xz;
        rg = tex2D(fragmentTextures1, (uv3 + 0.5) / 256.).yx;
        return lerp(rg.x, rg.y, f.y);
    }

    float val26(void)
    {
        p8 = pt * 4. + float3(0.8, -1.2, 0.95) * noiseTime;
        return val27() * 2. - 1.;
    }

    float val29(void)
    {
        x9 = p9;
        i3 = floor(x9);
        f = frac(x9);
        f = f * f * (3. - 2. * f);
        uv3 = (i3.xz + float2(37., 239.) * i3.y) + f.xz;
        rg = tex2D(fragmentTextures1, (uv3 + 0.5) / 256.).yx;
        return lerp(rg.x, rg.y, f.y);
    }

    float val28(void)
    {
        p9 = pt * 8. + float3(0., -1.3, -0.84) * noiseTime;
        return val29() * 2. - 1.;
    }

    float val31(void)
    {
        x10 = p10;
        i3 = floor(x10);
        f = frac(x10);
        f = f * f * (3. - 2. * f);
        uv3 = (i3.xz + float2(37., 239.) * i3.y) + f.xz;
        rg = tex2D(fragmentTextures1, (uv3 + 0.5) / 256.).yx;
        return lerp(rg.x, rg.y, f.y);
    }

    float val30(void)
    {
        p10 = pt * 12. + float3(0., 1.5, 0.0) * noiseTime;
        return val31() * 2. - 1.;
    }

    float val20(void)
    {
        v4 = samplePt3 + lightStep;
        curFow = val21();
        fogHeight = curFow.w;
        d2 = (0. + fogHeight - v4.y) * fragmentParams[5].z;
        {
            noiseTime = curTime * fragmentParamsNoise.y;
            tnoise = 0.;
            pt = v4 * nscale;
            if (int(fragmentParams[5].x) >= 1) tnoise += val22() * 1.;
            if (int(fragmentParams[5].x) >= 2) tnoise += val24() * 1. / fragmentParams[11].z;
            if (int(fragmentParams[5].x) >= 3) tnoise += val26() * 1. / fragmentParams[11].w;
            if (int(fragmentParams[5].x) >= 4) tnoise += val28() * 1. / fragmentParams[12].x;
            if (int(fragmentParams[5].x) >= 5) tnoise += val30() * 1. / fragmentParams[12].y;
            d2 += tnoise * fragmentParamsNoise.x;
        }
        d2 *= fragmentParams[6].x;
        return d2;
    }

    float4 val18(void)
    {
        samplePt3 = samplePt2;
        terrainZ2 = terrainZ;
        dblend = distBlend;
        d4 = d3;
        col = val19();
        dirLight = max(0., d4 - val20());
        col += clamp(dirLight * _LightColor * fragmentParamsVolumeLight.x, 0., 1.);
        a = clamp(d4, 0., 1.);
        colBlend2 = float4(col.xyz * a, a);
        return colBlend2;
    }

    float3 val32(void)
    {
        col3 = colorAcc.xyz;
        return col3 * col3;
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

        curTime = _Time.y;
        nscale = fragmentParams[10].w;
        nscale.y *= fragmentParams[8].x;
        
        float4 basePixelColor = float4(tex2D(_MainTex, input.texcoord).xyz, 0.);
        float4 volumePixelColor = 0;
        pixelPos = worldPos;
        float3 camRay = GetRay(worldPos.xyz);

        depthDist = min(_VolumeDistanceParams.x + _VolumeDistanceParams.y, length((pixelPos - _WorldSpaceCameraPos.xyz)));
        float ditherNoise = 0.0;
        
        nuv = input.texcoord * fragmentParamsRenderResolution.xy / fragmentParamsDitherNoise.xy;
        ditherNoise = tex2D(fragmentTextures5, nuv).x;
        ditherNoise = frac(ditherNoise + float(int(fragmentParamsDitherNoise.z)) * 0.61803398875);
        
        lightStep = -_LightDir.xyz * fragmentParamsRay.x;
        minDist = 100000000.;

        //RayMarching到接触体积云的位置
        float startD = -1.0;
        
        float d = ditherNoise * fragmentParamsRay.y;
        numSteps = int(depthDist / fragmentParamsRay.y) + 1;
        UNITY_LOOP
        for (i = 0; i < numSteps; i++)
        {
            samplePt = _WorldSpaceCameraPos.xyz + camRay * d;
            dens = val2();
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
            colorAcc = 0.0;
            //云内部的步进距离
            stepSize = fragmentParamsRay.w;
            curDist = startD;
            numSteps2 = int((depthDist - startD) / stepSize) + 1;
            UNITY_LOOP
            for (i2 = 0; i2 < numSteps2; i2++)
            {
                samplePt2 = _WorldSpaceCameraPos + camRay * curDist;
                d3 = val4();
                if (d3 > fragmentParamsRay.z)
                {
                    terrainZ = val16();
                    distBlend = val17();
                    colBlend = val18();
                    alpha = 1.;
                    alpha *= clamp(abs(depthDist - curDist) / fragmentParams[7].w, 0., 1.);
                    alpha *= 1. - distBlend;
                    colorAcc += colBlend * (1. - colorAcc.w) * alpha * stepSize;
                    minDist = min(minDist, curDist);
                }
                if (colorAcc.w > 0.99) break;
                curDist += stepSize;
            }
            colorAcc.xyz /= (0.001 + colorAcc.w);
            colorAcc.xyz = remap01(colorAcc.xyz, fragmentParamsVolumeFinalColor.y, fragmentParamsVolumeFinalColor.z);
            colorAcc.xyz = pow(colorAcc.xyz, fragmentParamsVolumeFinalColor.x);
            colorAcc.xyz = val32();
            colorAcc.w = clamp(pow(colorAcc.w, fragmentParamsVolumeFinalColorBlend.x) * fragmentParamsVolumeFinalColorBlend.y, 0., 1.);
            volumePixelColor = colorAcc;
        };
        outputDist = minDist;
        // color = pixelColor;
        // OUTPUT1 = color;
        // OUTPUT2 = outputDist;
        return lerp(basePixelColor, volumePixelColor, volumePixelColor.w);
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
    }
}