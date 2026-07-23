;;; vulpea-auto-tag.el --- Automatically add tags into Vulpea notes prior to saving  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Darlan Cavalcante Moreira

;; Author: Darlan Cavalcante Moreira <darlan@darlan-desktop>
;; Version: 0.1
;; Package-Requires: ((emacs "30.2") (vulpea "2.5.0"))
;; Homepage: https://github.com/darcamo/vulpea-auto-tag

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is not part of GNU Emacs

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Easily define rules to automatically add/remove tags into Vulpea notes prior
;; to saving. For example, you can add a "todo" tag to any note that has at
;; least one TODO entry, and remove the "todo" tag from notes that have no TODO
;; entries.

;;; Code:
(require 'vulpea)


;; Define the vulpea-auto-tag group
(defgroup vulpea-auto-tag nil
  "Automatically add/remove tags into Vulpea notes prior to saving."
  :group 'vulpea
  :prefix "vulpea-auto-tag-")


(defcustom vulpea-auto-tag-rules '(vulpea-auto-tag-process-todo-tag)
  "List of functions to adjust tags.

Each function should not receive any arguments and return a cons cell
with tags to add and remove from the note"
  :type '(repeat (function :tag "Function"))
  :group 'vulpea-auto-tag)


(defcustom vulpea-auto-tag-todo-re
  "\\* \\(TODO\\|WAIT\\|CANC\\|STARTED\\|CYCLIC\\|PROJ\\|SOMEDAY\\)"
  "Regular expression to match TODO keywords in the current buffer."
  :type 'regexp
  :group 'vulpea-auto-tag)


(defun vulpea-auto-tag-process-todo-tag ()
  "Return a cons cell with tags to add/remove.

If the there are any TODOs in the current buffer, return a cons cell
with \"todo\" as the car, and nil as cdr. If there aren't any TODO
entries, return the oposit, with nil as car and \"todo\" as cdr. This
function is intended to be used in `vulpea-auto-tag-rules'."
  (if (vulpea-auto-tag--buffer-has-todo-p)
      '(("todo") . nil)
    '(nil . ("todo"))))


(defun vulpea-auto-tag--buffer-has-todo-p ()
  "Return non-nil if current buffer has any todo entry.

Only TODO keywords in `vulpea-auto-tag-todo-re' are considered, which
intentionaly leaves out keywords maching a DONE state. In other words,
this function returns nil if current buffer contains only completed
tasks."
  (save-excursion
    (goto-char (point-min))
    (let (case-fold-search)
      (re-search-forward vulpea-auto-tag-todo-re nil t))))


(defun vulpea-auto-tag--before-save ()
  "Process the functions in `vulpea-auto-tag-rules' to add/remove tags."
  (when (and (buffer-file-name)
             (string= (file-name-extension (buffer-file-name)) "org"))
    (dolist (fn vulpea-auto-tag-rules)
      (let* ((tags-cons (funcall fn))
             (tags-to-add (car tags-cons))
             (tags-to-remove (cdr tags-cons)))
        (save-excursion
          ;; Move to buffer start to make sure we add/remove file tags
          (goto-char (point-min))
          (when tags-to-add
            (vulpea-buffer-tags-add tags-to-add))
          (when tags-to-remove
            (vulpea-buffer-tags-remove tags-to-remove)))))))


(define-minor-mode vulpea-auto-tag-sync-mode
  "Add/remove \"todo\" tag to vulpea notes."
  :lighter nil
  ;; :group 'git-sync
  (cond
   (vulpea-auto-tag-sync-mode
    (add-hook 'before-save-hook #'vulpea-auto-tag--before-save nil 'local))
   (t
    (remove-hook 'before-save-hook #'vulpea-auto-tag--before-save 'local))))


(provide 'vulpea-auto-tag)
;;; vulpea-auto-tag.el ends here
