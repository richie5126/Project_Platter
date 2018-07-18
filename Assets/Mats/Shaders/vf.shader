
Shader "Lit/Diffuse With Shadows"
{
    Properties
    {
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
		_MainColor ("Main Color", Color) = (.34, .85, .92, 1) //
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1) //
		_OutlineThickness("Thickness", float) = 4
    }

	     SubShader 
     {
	  Pass
        {
            Tags {"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            // compile shader into multiple variants, with and without shadows
            // (we don't care about any lightmaps yet, so skip these variants)
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            // shadow helper functions and macros
            #include "AutoLight.cginc"

            struct v2f
            {
                float2 uv : TEXCOORD0;
                SHADOW_COORDS(1) // put shadows data into TEXCOORD1
                fixed3 diff : COLOR0;
                fixed3 ambient : COLOR1;
                float4 pos : SV_POSITION;
            };
			
			half amount;
            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                half3 worldNormal = UnityObjectToWorldNormal(v.normal);
				//o.pos += float4(v.normal, 0.0f);
                half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
				//if(nl > 0.5f) nl = 1.0f;
				//else if(nl > 0.0f) nl = 0.0f;
                o.diff = nl * _LightColor0.rgb;
                o.ambient = ShadeSH9(half4(worldNormal,1));
                // compute shadows data
                TRANSFER_SHADOW(o)
                return o;
            }

            sampler2D _MainTex;
			fixed4 _MainColor;
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * _MainColor;
                // compute shadow attenuation (1.0 = fully lit, 0.0 = fully shadowed)
                fixed shadow = SHADOW_ATTENUATION(i);
				
				//if(shadow > 0.0f && shadow <= 0.33f){shadow = 0.0f;}
				//if(shadow > 0.33f && shadow <= 0.66f){shadow = 0.5f;}
				//if(shadow > 0.66f && shadow <= 1.0f){shadow = 1.0f;}
                // darken light's illumination with shadow, keep ambient intact

				if(i.diff.r > 0.5) i.diff = half3(0.5, 0.5, 0.5);
				else if(i.diff.r < 0.1) i.diff = half3(0.1, 0.1, 0.1);
				else if(i.diff.r < 0.08) i.diff = half3(0.0, 0.0, 0.0);
				else i.diff = half3(0.33, 0.33, 0.33);

				
				if(i.ambient.r > 0.75) i.ambient *= 0.75f;
				else if (i.ambient.r > 0.50) i.ambient *= 0.5f;
				else if (i.ambient.r > 0.25) i.ambient *= 0.25f;
				else i.ambient.r = i.ambient *= 0.0f;

                fixed3 lighting = i.diff * shadow + i.ambient;
                col.rgb *= lighting;
                return col;
            }
            ENDCG
        }
     
         Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
         Blend SrcAlpha OneMinusSrcAlpha
         Cull Back
         ZTest always
         Pass
         {
             Stencil {
                 Ref 1
                 Comp always
                 Pass replace
             }
             CGPROGRAM
             #pragma vertex vert
             #pragma fragment frag
             #pragma multi_compile_fog
             
             #include "UnityCG.cginc"
             
             struct v2g 
             {
                 float4  pos : SV_POSITION;
                 float2  uv : TEXCOORD0;
                 float3 viewT : TANGENT;
                 float3 normals : NORMAL;
             };
             
             struct g2f 
             {
                 float4  pos : SV_POSITION;
                 float2  uv : TEXCOORD0;
                 float3  viewT : TANGENT;
                 float3  normals : NORMAL;
             };
 
             v2g vert(appdata_base v)
             {
                 v2g OUT;
                 OUT.pos = UnityObjectToClipPos(v.vertex);
                 OUT.uv = v.texcoord; 
                  OUT.normals = v.normal;
                 OUT.viewT = ObjSpaceViewDir(v.vertex);
                 
                 return OUT;
             }
             
             half4 frag(g2f IN) : COLOR
             {
                 //this renders nothing, if you want the base mesh and color
                 //fill this in with a standard fragment shader calculation
                 return 0;
             }
             ENDCG
         }

         Pass 
         {
             Stencil {
                 Ref 0
                 Comp equal
				 Pass replace
             }
             CGPROGRAM
             #include "UnityCG.cginc"
             #pragma target 4.0
             #pragma vertex vert
             #pragma geometry geom
             #pragma fragment frag
             
             
             half4 _OutlineColor;
             float _OutlineThickness;
         
             struct v2g 
             {
                 float4 pos : SV_POSITION;
                 float2 uv : TEXCOORD0;
                 float3 viewT : TANGENT;
                 float3 normals : NORMAL;
             };
             
             struct g2f 
             {
                 float4 pos : SV_POSITION;
                 float2 uv : TEXCOORD0;
                 float3 viewT : TANGENT;
                 float3 normals : NORMAL;
             };
 
             v2g vert(appdata_base v)
             {
                 v2g OUT;
                 OUT.pos = UnityObjectToClipPos(v.vertex);
                 
                 OUT.uv = v.texcoord;
                  OUT.normals = v.normal;
                 OUT.viewT = ObjSpaceViewDir(v.vertex);
                 
                 return OUT;
             }
             
             void geom2(v2g start, v2g end, inout TriangleStream<g2f> triStream)
             {
                 float thisWidth = _OutlineThickness/100;
                 float4 parallel = end.pos-start.pos;
                 normalize(parallel);
                 parallel *= thisWidth;
                 
                 float4 perpendicular = float4(parallel.y,-parallel.x, 0, 0);
                 perpendicular = normalize(perpendicular) * thisWidth;
                 float4 v1 = start.pos-parallel;
                 float4 v2 = end.pos+parallel;
                 g2f OUT;
                 OUT.pos = v1-perpendicular;
                 OUT.uv = start.uv;
                 OUT.viewT = start.viewT;
                 OUT.normals = start.normals;
                 triStream.Append(OUT);
                 
                 OUT.pos = v1+perpendicular;
                 triStream.Append(OUT);
                 
                 OUT.pos = v2-perpendicular;
                 OUT.uv = end.uv;
                 OUT.viewT = end.viewT;
                 OUT.normals = end.normals;
                 triStream.Append(OUT);
                 
                 OUT.pos = v2+perpendicular;
                 OUT.uv = end.uv;
                 OUT.viewT = end.viewT;
                 OUT.normals = end.normals;
                 triStream.Append(OUT);
             }
             
             [maxvertexcount(12)]
             void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
             {
                 geom2(IN[0],IN[1],triStream);
                 geom2(IN[1],IN[2],triStream);
                 geom2(IN[2],IN[0],triStream);
             }
             
             half4 frag(g2f IN) : COLOR
             {
                 _OutlineColor.a = 1;
                 return _OutlineColor;
             }
             
             ENDCG
 
         }
		 
        // shadow casting support
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
		
     }

}