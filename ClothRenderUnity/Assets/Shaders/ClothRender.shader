Shader "Custom/ClothRender"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _InternalTessellation("Internal Tessellation", Float) = 5
        _EdgeTessellation("Edge Tessellation", Float) = 5
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" }
        
        Pass {
            //Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            //ZWrite On ZTest LEqual

            CGPROGRAM
            #pragma target 5.0


            /*#pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster*/
            #pragma vertex vert
            #pragma hull hull
            #pragma domain dom
            #pragma geometry geom 
            #pragma fragment frag
            #pragma multi_compile_shadowcaster

            #include "UnityStandardShadow.cginc"
            #include "UnityCG.cginc"

            struct VS_OUTPUT {
                float4 position     : POSITION;     // vertex position
                //float2 uv           : TEXCOORD0;
            };
            struct HS_OUTPUT {
                float3 position : BEZIERPOS;
                //float2 uv       : TEXCOORD0;
                float3 p0       : TEXCOORD1;
                float3 p3       : TEXCOORD2;
            };

            struct HS_CONSTANT_OUTPUT
            {
                float Edges[2]        : SV_TessFactor;
            };
            struct DS_OUTPUT
            {
                float4 position : POSITION;
            };
            struct GS_OUTPUT
            {
                float4 pos     : POSITION;     // fragment position
                //V2F_SHADOW_CASTER;
            };
            VS_OUTPUT vert(appdata_base v)
            {
                VS_OUTPUT output;
                output.position = v.vertex;
                return output;
            }
            HS_CONSTANT_OUTPUT hsConstant(
                InputPatch<VS_OUTPUT, 4> ip,
                uint PatchID : SV_PrimitiveID)
            {
                HS_CONSTANT_OUTPUT output;
                output.Edges[0] = 1;// 多少根
                output.Edges[1] = 63;//每根多少
                return output;
            }

            [domain("isoline")]
            [partitioning("fractional_even")]
            [outputtopology("line")]
            [outputcontrolpoints(2)]
            [patchconstantfunc("hsConstant")]
            HS_OUTPUT hull(InputPatch<VS_OUTPUT, 4> ip, uint i : SV_OutputControlPointID, uint PatchID : SV_PrimitiveID) {

                HS_OUTPUT output;
                output.position = ip[i + 1].position;

                output.p0 = ip[0].position;
                output.p3 = ip[3].position;

                return output;
            }
            [domain("isoline")]
            DS_OUTPUT dom(HS_CONSTANT_OUTPUT input, float2 UV : SV_DomainLocation, const OutputPatch<HS_OUTPUT, 2> patch) {
                DS_OUTPUT output;

                float u = UV.x;
                float v = UV.y;
                if (v == 0.0) {
                    // tess as core fibre
                }

                float b0 = (-1.f * u) + (2.f * u * u) + (-1.f * u * u * u);
                float b1 = (2.f) + (-5.f * u * u) + (3.f * u * u * u);
                float b2 = (u)+(4.f * u * u) + (-3.f * u * u * u);
                float b3 = (-1.f * u * u) + (u * u * u);
                float3 centerWorldPos = 0.5f * (b0 * patch[0].p0 + b1 * patch[0].position + b2 * patch[1].position + b3 * patch[0].p3);


                float4 finalPosition;
                finalPosition.xyz = centerWorldPos + v * float3(1.0f, 1.0f, 1.0f);
                finalPosition.w = 1.0;
                output.position = finalPosition;
                return output;
            }
            // Geometry Shader
            [maxvertexcount(6)]
            void geom(line DS_OUTPUT p[2], inout TriangleStream<GS_OUTPUT> triStream)
            {

                p[0].position = UnityObjectToClipPos(p[0].position);
                p[1].position = UnityObjectToClipPos(p[1].position);
                
                GS_OUTPUT i1, i2, i3, i4;
                i1.pos = p[0].position;
                i2.pos = p[1].position;
                //float width = 0.02;
                float width = 0.1;
                i3.pos = p[1].position + float4(width, -width, 0, 0);
                i4.pos = p[0].position + float4(width, -width, 0, 0);

                /*TRANSFER_SHADOW_CASTER_NORMALOFFSET(i1)
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(i2)
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(i3)
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(i4)*/

                triStream.Append(i2);
                triStream.Append(i1);
                triStream.Append(i3);
                triStream.Append(i4);
            }
            // Fragment Shader
            float4 frag(GS_OUTPUT input, fixed facing : VFACE) : SV_Target
            {
                //SHADOW_CASTER_FRAGMENT(input)
                return 0;
            }           

            ENDCG
        }
        Pass
        {
            //Cull Off
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM

            #pragma target 5.0
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase   

            #include "AutoLight.cginc"


            #pragma vertex vert
            #pragma hull hull
            #pragma domain dom
            #pragma geometry geom 
            #pragma fragment frag


            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _InternalTessellation;
            float _EdgeTessellation;
            float _HideWireframe;
            uniform StructuredBuffer<float3> _controlPoints;

            // Vertex to Hull
            struct VS_OUTPUT {
                float4 position     : POSITION;     // vertex position
                //float2 uv           : TEXCOORD0;
            };

            // Hull to Domain
            // Output control point
            struct HS_OUTPUT {
                float3 position : BEZIERPOS;
                //float2 uv       : TEXCOORD0;
                float3 p0       : TEXCOORD1;
                float3 p3       : TEXCOORD2;
            };

            // Hull Constant to Domain
            // Output patch constant data.
            struct HS_CONSTANT_OUTPUT
            {
                float Edges[2]        : SV_TessFactor;
                //float Inside[2]       : SV_InsideTessFactor;

                //float3 vTangent[4]    : TANGENT;
                //float2 vUV[4]         : TEXCOORD;
                //float3 vTanUCorner[4] : TANUCORNER;
                //float3 vTanVCorner[4] : TANVCORNER;
                //float4 vCWts          : TANWEIGHTS;
            };

            // Domain to Geometry 
            struct DS_OUTPUT
            {
                float4 position : POSITION;
                /*float4 col : COLOR;
                float2 uv : TEXCOORD0;*/
            };

            // Geometry to Fragment
            struct GS_OUTPUT
            {
                float4 pos     : SV_POSITION;     // fragment position
                /*float4 col          : COLOR;
                float2 uv           : TEXCOORD0;
                float3 normal       : NORMAL;
                float3 dist         : TEXCOORD1;*/
                SHADOW_COORDS(1)
            };

            // Vertex Shader
            VS_OUTPUT vert(appdata_base v)
            {
                // Pass through shader
                // The control points define position
                VS_OUTPUT output;
                output.position = v.vertex;
                //output.uv = v.texcoord.xy;
                return output;
            }

            // Patch Constant Function
            HS_CONSTANT_OUTPUT hsConstant(
                InputPatch<VS_OUTPUT, 4> ip, // TODO: 这里应该是outputpatch和out_point_num?
                uint PatchID : SV_PrimitiveID)
            {
                HS_CONSTANT_OUTPUT output;

                /*float edge = _EdgeTessellation;
                float inside = _InternalTessellation;*/


                output.Edges[0] = 1;// 多少根
                output.Edges[1] = 63;//每根多少

                // Set the tessellation factors for the inside
                // and outside edges of the quad
                /*output.Edges[0] = edge;
                output.Edges[1] = edge;
                output.Edges[2] = edge;
                output.Edges[3] = edge;*/

                /*output.Inside[0] = inside;
                output.Inside[1] = inside;*/

                return output;
            }

            // Hull Shader
            [domain("isoline")]
            [partitioning("fractional_even")]
            [outputtopology("line")]
            [outputcontrolpoints(2)]
            [patchconstantfunc("hsConstant")]
            HS_OUTPUT hull(InputPatch<VS_OUTPUT, 4> ip, uint i : SV_OutputControlPointID, uint PatchID : SV_PrimitiveID) {

                HS_OUTPUT output;
                //output.uv = ip[i+1].uv;

                output.position = ip[i+1].position;

                output.p0 = ip[0].position;
                output.p3 = ip[3].position;

                return output;
            }

            // Domain Shader
            [domain("isoline")]
            DS_OUTPUT dom(HS_CONSTANT_OUTPUT input, float2 UV : SV_DomainLocation, const OutputPatch<HS_OUTPUT, 2> patch) {
                DS_OUTPUT output;


                float u = UV.x;
                float v = UV.y;
                if (v == 0.0) {
                    // tess as core fibre
                }

                float b0 = (-1.f * u) + (2.f * u * u) + (-1.f * u * u * u);
                float b1 = (2.f) + (-5.f * u * u) + (3.f * u * u * u);
                float b2 = (u)+(4.f * u * u) + (-3.f * u * u * u);
                float b3 = (-1.f * u * u) + (u * u * u);
                float3 centerWorldPos = 0.5f * (b0 * patch[0].p0 + b1 * patch[0].position + b2 * patch[1].position + b3 * patch[0].p3);


                //// Why do we have to do this?
                //float2 uv = UV;
                //uv *= 0.9999998;
                //uv.x += 0.0000001;
                //uv.y += 0.0000001;

                //float4 pos = float4(SurfaceSolve(_controlPoints, uv),1);
                float4 finalPosition;
                finalPosition.xyz = centerWorldPos + v * float3(1.0f, 1.0f, 1.0f);
                finalPosition.w = 1.0;
                output.position = finalPosition;
                //output.uv = UV;
                //output.col = float4(1, 1, 1, 1);

                return output;
            }

            // Geometry Shader
            [maxvertexcount(6)]
            void geom(line DS_OUTPUT p[2], inout TriangleStream<GS_OUTPUT> triStream)
            {



                /*float3 norm = cross(p[0].position - p[1].position, p[0].position - p[2].position);
                norm = normalize(mul(unity_ObjectToWorld, float4(norm, 0))).xyz;*/

                p[0].position = UnityObjectToClipPos(p[0].position);
                p[1].position = UnityObjectToClipPos(p[1].position);
                //p[2].position = UnityObjectToClipPos(p[2].position);

                //float3 dist = UCLAGL_CalculateDistToCenter(p[0].position, p[1].position, p[2].position);

                GS_OUTPUT i1, i2, i3, i4;

                // Add the normal facing triangle
                i1.pos = p[0].position;
                /* i1.col = p[0].col;
                i1.uv = p[0].uv;
                i1.normal = norm;
                i1.dist = float3(dist.x, 0, 0);*/

                i2.pos = p[1].position;
                /*i2.col = p[1].col;
                i2.uv = p[1].uv;
                i2.normal = norm;
                i2.dist = float3(0, dist.y, 0);*/


                //float width = 0.02;
                float width = 0.1;
                i3.pos = p[1].position + float4(width, -width, 0, 0);
                /*i3.col = p[2].col;
                i3.uv = p[2].uv;
                i3.normal = norm;
                i3.dist = float3(0, 0, dist.z);*/
                i4.pos = p[0].position + float4(width, -width, 0, 0);

                TRANSFER_SHADOW(i1)
                TRANSFER_SHADOW(i2)
                TRANSFER_SHADOW(i3)
                TRANSFER_SHADOW(i4)

                triStream.Append(i2);
                triStream.Append(i1);
                triStream.Append(i3);
                triStream.Append(i4);
            }

            // Fragment Shader
            float4 frag(GS_OUTPUT input, fixed facing : VFACE) : COLOR
            {
                

                float4 col = float4(0.1, 0.6, 0.4, 1.0);
                half shadow = SHADOW_ATTENUATION(input);
                //return shadow < 0.9 ? float4(0.0, 0.0, 0.0, 1.0) : col;
                //return col * shadow;
                return float4(shadow, shadow, shadow, 1.0);
                //return col;
            }

            ENDCG
        }
    }
    //FallBack "Diffuse"

}