![比較画像](https://github.com/user-attachments/assets/a6e7c6f9-e3f7-4b6e-93aa-1ccd4219debe)# PostProcessPixelShader
![image](https://github.com/user-attachments/assets/45f9c531-8982-4559-916b-a65f42653f2d)

## 概要
Unityにて、ポストプロセスにより、3DCGをドット絵風に変換するシェーダーです。  

- ドットの細かさ
- ハーフトーンのON/OFF
- アウトラインのON/OFF
- アウトラインの色
- 色の階調化のON/OFF

などが調整できます。  

![比較画像](https://github.com/user-attachments/assets/e4d1ec68-332c-4727-ab4a-f154bac19ee1)

## 動作環境
Unity 2022.3.33f1にて動作確認をしております。  

## 利用方法
1. Releseからunitypackageをダウンロード
2. ダウンロードしたunitypackageを、利用したいUnity Projectに読み込む
3. "PixelPostProcessor.cs"をカメラにアタッチ
4. アタッチした"PixelPostProcessor"の「Shader」欄に"PostProcessPixelShader.shader"

とすることで利用できます。

## 利用上の注意
半透明オブジェクトには、アウトラインをつけられません。  
また、VR環境での動作確認はしておりません。

## 仕様詳細
1. カメラで取得した深度からアウトラインを生成
2. モザイク処理のような処理でドット化
3. 色を階調化
4. 階調化した際に、元の色と大きく色が変わる部分にハーフトーンを施す

といった順番での処理となっております。

## クレジット
説明画像にて、以下のモデルを利用させていただいております。
- オリジナル3Dモデル【あのめあ】 by なるか 様  
  https://booth.pm/ja/items/5020157
  
- [無料]バスルーム[VRCHAT想定] by 甘野氷 様  
  https://booth.pm/ja/items/1998850
