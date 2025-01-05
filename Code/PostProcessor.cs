using UnityEngine;
using System;
[ExecuteInEditMode]

public class PostProcessor : MonoBehaviour
{
    //[SerializeField] private Material[] PP;

    [SerializeField] private Shader _shader;
    private Material _material;

    // アウトライン関連の変数
    [SerializeField] private bool _outlineON = true;                // アウトラインを描画するか
    [SerializeField] private float _outlineThreshold = 0.2f;        // アウトラインのしきい値（0ですべてにアウトラインがつく）
    [SerializeField] private Color _outlineColor = Color.white;     // アウトラインの色
    [SerializeField] private float _outlineThick = 10.0f;            // アウトラインの厚み

    // ドット化関連の変数
    [SerializeField][Range(1, 30)] private int _pixelSize = 10;            // 1ドットにつかうピクセル数
    [SerializeField] private bool _posterization = false;                   // 色の階調化を行うか
    [SerializeField] private bool _dithering = true;                        // ディザリングを行うか
    [SerializeField][Range(1, 50)] private int _posterizationRatio = 16;    // 何段階に階調化を行うか

    private void Start()
    {
        _material = new Material(_shader);
        var camera = GetComponent<Camera>();
        camera.depthTextureMode |= DepthTextureMode.Depth;

        SetMaterialProperties();
    }

    private void Update()
    {
#if UNITY_EDITOR
        SetMaterialProperties();
#endif
    }
    

    private void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        if (_material != null) Graphics.Blit(src, dst, _material);
    }

    private void SetMaterialProperties()
    {
        if (_material != null)
        {
            _material.SetFloat("_OutlineThreshold", _outlineThreshold);
            _material.SetColor("_OutlineColor", _outlineColor);
            _material.SetFloat("_OutlineThick", _outlineThick);
            _material.SetInt("_PixelSize", _pixelSize);
            _material.SetInt("_Posterization", Convert.ToInt32(_posterization));
            _material.SetInt("_Dithering", Convert.ToInt32(_dithering));
            _material.SetInt("_PosterizationNum", _posterizationRatio);
            _material.SetInt("_OutlineON", Convert.ToInt32(_outlineON));
        }
    }
}