package com.lingzerg.fourier;

import java.text.NumberFormat;

public class Complex {
    private double real;//实数
    private double image;//虚数
 
    NumberFormat nf = NumberFormat.getInstance();
    
    
    public Complex() {
        real = 0;
        image = 0;
        
        // 设置此格式中不使用分组
        nf.setGroupingUsed(false);
        // 设置数的小数部分所允许的最大位数。
        nf.setMaximumFractionDigits(4);
    }
 
    public Complex(double real) {
        this.real = real;
        this.image = 0;
    }
 
    public Complex(double real, double image) {
        this.real = real;
        this.image = image;
    }
 
    //加：(a+bi)+(c+di)=(a+c)+(b+d)i
    public Complex add(Complex complex) {
        double real = complex.getReal();
        double image = complex.getImage();
        double newReal = this.real + real;
        double newImage = this.image + image;
        return new Complex(newReal, newImage);
    }
 
    //减：(a+bi)-(c+di)=(a-c)+(b-d)i
    public Complex sub(Complex complex) {
        double real = complex.getReal();
        double image = complex.getImage();
        double newReal = this.real - real;
        double newImage = this.image - image;
        return new Complex(newReal, newImage);
    }
 
    //乘：(a+bi)(c+di)=(ac-bd)+(bc+ad)i
    public Complex mul(Complex complex) {
        double real = complex.getReal();
        double image = complex.getImage();
        double newReal = this.real * real - this.image * image;
        double newImage = this.image * real + this.real * image;
        return new Complex(newReal, newImage);
    }
 
    //乘：a(c+di)=ac+adi
    public Complex mul(double multiplier) {
        return mul(new Complex(multiplier));
    }
 
    //除：(a+bi)/(c+di)=(ac+bd)/(c^2+d^2) +((bc-ad)/(c^2+d^2))i
    public Complex div(Complex complex) {
        double real = complex.getReal();
        double image = complex.getImage();
        double denominator = real * real + image * image;
        double newReal = (this.real * real + this.image * image) / denominator;
        double newImage = (this.image * real - this.real * image) / denominator;
        return new Complex(newReal, newImage);
    }
 
    public double getReal() {
        return real;
    }
 
    public void setReal(double real) {
        this.real = real;
    }
 
    public double getImage() {
        return image;
    }
 
    public void setImage(double image) {
        this.image = image;
    }
 
    @Override
    public String toString() {
    	
    	
        String str = "";
        if (real != 0) {
            str += nf.format(real);
        } else {
            str += "0";
        }
        if (image < 0) {
            str += " *** " + nf.format(image) + "i";
        } else if (image > 0) {
            str += " *** " + nf.format(image) + "i";
        }
        return str;
    }
 
    //欧拉公式 e^(ix)=cosx+isinx
    public static Complex euler(double x) {
        double newReal = Math.cos(x);
        double newImage = Math.sin(x);
        return new Complex(newReal, newImage);
    }
 
 
 
    /**
     * 将double数组转换为复数数组
     *
     * @param doubleArray double数组
     */
    public static Complex[] getComplexArray(double[] doubleArray) {
        int length = doubleArray.length;
        Complex[] complexArray = new Complex[length];
        for (int i = 0; i < length; i++) {
            complexArray[i] = new Complex(doubleArray[i]);
        }
        return complexArray;
    }
 
    /**
     * 将二维double数组转换为二维复数数组
     *
     * @param doubleArray double二维数组
     */
    public static Complex[][] getComplexArray(double[][] doubleArray) {
        int length = doubleArray.length;
        Complex[][] complexArray = new Complex[length][];
        for (int i = 0; i < length; i++) {
            complexArray[i] = getComplexArray(doubleArray[i]);
        }
        return complexArray;
    }
 
    /**
     * 二维复数数组转置
     *
     * @param a 二维复数数组
     */
    public static Complex[][] transform(Complex[][] a) {
        int row = a.length;
        int column = a[0].length;
        Complex[][] result = new Complex[column][row];
        for (int i = 0; i < column; i++)
            for (int j = 0; j < row; j++)
                result[i][j] = a[j][i];
        return result;
    }
}