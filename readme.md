> [!NOTE]
> I no longer use Helm, and the code in this repository hasn't been changed for several years.
#  Etags helm.el interface
[![MELPA](http://melpa.org/packages/helm-etags-plus-badge.svg)](http://melpa.org/#/helm-etags-plus)


The easiest way to get started is to install the package via [MELPA][melpa]:

 [melpa]: http://melpa.org/

```elisp
(package-install 'helm-etags-plus)
```
it support multiple tag files.

    (setq tags-table-list '("/path/of/TAGS1"    "/path/of/TAG2"))

  if there is a TAG in the root of project
  you needn't add this special file to 'tags-table-list'
   
     (require 'helm-etags-plus)
     (global-set-key "\M-." 'helm-etags-plus-select)

 M-. default use symbol under point as tagname
 C-uM-. use pattern you typed as tagname

## Go back and forward
    ;;list all visited tags
    (global-set-key "\M-*" 'helm-etags-plus-history)
    ;;go back directly
    (global-set-key "\M-," 'helm-etags-plus-history-go-back)
    ;;go forward directly
    (global-set-key "\M-/" 'helm-etags-plus-history-go-forward)
  
  
 if you want to use [bm.el](https://github.com/joodland/bm) for navigating history,you could

        (setq bm-in-lifo-order t)

        (autoload 'bm-bookmark-add "bm" "add bookmark")
        
        (add-hook 'helm-etags-plus-before-jump-hook 'bm-bookmark-add)
        ;;or
        (add-hook 'helm-etags-plus-before-jump-hook '(lambda()(bm-bookmark-add nil nil t)))
        ;Auto remove bookmark after jump to it by bm-next or bm-previous

 then use bm-previous bm-next to jump 

##   Integration with etags-table.el

    (require 'etags-table)
    (setq etags-table-alist
            (list
            '("/home/me/Projects/foo/.*\\.[ch]$" "/home/me/Projects/lib1/TAGS" "/home/me/Projects/lib2/TAGS")
            '("/home/me/Projects/bar/.*\\.py$" "/home/me/Projects/python/common/TAGS")
            '("/tmp/.*\\.c$"  "/java/tags/linux.tag" "/tmp/TAGS" )
            '(".*\\.java$"  "/opt/sun-jdk-1.6.0.22/src/TAGS" )
            '(".*\\.[ch]$"  "/java/tags/linux.ctags")
            ))
    (add-hook 'helm-etags-plus-select-hook 'etags-table-recompute)
     


# ctags-update.el 
   moved to https://github.com/jixiuf/ctags-update
