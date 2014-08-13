;;; ntriple-mode.el --- A mode for editing N-Triple files

;; Copyright (C) 2014 Aaron Kunde <aaron.kunde@web.de>

;; Author: 2014 Aaron Kunde <aaron.kunde@web.de>

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; A major mode of editing RDF-files serialized as N-Triples as specified in
;; W3C recommendation REC-n-triples-20140225
;; (<http://www.w3.org/TR/2014/REC-n-triples-20140225/>).

;; Documetation
;; ------------
;; For more information how I wrote this mode, please see the documentation in
;; <https://github.com/aaron-kunde/ntriple-mode/ntriple-mode.org>

;; Features
;; --------
;; - Basic syntax highlighting

;; Changelog
;; ---------
;; Version 0.1: Added basic highlighting

;;; Code:

(define-derived-mode ntriple-mode fundamental-mode "N-Triple"
  "Major mode for editing RDF-files serialized as N-Triples (W3C recommendation REC-n-triples-20140225)."
  (set (make-local-variable 'font-lock-defaults) '(()))
  (modify-syntax-entry ?# "<") ; Mark comments
  (modify-syntax-entry ?\n ">")
  (set (make-local-variable 'font-lock-syntactic-keywords) ; No comments in IRIs
       '(("<[^>]*\\(#[^>]*\\)" 1 "w")))
  (modify-syntax-entry ?< "(") ; Make '<' and '>' parenthesis
  (modify-syntax-entry ?> ")"))