;;; helm-etags+.el --- Another Etags helm.el interface

;; Created: 2011-02-23
;; Last Updated: Joseph 2012-09-30 01:18:31 星期日
;; Version: 0.1.5
;; Author: 纪秀峰(Joseph) <jixiuf@gmail.com>
;; Copyright (C) 2011~2012, 纪秀峰(Joseph), all rights reserved.
;; URL       :https://github.com/jixiuf/helm-etags-plus
;; screencast:http://screencast-repos.googlecode.com/files/emacs-anything-etags-puls.mp4.bz2
;; Keywords: helm, etags
;; Compatibility: (Test on GNU Emacs 23.2.1)
;;
;; Features that might be required by this library:
;;
;; `helm' `etags'
;;
;;
;;; This file is NOT part of GNU Emacs

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; This package use `helm' as an interface to find tag with Etags.
;;
;;  it support multiple tag files.
;;  and it can recursively searches each parent directory for a file named
;;  'TAGS'. so you needn't add this special file to `tags-table-list'
;;
;;  if you use GNU/Emacs ,you can set `tags-table-list' like this.
;;  (setq tags-table-list '("/path/of/TAGS1" "/path/of/TAG2"))
;;
;;  (global-set-key "\M-." 'helm-etags+-select-one-key)
;;       `M-.' call  helm-etags+-select-at-point
;;       `C-uM-.' call helm-etags+-select
;;
;; helm-etags+.el also support history go back ,go forward and list tag
;; histories you have visited.(must use commands list here:)
;;  `helm-etags+-history'
;;    List all tag you have visited with `helm'.
;;  `helm-etags+-history-go-back'
;;    Go back cyclely.
;;  `helm-etags+-history-go-forward'
;;    Go Forward cyclely.
;;
;; if you want to work with `etags-table.el' ,you just need
;; add this line to to init file after loading etags-table.el
;;
;;     (add-hook 'helm-etags+-select-hook 'etags-table-recompute)
;;    (setq etags-table-alist
;;     (list
;;        '("/home/me/Projects/foo/.*\\.[ch]$" "/home/me/Projects/lib1/TAGS" "/home/me/Projects/lib2/TAGS")
;;        '("/home/me/Projects/bar/.*\\.py$" "/home/me/Projects/python/common/TAGS")
;;        '(".*\\.[ch]$" "/usr/local/include/TAGS")
;;        ))
;;
;;; Installation:
;;
;; Just put helm-etags+.el to your load-path.
;; The load-path is usually ~/elisp/.
;; It's set in your ~/.emacs like this:
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;;
;; And the following to your ~/.emacs startup file.
;;
;; (require 'helm-etags+)
;;
;; No need more.
;;
;; I use GNU/Emacs,and this is my config file about etags
;; (require 'helm-etags+)
;; (setq helm-etags+-use-short-file-name nil)
;; ;;you can use  C-uM-. input symbol (default thing-at-point 'symbol)
;; (global-set-key "\M-." 'helm-etags+-select-one-key)
;; ;;list all visited tags
;; (global-set-key "\M-*" 'helm-etags+-history)
;; ;;go back directly
;; (global-set-key "\M-," 'helm-etags+-history-action-go-back)
;; ;;go forward directly
;; (global-set-key "\M-/" 'helm-etags+-history-action-go-forward)
;;
;; and how to work with etags-table.el
;; (require 'etags-table)
;; (setq etags-table-alist
;;       (list
;;        '("/home/me/Projects/foo/.*\\.[ch]$" "/home/me/Projects/lib1/TAGS" "/home/me/Projects/lib2/TAGS")
;;        '("/home/me/Projects/bar/.*\\.py$" "/home/me/Projects/python/common/TAGS")
;;        '("/tmp/.*\\.c$"  "/java/tags/linux.tag" "/tmp/TAGS" )
;;        '(".*\\.java$"  "/opt/sun-jdk-1.6.0.22/src/TAGS" )
;;        '(".*\\.[ch]$"  "/java/tags/linux.ctags")
;;        ))
;; (add-hook 'helm-etags+-select-hook 'etags-table-recompute)

;;; Commands:
;;
;; Below are complete command list:
;;
;;  `helm-etags+-select'
;;    Tag jump using etags and `helm'.
;;  `helm-etags+-select-at-point'
;;    Tag jump with current symbol using etags and `helm'.
;;  `helm-etags+-select-one-key'
;;    you can bind this to `M-.'
;;  `helm-etags+-history-go-back'
;;    Go Back.
;;  `helm-etags+-history-go-forward'
;;    Go Forward.
;;  `helm-etags+-history'
;;    show all tag historys using `helm'
;;
;;; Customizable Options:
;;
;; Below are customizable option list:
;;
;;  `helm-etags+-use-short-file-name'
;;    t means use filename,
;;    default = nil
;;  `helm-etags+-filename-location'
;;    display src filename after src file name parent dir or not.
;;    default = (quote filename-after-dir)
;;  `helm-etags+-highlight-tag-after-jump'
;;    *If non-nil, temporarily highlight the tag
;;    default = t
;;  `helm-etags+-highlight-delay'
;;    *How long to highlight the tag.
;;    default = 0.2

;;; Code:

;; Some functions are borrowed from helm-etags.el and etags-select.el.

;;; Require
;; (require 'custom)
(require 'etags)
(require 'helm)
;; (require 'helm-config nil t)        ;optional
(eval-when-compile
   (require 'helm-match-plugin nil t)
  )
;;  ;optional

;;; Custom

(defgroup helm-etags+ nil
  "Another Etags helm.el interface."
  :prefix "helm-etags+-"
  :group 'etags)

(defcustom helm-etags+-use-short-file-name nil
  "t means use filename,
  'absolute means use absolute filename
  nil means use relative filename as the display,
 search '(DISPLAY . REAL)' in helm.el for more info."
  :type '(choice (const nil) (const t) (const absolute))
  :group 'helm-etags+)

(defcustom helm-etags+-filename-location 'filename-after-dir
  "display src filename after src file name parent dir or not."
  :type '(choice (const filename-before-dir) (const filename-after-dir))
  :group 'helm-etags+)

(defcustom helm-etags+-highlight-tag-after-jump t
  "*If non-nil, temporarily highlight the tag
  after you jump to it.
  (borrowed from etags-select.el)"
  :group 'helm-etags+
  :type 'boolean)

(defcustom helm-etags+-highlight-delay 0.2
  "*How long to highlight the tag.
  (borrowed from etags-select.el)"
  :group 'helm-etags+
  :type 'number)

(defface helm-etags+-highlight-tag-face
  '((t (:foreground "white" :background "cadetblue4" :bold t)))
  "Font Lock mode face used to highlight tags.
  (borrowed from etags-select.el)"
  :group 'helm-etags+)

(defun helm-etags+-highlight (beg end)
  "Highlight a region temporarily.
   (borrowed from etags-select.el)"
  (let ((ov (make-overlay beg end)))
      (overlay-put ov 'face 'helm-etags+-highlight-tag-face)
      (sit-for helm-etags+-highlight-delay)
      (delete-overlay ov)))

;;; Hooks

(defvar helm-etags+-select-hook nil
  "hooks run before `helm' funcion with
   source `helm-c-source-etags+-select'")

;;; Variables
(defvar  helm-etags+-tag-marker-ring (make-ring 8))

(defvar helm-etags+-current-marker-in-tag-marker-ring nil
  "a marker in `helm-etags+-tag-marker-ring', going back and going
forward are related to this variable.")

;; (defvar helm-etags+-history-tmp-marker nil
;;   "this variable will remember current position
;;    when you call `helm-etags+-history'.
;;   after you press `RET' execute `helm-etags+-history-action'
;;  it will be push into `helm-etags+-tag-marker-ring'")
(defvar helm-etags+-tag-table-buffers nil
  "each time `helm-etags+-select' is executed ,it
will set this variable.")
(defvar helm-idle-delay-4-helm-etags+ 1.0
  "see `helm-idle-delay'. I will set it locally
   in `helm-etags+-select'")

(defvar previous-opened-buffer-in-persistent-action nil
  "record it to kill-it in persistent-action,in order to
   not open too much buffer.")

(defvar helm-etags+-previous-matched-pattern nil
  "work with `helm-etags+-candidates-cache'.
  the value is (car (helm-mp-make-regexps helm-pattern))
:the first part of `helm-pattern', the matched
 candidates is saved in `helm-etags+-candidates-cache'. when current
'(car (helm-mp-make-regexps helm-pattern))' is equals to this value
then the cached candidates can be reused ,needn't find from the tag file.")

(defvar helm-etags+-candidates-cache nil
  "documents see `helm-etags+-previous-matched-pattern'")
(defvar helm-etags+-untransformed-helm-pattern
  "this variable is seted in func of transformed-pattern .and is used when
getting candidates.")

;;; Functions

(defun helm-etags+-case-fold-search ()
  "Get case-fold search."
  (when (boundp 'tags-case-fold-search)
    (if (memq tags-case-fold-search '(nil t))
        tags-case-fold-search
      case-fold-search)))

(defun helm-etags+-find-tags-file ()
  "recursively searches each parent directory for a file named 'TAGS' and returns the
path to that file or nil if a tags file is not found. Returns nil if the buffer is
not visiting a file"
(let ((tag-root-dir (locate-dominating-file default-directory "TAGS")))
    (if tag-root-dir
        (expand-file-name "TAGS" tag-root-dir)
      nil)))

(defun helm-etags+-get-tag-files()
  "Get tag files."
  (let ((local-tag  (helm-etags+-find-tags-file)))
      (when local-tag
        (add-to-list 'tags-table-list (helm-etags+-find-tags-file)))
      (dolist (tag tags-table-list)
        (when (not (file-exists-p tag))
          (setq  tags-table-list (delete tag tags-table-list))))
      (mapcar 'tags-expand-table-name tags-table-list)))

(defun helm-etags+-rename-tag-file-buffer-maybe(buf)
  (with-current-buffer buf
    (if (string-match "^ \\*Helm" (buffer-name))
        buf
      (rename-buffer (concat" *Helm etags+:" (buffer-name) "*") t)
      ))buf)

(defun helm-etags+-get-tag-table-buffer (tag-file)
  "Get tag table buffer for a tag file."
  (when (file-exists-p tag-file)
    (let ((tag-table-buffer) (current-buf (current-buffer))
          (tags-revert-without-query t)
          (large-file-warning-threshold nil)
          (tags-add-tables t))

        (visit-tags-table-buffer tag-file)
        (setq tag-table-buffer (find-buffer-visiting tag-file))
      (set-buffer current-buf)
      (helm-etags+-rename-tag-file-buffer-maybe tag-table-buffer))))

(defun helm-etags+-get-available-tag-table-buffers()
  "Get tag table buffer for a tag file."
  (setq helm-etags+-tag-table-buffers
        (delete nil (mapcar 'helm-etags+-get-tag-table-buffer
                            (helm-etags+-get-tag-files)))))

(defun helm-etags+-get-candidates-with-cache-support()
  "for example when the `helm-pattern' is 'toString System pub'
   only 'toString' is treated as tagname,and
`helm-etags+-get-candidates-from-all-tag-file'
will search `toString' in all tag files. and the found
 candidates is stored in `helm-etags+-candidates-cache'
'toString' is stored in `helm-etags+-previous-matched-pattern'
so when the `helm-pattern' become to 'toString System public'
needn't search tag file again."
  (let ((pattern (car (helm-mp-make-regexps helm-etags+-untransformed-helm-pattern))));;default use whole helm-pattern to search in tag files
    ;; first collect candidates using first part of helm-pattern
    ;; (when (featurep 'helm-match-plugin)
    ;;   ;;for example  (helm-mp-make-regexps "boo far") -->("boo" "far")
    ;;   (setq pattern  (car (helm-mp-make-regexps helm-etags+-untransformed-helm-pattern))))
    (unless (string-equal helm-etags+-previous-matched-pattern pattern)
      ;;          (setq candidates helm-etags+-candidates-cache)
      (setq helm-etags+-candidates-cache (helm-etags+-get-candidates-from-all-tag-file pattern))
      (setq helm-etags+-previous-matched-pattern pattern))
    helm-etags+-candidates-cache))

(defun helm-etags+-get-candidates-from-all-tag-file(first-part-of-helm-pattern)
  (let (candidates)
    (dolist (tag-table-buffer helm-etags+-tag-table-buffers)
      (setq candidates
            (append
             candidates
             (helm-etags+-get-candidates-from-tag-file
              first-part-of-helm-pattern tag-table-buffer))))
    candidates))

(defun helm-etags+-get-candidates-from-tag-file (tagname tag-table-buffer)
  "find tagname in tag-table-buffer. "
  (catch 'failed
    (let ((case-fold-search (helm-etags+-case-fold-search))
          tag-info tag-line src-file-name full-tagname
          tag-regex
          tagname-regexp-quoted
          candidates)
      (if (string-match "\\\\_<\\|\\\\_>[ \t]*" tagname)
          (progn
            (setq tagname (replace-regexp-in-string "\\\\_<\\|\\\\_>[ \t]*" ""  tagname))
            (setq tagname-regexp-quoted (regexp-quote tagname))
            (setq tag-regex (concat "^.*?\\(" "\^?\\(.+[:.']"  tagname-regexp-quoted "\\)\^A"
                                    "\\|" "\^?"  tagname-regexp-quoted "\^A"
                                    "\\|" "\\<"  tagname-regexp-quoted "[ \f\t()=,;]*\^?[0-9,]"
                                    "\\)")))
        (setq tagname-regexp-quoted (regexp-quote tagname))
        (setq tag-regex (concat "^.*?\\(" "\^?\\(.+[:.'].*"  tagname-regexp-quoted ".*\\)\^A"
                                "\\|" "\^?.*"  tagname-regexp-quoted ".*\^A"
                                "\\|" ".*"  tagname-regexp-quoted ".*[ \f\t()=,;]*\^?[0-9,]"
                                "\\)")))
      (with-current-buffer tag-table-buffer
        (modify-syntax-entry ?_ "w")
        (goto-char (point-min))
        (while (search-forward  tagname nil t) ;;take care this is not re-search-forward ,speed it up
          (beginning-of-line)
          (when (re-search-forward tag-regex (point-at-eol) 'goto-eol)
            (setq full-tagname (or (match-string-no-properties 2) tagname))
            (beginning-of-line)
            (save-excursion (setq tag-info (etags-snarf-tag)))
            (re-search-forward "\\s-*\\(.*?\\)\\s-*\^?" (point-at-eol) t)
            (setq tag-line (match-string-no-properties 1))
            (setq tag-line (replace-regexp-in-string  "/\\*.*\\*/" "" tag-line))
            (setq tag-line (replace-regexp-in-string  "\t" (make-string tab-width ? ) tag-line))
            (end-of-line)
            ;;(setq src-file-name (etags-file-of-tag))
            (setq src-file-name   (file-truename (etags-file-of-tag)))
            (let ((display)(real (list  src-file-name tag-info full-tagname))
                  (src-location-display (file-name-nondirectory src-file-name)))
              (cond
               ((equal helm-etags+-use-short-file-name nil)
                (let ((tag-table-parent (file-truename (file-name-directory (buffer-file-name tag-table-buffer))))
                      (src-file-parent (file-name-directory src-file-name)))
                  (when (string-match  (regexp-quote tag-table-parent) src-file-name)
                    (if (equal 'filename-after-dir helm-etags+-filename-location)
                        (setq src-location-display (substring src-file-name (length  tag-table-parent)))
                      (setq src-location-display (concat src-location-display "\\"  (substring src-file-parent (length  tag-table-parent))))
                      ))))
               ((equal helm-etags+-use-short-file-name t)
                (setq src-location-display (file-name-nondirectory src-file-name)))
               ((equal helm-etags+-use-short-file-name 'absolute)
                (let ((src-file-parent (file-name-directory src-file-name)))
                  (if (equal 'filename-after-dir helm-etags+-filename-location)
                      (setq src-location-display src-file-name)
                    (setq src-location-display (concat src-location-display "\\"
                                                       (mapconcat 'identity (reverse (split-string src-file-parent "/")) "/" )))
                  )
                  )

                ))
              (setq display (concat tag-line
                                    (or (ignore-errors
                                          (make-string (- (window-width)
                                                          (string-width tag-line)
                                                          (string-width  src-location-display))
                                                       ? )) "")
                                    src-location-display))
              (add-to-list 'candidates (cons display real)))))
        (modify-syntax-entry ?_ "_"))
      candidates)))

(defun helm-etags+-find-tag(candidate)
  "Find tag that match CANDIDATE from `tags-table-list'.
   And switch buffer and jump tag position.."
  (let ((src-file-name (car candidate))
        (tag-info (nth 1 candidate))
        (tagname (nth 2 candidate))
        src-file-buf)
    (when (file-exists-p src-file-name)
      ;; Jump to tag position when
      ;; tag file is valid.
      (setq src-file-buf (find-file src-file-name))
      (etags-goto-tag-location  tag-info)

      (beginning-of-line)
      (when (search-forward tagname (point-at-eol) t)
        (goto-char (match-beginning 0))
        (setq tagname (thing-at-point 'symbol))
        (beginning-of-line)
        (search-forward tagname (point-at-eol) t)
        (goto-char (match-beginning 0))
        (when(and helm-etags+-highlight-tag-after-jump
                  (not helm-in-persistent-action))
          (helm-etags+-highlight (match-beginning 0) (match-end 0))))

      (when (and helm-in-persistent-action ;;color
                 (fboundp 'helm-match-line-color-current-line))
        (helm-match-line-color-current-line))

      (if helm-in-persistent-action ;;prevent from opening too much buffer in persistent action
          (progn
            (if (and previous-opened-buffer-in-persistent-action
                     (not (equal previous-opened-buffer-in-persistent-action src-file-buf)))
                (kill-buffer  previous-opened-buffer-in-persistent-action))
            (setq previous-opened-buffer-in-persistent-action src-file-buf))
        (setq previous-opened-buffer-in-persistent-action nil)))))

(defun helm-c-etags+-goto-location (candidate)
  (unless helm-in-persistent-action
    (when (and
           (not (ring-empty-p helm-etags+-tag-marker-ring))
           helm-etags+-current-marker-in-tag-marker-ring
           (not (equal helm-etags+-current-marker-in-tag-marker-ring (ring-ref helm-etags+-tag-marker-ring 0))))
      (while (not (ring-empty-p helm-etags+-tag-marker-ring ))
        (ring-remove helm-etags+-tag-marker-ring)
        ))
    ;;you can use `helm-etags+-history' go back
    (ring-insert helm-etags+-tag-marker-ring (point-marker))
    (setq helm-etags+-current-marker-in-tag-marker-ring (point-marker))
    )
  (helm-etags+-find-tag candidate);;core func.
  )

(defun helm-etags+-select-internal(init-pattern prompt)
  (run-hooks 'helm-etags+-select-hook)
  (helm '(helm-c-source-etags+-select)
            ;; Initialize input with current symbol
            init-pattern  prompt nil))

;;;###autoload
(defun helm-etags+-select()
  "Tag jump using etags and `helm'.
If SYMBOL-NAME is non-nil, jump tag position with SYMBOL-NAME."
  (interactive)
  (let ((helm-execute-action-at-once-if-one t)
        (helm-candidate-number-limit nil)
        (helm-idle-delay helm-idle-delay-4-helm-etags+))
    (helm-etags+-select-internal nil "Find Tag(require 3 char): ")))

;;;###autoload
(defun helm-etags+-select-at-point()
  "Tag jump with current symbol using etags and `helm'."
  (interactive)
  (let ((helm-execute-action-at-once-if-one t)
        (helm-candidate-number-limit nil)
        (helm-idle-delay 0))
    ;; Initialize input with current symbol
    (helm-etags+-select-internal
     (concat "\\_<" (thing-at-point 'symbol) "\\_> ")
             ;; (if (featurep 'helm-match-plugin) " ")
     "Find Tag: ")))

;;;###autoload
(defun helm-etags+-select-one-key (&optional args)
  "you can bind this to `M-.'"
  (interactive "P")
  (if args
      (helm-etags+-select)
    (helm-etags+-select-at-point)))

;;;###autoload
(defvar helm-c-source-etags+-select
  '((name . "Etags+")
    (init . helm-etags+-get-available-tag-table-buffers)
    (candidates . helm-etags+-get-candidates-with-cache-support)
    (volatile);;candidates
    (pattern-transformer (lambda (helm-pattern)
                           (setq helm-etags+-untransformed-helm-pattern helm-pattern)
                           (regexp-quote (replace-regexp-in-string "\\\\_<\\|\\\\_>" ""  helm-pattern))))
    (requires-pattern  . 3);;need at least 3 char
    (delayed);; (setq helm-idle-delay-4-anthing-etags+ 1)
    (action ("Goto the location" . helm-c-etags+-goto-location))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Go Back and Go Forward

;;util func

;;(helm-etags+-is-marker-avaiable (ring-ref helm-etags+-tag-marker-ring 0))
(defun helm-etags+-is-marker-available(marker)
  "return nil if marker is nil or  in dead buffer ,
   return marker if it is live"
  (if (and marker
           (markerp marker)
           (marker-buffer marker))
      marker
    ))
;;; func about history
(defun helm-etags+-history-get-candidate-from-marker(marker)
  "genernate candidate from marker candidate= (display . marker)."
  (let ((buf (marker-buffer marker))
        (pos (marker-position marker))
        line-num line-text candidate display
        file-name empty-string)
    (when  buf
      ;;      (save-excursion
      ;;        (set-buffer buf)
      (with-current-buffer buf
        (setq file-name  (buffer-name))
        (goto-char pos)
        (setq line-num (int-to-string (count-lines (point-min) pos)))
        (setq line-text (buffer-substring-no-properties (point-at-bol)(point-at-eol)))
        (setq line-text (replace-regexp-in-string "^[ \t]*\\|[ \t]*$" "" line-text))
        (setq line-text (replace-regexp-in-string  "/\\*.*\\*/" "" line-text))
        (setq line-text (replace-regexp-in-string  "\t" (make-string tab-width ? ) line-text)))
      ;;          )
      (if (equal marker helm-etags+-current-marker-in-tag-marker-ring)
          ;;this one will be preselected
          (setq line-text (concat line-text "\t")))
      (setq empty-string  (or (ignore-errors
                                (make-string (- (window-width) 4
                                                (string-width  line-num)
                                                (string-width file-name)
                                                (string-width line-text))
                                             ? )) " "))
      (setq display (concat line-text empty-string
                            file-name ":[" line-num "]"))
      (setq candidate  (cons display marker)))))

;;(helm-etags+-history-get-candidate-from-marker (ring-remove (ring-copy helm-etags+-tag-marker-ring)))
;; (ring-remove )
;; (ring-length helm-etags+-tag-marker-ring)
;; (helm-etags+-history-get-candidates)
;; time_init
(defun helm-etags+-history-candidates()
  "generate candidates from `helm-etags+-tag-marker-ring'.
  and remove unavailable markers in `helm-etags+-tag-marker-ring'"
  (let ((candidates (mapcar 'helm-etags+-history-get-candidate-from-marker (ring-elements helm-etags+-tag-marker-ring))))
    ;; (when helm-etags+-history-tmp-marker
    ;;   (setq candidates (append (list (helm-etags+-history-get-candidate-from-marker helm-etags+-history-tmp-marker)) candidates)))
    candidates))

(defun helm-etags+-history-init()
  "remove #<marker in no buffer> from `helm-etags+-tag-marker-ring'.
   and remove those markers older than #<marker in no buffer>."
  (let ((tmp-marker-ring))
    (while (not (ring-empty-p helm-etags+-tag-marker-ring))
      (helm-aif (helm-etags+-is-marker-available (ring-remove helm-etags+-tag-marker-ring 0))
          (setq tmp-marker-ring (append tmp-marker-ring (list it)));;new item first
        (while (not (ring-empty-p helm-etags+-tag-marker-ring));;remove all old marker
          (ring-remove helm-etags+-tag-marker-ring))))
    ;;reinsert all available marker to `helm-etags+-tag-marker-ring'
    (mapcar (lambda(marker) (ring-insert-at-beginning helm-etags+-tag-marker-ring marker)) tmp-marker-ring))
  ;; (when (not (ring-empty-p helm-etags+-tag-marker-ring))
  ;;   (let ((last-marker-in-helm-etags+-tag-marker-ring (ring-ref  helm-etags+-tag-marker-ring 0)))
  ;;     (when (and (equal helm-etags+-current-marker-in-tag-marker-ring  last-marker-in-helm-etags+-tag-marker-ring)
  ;;                (or (not (equal (marker-buffer last-marker-in-helm-etags+-tag-marker-ring) (current-buffer)))
  ;;                    (> (abs (- (marker-position last-marker-in-helm-etags+-tag-marker-ring) (point))) 350)))
  ;;       (setq helm-etags+-history-tmp-marker (point-marker)))))
  )

(defun helm-etags+-history-clear-all(&optional candidate)
  "param `candidate' is unused."
  (while (not (ring-empty-p helm-etags+-tag-marker-ring));;remove all marker
    (ring-remove helm-etags+-tag-marker-ring)))


;;;###autoload
(defun helm-etags+-history-go-back()
  "Go Back."
  (interactive)
  (helm-etags+-history-init)
  (when (and
         (helm-etags+-is-marker-available helm-etags+-current-marker-in-tag-marker-ring)
         (ring-member helm-etags+-tag-marker-ring helm-etags+-current-marker-in-tag-marker-ring))
    (let* ((next-marker (ring-next helm-etags+-tag-marker-ring helm-etags+-current-marker-in-tag-marker-ring)))
      (helm-etags+-history-go-internel next-marker)
      (setq helm-etags+-current-marker-in-tag-marker-ring next-marker))))

;;;###autoload
(defun helm-etags+-history-go-forward()
  "Go Forward."
  (interactive)
  (helm-etags+-history-init)
  (when (and
         (helm-etags+-is-marker-available helm-etags+-current-marker-in-tag-marker-ring)
         (ring-member helm-etags+-tag-marker-ring helm-etags+-current-marker-in-tag-marker-ring))
    (let* ((previous-marker (ring-previous helm-etags+-tag-marker-ring helm-etags+-current-marker-in-tag-marker-ring)))
      (helm-etags+-history-go-internel previous-marker)
      (setq helm-etags+-current-marker-in-tag-marker-ring previous-marker))))

(defun helm-etags+-history-go-internel (candidate-marker)
  "Go to the location depend on candidate."
  (let ((buf (marker-buffer candidate-marker))
        (pos (marker-position candidate-marker)))
    (when buf
      (switch-to-buffer buf)
      (set-buffer buf)
      (goto-char pos))))

;; (action .func),candidate=(Display . REAL), now in this func
;; param candidate is 'REAL' ,the marker.
(defun helm-etags+-history-action-go(candidate)
  "List all history."
  (helm-etags+-history-go-internel candidate)
  (unless  helm-in-persistent-action
    (setq helm-etags+-current-marker-in-tag-marker-ring candidate)
    ;; (when helm-etags+-history-tmp-marker
    ;;   (ring-insert helm-etags+-tag-marker-ring helm-etags+-history-tmp-marker)
    ;;   (setq helm-etags+-history-tmp-marker nil))
    )
  (when (and helm-in-persistent-action ;;color
             (fboundp 'helm-match-line-color-current-line))
    (helm-match-line-color-current-line)))

(defvar helm-c-source-etags+-history
  '((name . "Etags+ History: ")
    (header-name .( (lambda (name) (concat name "`RET': Go ,`C-z' Preview. `C-e': Clear all history."))))
    (init .  helm-etags+-history-init)
    (candidates . helm-etags+-history-candidates)
    ;;        (volatile) ;;maybe needn't
    (action . (("Go" . helm-etags+-history-action-go)
               ("Clear all history" . helm-etags+-history-clear-all)))))

;;;###autoload
(defun helm-etags+-history()
  "show all tag historys using `helm'"
  (interactive)
  (let ((helm-execute-action-at-once-if-one t)
        (helm-quit-if-no-candidate
         (lambda () (message "No history record in `helm-etags+-tag-marker-ring'"))))
    (helm '(helm-c-source-etags+-history)
              ;; Initialize input with current symbol
              ""  nil nil "\t")))

(provide 'helm-etags+)
;;;helm-etags+.el ends here.
