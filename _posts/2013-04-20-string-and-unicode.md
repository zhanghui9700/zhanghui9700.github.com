---
layout: post
title: python2.7 string vs unicode
category : python
tags : [python, string, unicode]
---

{% include JB/setup %}

### exception

{% highlight python %}
    "你好".encode("utf8")
    Traceback (most recent call last):
    File "<stdin>", line 1, in <module>
    UnicodeDecodeError: 'ascii' codec can't decode byte 0xe4 in
    position 0: ordinal not in range(128)
{% endhighlight %}

>`"你好".encode('utf-8')` <br />
>encode converts a unicode object to a string object. But here you have invoked it on a string object (because you don't have the u). <br />
>So python has to convert the string to a unicode object first. So it does the equivalent of
> `"你好".decode().encode('utf-8')` <br />
>But the decode fails because the string isn't valid ascii. That's why you get a complaint about not being able to decode.

>"你好" 的编码有外部文本环境决定 例如 # -\*- coding: utf-8 -\*- 则 编码为'utf8',而此时系统编码为默认的ascii, </br>
>所以第一步 utf8-->ascii 编码肯定会错误的。。


### ASCII
> `man ascii`

    For convenience, let us give more compact tables in hex and decimal.

          2 3 4 5 6 7       30 40 50 60 70 80 90 100 110 120
        -------------      ---------------------------------
       0:   0 @ P ` p     0:    (  2  <  F  P  Z  d   n   x
       1: ! 1 A Q a q     1:    )  3  =  G  Q  [  e   o   y
       2: " 2 B R b r     2:    *  4  >  H  R  \  f   p   z
       3: # 3 C S c s     3: !  +  5  ?  I  S  ]  g   q   {
       4: $ 4 D T d t     4: "  ,  6  @  J  T  ^  h   r   |
       5: % 5 E U e u     5: #  -  7  A  K  U  _  i   s   }
       6: & 6 F V f v     6: $  .  8  B  L  V  `  j   t   ~
       7: ´ 7 G W g w     7: %  /  9  C  M  W  a  k   u  DEL
       8: ( 8 H X h x     8: &  0  :  D  N  X  b  l   v
       9: ) 9 I Y i y     9: ´  1  ;  E  O  Y  c  m   w
       A: * : J Z j z
       B: + ; K [ k {
       C: , < L \ l |
       D: - = M ] m }
       E: . > N ^ n ~
       F: / ? O _ o DEL


### UNICODE

![img](https://raw.github.com/acmerfight/insight_python/master/images/code.png "unicode charset")





### 参考
[字符编码简介](https://github.com/acmerfight/insight_python/blob/master/Unicode_and_Character_Sets.md) <br >
[中文编码问题](https://github.com/xiyoulaoyuanjia/blog/blob/master/python%20%E7%BC%96%E7%A0%81%E9%97%AE%E9%A2%98.md) <br />
[字符集和字符编码](http://www.cnblogs.com/skynet/archive/2011/05/03/2035105.html ) <br />
[python里的string和unicode](http://blog.csdn.net/ktb2007/article/details/3876436) <br />
