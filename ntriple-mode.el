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
;; - Indentation
;; - Validation

;; Changelog
;; ---------
;; Version 0.3: Added validation function
;; Version 0.2: Added indentation
;; Version 0.1: Added basic highlighting

;;; Code:

;; Start: Validation
;; Definition of regular expressions for validation
(defconst NTRIPLE_UCHAR
  "\\(?:\\\\u[[:xdigit:]]\\{4\\}\\|\\\\U[[:xdigit:]]\\{8\\}\\)"
  "The regular expression, to which a Unicode escaped character must match.")

(defconst NTRIPLE_IRIREF
  (format "\\(:?<\\(:?[^%c-%c<>\"{}|^`\\\\]\\|%s\\)*>\\)"
	  #x00 #x20 NTRIPLE_UCHAR)
  "The regular expression, to which an IRI reference must match.")

(defconst NTRIPLE_PN_CHARS_BASE
  (format "\\(:?[A-Z]\\|[a-z]\\|[%c-%c]\\|[%c-%c]\\|[%c-%c]\\|[%c-%c]\\|[%c-%c]\\|[%c-%c]\\|[%c-%c]\\|[%c-%c]\\|[%c-%c]\\|[%c-%c]\\|[%c-%c]\\|[%c-%c]\\)"
	  #x00C0 #x00D6 #x00D8 #x00F6 #x00F8 #x02FF #x0370 #x037D #x037F #x1FFF
	  #x200C #x200D #x2070 #x218F #x2C00 #x2FEF #x3001 #xD7FF #xF900 #xFDCF
	  #xFDF0 #xFFFD #x10000 #xEFFFF)
  "The regular expression, containing all basic characters, which can be part of
 a name.")

(defconst NTRIPLE_PN_CHARS_U (format "\\(:?%s\\|_\\|:\\)" NTRIPLE_PN_CHARS_BASE)
  "The regular expression, containing all characters, which can be part of a
 name, including underscore `_' and colon `:'.")

(defconst NTRIPLE_PN_CHARS
  (format "\\(:?%s\\|-\\|[0-9]\\|%c\\|[%c-%c]\\|[%c-%c]\\)"
	  NTRIPLE_PN_CHARS_U #x00B7 #x0300 #x036F #x203F #x2040)
  "The regular expression, containing all characters, which can be part of a
 name.")

(defconst NTRIPLE_BLANK_NODE_LABEL
  (format "\\(:?_:\\(:?%s\\|[0-9]\\)\\(:?\\(:?%s\\|\\.\\)*%s\\)?\\)"
	  NTRIPLE_PN_CHARS_U NTRIPLE_PN_CHARS NTRIPLE_PN_CHARS)
  "The regular expression, to which the label of a blank node must match.")

(defconst NTRIPLE_ECHAR "\\(:?\\\\[tbnrf\"`\\\\]\\)"
  "The regular expression containing all escape characters.")

(defconst NTRIPLE_STRING_LITERAL_QUOTE
  (format "\\(:?\"\\(:?[^%c%c%c%c]\\|%s\\|%s\\)*\"\\)"
	  #x22 #x5c #xa #xd NTRIPLE_ECHAR NTRIPLE_UCHAR)
  "The regular expression, to which a quoted string must match.")

(defconst NTRIPLE_LANGTAG "\\(:?@[a-zA-Z]+\\(:?-[a-zA-Z0-9]+\\)*\\)"
  "The regular expression, to which a language tag must match.")

(defconst NTRIPLE_LITERAL
  (format "\\(:?%s\\(:?^^%s\\|%s\\)?\\)"
	  NTRIPLE_STRING_LITERAL_QUOTE NTRIPLE_IRIREF NTRIPLE_LANGTAG)
  "The regular expression, to which a literal must match.")

;; Validation functions
(defun ntriple-validate-buffer ()
  "Validates the current buffer."
  (interactive)
  (beginning-of-buffer)
  (while (and (not (eobp)) (ntriple-validate-current-line))
    (forward-line 1)))

(defun ntriple-validate-current-line ()
  "Validates the current line. Lines are valid, if they are empty, contain only
 comments or triples."
  (interactive)
  (beginning-of-line)
  (if (looking-at "^[[:blank:]]*\\(:?#.*\\)?$") ; Skip comments and empty lines
      t
    (if (looking-at "^\\(.*?\\)[[:blank:]]+\\(.*?\\)[[:blank:]]+\\(.*?\\)[[:blank:]]+\\.[[:blank:]]*\\(:?#.*\\)?$") ; Is line valid triple?
	(if (ntriple-validate-subject (match-string 1))
	    (if (ntriple-validate-predicate (match-string 2))
		(if (ntriple-validate-object (match-string 3))
		    t ; Line is finally valid
		  (error "Invalid object: %s" (match-string 3)))
	      (error "Invalid predicate: %s" (match-string 2)))
	  (error "Invalid subject: %s" (match-string 1)))
      (error "Invalid triple"))))

(defun ntriple-validate-subject (subject)
  "Validates the subject of a triple."
  (or (ntriple-validate-iriref subject)
      (ntriple-validate-blank-node-label subject)))

(defun ntriple-validate-iriref (iriref)
  "Checks whether an IRI reference is valid."
  (string-match-p NTRIPLE_IRIREF iriref))

(defun ntriple-validate-blank-node-label (label)
  "Checks whether a blank node label is valid."
  (string-match-p NTRIPLE_BLANK_NODE_LABEL label))

(defun ntriple-validate-predicate (predicate)
  "Checks whether a predicate of a triple is valid."
  (ntriple-validate-iriref predicate))

(defun ntriple-validate-object (object)
  "Checks whether an object of a triple is valid."
  (or (ntriple-validate-iriref object)
      (ntriple-validate-blank-node-label object)
      (ntriple-validate-literal object)))

(defun ntriple-validate-literal (literal)
  "Checks whether a literal is valid."
  (string-match-p NTRIPLE_LITERAL literal))
;; End: Validation

(defun ntriple-indent-line ()
  "Indents the current line to column 0."
  (interactive)
  (indent-line-to 0))

(define-derived-mode ntriple-mode fundamental-mode "N-Triple"
  "Major mode for editing RDF-files serialized as N-Triples (W3C recommendation REC-n-triples-20140225)."
  (set (make-local-variable 'font-lock-defaults)
       `(((,NTRIPLE_IRIREF . font-lock-keyword-face)
	  (,NTRIPLE_BLANK_NODE_LABEL . font-lock-builtin-face)
	  (,NTRIPLE_LANGTAG . font-lock-variable-name-face))))
  (modify-syntax-entry ?# "<") ; Mark comments
  (modify-syntax-entry ?\n ">")
  (set (make-local-variable 'font-lock-syntactic-keywords) ; No comments in IRIs
       '(("<[^>]*\\(#[^>]*\\)" 1 "w")))
  (modify-syntax-entry ?< "(") ; Make '<' and '>' parenthesis
  (modify-syntax-entry ?> ")")
  (set (make-local-variable 'indent-line-function) 'ntriple-indent-line))

(provide 'ntriple-mode)
