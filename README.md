# gomotion.vim 

A plugin that navigates you through Go declarations: functions, structures, interfaces
## Prerequisites
Go installed and env set up:
```
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
```

[Motion](https://github.com/fatih/motion) that is an engine for plugin:
```
go get github.com/fatih/motion
```
[fzf.vim](https://github.com/junegunn/fzf.vim)
Using [vim-plug](https://github.com/junegunn/vim-plug)
```
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
```

## Installation
Using vim-plug
```
Plug 'sergii4/gomotion.vim'

```

## Using
In vim:
```
:GoDecls
```

[![asciicast](https://asciinema.org/a/517745.svg)](https://asciinema.org/a/517745)
