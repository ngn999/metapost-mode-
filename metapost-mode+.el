;;; metapost-mode+.el --- Drawing with metapost interactively in Emacs

;; Author: Yu LI <liyu1981@gmail.com>
;; Maintainer: Yu LI <liyu1981@gmail.com>
;; Keywords: metapost
;; Version: <2007-10-06 Sat 16:14>

;; This file is NOT part of GNU Emacs. 
;; This file is licensed under GPLv2.

;;; Requirements:

;; metapost-mode.el and doc-view.el, which are part of GNU Emacs 22.1
;; or newer.  You also need `epstopdf', which comes with TeXLive

;;; Commentary:


;;; Configuration:

;; Basically metapost-mode+ should be quite usable with its standard settings, so
;; putting
;;
;;     (require 'metapost-mode+)
;;
;; into your `user-init-file' should be enough.  If the images are too small or
;; too big you should set the "-rXXX" option in `doc-view-ghostscript-options'
;; to another value.  (The bigger your screen, the higher the value.)
;;
;; This and all other options can be set with the customization interface.
;; Simply do
;;
;;     M-x customize-group RET doc-view RET
;;
;; and modify them to your needs.

;;; Code:

;;(require 'metapost-mode)
(require 'doc-view)

;;;; Customization Options

;;;; Internal Variables

(defvar metapost-mode+-prog-mpost
  (executable-find "mpost")
  "The mpost executable path.")

(defvar metapost-mode+-prog-epstopdf
  (executable-find "epstopdf")
  "The epstopdf executable path.")

(defvar metapost-mode+-current-source-buffer
  "The working source buffer.")

;;;; metapost-mode+ Keymap

(add-hook 'metapost-mode-hook
          (lambda ()
            (define-key meta-mode-map "\C-c\C-c" 'metapost-next)))

;;;;

(defun metapost-compile-buffer ()
  "Compile current buffer with Metapost."
  ;; (interactive)
  (setq curbuf-fname (shell-quote-argument buffer-file-name))
  (call-process metapost-mode+-prog-mpost
                nil
                (concat "*Metapost:" (file-name-nondirectory curbuf-fname) " *")
                nil
                curbuf-fname))

(defun metapost-prepare-preview-buffer (buffer-name)
  (let* ((old-buffer (get-buffer (concat "* Metapost-preview: " buffer-name " *"))))
    (and old-buffer
         (quit-window t old-buffer)))
  (get-buffer-create (concat "* Metapost-preview: " buffer-name " *")))

(defun metapost-preview ()
  "View current figure."
  ;; (interactive)
  (let* ((prog-epstopdf metapost-mode+-prog-epstopdf)
         (curbuf-fname (shell-quote-argument buffer-file-name))
         (curbuf-fname-nodir (file-name-sans-extension (file-name-nondirectory curbuf-fname)))
         (curbuf-dir (file-name-directory curbuf-fname))
         (curbuf-figure-name (concat curbuf-fname-nodir ".1"))
         (preview-buffer (metapost-prepare-preview-buffer (file-name-nondirectory curbuf-fname))))
    (if (= 0 (call-process prog-epstopdf
                           curbuf-figure-name
                           preview-buffer
                           nil
                           ;; args
                           "-f"))
        (progn (setq metapost-mode+-current-source-buffer (current-buffer)) 
               (switch-to-buffer-other-window preview-buffer)
               (set-buffer-file-coding-system 'raw-text)
               (doc-view-mode)
               (switch-to-buffer-other-window metapost-mode+-current-source-buffer)))))

(defun metapost-next ()
  (interactive)
  (if (or (not (buffer-modified-p))
          (and (buffer-modified-p)
               (y-or-n-p (format "Save %s to preview the figure?" (buffer-file-name)))))
      (if (metapost-compile-buffer)
          (metapost-preview)
        (message (concat "Metapost compile of " curbuf-fname " FAILED.")))))
