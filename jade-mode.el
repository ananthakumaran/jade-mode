;;; jade-mode.el --- Major mode for editing Jade files

;; Copyright (C) 2012 Anantha Kumaran.

;; Author: Anantha kumaran <ananthakumaran@gmail.com>
;; Version: 0.1
;; Keywords: markup, language, html

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'js)

(defgroup jade nil
  "Support for Jade markup language."
  :group 'languages
  :prefix "jade-")

(defcustom jade-indent-offset 2
  "Amount of offset per level of indentation."
  :type 'integer
  :group 'jade)

(defun jade-previous-line-indentation ()
  (save-excursion
    (beginning-of-line)
    (if (bobp)
        nil
      (forward-line -1)
      (current-indentation))))

(defun jade-move-to (offset)
  (beginning-of-line)
  (delete-horizontal-space)
  (indent-to offset))

(defun jade-compute-indent ()
  (let ((pi (jade-previous-line-indentation))
        (ci (current-indentation)))
    (if (not (= (+ (point-at-bol) ci) (point)))
        (+ pi jade-indent-offset)
      (if (not pi)
          0
        (if (= ci 0)
            (+ pi jade-indent-offset)
          (- ci jade-indent-offset))))))

(defun jade-indent-line ()
  (interactive)
  (jade-move-to (jade-compute-indent)))

(defun jade-indent-region (beg end)
  (save-excursion
    (goto-char end)
    (setq end (point-marker))
    (goto-char beg)
    (forward-to-indentation 0)
    (let* ((ci (current-indentation))
           (pi (jade-previous-line-indentation))
           (offset (if (and pi (<= ci pi))
                       jade-indent-offset
                     (- (jade-compute-indent) (current-indentation)))))
      (while (< (point) end)
        (jade-move-to (+ (current-indentation) offset))
        (forward-line 1)))))

(defvar jade-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_ "w" table)
    (modify-syntax-entry ?/ ". 12" table)
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?\' "\"" table)
    table))

(defvar jade-mode-map
  (let ((map (make-sparse-keymap)))
    map))

(defun jade-fontify-js-region (beg end)
  (save-excursion
    (save-match-data
      (let ((font-lock-keywords js--font-lock-keywords-3)
            (font-lock-syntax-table js-mode-syntax-table)
            (font-lock-multiline 'undecided)
            font-lock-keywords-only
            font-lock-extend-region-functions
            font-lock-keywords-case-fold-search)
        (ignore-errors
	  (font-lock-fontify-region (- beg 1) end))))))

(defun jade-highlight-js-block (limit)
  (when (re-search-forward "^ *\\(-\\) \\(.*\\)$" limit t)
    (jade-fontify-js-region (match-beginning 2) (match-end 2))
    t))

(defun jade-highlight-attributes (limit)
  (when (re-search-forward "^ *[^ \n]*\\(\\)(\\(.*\\)).*$" limit t)
    (goto-char (match-beginning 2))
    (save-match-data
      (let ((limit (save-excursion (end-of-line) (point))))
	(while (re-search-forward " *\\([^= \n,'\"]+?\\) *[=,\)]" limit t)
	  (put-text-property (match-beginning 1) (match-end 1)
			     'face font-lock-constant-face)
	  (backward-char)
	  (re-search-forward "," limit t))))
    t))

(defconst jade-font-lock-keywords
  `(("^!!!.*$" 0 font-lock-constant-face)
    (jade-highlight-js-block 1 font-lock-preprocessor-face)
    (jade-highlight-attributes 1 font-lock-preprocessor-face)
    ("^ *[^ \n]*\\(#\\(\\w\\|_\\|-\\)+\\)" 1 font-lock-keyword-face)
    ("^ *\\([a-z0-9_:\\-]+\\)"  1 font-lock-type-face)
    ("^ *[^ \n]*\\(\\.\\(\\w\\|_\\|-\\)+\\)" 1 font-lock-type-face)
    ("[^\\]\\([#!]{\\).*?\\(\}\\)"  (1 font-lock-variable-name-face)
     (2 font-lock-variable-name-face))))

;;;###autoload
(define-derived-mode jade-mode fundamental-mode "Jade"
  "Major mode for editing Jade files.

\\{jade-mode-map}"

  (set-syntax-table jade-mode-syntax-table)
  (setq indent-tabs-mode nil)
  (set (make-local-variable 'comment-start) "// ")
  (set (make-local-variable 'comment-start-skip) "//-?\\s *")
  (set (make-local-variable 'comment-end) "")
  (set (make-local-variable 'indent-line-function) 'jade-indent-line)
  (set (make-local-variable 'indent-region-function) 'jade-indent-region)
  (setq font-lock-defaults '(jade-font-lock-keywords)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.jade$" . jade-mode))

(provide 'jade-mode)
;;; jade-mode.el ends here
