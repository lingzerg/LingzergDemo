Shader "Woody/PhysicallyBasedSky-Atmosphere"
{
    Properties
    {
        [Header(Base)]
        _Color("Base Color", Color) = (1,1,1,1)

         [Header(Atmospheric)]
        _G ("G - Ray Scattering Coefficient", Range(0, 10)) = 0.76
        _RayH("Ray-H-Rayleigh thickness", Range(0, 25000)) = 8500
        _MieH("Mie-H-Mie thickness", Range(0, 3000)) = 1200
        _MieC("Mie-Atmospheric Density,10^-17", Range(6, 25)) = 6

        [Header(Planet)]
        _PlanetRadius("Planet Radius", Float) = 6371393

        [Header(Sample)]
        _StepCount("Step Count", Range(1, 25)) = 10
    }
        SubShader
        {
            Tags { "Queue" = "Background" "RenderType" = "Background" "PreviewType" = "Skybox" }

            Cull Off ZWrite Off

            Pass
            {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #pragma enable_d3d11_debug_symbols

                #include "UnityStandardBRDF.cginc" 

                #define PI 3.14159265f

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
                    float3 normal : TEXCOORD2;

                };

                uniform float4 _Color;
                uniform float _G;
                uniform float _RayH,_MieH, _MieC;
                uniform int _StepCount;
                uniform float _PlanetRadius;

                Interpolators vert(VertexInput v)
                {
                    Interpolators i;
                    i.vertex = UnityObjectToClipPos(v.vertex);
                    i.worldPos = mul(unity_ObjectToWorld, v.vertex);
                    i.uv = v.uv;// TRANSFORM_TEX(v.uv, _MainTex);
                    i.normal = UnityObjectToWorldNormal(v.normal);
                    i.normal = normalize(i.normal);
                    return i;
                }

                float PhaseMie(float theta) {
                    
                    return 3 / (16 * PI) * (1 + pow(cos(theta),2));
                }

                float PhaseRayleigh(float theta) {

                    return (1-pow(_G,2))/ (4 * PI * (1+ pow(_G,2) - 2 *_G * pow(cos(theta), 2)));
                }

                //rho
                float Density(float h, float H) {

                    return exp(-h / H);
                }

                //beta
                float3 RayleighScatteringCoefficient(float h) {
                    float bate = 8 * pow(PI, 3) * pow(1.00029 * 1.00029 - 1, 2) / 3 * (1 / 2.504 * pow(10, 25));
                    float redLambda = 0.0000519673;
                    float greenLambda = 0.0000121427;
                    float blueLambda = 0.0000296453;
                    return bate * (1/float3(redLambda, greenLambda, blueLambda));
                }

                //beta
                float3 MieScatteringCoefficient() {
                    float redLambda = 0.0000519673;
                    float greenLambda = 0.0000121427;
                    float blueLambda = 0.0000296453;
                    float3 lambda = float3(redLambda, greenLambda, blueLambda);
                    float c = _MieC * pow(10, -17);
                    float K = 0.69;
                    float v = 4;
                    return 0.434*c*PI*pow(2 * PI / lambda, v-2)* K;
                }

                fixed TransmittanceFunction() {

                    return 0;
                }

                //-----------------------------------------------------------------------------------------
                // Helper Funcs : RaySphereIntersection
                //-----------------------------------------------------------------------------------------
                float2 RaySphereIntersection(float3 rayOrigin, float3 rayDir, float3 sphereCenter, float sphereRadius)
                {
                    rayOrigin -= sphereCenter;
                    float a = dot(rayDir, rayDir); //cos theta
                    float b = 2.0 * dot(rayOrigin, rayDir);
                    float c = dot(rayOrigin, rayOrigin) - (sphereRadius * sphereRadius);
                    float d = b * b - 4 * a * c;
                    if (d < 0)
                    {
                        return -1;
                    }
                    else
                    {
                        d = sqrt(d);
                        return float2(-b - d, -b + d) / (2 * a);
                    }
                }

                float3 getAtmospherePos(float dir) {
                    return float3(0,0,0);
                }


                float4 frag(Interpolators i) : SV_Target
                {
                    float4 FinalColor = 0;
                    FinalColor = 0;

                    float3 lightColor = _LightColor0.rgb;
                    float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                    float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                    float3 halfVector = normalize(lightDir + viewDir);  //半角向量

                    //定义当前片元的相对方向
                    float3 AtmosphereDir = normalize(i.worldPos.xyz - float3(0, 6371393, 0));
                    

                    //利用分段得到每个采样点的坐标
                    //地球半径: 6371.393km = 6371393m
                    //大气外层半径: 6371393 + _RayH;

                    float2 pos = RaySphereIntersection(float3(0,6371393,0), AtmosphereDir, float3(0,0,0), 6371393 + _RayH);


                    int _count = (int)_StepCount;
                    float segmentLenght = 6371393 / _count;
                    float segment0Pos = AtmosphereDir* segmentLenght;

                    //从最远端开始计算散射, 方便累加散射量
                    for (int i = _count; i > 0; i--)
                    {
                        float3 pos = segment0Pos* i;
                    }

                    return FinalColor;
                }
                ENDCG
            }
        }
}
