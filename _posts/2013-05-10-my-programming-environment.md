---
layout: post
title: my python programming environment
category: life
tags: [linux, python]
---


##### 公司用的是台式机，安装ubuntu12.04
**uname -a**
`Linux zhanghui-pc 3.2.0-32-generic #51-Ubuntu SMP Wed Sep 26 21:33:09 UTC 2012 x86_64 x86_64 x86_64 GNU/Linux`

**cat /etc/lsb-release** <br />
`DISTRIB_ID=Ubuntu` <br />
`DISTRIB_RELEASE=12.04` <br />
`DISTRIB_CODENAME=precise` <br />
`DISTRIB_DESCRIPTION="Ubuntu 12.04.2 LTS"` <br />

**tmux**
`sudo apt-get install tmux` <br />
[\[tmux\]](http://tmux.sourceforge.net/)

**terminator**
`sudo apt-get install terminator`
> 设置teminator自动启动tmux <br/>
> terminaor preferences -> profiles -> command -> run a custome command instead of my shell -> `([[ -f "$TMUX" ]] && tmux -2 -S $TMUX) || (TMUX="" tmux -2)`

**zsh**
`sudo apt-get install zsh`
> sudo chsh
> 输入: /bin/zsh 回车
[我的zsh配置](https://github.com/zhanghui9700/pykit/blob/develop/zshrc)

**git**
`sudo apt-get install git`

**vim**
`sudo apt-get install vim` <br />
[我的vim配置](https://github.com/zhanghui9700/pykit/blob/develop/vimrc)
{% highlight python %}
    call pathogen#helptags() " generate helptags for everything in 'runtimepath'
    filetype plugin indent on

    syntax on
    set tabstop=4
    set softtabstop=4
    set shiftwidth=4
    set nu
    set autoindent
    set smartindent
    set expandtab
    set mouse=nv
    set cursorline

    set list
    set listchars=tab:>-,trail:<

    autocmd FileType c set expandtab
    autocmd FileType python set expandtab

    set hlsearch
    set statusline=[%n]\ %f%m%r%h\ %=\|\ %l,%c\ %p%%\ \|\ %{((&fenc==\"\")?\"\":\"\ \".&fenc)}\ \|\ %{hostname()}
{% endhighlight %}

**配置jedi-vim** [jedi-vim](https://github.com/davidhalter/jedi-vim) <br />
安装pathoge
{%highlight python%}
    mkdir -p ~/.vim/autoload ~/.vim/bundle;
    curl -Sso ~/.vim/autoload/pathogen.vim https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim
{%endhighlight%}

编辑vimrc，添加到文件头部。
{% highlight python %}
    " Pathogen
    execute pathogen#infect()
    call pathogen#helptags() " generate helptags for everything in 'runtimepath'
    syntax on
    filetype plugin indent on
{% endhighlight %}
安装jedi
{% highlight python %}
    sudo pip install jedi
    cd ~/.vim/bundle
    git clone https://github.com/davidhalter/jedi-vim.git
{% endhighlight %}

配置完成jedi后通过vim写代码就可以有只能提示了，默认是通过.和ctrl+space的方式呼出。
不过对于在桌面系统的coder来说ctrl+space默认是切换输入法，所以编辑.vimrc修改默认jedi快捷键。 <br />
`let g:jedi#autocompletion_command = "<C-j>"`

---
现在基本可以用vim来流畅的写python代码了，如果愿意的话可以再给vim装点插件代码高亮之类，视个人爱好折腾。
