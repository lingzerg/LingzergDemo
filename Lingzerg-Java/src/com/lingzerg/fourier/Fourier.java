package com.lingzerg.fourier;

import java.util.Arrays;

public class Fourier {
	public Fourier() {
		
	}
	
	/**
	 * 离散傅里叶变换
	 * @param array 复数数组
	 * @param minus 正负值，DFT=-1，IDFT=1
	 */
	public static Complex[] DFT(Complex[] array, int minus) {
	    int length = array.length;
	    Complex[] complexArray = new Complex[length];
	    // minus * 2 * PI / N
	    double flag = minus * 2 * Math.PI / length;
	    for (int i = 0; i < length; i++) {
	        Complex sum = new Complex();
	        for (int j = 0; j < length; j++) {
	            //array[x] * e^((minus * 2 * PI * k / N)i)
	            Complex complex = Complex.euler(flag * i * j).mul(array[j]);
	            sum = complex.add(sum);
	        }
	        //累加
	        complexArray[i] = sum;
	    }
	    return complexArray;
	}
	
	/***
	 * 快速傅里叶变换,递归算法, FFT的最单纯形态
	 * @param list
	 * @param minus
	 * @return
	 */
	public static Complex[] FFTRecursion(Complex[] list,int minus) {
		//lim进来就是除过2的, 所以lim=1, 就是数组里只有2个元素, 就不遍历了
		if(list.length <= 1) {
			return new Complex[]{list[0]};
			 //return list;
		}
		int lim = list.length/2;
		
		Complex[] a0 = new Complex[lim];
		Complex[] a1 = new Complex[lim];
		
		for (int i = 0; i < lim; i++) {
			 a0[i] = list[i*2]; // 0 2 4 6
			 a1[i] = list[i*2+1]; //1 3 5 7
		}
		
		//递归到根节点
		a0 = FFTRecursion(a0,minus);
		a1 = FFTRecursion(a1,minus);
		
		double p = minus * 2  * Math.PI  / list.length;
		
		Complex wn = new Complex(Math.cos(p), Math.sin(p));
		Complex w = new Complex(1,0);
		
		Complex[] ak = new Complex[list.length];
		
		
		for (int k = 0; k < lim; k++) {
			
			//Complex w = new Complex(Math.cos(p), Math.sin(p));
			
			Complex wA1 =  w.mul(a1[k]);
			
			ak[k] = a0[k].add(wA1); // a0 + w*a1
			Complex cc = a0[k].sub(wA1);
			
			ak[k+lim] = cc; // a0 - w*a1
			
			w = w.mul(wn);
		}
		
		return ak;
	}

	static int lim = 1;
	
	/***
	 * 快速傅里叶变换利用蝶形网络的加速算法
	 * @param list
	 * @param minus
	 * @return
	 */
	public static Complex[] FFTButterfly(Complex[] list,int minus) {
		
		int[] rev = BitReverse(list.length);
		
		for (int i = 0; i < lim; i++) {
			if(i<rev[i]) {
				Complex temp = list[i];
				list[i] = list[rev[i]];
				list[rev[i]] = temp;
			}
		}
		
		System.out.println("lim:"+lim);
		for (int i = 1; i <= log2(lim); i++) {
			int m = 1 << i;
			double p = minus * 2  * Math.PI  / m;
			Complex wn = new Complex(Math.cos(p), Math.sin(p));
			for (int j = 0; j < lim; j+=m) {
				Complex w = new Complex(1);
				for (int k = 0; k < m/2; k++) {
					Complex t = w.mul(list[k+j+m/2]);
					Complex u = list[k+j];
					list[j+k] = u.add(t);
					list[j+k+m/2] = u.sub(t);
					w = w.mul(wn);
				}
			}
		}
		
		return list;
	}

	public static double log2(double N) {
		return log(N,2);
	}
	
	/***
	 * bit翻转
	 * @param n
	 * @return
	 */
	public static int[] BitReverse (int n) {
		
		int[] rev = new int[128];
		
		int len = 0;
		lim = 1;
		while(lim < n) {
			lim <<= 1;
			len ++;
		}
		
		for (int i = 0; i < lim; i++) {
			rev[i] = (rev[i>>1]>>1) | ((i & 1)<<(len-1)); 
			//rev[i>>1] 这个是找到子问题 i/2的下标
			//rev[i>>1]>>1 右移一位, 取他的前n-1位
			// i & 1 根据奇偶判断首位是0还是1 
			// << len- 1 左移len-1位将其移动到首位
			// 然后用按位或运算合并两者
		}
		return Arrays.copyOf(rev, n);
	}
	
	static public double log(double value, double base) {
		return Math.log(value) / Math.log(base);
	}
	
	public static void swap(int a, int b)
	{
	    int temp;
	    temp = a;
	    a = b;
	    b = temp;
	}
	
	public static void swap(Object a, Object b)
	{
		Object temp;
	    temp = a;
	    a = b;
	    b = temp;
	}
	
	
}
