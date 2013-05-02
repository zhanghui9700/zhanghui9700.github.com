---
layout: post
category: life
title: how to use markdown
tags: [markdown]
---

{% include JB/setup %}

### 1.段落
使用一个或多个空行分隔内容段来生成段落 &lt;p&gt; <br />
段内换行需要手动添加&lt;br /&gt;

this is first paragraph,
    fuck great firewall<br />
    fuck great firewall

this is second paragraph


this is third paragraph

### 2.标题
标题（h1~h6）格式为使用相应个数的“#”作前缀，比如以下代码表示：

# this is a level-1 header
## this is a level-2 header
### this is a level-3 header
#### this is a level-4 header
##### this is a level-5 header
###### this is a level-6 header
####### this is a level-7 header (support max # length is 6)

### 3.引用
使用“>”作为段落前缀来标识引用文字段落。这其实是 email 中标记引用文字的标准方式：

>引用的内容 <br />
>>这个记号直接借鉴的邮件标准,可以嵌套引用内容

### 4.列表
使用“\*”“+”“-”来表示无序列表；使用数字加“\.”表示有序列表。如：

* first
* second
* third

---
+ first
+ second
+ third

---
- first
- second
- third

---
1.  first
2.  second
3.  third

### 5.转义段落
使用 4 个以上 空格或 1 个以上 的 tab 来标记代码段落，它们将被
&lt;pre&gt; 和 &lt;code&gt; 包裹，这意味着代码段内的字体会是 monospace
家族的，并且特殊符号不会被转义。

{% highlight js %}
    //this is a monospace paragraph
    <script type="text/javascript">
    $(document).ready(function(){
        console.log("hello world!");
    });
    </script>
{% endhighlight %}

### 6.图片和链接
使用[www.google.com](https://www.google.com "mouse over title")来标记普通链接。

    使用[www.google.com](https://www.google.com "mouse over title")来标记普通链接。


使用 ![img](http://img.hb.aicdn.com/189331a13a653f1b69e266ece9214e9f7aaf969612cc-8XQ4H6_sq75 "mouse over title") 来标记图片。 <br />
引号内的 title 文字是可选的，链接也可以使用相对路径。

    使用 ![img](http://img.hb.aicdn.com/189331a13a653f1b69e266ece9214e9f7aaf969612cc-8XQ4H6_sq75 "mouse over title") 来标记图片。

### 7. 强调字体
使用 * 或 _ 包裹文本产生 strong 效果：

*你是什么意思，我想上人人网。*
>\*你是什么意思，我想上人人网。\*

_你是什么意思，我想上人人网。_
>\_你是什么意思，我想上人人网。\_

__你是什么意思，我想上人人网。__
>\_\_你是什么意思，我想上人人网。\_\_

<b>你是什么意思，我想上人人网。</b>
>\*\*你是什么意思，我想上人人网。\*\*

### 8.CODE

this is inline code. `javascript:$(this).html("clicked.");`

> this is inline code. \`javascript:$(this).html("clicked.");\`

this is code block

{% highlight python %}
    import sys
    import os
    import unittest

    if __name__ == '__main__':
        main_test.run()
{% endhighlight %}
