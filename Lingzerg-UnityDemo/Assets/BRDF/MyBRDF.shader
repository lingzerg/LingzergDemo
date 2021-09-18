Shader "Woody/MyBRDF"
{
    Properties
    {
        _Color ("Base Color", Color) = (1,1,1,1)
        [Gamma] _Metallic ("Metallic", Range(0,1)) = 0
        _Roughness ("Roughness", Range(0,1)) = 0.5
        _BaseF0 ("BaseF0",Range(0,1)) = 0.04
        [Toggle]
		_PISwitch ("PISwitch",Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityStandardBRDF.cginc" 
            
            #define PI 3.14159274f

            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
                
            };

            struct Interpolators
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                fixed3 normal : TEXCOORD2;
				
                
            };

            fixed4 _Color;
            fixed _Metallic,_Roughness,_BaseF0;
            half _PISwitch;

            Interpolators vert (VertexInput v)
            {
                Interpolators i;
                i.vertex = UnityObjectToClipPos(v.vertex);
				i.worldPos = mul(unity_ObjectToWorld, v.vertex);
                i.uv = 0;
                i.normal = UnityObjectToWorldNormal(v.normal);
                i.normal = normalize(i.normal);
                return i;
            }

            //F项 fresnel
            fixed3 fresnelSchlick(float cosTheta, fixed3 F0)
            {
                return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
            }
            

            //G项
            fixed SchlickGGX(float cosTheta, fixed k) {
                return cosTheta/(cosTheta* (1-k)+k);
            }

            //D项
            fixed DistributionGGX(fixed3 NdotH, fixed a) {

                fixed a2 = a*a;
                fixed denom = (NdotH*NdotH * (a2-1)+1);
                denom = PI * denom * denom;

                return a2/denom;
            }

            fixed4 frag (Interpolators i) : SV_Target
            {
                fixed4 FinalColor = 0;
                float3 lightColor = _LightColor0.rgb;
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				float3 halfVector = normalize(lightDir + viewDir);  //半角向量

                float3 normal = normalize(i.normal);
                float VdotH = max(saturate(dot(viewDir, halfVector)), 0.000001);
                float NdotL = max(saturate(dot(normal, lightDir)), 0.000001);
                float NdotH = max(saturate(dot(normal, halfVector)), 0.000001);
                float NdotV = max(saturate(dot(normal, viewDir)), 0.000001);

                fixed3 F0 = _BaseF0;//unity_ColorSpaceDielectricSpec.rgb;// 
                F0 = lerp(F0, _Color.rgb, _Metallic);
                fixed3 F = fresnelSchlick(VdotH, F0);
                //float3 F = F0 + (1 - F0) * exp2((-5.55473 * VdotH - 6.98316) * VdotH);
                fixed kd = (1-F)*(1-_Metallic);
                
                //计算漫反射
                float3 diffuse = _Color.rgb/PI * kd;
                //可以用下面这句输出一下漫反射看看
                //return fixed4(diffuse*NdotL*_LightColor0.rgb * PI,1);

                //粗糙度平方, 方便美术拉动
                fixed roughness = _Roughness*_Roughness;

                fixed squareRoughness = roughness * roughness;

                fixed D = DistributionGGX(NdotH,roughness);
                //return D;

                fixed k_dir = pow((squareRoughness+1),2)/8;
                
                fixed ggx1 = SchlickGGX(NdotL,k_dir);
                fixed ggx2 = SchlickGGX(NdotV,k_dir);
                fixed G = ggx1 * ggx2;
                //return G;

                //return fixed4(F*G*D,1);
                fixed3 FDG = D * F * G;
                FDG /= 4*NdotV*NdotL;
                //return fixed4(FDG,1) * PI;
                
                FinalColor.rgb = diffuse;
                FinalColor.rgb += +FDG;
                
                FinalColor.rgb *=  lightColor * NdotL;
                FinalColor.rgb *= lerp(1,PI,_PISwitch);
                FinalColor.a = 1;
                return FinalColor;
            }
            ENDCG
        }
    }
}
