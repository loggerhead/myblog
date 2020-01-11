title: Java 内部类用法小结
date: 2012-07-31 16:20
tags: Java

##定义
顾名思义，创建于外部类之内的类。可以定义于外部类的方法内。下面用I类表内部类，O类表外部类。（I：inner，O：outer）

##用途
1. private修饰的内部类用来隐藏实现的细节
2. 匿名类使方法实现更简洁、优美（例：工厂方法，适配器方法）
3. 可用于有效的实现“多重继承”

<!--- SUMMARY_END -->

##特性
1. 可以使用O类所有成员（包括private）
2. 可以被static、private修饰（O类不可以）
3. 可以匿名，但必须进行继承
4. 可实例化，如果被static修饰：new O.I()；否则：new O().new I()  （O类引用.new I()）
5. 不可在O类的导出类中被覆盖 (这点不像O类方法)
6. 可被继承，但其指向O类的“秘密的”引用必须被初始化

##示例
```java
class Outer {
    private class Inner {
        void innerMethod(String s) {
            System.out.println(s);
        }
    }
    private Inner inner = new Inner();
    public void outerMethod(String s) {
        inner.innerMethod(s);
    }
}
public class Test1 {
    public static void main(String[] args) {
        new Outer().outerMethod("InnerMethod print the string");
    }
}
```

```java
//工厂模式示例
interface Product {
    String getName();
}
interface ProductFactory {
    Product getProduct();
}
class CandyFactory implements ProductFactory {
    public Product getProduct() {
        return new Product() {
            public String getName() {
                return "Candy";
            }
        };
    }
}
class JellyFactory implements ProductFactory {
    public Product getProduct() {
        return new Product() {
            public String getName() {
                return "Jelly";
            }
        };
    }
}
public class Test1 {
    static void production(ProductFactory factory) {
        Product p = factory.getProduct();
        String name = p.getName();
        System.out.println(name);
    }
    public static void main(String[] args) {
        production(new CandyFactory());
        production(new JellyFactory());
    }
}
```

```java
interface Interface1 { void methodI1(); }
interface Interface2 { void methodI2(); }
class Class1 { void methodC1() {} }
class Class2 { void methodC2() {} }

public class Test1 {
    private class RealInterface implements Interface1,Interface2 {
        public void methodI1() { System.out.println("Implements Interface1"); }
        public void methodI2() { System.out.println("Implements Interface2"); }
    }
    private class RealClass1 extends Class1 {
        @Override
        void methodC1() { System.out.println("Implements Class1"); }
    }
    private class RealClass2 extends Class2 {
        @Override
        void methodC2() { System.out.println("Implements Class2"); }
    }
    private RealInterface i = new RealInterface();
    private RealClass1 c1 = new RealClass1();
    private RealClass2 c2 = new RealClass2();
    public void methodI1() { i.methodI1(); }
    public void methodI2() { i.methodI2(); }
    void methodC1() { c1.methodC1(); }
    void methodC2() { c2.methodC2(); }
    public static void main(String[] args) {
        Test1 t = new Test1();
        t.methodI1();
        t.methodI2();
        t.methodC1();
        t.methodC2();
    }
}
```

```java
/*
1.可以使用O类所有成员（包括private）
2.可以被static、private修饰（O类不可以）
3.可以匿名，但必须进行继承
4.可实例化，如果被static修饰：new O.I()；否则：new O().new I()  （O类引用.new I()）
5.不可在O类的导出类中被覆盖 (这点不像O类方法)
6.可被继承，但其指向O类的“秘密的”引用必须被初始化
 */
interface Anonymity {}
class Outer {
    Outer() {
        System.out.println("Outer()");
        new Inner1();
    }
    private String s = "Outer string s";
    public class Inner1 {
        Inner1() {
            System.out.println("Inner1()");
        }
        private String s = "Inner string s";
        void print() {
            System.out.println(s);
            //特性1
            System.out.println(Outer.this.s);
        }
    }
    //特性2
    private static class Inner2 {}
    public static class StaticInner {
        StaticInner() {
            System.out.println("StaticInner()");
        }
    }
    public Anonymity getAnonumityClass() {
        //特性3
        return new Anonymity() {
            {
                System.out.println("AnonymityClass()");
            }
        };
    }
}
class ExtendsOuter extends Outer{
    //特性5
    ExtendsOuter() {
/*  ==    super();
    ==    System.out.println("Outer()");
     +      new Inner1();
*/  }
    public class Inner1 {
        Inner1() {
            System.out.println("ExtendsOuter.Inner1()");
        }
    }
    //特性6特例
    //因为ExtendsOuter已经继承了Outer
    //从而指向外围类(Outer)的“秘密的”的引用已经通过继承关系(ExtendsOuter extends Outer)进行了初始化
    //所以不必再进行“特殊处理”
    public class ExtendsInner1 extends Outer.Inner1 {
        ExtendsInner1() {
            System.out.println("ExtendsOuter.ExtendsInner1()");
        }
    }
}
public class Test1 {
    //特性6
    public class ExtendsInner2 extends Outer.Inner1 {
        ExtendsInner2() {
            new Outer().super();
            System.out.println("Test1.ExtendsOuter2()");
        }
        ExtendsInner2(Outer outer) {
            outer.super();
            System.out.println("Test1.ExtendsOuter2(Outer outer)");
        }
    }
    public static void main(String[] args) {
        Test1 t = new Test1();
        //特性4
        new Outer().new Inner1();
        new Outer.StaticInner();
        //特性5
        new ExtendsOuter();
    }
}
```
