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

(defconst vulpea-auto-tag-todo-re
  "\\* \\(TODO\\|WAIT\\|CANC\\|STARTED\\|CYCLIC\\|PROJ\\|SOMEDAY\\)")


(defun vulpea-auto-tag-buffer-has-todo-p ()
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
  "Function to be added to `before-save-hook'.

If the current buffer has any TODO entry, add the tag \"todo\" to the
note. Otherwise, remove the tag \"todo\" from the note."
  (when (and (buffer-file-name)
             (string= (file-name-extension (buffer-file-name)) "org"))
    (save-excursion
      ;; Move to buffer start to make sure we add/remove file tags
      (goto-char (point-min))
      (if (vulpea-auto-tag-buffer-has-todo-p)
          (vulpea-buffer-tags-add "todo")
        (let ((tags (vulpea-buffer-tags-get)))
          (when (member "todo" tags)
            (vulpea-buffer-tags-remove "todo")))))))


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
