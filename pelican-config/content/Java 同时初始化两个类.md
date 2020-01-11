title: Java 同时初始化两个类
date: 2012-12-07 20:00
tags: Java

同时初始化两个类的意义在于当两个类之间关系密切，即方法经常与另一个类进行通信时，可以简化通信。

<!--- SUMMARY_END -->

我们直接看代码：
```java
/**
 * 同时初始化只适用于单例模式，且不适用于饿汉式
 */
class A {
    public static A a;
    private String name = "A";

    public static A getInstance() {
        if(a==null)
        {
            a = new A();
            //初始化B
            B.getInstance();
        }
        return a;
    }

    @Override
    public String toString() {
        return name;
    }
}

class B {
    public static B b;
    private String name = "B";

    public static B getInstance() {
        if(b==null)
        {
            b = new B();
            //初始化C
            C.getInstance();
        }
        return b;
    }

    @Override
    public String toString() {
        return name;
    }
}

class C {
    public static C c;
    private String name = "C";

    public static C getInstance() {
        if(c==null)
        {
            c = new C();
            //初始化A
            A.getInstance();
        }
        return c;
    }

    @Override
    public String toString() {
        return name;
    }
}

public class Test {
    public static void main(String[] args) {
        //未初始化
        System.out.println(A.a+" "+B.b+" "+C.c);
        //同时初始化
        A.getInstance();
        System.out.println("Hello, world!");
        System.out.println(A.a+" "+B.b+" "+C.c);
    }
}
```
