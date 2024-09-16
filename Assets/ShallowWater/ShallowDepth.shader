Shader "Custom/ShallowDepth" {

    Properties
    {
    }
    
    CGINCLUDE
    
    struct v2f {
        float4 vertex : SV_POSITION;
        float4 texPos : TEXCOORD0;
    };

    #include "UnityCG.cginc"
            
    v2f vert(appdata_base v)
    {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        float z = mul(UNITY_MATRIX_MV, v.vertex).z;
        o.texPos.z = z;
        return o;
    }

    uniform float4 _ShallowWaterParams;

    fixed4 frag(v2f i) : SV_Target
    {
        float depth = i.texPos.z;
        depth = clamp(-depth, 0, _ShallowWaterParams.z);
        depth = depth / _ShallowWaterParams.z;
        return float4(EncodeFloatRG(depth), 0, 1);
    }
    
    ENDCG

    SubShader{
        Tags{ "RenderType" = "Opaque" }
        CULL Off
        Pass{
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            ENDCG
        }
    }
}