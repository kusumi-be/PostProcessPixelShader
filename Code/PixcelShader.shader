Shader "PostProcess/PostProcessPixcelShader"

// ドット絵風に変換するポストプロセス用シェーダー
// 2パスシェーダーであり、
// 1パスでアウトラインを生成
// 2パスでドット絵化
// を行っています

{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Cull Off
        ZWrite Off
        ZTest Always
        
        // Tags { "RenderType"="Opaque" }
        // LOD 100

        // アウトラインシェーダー
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2: TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv2: TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            // アウトラインの設定用変数
            uniform bool _OutlineON;            // アウトラインのオンオフ
            uniform float _OutlineThreshold;    // アウトラインをつける範囲　0だとすべてにアウトラインがつく（画面が真っ暗になる）
            uniform fixed4 _OutlineColor;       // アウトラインの色
            uniform float _OutlineThick;        // アウトラインの厚み

            // カメラの取得画像
            sampler2D _MainTex;
            float4 _MainTex_ST;

            // カメラから取得した深度情報
            sampler2D _CameraDepthTexture;
            float4 _CameraDepthTexture_ST;
            float4 _CameraDepthTexture_TexelSize;
            
            v2f vert (appdata v)
            {
                v2f o;

                // シングルパスインスタンシングレンダリング
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv2 = TRANSFORM_TEX(v.uv, _CameraDepthTexture);
                o.uv = TRANSFORM_TEX(v.uv2, _MainTex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // シングルパスインスタンシングレンダリング
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                fixed4 col;

                if (_OutlineON) {
                    // アウトラインの演算
                    // 現状は、thickが特定方向にのみかかる問題がある
                    float diffX = _CameraDepthTexture_TexelSize.x * _OutlineThick;
                    float diffY = _CameraDepthTexture_TexelSize.y * _OutlineThick;
                    float col00 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv2 + half2(-diffX, -diffY)).r;
                    float col10 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv2 + half2(0, -diffY)).r;
                    float col01 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv2 + half2(-diffX, 0)).r;
                    float col11 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv2 + half2(0, 0)).r;

                    float ru = (col00 - col11);
                    float ld = (col10 - col01);

                    // アウトラインの描画
                    fixed outlineValue = 1 - Linear01Depth(ru*ru + ld*ld);
                    // clip(outlineValue - _OutlineThreshold);

                    col = tex2D(_MainTex, i.uv);
                    if (outlineValue > _OutlineThreshold) col = _OutlineColor;
                }
                else {
                    col = tex2D(_MainTex, i.uv);
                }

                return col;
            }
            ENDCG
        }
        
        // アウトラインシェーダーの結果をドット絵シェーダーに渡す
        GrabPass{"_SubTex"}
        
        // ドット絵シェーダー
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_SubTex);
            
            uniform float4 _SubTex_TexelSize;   // テクスチャのサイズ .x .yで横、縦幅の逆数が取得できる
            uniform int _PixelSize;             // 1ドットに何画素使うか
            uniform bool _Posterization;        // 階調化を行うか
            uniform int _PosterizationNum;      // 階調化の幅
            uniform bool _Dithering;            // ディザ処理を行うか

            // vertex shader
            v2f vert (appdata v)
            {
                v2f o;

                // シングルパスインスタンシングレンダリング
                // VR時の軽量化に寄与
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                // vertex shaderの基本処理
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = ComputeGrabScreenPos(o.vertex);

                return o;
            }

            // fragment shader
            fixed4 frag (v2f i) : SV_Target
            {
                // シングルパスインスタンシングレンダリング
                // VR時の軽量化に寄与
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                // モザイク処理
                // _PixelSiz四方のピクセルで、同じUV位置の色を共有
                int2 TexelPos = floor(i.uv / _SubTex_TexelSize.xy / _PixelSize);
                fixed2 uv = _SubTex_TexelSize.xy * TexelPos * _PixelSize;

                // モザイクを適用
                fixed4 col = tex2D(_SubTex, uv);

                // 色の階調化を行う場合
                if (_Posterization) {
                    // 階調化
                    // floor関数を使って切り捨て
                    fixed4 colPost = floor(col * _PosterizationNum) / _PosterizationNum;    

                    // ディザ処理を行う場合
                    if (_Dithering) {
                        // 倍精度で階調化を行う
                        fixed3 colPostDouble = floor(col.rgb * _PosterizationNum * 2.0f) /_PosterizationNum/2;

                        // グレースケールにした場合の濃淡を求める
                        fixed3 colorBalance = {0.3, 0.6, 0.1};
                        fixed grayScale = dot(colPostDouble, colorBalance);

                        // 階調化をした際に、本来の色よりRGBどちらの方向にずれているかを導出
                        fixed3 colGap = (colPostDouble - colPost);
                        colGap *= 2;   // 階調化で表示できる色に変換

                        

                        // ディザ処理用のマスクを生成
                        // 中間色の場合（中間色とは、階調と階調と間の色を指している）に色をディザ処理で置き換える
                        // ex. 色を2値化する場合、#808080のような色が中間色にあたる
                        fixed dizMask = 1 - step(floor(grayScale * _PosterizationNum) % 2, 0);
                        // 市松柄にディザ処理を行うためのマスクを生成
                        fixed checkerMask = step((TexelPos.x % 2) ^ !(TexelPos.y % 2), 0);

                        // ディザ処理
                        // 階調化で、本来の色とずれた方向の色を加算する
                        colPost.rgb += colGap * dizMask * checkerMask;
                    }
                    col = colPost;
                }
                return col;
            }   
            ENDCG
        }
    }
}