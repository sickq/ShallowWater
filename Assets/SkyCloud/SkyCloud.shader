Shader "Unlit/SkyCloud"
{
    Properties
    {
    }
    
    CGINCLUDE

    #include "UnityCG.cginc"

    struct appdata
    {
        float4 vertex : POSITION;
    };

    struct v2f
    {
        float4 vertex : SV_POSITION;
        float4 objPos : TEXCOORD0;
        float3 worldPos : TEXCOORD1;
    };

    float4 g_AtmosphereLightDirection;
    float4 g_CameraAerialPerspectiveVolumeParam;
    UNITY_DECLARE_TEX3D(AtmosphereCameraScatteringVolume);

    UNITY_DECLARE_TEX2DARRAY(_worleyNoiseTex);
    sampler2D _perlinForSkyCloudTex;
    sampler2D _perlinToDilateWorley;

    float4 _CloudNoiseParam;
    float4 _FakeCloudTransmittanceParam;
    float4 _PerlinOffsetAndScale;
    float4 _Worley2Param;
    float4 _WorleyOffsetAndScale;
    float4 _backPhaseParam;
    float4 _darkColor;
    float4 _envColor;
    float4 _extraParam1;
    float4 _phaseParam;
    float4 _sampleParam;
    float4 _startPosOS;
    float4 _subRayParam;
    float4 _subRayStep;
    float4 _sunColor;
    float4 _sunDir;
    float4 invscale;
    float4 scale;
    
    v2f vert (appdata v)
    {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz;
        // o.objPos.w = mul(UNITY_MATRIX_V, float4(o.worldPos, 1.0)).z;
        o.objPos.xyz = (v.vertex.xyz + float3(0.5f, 0.5f, 0.5f)) * scale.xyz;
        return o;
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

    float SamplePerlinNoise(float3 rayPos, float perlinSkyMipmap, float perlinDilateMipmap)
    {
        float2 perlinForSkyCloudUV = rayPos.xz * _PerlinOffsetAndScale.zz + _PerlinOffsetAndScale.xy;
        float2 perlinToDilateWorleyUV = perlinForSkyCloudUV * _PerlinOffsetAndScale.ww;
        float perlinForSkyCloud = tex2Dlod(_perlinForSkyCloudTex, float4(perlinForSkyCloudUV, 0, perlinSkyMipmap)).x;
        float perlinToDilateWorley = tex2Dlod(_perlinToDilateWorley, float4(perlinToDilateWorleyUV, 0, perlinDilateMipmap)).x;

        float noise = perlinToDilateWorley * _Worley2Param.x + perlinForSkyCloud;
        noise = noise * _Worley2Param.y;
        noise = pow(noise, _CloudNoiseParam.x);

        return noise;
    }

    float SampleWorleyNoise(float3 rayPos, float worleyNoiseMipmap)
    {
                float3 worleyNoiseUV = 0;
        worleyNoiseUV.xy = rayPos.xz * _CloudNoiseParam.yy;
        worleyNoiseUV.z = rayPos.y * _WorleyOffsetAndScale.w;
        worleyNoiseUV.xyz = worleyNoiseUV.xyz + _WorleyOffsetAndScale.xzy;
        float worleyNoise = UNITY_SAMPLE_TEX2DARRAY_LOD(_worleyNoiseTex, worleyNoiseUV, worleyNoiseMipmap).x;
        worleyNoise = saturate(worleyNoise);
        return worleyNoise;
    }

    float BlendPerlinWorleyNoise(float rayPosY, float noise, float worleyNoise)
    {
        noise = noise - worleyNoise * _CloudNoiseParam.z;
        float noiseTemp = max(1 - worleyNoise * _CloudNoiseParam.z, 0.0001f);
        noise = saturate(noise / noiseTemp);
        float noiseDisY = noise - rayPosY;
        noiseDisY = noiseDisY * _Worley2Param.z;


        float tempValue2 = 1 - min(rayPosY * _Worley2Param.w, 1);
        noise = noise - tempValue2;
        noise = max(noise, 0);
        noise = max(noise * noiseDisY, 0);
        return noise;
    }

    
    half4 frag (v2f i) : SV_Target
    {
        float3 cam2World = i.worldPos - _WorldSpaceCameraPos.xyz;
        float cam2WorldLength = length(cam2World);
        float3 cam2OS = i.objPos.xyz - _startPosOS.xyz;

        float3 viewDir = cam2World / cam2WorldLength;
        float3 osViewDir = cam2OS / cam2WorldLength;


        float2 ddxXZ = ddx(i.worldPos.xz);
        float sqrddxXZ = dot(ddxXZ, ddxXZ);
        float2 ddyXZ = ddy(i.worldPos.xz);
        float sqrddyXZ = dot(ddyXZ, ddyXZ);

        float sqrtddxXZ = sqrt(sqrddxXZ);
        float sqrtddyXZ = sqrt(sqrddyXZ);
        
        float scaleTempValue = sqrtddyXZ * _PerlinOffsetAndScale.z;
        float perlinForSkyCloudMipmap = max(log2(scaleTempValue * invscale.x * 64.0f), 0);

        scaleTempValue = scaleTempValue * _PerlinOffsetAndScale.w;
        float perlinToDilateWorleyMipmap = max(log2(scaleTempValue * invscale.x * 128.0f), 0);
        
        float worleyNoiseTexMipmap = max(log2(sqrtddxXZ * _CloudNoiseParam.y * invscale.x * 64.0f), 0);

        float inCloudLength = scale.y / viewDir.y;

        float VoL = dot(osViewDir, _sunDir.xyz);
        float negVoL = saturate(-VoL);
        float transmittanceWeight = pow(negVoL, _FakeCloudTransmittanceParam.y);
        //_FakeCloudTransmittanceParam.y powValue
        //_FakeCloudTransmittanceParam.x 权重
        transmittanceWeight = 1 - transmittanceWeight * _FakeCloudTransmittanceParam.x;

        transmittanceWeight = transmittanceWeight * _subRayParam.y;

        // return VoL;
        float phaseValue = _phaseParam.z * VoL + _phaseParam.y;
        phaseValue = pow(phaseValue, 1.5f);
        phaseValue = max(phaseValue, 0.0001f);
        phaseValue = _phaseParam.x / phaseValue;

        float backphaseValue = _backPhaseParam.z * VoL + _backPhaseParam.y;
        backphaseValue = pow(backphaseValue, 1.5f);
        backphaseValue = max(backphaseValue, 0.0001f);
        backphaseValue = _backPhaseParam.x / backphaseValue;

        float phaseValueTotal = phaseValue + backphaseValue;
        phaseValueTotal = min(phaseValueTotal, 1);

        float3 lightColor = phaseValueTotal * _sunColor.xyz;

        float cam2EndLength = cam2WorldLength + inCloudLength;
        float3 osViewDirInCloud = osViewDir.xyz * invscale.xyz;

        float2 camLength = float2(cam2WorldLength, cam2EndLength);
        camLength = camLength * _sampleParam.xx + _sampleParam.yy;
        camLength = log(camLength) / _sampleParam.xx;

        float2 camLengthCeil = ceil(camLength);
        float tempValue = exp(camLengthCeil.x * _sampleParam.x);

        osViewDir.xyz = osViewDir.xyz * (camLengthCeil.x - camLength.x);
        osViewDir.xyz = osViewDir.xyz * tempValue + i.objPos.xyz;

        int disCount = int(min(camLengthCeil.y, _sampleParam.w)) - camLengthCeil.x;
        disCount = int(min(float(disCount), _sampleParam.z));

        //TODO 解释
        float tempValue1 = exp(_sampleParam.x);

        osViewDir.xyz = osViewDir.xyz * invscale.xyz;
        osViewDir.xyz = saturate(osViewDir.xyz);

        float3 cloudColor = 0;

        float3 rayStartPos = osViewDir.xyz;

        float rayCount = tempValue;

        float weight = 1;

        for(int i = 0; i < disCount; i++)
        {
            if(weight <= 0.001f)
            {
                break;
            }
            
            float perlinNoise = SamplePerlinNoise(rayStartPos, perlinForSkyCloudMipmap, perlinToDilateWorleyMipmap);
            float worleyNoise = SampleWorleyNoise(rayStartPos, worleyNoiseTexMipmap);
            float noise = BlendPerlinWorleyNoise(rayStartPos.y, perlinNoise, worleyNoise);

            if(noise > 0.0001f)
            {
                noise = -noise * _extraParam1.x;
                noise = rayCount * noise;
                noise = exp(noise);

                float envColorWeight = rayStartPos.y * 0.0149999997;

                float3 subRayDir = rayStartPos - _subRayStep.xyz;
                
                float lightWeight = 1.0;
                for(int j = 0; j < _subRayParam.x; j++)
                {
                    float subRayY = saturate(subRayDir.y);

                    float perlinNoise = SamplePerlinNoise(subRayDir, perlinForSkyCloudMipmap, perlinToDilateWorleyMipmap);
                    float worleyNoiseLight = worleyNoise;
                    float lightNoise = BlendPerlinWorleyNoise(subRayY, perlinNoise, worleyNoiseLight);
                    
                    lightNoise = transmittanceWeight * (-lightNoise);
                    lightNoise = exp(lightNoise);

                    lightWeight = lightWeight * lightNoise;

                    subRayDir = subRayDir + (-_subRayStep.xyz);
                }
                float3 envColor = envColorWeight * _envColor.xyz;
                envColor = lightWeight * lightColor + envColor;

                float lerpValue = 1 - noise;
                envColor = lerpValue * envColor;
                cloudColor = envColor * weight + cloudColor;
                weight = noise * weight;
            }
            rayCount = rayCount * tempValue1;
            rayStartPos = osViewDirInCloud * rayCount + rayStartPos;
        }

        cloudColor = max(cloudColor, 0);
        float resultWeight = 1 - weight;
        float luma = dot(cloudColor.xyz, float3(0.212599993, 0.715200007, 0.0722000003));
        luma = min(luma, 1);
        luma = 1 - luma;
        luma = resultWeight * luma;
        cloudColor =  luma * _darkColor.xyz + cloudColor;

        
        cam2WorldLength = cam2WorldLength * _FakeCloudTransmittanceParam.z;
        float2 viewDirXZOffset = viewDir.xz * cam2WorldLength;
        float viewDirYOffset = viewDir.y * cam2WorldLength + _WorldSpaceCameraPos.y;

        float xz = 1 - viewDir.y * viewDir.y;

        float atmosTempValue = dot(float2(-viewDir.x, viewDir.z), g_AtmosphereLightDirection.xy);
        atmosTempValue = clamp(atmosTempValue / xz, -1, 1);
        
        atmosTempValue = acos(atmosTempValue);
        atmosTempValue = atmosTempValue / UNITY_PI;
        atmosTempValue = sqrt(atmosTempValue);


        float tempValue11 = sqrt(dot(viewDirXZOffset, viewDirXZOffset));
        float tempValue12 = viewDirYOffset + g_CameraAerialPerspectiveVolumeParam.x;

        float2 uvYZ = float2(tempValue12, tempValue11) * g_CameraAerialPerspectiveVolumeParam.zy;
        uvYZ = saturate(uvYZ);

        uvYZ = sqrt(uvYZ);
        float3 uv = float3(atmosTempValue, uvYZ);
        float4 atmosphereColor = UNITY_SAMPLE_TEX3D_LOD(AtmosphereCameraScatteringVolume, uv, 0);
        
        float4 resultColor = atmosphereColor * resultWeight + float4(cloudColor, resultWeight) * (1 - atmosphereColor.w);
        
        return resultColor;
    }
    
    ENDCG
    
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            ENDCG
        }
    }
}
