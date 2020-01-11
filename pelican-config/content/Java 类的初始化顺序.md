title: Java 类的初始化顺序
date: 2012-06-14 19:45
tags: Java

##示例
```java
/*
由这个实例可看出同一个类中初始化的先后顺序是：
1.静态变量&&静态代码块（靠前的先初始化）
2.非静态变量&&非静态代码块（靠前的先初始化）
*/
public class InitializeDemo {
    {
        System.out.println("block 1");
    }
    static{
        System.out.println("static block 1");
    }
    String a = f();
    {
        b = "string b2";
        System.out.println("block 2");
    }
    static String b = "string b1";
    static{
        System.out.println(b);
        System.out.println("static block 2");
    }
    String f(){
        System.out.println("f()");
        return b;
    }
    public static void main(String[] args) {
        /*
        注释掉1、2行可以发现：
        静态代码块、静态变量初始化在该类被使用之前执行
        非静态代码块、非静态变量在创建对象时被执行
        */
        InitializeDemo ini = new InitializeDemo();   //1
        System.out.println(ini.a);                   //2
        System.out.println(b);
    }
}
```

<!--- SUMMARY_END -->

```java
/*
 *由此实例可知导出类及基类的初始化顺序是：
 *1.基类的静态变量&&静态代码块
 *2.导出类的静态变量&&静态代码块
 *3.基类的非静态变量&&非静态代码块
 *4.基类的构造方法
 *5.导出类的非静态变量&&非静态代码块
 *6.导出类的构造方法
 */
//可理解为extends IniA是对IniA的一次调用，于是IniA中的static执行
public class InitializeDemo2 extends IniA{
    static{
        System.out.println("static block");
    }
    InitializeDemo2(){
        System.out.println("InitializeDemo2()");
    }
    {
        System.out.println("block");
    }
    public static void main(String[] args) {
        new InitializeDemo2();
    }
}
class IniA{
    static{
        System.out.println("IniA static block");
    }
    IniA(){
        System.out.println("IniA()");
    }
    {
        System.out.println("IniA block");
    }
}
```

```java
/*
 * 这个实例说明：
 * 在其他任何事物发生之前，对象的存储空间初始化为二进制的零
 * 构造器应尽可能在不调用方法的条件下使用简单的方法使对象进入正常状态（以免多态性造成灾难）
 * 构造器可安全调用的方法是final方法（private方法属于final方法）
 */
import static java.lang.System.*;
class Ini1{
    public Ini1(){
        out.println("Ini1() before");
        draw();
        draw2();
        draw3();
        out.println("Ini1() after");
    }
    public void draw(){
        out.println("Ini1.draw()");
    }
    private void draw2(){
        out.println("Ini1.draw2()");
    }
    public final void draw3(){
        out.println("Ini1.draw3()");
    }
}
public class InitializeDemo3 extends Ini1{
    private int r = 1;
    public void draw(){
        out.println("InitializeDemo3.draw("+r+")");
    }
    public void draw2(){
        out.println("InitializeDemo3.draw2("+r+")");
    }
    public InitializeDemo3(){
        draw2();
        out.println("InitializeDemo3() after");
    }
    {
        out.println("Initialize!");
    }
    /* 报错！不能覆盖基类final方法
    public void draw3(){
        out.println("Ini1.draw3()");
    }
    */
    public static void main(String[] args) {
        new InitializeDemo3();
    }
}
```

##总结
初始化顺序是：

0. 存储空间初始化为二进制的零
1. static先于非static
2. 基类先于导出类
3. 非static先于构造器
4. 导出类static先于基类非static

只要存在对类的调用（extends视为对其调用），该类的static就会执行。
只有创建该类的对象，非static才会执行。

也可以抽象理解为优先级：static>继承关系>非static>构造器
同一优先级的，按先后顺序进行初始化
