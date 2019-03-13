Shader "Custom/Dissolve"
{
    Properties
    {
		[PerRendererData]
        _MainTex("Texture", 2D) = "white" {}

		[KeywordEnum(BlockNoise, ValueNoise, PerlinNoise)]
		_NoiseType("Noise Type", float) = 0

		[Toggle]
		_ShowNoise("ShowNoiseBlock", float) = 0

		[Toggle]
		_ShowAnim("Show Anim", float) = 0

		_NoiseColor("Noise Color", COLOR) = (0, 0, 0, 1)

		_Threshold("Threshold", Range(0, 1)) = 0

		_AlphaThreshold("Alpha Threshold", Range(0, 1)) = 0.2

		_AnimSpeed("Fade Speed", Range(0, 5)) = 1

		_Emission("Emission", Range(1, 10)) = 1

		_Seed("Seed", int) = 0

		_Size("Size", int) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderQueue"="Transparent" }

		Cull Back

		Blend SrcAlpha OneMinusSrcAlpha
		
        Pass
        {
			Name "DISSOLVE"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			#pragma multi_compile _NOISETYPE_BLOCKNOISE _NOISETYPE_VALUENOISE _NOISETYPE_PERLINNOISE

			#pragma shader_feature _SHOWNOISE_ON

			#pragma shader_feature _SHOWANIM_ON

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				fixed4 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
            };

            sampler2D _MainTex;

			fixed4 _NoiseColor;

			fixed _Threshold;

			fixed _AlphaThreshold;

			fixed _AnimSpeed;

			fixed _Emission;

			int _Seed;

			int _Size;

			float Random(float2 st, int seed) 
			{
				return frac(sin(dot(st.xy, float2(12.9898, 78.233)) + seed) * 43758.5453123);
			}
			
			#ifdef _NOISETYPE_VALUENOISE
			
			float ValueNoise(float2 st, int seed) 
			{
				//uvの整数部分
				float2 i_st = floor(st);

				//uvの小数部分
				float2 f = frac(st);

				float a = Random(i_st, seed);

				float b = Random(i_st + fixed2(1, 0), seed);

				float c = Random(i_st + fixed2(0, 1), seed);

				float d = Random(i_st + fixed2(1, 1), seed);

				//x軸の補間割合：tx=3f2x−2f3x,y軸の補間割合: ty=3f2y−2f3y 
				float2 t = f * f * (3 - 2 * f);

				return lerp(lerp(a, b, t.x), lerp(c, d, t.x), t.y);
			}
			
			#endif

			#ifdef _NOISETYPE_PERLINNOISE
			
			float PerlinNoise(float2 st, int seed) 
			{
				float2 i_st = floor(st);

				float2 f = frac(st);

				float a = Random(i_st, seed);

				float b = Random(i_st + fixed2(1, 0), seed);

				float c = Random(i_st + fixed2(0, 1), seed);

				float d = Random(i_st + fixed2(1, 1), seed);

				float2 t = f * f * (3 - 2 * f);

				return lerp(lerp(dot(a, f - float2(0, 0)), dot(b, f - float2(1, 0)), t.x), 
				lerp(dot(c, f - float2(1, 0)), dot(d, f - float2(1, 1)), t.x), t.y) + 0.5;
			} 

			#endif

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
				o.color = v.color;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
				fixed4 col = tex2D(_MainTex, i.uv) * i.color;

				fixed noiseRate;

				#ifdef _NOISETYPE_BLOCKNOISE

				noiseRate = abs(1 - Random(floor(i.uv * max(_Size, 1)), _Seed));

				#elif _NOISETYPE_VALUENOISE

				noiseRate = abs(1 - ValueNoise(i.uv * _Size, _Seed));

				#elif _NOISETYPE_PERLINNOISE 

				noiseRate = PerlinNoise(i.uv * _Size, _Seed);

				#endif

				#ifdef _SHOWNOISE_ON
				col.rgb = lerp(_NoiseColor.rgb, col.rgb, noiseRate);
				#endif

				#ifdef _SHOWANIM_ON
				_Threshold = sin(_Time.y * _AnimSpeed);
				#endif

				//消える演出
				fixed rate = smoothstep(noiseRate, 0, _Threshold);

				_NoiseColor.a *= col.a;

				col = lerp(col, _NoiseColor * _Emission, step(rate, _AlphaThreshold) * step(0.001, rate));

				col.a *= step(rate, _AlphaThreshold);
				
                return col;
            }
            ENDCG
        }
    }
}
