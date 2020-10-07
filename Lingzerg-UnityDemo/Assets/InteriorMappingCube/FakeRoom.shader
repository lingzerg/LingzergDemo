Shader "Custom/FakeRoom"
{
    Properties
    {
        [NoScaleOffset] _WindowTex("Window Texture", 2D) = "black" {}
        _RoomTex("Room Texture", CUBE) = ""{}
        _RoomDepth("Room Depth", Range(0.01, 1)) = 1.0
    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" }
            Cull Back

            Pass
            {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"
                #define FLT_EPS  5.960464478e-8  // 2^-24, machine epsilon: 1 + EPS = 1 (half of the ULP for 1.0f)
                #define Max3(a, b, c) max(max(a, b), c)
                #define Min3(a, b, c) min(min(a, b), c)

                struct appdata
                {
                    float4 positionOS : POSITION;
                    float2 uv : TEXCOORD0;
                    float3 normal : NORMAL;
                };

                struct v2f
                {
                    float2 uv : TEXCOORD0;
                    float4 positionCS : SV_POSITION;
                    float3 positionOS : TEXCOORD1;
                    float3 viewDirOS : TEXCOORD2;
                    float3 normalOS : TEXCOORD3;
                };

                sampler2D _WindowTex;
                samplerCUBE _RoomTex;
                float4 _RoomTex_ST;
                fixed _RoomDepth;

                bool IntersectRayAABB(float3 rayOrigin, float3 rayDirection,
                                      float3 boxMin,    float3 boxMax,
                                      float  tMin,       float tMax,
                                  out float  tEntr,  out float tExit)
                {
                    // Could be precomputed. Clamp to avoid INF. clamp() is a single ALU on GCN.
                    // rcp(FLT_EPS) = 16,777,216, which is large enough for our purposes,
                    // yet doesn't cause a lot of numerical issues associated with FLT_MAX.
                    float3 rayDirInv = clamp(rcp(rayDirection), -rcp(FLT_EPS), rcp(FLT_EPS));

                    // Perform ray-slab intersection (component-wise).
                    float3 t0 = boxMin * rayDirInv - (rayOrigin * rayDirInv);
                    float3 t1 = boxMax * rayDirInv - (rayOrigin * rayDirInv);

                    // Find the closest/farthest distance (component-wise).
                    float3 tSlabEntr = min(t0, t1);
                    float3 tSlabExit = max(t0, t1);

                    // Find the farthest entry and the nearest exit.
                    tEntr = Max3(tSlabEntr.x, tSlabEntr.y, tSlabEntr.z);
                    tExit = Min3(tSlabExit.x, tSlabExit.y, tSlabExit.z);

                    // Clamp to the range.
                    tEntr = max(tEntr, tMin);
                    tExit = min(tExit, tMax);

                    return tEntr < tExit;
                }

                v2f vert(appdata v)
                {
                    v2f o;
                    o.positionCS = UnityObjectToClipPos(v.positionOS);
                    o.uv = v.uv;
                    o.positionOS = v.positionOS;
                    o.viewDirOS = ObjSpaceViewDir(v.positionOS);
                    o.normalOS = v.normal;
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {

                    fixed4 windowColor = tex2D(_WindowTex, i.uv);
                    float3 viewDirOS = normalize(i.viewDirOS);
                    float3 normalOS = i.normalOS;
                    float radius = 0.5, posEntr, posExit;
                    float bias = 2 * radius * (1 - _RoomDepth);

                    float3 boxMin = (float3)(-radius) + lerp((float3)0, bias * normalOS, Max3(normalOS.x, normalOS.y, normalOS.z));
                    float3 boxMax = (float3)(radius) + lerp(bias * normalOS, (float3)0, Max3(normalOS.x, normalOS.y, normalOS.z));

                    IntersectRayAABB(i.positionOS, -viewDirOS, boxMin, boxMax, 1, 2, posEntr, posExit);
                    float3 sampleDir = i.positionOS - posExit * viewDirOS;
                    sampleDir -= bias * normalOS;

                    fixed4 col = texCUBElod(_RoomTex, float4(sampleDir, 0));
                    col.rgb += windowColor.rgb * windowColor.a;
                    return col;
                }

                ENDCG
            }
        }
}