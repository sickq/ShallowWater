Shader "Custom/ShowShallowDepth" {

    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }
    
    HLSLINCLUDE
    
    struct v2f {
        float4 vertex : SV_POSITION;
        float4 posWorld : TEXCOORD0;
    };

    #include "UnityCG.cginc"

    sampler2D _ShallowHeightMap;
    float4 _ShallowWaterParams;

    int _ShallowWaterSize;
    sampler2D _ShallowWaterHeightRT;
    
    v2f vert(appdata_base v)
    {
        v2f o;
        o.posWorld = mul(unity_ObjectToWorld, v.vertex);

        //需要注意View空间左右手坐标系的转换
        float2 uv = (o.posWorld.xz - _ShallowWaterParams.xy) * _ShallowWaterParams.w * float2(1, -1) + float2(0.5, 0.5);

        uv = saturate(uv);
        float inShowBound = uv.x > 0 && uv.y > 0 && uv.x < 1 && uv.y < 1;
        float inArea = inShowBound ? 1 : 0;

        float heightValue = tex2Dlod(_ShallowWaterHeightRT, float4(uv, 0, 0)).r * inArea;
        o.posWorld.y += heightValue;

        o.vertex = mul(UNITY_MATRIX_VP, o.posWorld);
        return o;
    }

    sampler2D _MainTex;
    
    half4 frag(v2f i) : SV_Target
    {
        return tex2D(_MainTex, i.posWorld.xz);
        //需要注意View空间左右手坐标系的转换
        float2 uv = (i.posWorld.xz - _ShallowWaterParams.xy) * _ShallowWaterParams.w * float2(1, -1) + float2(0.5, 0.5);

        uv = saturate(uv);
        float inShowBound = uv.x > 0 && uv.y > 0 && uv.x < 1 && uv.y < 1;
        float inArea = inShowBound ? 1 : 0;

        float heightValue = -tex2D(_ShallowWaterHeightRT, uv).r;
        return heightValue * inArea;
    }
    
    ENDHLSL

    SubShader{
        Tags{ "RenderType" = "Opaque" }
        CULL Off
        Pass{
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            ENDHLSL
        }
    }
}