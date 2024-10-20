// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Skybox/AtmosphereSky" {
Properties {
    [KeywordEnum(None, Simple, High Quality)] _SunDisk ("Sun", Int) = 2
    _SunSize ("Sun Size", Range(0,1)) = 0.04
    _SunSizeConvergence("Sun Size Convergence", Range(1,10)) = 5

    _AtmosphereThickness ("Atmosphere Thickness", Range(0,5)) = 1.0
    _SkyTint ("Sky Tint", Color) = (.5, .5, .5, 1)
    _GroundColor ("Ground", Color) = (.369, .349, .341, 1)

    _Exposure("Exposure", Range(0, 8)) = 1.3
}

SubShader {
    Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
    Cull Off ZWrite Off

    Pass {

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"
        #include "Lighting.cginc"


        uniform half _Exposure;     // HDR exposure
        uniform half3 _GroundColor;
        uniform half _SunSize;
        uniform half _SunSizeConvergence;
        uniform half3 _SkyTint;
        uniform half _AtmosphereThickness;

        struct appdata_t
        {
            float4 vertex : POSITION;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct v2f
        {
            float4  pos             : SV_POSITION;

        #if SKYBOX_SUNDISK == SKYBOX_SUNDISK_HQ
            // for HQ sun disk, we need vertex itself to calculate ray-dir per-pixel
            float3  vertex          : TEXCOORD0;
        #elif SKYBOX_SUNDISK == SKYBOX_SUNDISK_SIMPLE
            half3   rayDir          : TEXCOORD0;
        #else
            // as we dont need sun disk we need just rayDir.y (sky/ground threshold)
            half    skyGroundFactor : TEXCOORD0;
        #endif

            // calculate sky colors in vprog
            half3   groundColor     : TEXCOORD1;
            half3   skyColor        : TEXCOORD2;

        #if SKYBOX_SUNDISK != SKYBOX_SUNDISK_NONE
            half3   sunColor        : TEXCOORD3;
        #endif

            UNITY_VERTEX_OUTPUT_STEREO
        };

        float4 CameraAerialPerspectiveVolumeParam;
	    float4 CameraAerialPerspectiveVolumeParam2;
	    float4 CameraAerialPerspectiveVolumeParam3;

        float4 g_AtmosphereLightDirection;

        sampler2D _SkyViewLutTextureL;
        
        v2f vert (appdata_t v)
        {
            v2f OUT;
            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
            OUT.pos = UnityObjectToClipPos(v.vertex);

            OUT.vertex = v.vertex.xyz;
            
            return OUT;
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

        
        half4 frag (v2f IN) : SV_Target
        {
            half3 col = half3(0.0, 0.0, 0.0);

            float3 uniformVertPos = normalize(IN.vertex);
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

            col = tex2D(_SkyViewLutTextureL, tempUV);

            return half4(col, 0.0);

        }
        ENDCG
    }
}


Fallback Off
}
