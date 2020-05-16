Shader "Custom/oceanClear"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGBA)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _NoiseTexCircles ("Circle Noise Texture", 2D) = "white" {}
        _NoiseScale ("Noise Scale", float) = 1
        _FoamSize ("Foam Size", float) = 2
        _WaveMode("Wave Mode", int) = 0
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert alpha

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _NoiseTex;
        sampler2D _NoiseTexCircles;
        sampler2D _CameraDepthTexture;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
            float4 screenPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        float _NoiseScale;
        float _FoamSize;
        int _WaveMode;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void vert(inout appdata_full v) {

            float dist = clamp(length(v.vertex.xz), 0, 0.49f);
            float tex;

            if(_WaveMode == 0) {
                tex = (tex2Dlod(_NoiseTex, float4(v.texcoord.xy + _Time.x * (dist*dist*2), 0, 0)).r - 0.5f) * (dist / 30);
            }
            else if(_WaveMode == 1) {
                tex = (tex2Dlod(_NoiseTex, float4(v.texcoord.xy + _Time.x * (dist*dist*0.3f + 0.3f), 0, 0)).r - 0.5f) * (dist + 0.1f) / 40;
            }
            else {
                tex = (tex2Dlod(_NoiseTex, float4(v.texcoord.xy * (dist*dist*0.3f + 0.3f), 0, 0)).r - 0.5f) * (dist + 0.1f) / 40;
            }

            v.vertex.y += tex; // adjust wave height
            v.vertex.xz *= -0.2f/((dist-0.5f)*(dist+0.5f)); // expand plane
        }

        void surf (Input IN, inout SurfaceOutputStandard o) {

            float depth = tex2Dproj(_CameraDepthTexture, IN.screenPos);
            float depthLinear = LinearEyeDepth(depth);
            float depthDifference = depthLinear - IN.screenPos.w;

            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = (depthDifference < _FoamSize && tex2D(_NoiseTexCircles, IN.uv_MainTex * 25).r > depthDifference / _FoamSize) ? float4(1, 1, 1, 1) : c.rgb;

            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;

            float3 dzdx = ddx(IN.worldPos);
            float3 dzdy = ddy(IN.worldPos);
            float3 derivedNormal = cross( dzdx, dzdy );

            o.Normal = cross(derivedNormal, float3(1, 0, 0));
        }
        ENDCG
    }
    FallBack "Diffuse"
}
