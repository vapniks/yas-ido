;;; yas-ido.el --- Access yas snippets using ido

;; Filename: yas-ido.el
;; Description: Access yas snippets using ido
;; Author: Joe Bloggs <vapniks@yahoo.com>
;; Maintainer: Joe Bloggs <vapniks@yahoo.com>
;; Copyleft (Ↄ) 2015, Joe Bloggs, all rites reversed.
;; Created: 2015-08-29 15:00:00
;; Version: 0.1
;; Last-Updated: 2015-08-29 15:00:00
;;           By: Joe Bloggs
;; URL: https://github.com/vapniks/yas-ido
;; Keywords: convenience
;; Compatibility: GNU Emacs 24.5.1
;; Package-Requires: ((yasnippet "0.8.0beta"))
;;
;; Features that might be required by this library:
;;
;; yasnippet

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
;; along with this program; see the file COPYING.
;; If not, see <http://www.gnu.org/licenses/>.

;;; Commentary: 
;;
;; This package contains a couple of commands for using yasnippets with `ido'.
;;
;; Bitcoin donations gratefully accepted: 1ArFina3Mi8UDghjarGqATeBgXRDWrsmzo
;;
;;;;

;;; Commands:
;;
;; Below are complete command list:
;;
;; `yas-ido-expand-snippet'
;;   Select snippet using ido and expand it. 
;; `yas-ido-edit-snippet'
;;   Select snippet using ido and edit it.
;;;;

;;; Installation:
;;
;; Put yas-ido.el in a directory in your load-path, e.g. ~/.emacs.d/
;; You can add a directory to your load-path with the following line in ~/.emacs
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;; where ~/elisp is the directory you want to add 
;; (you don't need to do this for ~/.emacs.d - it's added by default).
;;
;; Add the following to your ~/.emacs startup file.
;;
;; (require 'yas-ido)

;;; Require
(require 'ido)

;;; Code:

(defun yas-ido-expand-snippet (location)
  "Select yasnippet using ido and expand it.
When called non-interactively expand snippet in file at LOCATION."
  (interactive (let* ((topdir yas/root-directory)
                      (dirpathslist (get-subdirs topdir 5))
                      (dirnameslist (mapcar 'file-name-nondirectory dirpathslist))
                      (chosendirname (ido-completing-read "Snippets folder: " dirnameslist nil t))
                      (numdirnames (length dirnameslist))
                      (afterdirnameslist (member chosendirname dirnameslist))
                      (posindirlist (- numdirnames (length afterdirnameslist)))
                      (chosendirpath (nth posindirlist dirpathslist))
                      (snippetslist nil)
                      (snippetslist (progn
                                      (dolist (x (directory-files chosendirpath t))
                                        (if (and (file-regular-p x) (not (file-symlink-p x)))
                                            (setq snippetslist (append (list (file-name-nondirectory x)) snippetslist))))
                                      snippetslist))
                      (chosensnippetname (ido-completing-read "Name of snippet: " snippetslist))
                      (chosensnippetpath (concat chosendirpath "/" chosensnippetname)))
                 (list chosensnippetpath)))
  (let ((snippet))
    (with-temp-buffer
      (insert-file-contents location)
      (goto-char (point-min))
      (setq snippet
            (buffer-substring-no-properties
             (re-search-forward "# --.*\n")
             (point-max))))
    (yas/expand-snippet snippet)))

(defun yas-ido-edit-snippet (location content)
  "Select snippet using ido and edit it.
When called non-interactively make/edit a snippet in file at LOCATION placing CONTENT at the end"
  (interactive (let* ((topdir (nth 0 yas/root-directory))
                      (dirpathslist (get-subdirs topdir 5))
                      (dirnameslist (mapcar 'file-name-nondirectory dirpathslist))
                      (chosendirname (ido-completing-read "Snippets folder: " dirnameslist nil t))
                      (numdirnames (length dirnameslist))
                      (afterdirnameslist (member chosendirname dirnameslist))
                      (newdir (if afterdirnameslist nil t))
                      (posindirlist (if (not newdir) (- numdirnames (length afterdirnameslist))))
                      (chosendirpath (if (not newdir) (nth posindirlist dirpathslist) (concat topdir "/" chosendirname)))
                      (snippetslist nil)
                      (snippetslist (if (not newdir)
                                        (progn
                                          (dolist (x (directory-files chosendirpath t))
                                            (if (and (file-regular-p x) (not (file-symlink-p x)))
                                                (setq snippetslist (append (list (file-name-nondirectory x)) snippetslist))))
                                          snippetslist)))
                      (chosensnippetname (if newdir
                                             (read-from-minibuffer "Name of snippet: ")
                                           (ido-completing-read "Name of snippet: " snippetslist)))
                      (chosensnippetpath (concat chosendirpath "/" chosensnippetname))
                      (selectedregion (if mark-active (buffer-substring-no-properties (region-beginning) (region-end)) nil))
                      (chosencontent (if (and mark-active (y-or-n-p "Insert currently selected region (y/n)? ")) selectedregion "")))
                 (list chosensnippetpath chosencontent)))
  (let ((editsnippet (file-exists-p location)))
    (if editsnippet
        (progn
          (find-file location)
          (goto-char (point-max))
          (insert content))
      (let ((snippetsnippetfile (concat (nth 0 yas/root-directory) "/text-mode/snippet")))
        (switch-to-buffer (get-buffer-create location))
        (set-visited-file-name location)
        (insert content)
        (if (file-exists-p snippetsnippetfile)
            (progn
              (with-temp-buffer
                (goto-char (point-min))
                (insert-file-contents snippetsnippetfile)
                (goto-char (point-min))
                (setq snippettemplate
                      (buffer-substring-no-properties
                       (re-search-forward "# --.*\n")
                       (point-max))))
              (goto-char (point-min))
              (yas/expand-snippet 1 1 snippettemplate)))))))


(provide 'yas-ido)

;; (magit-push)
;; (yaoddmuse-post "EmacsWiki" "yas-ido.el" (buffer-name) (buffer-string) "update")

;;; yas-ido.el ends here
