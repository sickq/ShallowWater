Shader "Unlit/DefaultLit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("_Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 posWorld : TEXCOORD1;
                float4 viewDir : TEXCOORD2;
                float4 customValue : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;

            float4 g_AtmosphereLightDirection;
            float4 g_CameraAerialPerspectiveVolumeParam;
            UNITY_DECLARE_TEX3D(AtmosphereCameraScatteringVolume);
            
            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.posWorld = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
                // o.viewDir.xyz = o.posWorld - _WorldSpaceCameraPos.xyz;
                // float3 normalizeViewDir = normalize(o.viewDir.xyz);
                //
                // float xz = sqrt(1 - normalizeViewDir.y * normalizeViewDir.y);
                //
                // o.customValue.x = sqrt(dot(o.viewDir.xz, o.viewDir.xz));
                //
                // float atmosTempValue = dot(float2(-normalizeViewDir.x, normalizeViewDir.z), g_AtmosphereLightDirection.xy);
                // atmosTempValue = clamp(atmosTempValue / xz, -1, 1);
                //
                // atmosTempValue = acos(atmosTempValue);
                // atmosTempValue = atmosTempValue / UNITY_PI;
                // atmosTempValue = sqrt(atmosTempValue);
                // o.viewDir.w = atmosTempValue;
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            half4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv) * _Color;

                float3 viewDir = i.posWorld - _WorldSpaceCameraPos.xyz;
                float3 normalizeViewDir = normalize(viewDir);

                float xz = sqrt(1 - normalizeViewDir.y * normalizeViewDir.y);

                float tempValue = sqrt(dot(viewDir.xz, viewDir.xz));
                
                float atmosTempValue = dot(float2(-normalizeViewDir.x, normalizeViewDir.z), g_AtmosphereLightDirection.xy);
                atmosTempValue = clamp(atmosTempValue / xz, -1, 1);

                atmosTempValue = acos(atmosTempValue);
                atmosTempValue = atmosTempValue / UNITY_PI;
                atmosTempValue = sqrt(atmosTempValue);

                float atmosUVTemp = saturate((viewDir.y + g_CameraAerialPerspectiveVolumeParam.x) * g_CameraAerialPerspectiveVolumeParam.z);
                float atmosUVTemp1 = saturate(tempValue * g_CameraAerialPerspectiveVolumeParam.y);

                float3 atmosUV = 0;
                atmosUV.yz = sqrt(float2(atmosUVTemp, atmosUVTemp1));
                atmosUV.x = atmosTempValue;
                
                // float atmosUVTemp = saturate((i.viewDir.y + g_CameraAerialPerspectiveVolumeParam.x) * g_CameraAerialPerspectiveVolumeParam.z);
                // float atmosUVTemp1 = saturate(i.customValue.x * g_CameraAerialPerspectiveVolumeParam.y);
                //
                // float3 atmosUV = 0;
                // atmosUV.yz = sqrt(float2(atmosUVTemp, atmosUVTemp1));
                // atmosUV.x = i.viewDir.w;
                
                float4 atmosphereColor = UNITY_SAMPLE_TEX3D_LOD(AtmosphereCameraScatteringVolume, atmosUV, 0);

                col.rgb = lerp(col.rgb, atmosphereColor.rgb, atmosphereColor.a);
                col.a = 1 - atmosphereColor.a;
                return col;
            }
            ENDCG
        }
    }
}
