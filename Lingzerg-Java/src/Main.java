import com.lingzerg.fourier.Complex;
import com.lingzerg.fourier.Fourier;

public class Main {
	
	static Complex getEuler(double x) {
		
		Complex c = new Complex();
	    c.setReal(Math.cos(x));
	    c.setImage(Math.sin(x));
	    return c;
	} 
	
	public static void main(String[] args) {
		
		double arr[] = {1.0, 2.0, 3.0, 4.0, 5.0, 7.0, 8.0, 9.0};
		//double arr[] = {1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0};
		//double arr[] = {-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0};
		
		Complex[] complexArray = Complex.getComplexArray(arr);
		Complex[] result = Fourier.DFT(complexArray, -1);
		
		//showComplexArray(complexArray);
		
		System.out.println("------------- DFT -----------------");
		for (int i = 0; i < result.length; i++) {
			System.out.println(result[i].toString());
		}
		
		System.out.println("------------- FFT Recursion -----------------");
		
		Complex[] resultFFT = Fourier.FFTRecursion(complexArray, -1);
		for (int i = 0; i < resultFFT.length; i++) {
			System.out.println(resultFFT[i].toString());
		}
		
		System.out.println("------------- FFT Butterfly -----------------");
		
		Complex[] resultFFTButterfly = Fourier.FFTButterfly(complexArray, -1);
		for (int i = 0; i < resultFFTButterfly.length; i++) {
			System.out.println(resultFFTButterfly[i].toString());
		}
		
		complexArray = Complex.getComplexArray(arr);

		System.out.println("------------- FFT Stockham -----------------");
		
		Complex[] resultFFTStockham = Fourier.FFTStockham(complexArray, -1);
		for (int i = 0; i < resultFFTStockham.length; i++) {
			System.out.println(resultFFTStockham[i].toString());
		}
		
		//²âÊÔÏÂ·­×ª256
//		int[] list= Fourier.BitReverse(256);
//		for (int i = 0; i < list.length; i++) {
//			System.out.println(list[i]);
//		}
		
	}

	private static void showComplexArray(Complex[] complexArray) {
		System.out.println("------------- show ComplexArray -----------------");
		for (int i = 0; i < complexArray.length; i++) {
			System.out.println(complexArray[i].toString());
		}
		System.out.println("------------- end ComplexArray -----------------");
		
	}
}
