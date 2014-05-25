helm-etags+.el
=============
  This package use 'helm' as an interface to find tag with Etags.
  it support multiple tag files.

  (setq tags-table-list '("/path/of/TAGS1"    "/path/of/TAG2"))

  and it can search parent directory recursively for a file named
  'TAGS'. so you needn't add this special file to 'tags-table-list'

ctags-update.el
=============
    (auto) update TAGS using exuberant-ctags

       (autoload 'turn-on-ctags-auto-update-mode "ctags-update" "turn on 'ctags-auto-update-mode'." t)
       (add-hook 'c-mode-common-hook  'turn-on-ctags-auto-update-mode)
        ...
       (add-hook 'emacs-lisp-mode-hook  'turn-on-ctags-auto-update-mode)

       (autoload 'ctags-update "ctags-update" "update TAGS using ctags" t)
       (global-set-key "\C-cE" 'ctags-update)
       
   with prefix 'C-u' ,then you can generate a new TAGS file in your selected directory,
   with prefix 'C-uC-u' same to prefix 'C-u',but save it to kill-ring instead of execute it."


   when you save a file ,'ctags-auto-update-mode' will recursively searches each
   parent directory for a file named 'TAGS'. if found ,it will use
   'exuberant-ctags' update TAGS.
   
   it would not be updated if last time calling 'ctags-update' is not 5 minute age(default).
   
   if no 'TAGS' found ,it will check 'tags-table-list' and 'tags-file-name'
   if current buffer shares the same parent directory with 'tags-file-name'
   or one element of 'tags-table-list', it will auto create 'TAGS' file .


anything and helm
================
anything.el has been renamed to helm.el .

  - https://github.com/emacs-helm/helm.

so I renamed anything-etag-plus to helm-etag-plus,and new repos
will be https://github.com/jixiuf/helm-etags-plus
