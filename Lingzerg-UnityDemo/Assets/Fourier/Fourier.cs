using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Fourier : MonoBehaviour
{
    public ComputeShader _compute;
    
    public MeshRenderer forFourierSpectrumObj;
    public MeshRenderer forFourierPhaseObj;

    public MeshRenderer forFourierRevertObj;

    public MeshRenderer meshReal;

    public MeshRenderer meshImaginary;

    public Texture2D originalImg;

    [Range(16,512)]
    public int TextureSize = 512;
    
    int GRID = 32;

    void Start()
    {
        RenderTexture rtFourierSpectrum = CreateRenderTexture(TextureSize);
        //Spectrum
        //Phase

        RenderTexture rtFourierPhase = CreateRenderTexture(TextureSize);

        RenderTexture rtReal = CreateRenderTexture(TextureSize);
        RenderTexture rtImaginary = CreateRenderTexture(TextureSize);
        //
        RenderTexture rtFourierInverse = CreateRenderTexture(TextureSize);

        _compute.SetInt("TextureSize",TextureSize);

        /** DFT start **/
        DFTStart(rtFourierSpectrum, rtReal,  rtImaginary,  rtFourierPhase);
        /** DFT end **/

        /** IDFT start **/
        IDFTStart(rtFourierInverse, rtFourierSpectrum, rtFourierPhase);
        /** IDFT end **/

        /** FFT start **/
        //FFTStart(ref rtFourierSpectrum,ref rtFourierPhase);
        /** FFT END **/

        // 给mesh附上纹理
        forFourierSpectrumObj.material.SetTexture("_MainTex", rtFourierSpectrum);
        forFourierPhaseObj.material.SetTexture("_MainTex", rtFourierPhase);

        meshReal.material.SetTexture("_MainTex", rtReal);
        meshImaginary.material.SetTexture("_MainTex", rtImaginary);
        forFourierRevertObj.material.SetTexture("_MainTex", rtFourierInverse);
    }

    void FFTStart(ref RenderTexture rtFourierSpectrum, ref RenderTexture rtFourierPhase)
    {
        int kernelHandleFastFourierH = _compute.FindKernel("FastFourier");
        
        _compute.SetTexture(kernelHandleFastFourierH, "rtFourierSpectrum", rtFourierSpectrum);

        _compute.SetTexture(kernelHandleFastFourierH, "rtFourierPhase", rtFourierPhase);
        _compute.SetTexture(kernelHandleFastFourierH, "originalImg", originalImg);
        _compute.Dispatch(kernelHandleFastFourierH, GRID, GRID, 1);
    }

    //快速傅里叶变换分纵横的处理
    void FFTStart(ref RenderTexture rtFourierSpectrum)
    {
        Debug.Log("pow:" + (int)Mathf.Log(TextureSize, 2));

        RenderTexture InputRT = CreateRenderTexture(TextureSize);
        RenderTexture OutputRT = CreateRenderTexture(TextureSize);

        Graphics.Blit(originalImg, InputRT);


        for (int i = 0; i < (int)Mathf.Log(TextureSize, 2); i++)
        {
            int ns = (int)Mathf.Pow(2, i - 1);
            _compute.SetInt("Ns", ns);

            int kernelHandleFastFourierH = _compute.FindKernel("FastFourierH");

            ComputeFFT(kernelHandleFastFourierH, ref InputRT, ref OutputRT);

        }

        for (int i = 0; i < (int)Mathf.Log(TextureSize, 2); i++)
        {
            int ns = (int)Mathf.Pow(2, i - 1);
            _compute.SetInt("Ns", ns);

            int kernelHandleFastFourierV = _compute.FindKernel("FastFourierV");

            ComputeFFT(kernelHandleFastFourierV, ref InputRT, ref OutputRT);

        }

        Graphics.Blit(OutputRT, rtFourierSpectrum);
    }

    //计算fft
    private void ComputeFFT(int kernel, ref RenderTexture input, ref RenderTexture OutputRT)
    {
        _compute.SetTexture(kernel, "InputRT", input);
        _compute.SetTexture(kernel, "OutputRT", OutputRT);
        _compute.Dispatch(kernel, GRID, GRID, 1);

        //交换输入输出纹理
        RenderTexture rt = input;
        input = OutputRT;
        OutputRT = rt;
    }

    void DFTStart(RenderTexture rtFourierSpectrum,RenderTexture rtReal, RenderTexture rtImaginary, RenderTexture rtFourierPhase)
    {
        
        int kernelHandle = _compute.FindKernel("Fourier");
        _compute.SetTexture(kernelHandle, "rtFourierSpectrum", rtFourierSpectrum);
        
        _compute.SetTexture(kernelHandle, "rtReal", rtReal);
        _compute.SetTexture(kernelHandle, "rtImaginary", rtImaginary);

        _compute.SetTexture(kernelHandle, "rtFourierPhase", rtFourierPhase);
        _compute.SetTexture(kernelHandle, "originalImg", originalImg);
        _compute.Dispatch(kernelHandle, GRID, GRID, 1);
        
    }

    void IDFTStart(RenderTexture rtFourierInverse, RenderTexture rtFourierSpectrum, RenderTexture rtFourierPhase)
    {
        int kernelHandleFourierInverse = _compute.FindKernel("FourierInverse");
        _compute.SetTexture(kernelHandleFourierInverse, "rtFourierInverse", rtFourierInverse);
        _compute.SetTexture(kernelHandleFourierInverse, "rtFourierSpectrum", rtFourierSpectrum);
        _compute.SetTexture(kernelHandleFourierInverse, "rtFourierPhase", rtFourierPhase);
        _compute.Dispatch(kernelHandleFourierInverse, GRID, GRID, 1);
    }

    RenderTexture CreateRenderTexture(int size) {
        
        RenderTexture rt = new RenderTexture(size,size,24);
        rt.format = RenderTextureFormat.ARGBFloat;
        rt.enableRandomWrite = true;
        rt.filterMode = FilterMode.Point;
        rt.Create();
        rt.DiscardContents();
        return rt;
    }
}
