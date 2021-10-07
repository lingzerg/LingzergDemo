Shader "Woody/PhysicallyBasedSky-Atmosphere"
{
    Properties
    {
        [Header(Base)]
        _MainTex("Texture", 2D) = "white" {}
        _Color("Base Color", Color) = (1,1,1,1)
        _SunIntensity("Sun Intensity", Range(0, 1000)) = 10

         [Header(Atmospheric)]
        _G ("G - Ray Scattering Coefficient", Range(0, 10)) = 0.76
        _AtmosphereHeight ("Ray-H-Rayleigh thickness", Range(0, 25000)) = 8500
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

            #include "UnityCG.cginc"
            #include "UnityStandardBRDF.cginc" 
            #include "AtmospheresHelper.cginc"


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
            sampler2D _MainTex;
            uniform float4 _Color;
            uniform float _G, _SunIntensity;
            uniform float _AtmosphereHeight, _MieG, _MieC,_DistanceScale;
            float4 _DensityScaleHeight, _IncomingLight;
            float4 _ScatteringR, _ScatteringM, _ExtinctionR, _ExtinctionM;
            float4 _LightDir, _LightColor;
            float3 IncomingLight, _sunColor;
            uniform int _StepCount, _SampleCount;
            //地球半径
            uniform float _PlanetRadius;

            float4x4 _InverseViewMatrix;
            float4x4 _InverseProjectionMatrix;

            sampler2D_float _CameraDepthTexture;
            float4 _CameraDepthTexture_ST;

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

            //float PhaseMie(float theta) {
            //        
            //    return 3 / (16 * PI) * (1 + pow(cos(theta),2));
            //}

            //float PhaseRayleigh(float theta) {

            //    return (1-pow(_G,2))/ (4 * PI * (1+ pow(_G,2) - 2 *_G * pow(cos(theta), 2)));
            //}

            ////rho
            //float Density(float h, float H) {

            //    return exp(-h / H);
            //}

            ////beta
            //float3 RayleighScatteringCoefficient(float h) {
            //    float bate = 8 * pow(PI, 3) * pow(1.00029 * 1.00029 - 1, 2) / 3 * (1 / 2.504 * pow(10, 25));
            //    float redLambda = 0.0000519673;
            //    float greenLambda = 0.0000121427;
            //    float blueLambda = 0.0000296453;
            //    return bate * (1/float3(redLambda, greenLambda, blueLambda));
            //}

            ////beta
            //float3 MieScatteringCoefficient() {
            //    float redLambda = 0.0000519673;
            //    float greenLambda = 0.0000121427;
            //    float blueLambda = 0.0000296453;
            //    float3 lambda = float3(redLambda, greenLambda, blueLambda);
            //    float c = _MieC * pow(10, -17);
            //    float K = 0.69;
            //    float v = 4;
            //    return 0.434*c*PI*pow(2 * PI / lambda, v-2)* K;
            //}

            //fixed TransmittanceFunction() {

            //    return 0;
            //}

            //float3 getAtmospherePos(float3 dir) {
            //    float3 PlanetOrigin = float3(0,-_PlanetRadius,0);
            //    float AtmosphereRadius  = _PlanetRadius + 8500;
            //    float l = dot(PlanetOrigin, dir); // l
            //    float a2 = PlanetOrigin * PlanetOrigin; //a^2
            //    float m = a2 - l * l;
            //    float q2 = AtmosphereRadius * AtmosphereRadius - m*m; //R^2 - m^2
            //    float t = l + sqrt(q2);

            //    return dir*t;
            //}

            float3 GetWorldSpacePosition(float2 i_UV)
            {
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i_UV);

                float4 positionViewSpace = mul(_InverseProjectionMatrix, float4(2.0 * i_UV - 1.0, depth, 1.0));
                positionViewSpace /= positionViewSpace.w;


                float3 positionWorldSpace = mul(_InverseViewMatrix, float4(positionViewSpace.xyz, 1.0)).xyz;
                return positionWorldSpace;
            }

            //-----------------------------------------------------------------------------------------
            // Helper Funcs : RaySphereIntersection
            //-----------------------------------------------------------------------------------------
            float2 RaySphereIntersection(float3 rayOrigin, float3 rayDir, float3 sphereCenter, float sphereRadius)
            {
                rayOrigin -= sphereCenter;
                float a = dot(rayDir, rayDir);
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

            //----- Input
            // position			视线采样点P
            // lightDir			光照方向

            //----- Output : 
            // opticalDepthCP:	dcp
            bool lightSampleing(
                float3 position,							// Current point within the atmospheric sphere
                float3 lightDir,							// Direction towards the sun
                out float2 opticalDepthCP)
            {
                opticalDepthCP = 0;

                float3 rayStart = position;
                float3 rayDir = -lightDir;

                float3 planetCenter = float3(0, -_PlanetRadius, 0);
                float2 intersection = RaySphereIntersection(rayStart, rayDir, planetCenter, _PlanetRadius + _AtmosphereHeight);
                if (intersection.x > 0)
                {
                    return false;
                }
                float3 rayEnd = rayStart + rayDir * intersection.y;

                // compute density along the ray
                float stepCount = 50;// 250;
                float3 step = (rayEnd - rayStart) / stepCount;
                float stepSize = length(step);
                float2 density = 0;

                for (float s = 0.5; s < stepCount; s += 1.0)
                {
                    float3 position = rayStart + step * s;
                    float height = abs(length(position - planetCenter) - _PlanetRadius);
                    float2 localDensity = exp(-(height.xx / _DensityScaleHeight));

                    density += localDensity * stepSize;
                }

                opticalDepthCP = density;
                return true;

                //return true;
            }

            //----- Input
            // position			视线采样点P
            // lightDir			光照方向

            //----- Output : 
            //dpa
            //dcp
            bool GetAtmosphereDensityRealtime(float3 position, float3 planetCenter, float3 lightDir, out float2 dpa, out float2 dpc)
            {
                float height = length(position - planetCenter) - _PlanetRadius;
                dpa = exp((-height.xx / _DensityScaleHeight.xy));

                bool bOverGround = lightSampleing(position, lightDir, dpc);
                return bOverGround;
            }

            //----- Input
            // localDensity	rho(h)
            // densityPA
            // densityCP

            //----- Output : 
            // localInscatterR 
            // localInscatterM
            void ComputeLocalInscattering(float2 localDensity, float2 densityPA, float2 densityCP, out float3 localInscatterR, out float3 localInscatterM)
            {
                float2 densityCPA = densityCP + densityPA;

                float3 Tr = densityCPA.x * _ExtinctionR;
                float3 Tm = densityCPA.y * _ExtinctionM;

                float3 extinction = exp(-(Tr + Tm));

                localInscatterR = localDensity.x * extinction;
                localInscatterM = localDensity.y * extinction;
            }

            //----- Input
            // cosAngle			散射角

            //----- Output : 
            // scatterR 
            // scatterM
            void ApplyPhaseFunction(inout float3 scatterR, inout float3 scatterM, float cosAngle)
            {
                // r
                float phase = (3.0 / (16.0 * PI)) * (1 + (cosAngle * cosAngle));
                scatterR *= phase;

                // m
                float g = _MieG;
                float g2 = g * g;
                phase = (1.0 / (4.0 * PI)) * ((3.0 * (1.0 - g2)) / (2.0 * (2.0 + g2))) * ((1 + cosAngle * cosAngle) / (pow((1 + g2 - 2 * g * cosAngle), 3.0 / 2.0)));
                scatterM *= phase;
            }

            //----- Input
            // rayStart		视线起点 A
            // rayDir		视线方向
            // rayLength		AB 长度
            // planetCenter		地球中心坐标
            // distanceScale	世界坐标的尺寸
            // lightdir		太阳光方向
            // sampleCount		AB 采样次数

            //----- Output : 
            // extinction       T(PA)
            // inscattering:    Inscatering
            float4 IntegrateInscatteringRealtime(float3 rayStart, float3 rayDir, float rayLength, float3 planetCenter, float distanceScale, float3 lightDir, float sampleCount, out float4 extinction)
            {
                float3 step = rayDir * (rayLength / sampleCount);
                float stepSize = length(step) * distanceScale;

                float2 densityPA = 0;
                float3 scatterR = 0;
                float3 scatterM = 0;

                float2 localDensity;
                float2 densityCP;

                float2 prevLocalDensity;
                float3 prevLocalInscatterR, prevLocalInscatterM;
                GetAtmosphereDensityRealtime(rayStart, planetCenter, lightDir, prevLocalDensity, densityCP);

                ComputeLocalInscattering(prevLocalDensity, densityCP, densityPA, prevLocalInscatterR, prevLocalInscatterM);

                // P - current integration point
                // A - camera position
                // C - top of the atmosphere
                [loop]
                for (float s = 1.0; s < sampleCount; s += 1)
                {
                    float3 p = rayStart + step * s;

                    GetAtmosphereDensityRealtime(p, planetCenter, lightDir, localDensity, densityCP);
                    bool bOverGround = GetAtmosphereDensityRealtime(p, planetCenter, lightDir, localDensity, densityCP);
                    bool bInShadow = GetLightAttenuation(p) < 0.1;

                    if (!bInShadow && bOverGround)
                    {
                        densityPA += (localDensity + prevLocalDensity) * (stepSize / 2.0);
                        float3 localInscatterR, localInscatterM;
                        ComputeLocalInscattering(localDensity, densityCP, densityPA, localInscatterR, localInscatterM);

                        scatterR += (localInscatterR + prevLocalInscatterR) * (stepSize / 2.0);
                        scatterM += (localInscatterM + prevLocalInscatterM) * (stepSize / 2.0);

                        prevLocalInscatterR = localInscatterR;
                        prevLocalInscatterM = localInscatterM;

                        prevLocalDensity = localDensity;
                    }

                    prevLocalDensity = localDensity;
                }

                float3 m = scatterM;
                // phase function
                ApplyPhaseFunction(scatterR, scatterM, dot(rayDir, -lightDir.xyz));
                //scatterR = 0;
                float3 lightInscatter = (scatterR * _ScatteringR + scatterM * _ScatteringM) * _IncomingLight.xyz;
                //lightInscatter += RenderSun(m, dot(rayDir, -lightDir.xyz)) * _SunIntensity;
                float3 lightExtinction = exp(-(densityCP.x * _ExtinctionR + densityCP.y * _ExtinctionM));

                extinction = float4(lightExtinction, 0);
                return float4(lightInscatter, 1);
            }

            float3 ACESFilm(float3 x)
            {
                float a = 2.51f;
                float b = 0.03f;
                float c = 2.43f;
                float d = 0.59f;
                float e = 0.14f;
                return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
            }

            float4 frag(Interpolators i) : SV_Target
            {
                float deviceZ = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);

                float3 positionWorldSpace = GetWorldSpacePosition(i.uv);

                float3 rayStart = _WorldSpaceCameraPos;
                float3 rayDir = positionWorldSpace - _WorldSpaceCameraPos;
                float rayLength = length(rayDir);
                rayDir /= rayLength;

                if (deviceZ < 0.000001)
                {
                    rayLength = 1e20;
                }

                float3 planetCenter = float3(0, -_PlanetRadius, 0);
                float2 intersection = RaySphereIntersection(rayStart, rayDir, planetCenter, _PlanetRadius + _AtmosphereHeight);
                rayLength = min(intersection.y, rayLength);
                
                intersection = RaySphereIntersection(rayStart, rayDir, planetCenter, _PlanetRadius);
                if (intersection.x > 0)
                {
                    rayLength = min(rayLength, intersection.x);
                }

                float4 extinction;
                _SunIntensity = 0;

                float4 FinalResult = 0;
                if (deviceZ < 0.000001)
                {
                    float4 inscattering = IntegrateInscatteringRealtime(rayStart, rayDir, rayLength, planetCenter, 1, _LightDir, _SampleCount, extinction);
                    FinalResult = inscattering;
                }
                else
                {
                    float4 inscattering = IntegrateInscatteringRealtime(rayStart, rayDir, rayLength, planetCenter, _DistanceScale, _LightDir, _SampleCount, extinction);
                    float4 sceneColor = tex2D(_MainTex, i.uv);

                    FinalResult = sceneColor * extinction + inscattering;
                }

                FinalResult.xyz = ACESFilm(FinalResult.xyz);
                return FinalResult;
            }
            ENDCG
        }
    }
}
