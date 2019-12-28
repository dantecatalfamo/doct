;;; doct-test.el --- doct test suite ;; -*- lexical-binding: t -*-

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Code:
(require 'ert)
(require 'doct)
(require 'org-capture)

(ert-deftest first-file-target-wins ()
  "first file target keyword should override others"
  (should (equal (doct '(("fft-test" :keys "f"
                          :type entry
                          :template ""
                          :id "1"
                          :clock t
                          :function identity
                          :file "")))
                 '(("f" "fft-test" entry (id "1") "")))))

(ert-deftest first-file-target-extension-wins ()
  "first file target extension should override others"
  (should (equal (doct `(("ffte-test" :keys "f"
                          :type entry
                          :file ""
                          :template ""
                          ;;@HACK, not sure why this test fails if
                          ;;run more than once. The :olp list is
                          ;;nreversed in doct--convert, but
                          ;;multiple invocations of the test should
                          ;;get a fresh copy of the list...
                          :olp ,(seq-copy '("one" "two" "three"))
                          :regexp "one"
                          :headline "one"
                          :function identity)))
                 '(("f" "ffte-test" entry (file+olp "" "one" "two" "three") "")))))

(ert-deftest first-template-target-wins ()
  "first template target keyword should override other template target keywords"
  (should (equal (doct '(("ftt-test" :keys "tt"
                          :type entry
                          :id "1"
                          :clock t
                          :function identity
                          :template ""
                          :template-function ignore
                          :template-file "./template.txt"
                          :file "")))
                 '(("tt" "ftt-test" entry (id "1") "")))))


(ert-deftest :clock-target-should-not-have-cdr ()
  ":clock keyword shouldn't have a cdr when used as a target."
  (should (equal (doct '(("clock-test" :keys "c"
                          :type entry
                          :clock t
                          :template "")))
                 '(("c" "clock-test" entry (clock) "")))))

(ert-deftest :template-is-joined ()
  ":template should join multiple values with a newline"
  (should (equal (doct '(("template join test" :keys "t"
                          :file ""
                          :template ("one" "two" "three"))))
                 '(("t" "template join test" entry (file "") "one
two
three")))))

(ert-deftest :template-is-string ()
  ":template should be returned verbatim when it is a string"
  (should (equal (doct '(("template join test" :keys "t"
                          :template "test"
                          :file "")))
                 '(("t" "template join test" entry (file "") "test")))))

(ert-deftest :template-function ()
  ":template-function should properly convert to target entry"
  (should (equal (doct '(("template-function-test" :keys "t"
                          :type entry
                          :template-function identity
                          :file "")))
                 '(("t" "template-function-test" entry (file "") #'identity)))))

(ert-deftest nil-additional-option-not-included ()
  "Additional options with a nil value should not be included in returned entry."
  (should (equal (doct '(("test" :keys "t"
                          :type entry
                          :file ""
                          :template ""
                          :immediate-finish nil)))
                 '(("t" "test" entry (file "") "")))))

(ert-deftest additional-option-not-duplicated ()
  "If declared multiple times, first additional option value is returned once."
  (should (equal (doct '(("test" :keys "t"
                          :type entry
                          :file ""
                          :template ""
                          :immediate-finish t
                          :custom-option t
                          :immediate-finish nil
                          :custom-option nil)))
                 '(("t" "test" entry (file "") "" :immediate-finish t :custom-option t)))))

(ert-deftest file-without-target-is-proper-list ()
  "doct shouldn't return a dotted list when its target is a string.
It should return a proper list."
  (let ((form (doct '(("test" :keys "t"
                       :type entry
                       :file "test"
                       :template "")))))
    (should (equal form '(("t" "test" entry (file "test") ""))))))

(ert-deftest childern-inherit-keys ()
  "Each child should inherit its parent's keys as a prefix to its own keys."
  (should (equal (doct '(("parent" :keys "p"
                          :children
                          (("one" :keys "o")
                           ("two" :keys "t")))))
                 '(("p" "parent") ("po" "one") ("pt" "two")))))

;;error handling
(let ((types '(nil t symbol :keyword 1 1.0 "string" ?c '("list"))))
  (ert-deftest name-type-error ()
    "Error if name isn't a string."
    (dolist (garbage (seq-remove 'stringp types))
      (should-error (doct `((,garbage :keys "t" :children ()))) :type 'user-error)))

  (ert-deftest entry-type-error ()
    "Error if :type isn't a valid type symbol."
    ;;nil is valid, type will be determined by `doct-default-entry-type'.
    (dolist (garbage (delq nil types))
      (should-error (doct `(("test" :keys "t" :type ,garbage :file "" :template "")))
                    :type 'user-error)))

  (ert-deftest keys-type-error ()
    "Error if :keys isn't a string."
    (dolist (garbage (seq-remove 'stringp types))
      (should-error (doct `(("test" :keys ,garbage))) :type 'user-error))))
