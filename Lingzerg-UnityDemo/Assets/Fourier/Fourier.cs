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

    RenderTexture rtFourierSpectrum, rtFourierPhase, rtReal, rtImaginary, rtFourierInverse;

    void Start()
    {
        rtFourierSpectrum = CreateRenderTexture(TextureSize);
        //Spectrum
        //Phase

        rtFourierPhase = CreateRenderTexture(TextureSize);

        rtReal = CreateRenderTexture(TextureSize);
        rtImaginary = CreateRenderTexture(TextureSize);
        
        rtFourierInverse = CreateRenderTexture(TextureSize);

        _compute.SetInt("TextureSize",TextureSize);

        /** DFT start **/
        //DFTStart(rtFourierSpectrum, rtReal,  rtImaginary,  rtFourierPhase);
        /** DFT end **/

        /** IDFT start **/
        //IDFTStart(rtFourierInverse, rtFourierSpectrum, rtFourierPhase);
        /** IDFT end **/

        /** FFT start **/
        //FFTStart(ref rtFourierSpectrum,ref rtFourierPhase);
        /** FFT END **/

        BindTexture();
    }

    public void ShowFFT()
    {
        /** FFT start **/
        FFTStart(ref rtFourierSpectrum,ref rtFourierPhase);
        /** FFT END **/
    }

    public void ShowDFT()
    {
        /** DFT start **/
        DFTStart(rtFourierSpectrum, rtReal, rtImaginary, rtFourierPhase);
        /** DFT end **/

        /** IDFT start **/
        IDFTStart(rtFourierInverse, rtFourierSpectrum, rtFourierPhase);
        /** IDFT end **/
    }

    void BindTexture()
    {
        // 给mesh附上纹理
        forFourierSpectrumObj.material.SetTexture("_MainTex", rtFourierSpectrum);
        forFourierPhaseObj.material.SetTexture("_MainTex", rtFourierPhase);

        meshReal.material.SetTexture("_MainTex", rtReal);
        meshImaginary.material.SetTexture("_MainTex", rtImaginary);
        forFourierRevertObj.material.SetTexture("_MainTex", rtFourierInverse);
    }

    void FFTStart(ref RenderTexture rtFourierSpectrum, ref RenderTexture rtFourierPhase)
    {
        int[] rev = BitReverse(256);

        _compute.SetInts("rev", rev);
        _compute.SetInt("minus", -1);
        int kernelHandleFastFourierH = _compute.FindKernel("FastFourier");
        
        _compute.SetTexture(kernelHandleFastFourierH, "rtFourierSpectrum", rtFourierSpectrum);

        _compute.SetTexture(kernelHandleFastFourierH, "rtFourierPhase", rtFourierPhase);
        _compute.SetTexture(kernelHandleFastFourierH, "originalImg", originalImg);

        RenderTexture originalData = CreateRenderTexture(TextureSize);
        Graphics.Blit(originalImg, originalData);
        _compute.SetTexture(kernelHandleFastFourierH, "originalData", originalData);
        _compute.Dispatch(kernelHandleFastFourierH, GRID, GRID, 1);
    }

    int lim = 1;

    /***
    * bit翻转
    * @param n
    * @return
    */
    public int[] BitReverse(int n)
    {
        int[] rev = new int[128];

        int len = 0;
        lim = 1;
        while (lim < n)
        {
            lim <<= 1;
            len++;
        }

        for (int i = 0; i < lim; i++)
        {
            rev[i] = (rev[i >> 1] >> 1) | ((i & 1) << (len - 1));
            //rev[i>>1] 这个是找到子问题 i/2的下标
            //rev[i>>1]>>1 右移一位, 取他的前n-1位
            // i & 1 根据奇偶判断首位是0还是1 
            // << len- 1 左移len-1位将其移动到首位
            // 然后用按位或运算合并两者
        }

        int[] result = new int[n];
        System.Array.Copy(rev, result, n);
        return result;
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
