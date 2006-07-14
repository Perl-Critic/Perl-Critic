;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;     $URL$
;;;    $Date$
;;;  $Author$
;;; $Revison: $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                    Perl::Critic Checking
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Readme 0.04
;;;
;;; This is a minor mode for emacs intended to allow you to
;;; automatically incorporate perlcritic into your daily code
;;; writing. When enabled it can optionally prevent you from saving
;;; code that doesn't pass your enabled perlcritic policies.
;;;
;;; Even if you don't enable the automatic code checking you can still
;;; use the automatic checking or the `perlcritic' function.


;;; Installation instructions:
;;;
;;;   Copy perlcritic.el to your ~/.site-lib directory. If you don't
;;;   have a .site-lib directory create it and add the following line
;;;   to your .emacs file. This location isn't special, you could use
;;;   a different location if you wished.
;;;
;;;     (add-to-list 'load-path "/home/your-name/.site-lisp")
;;;
;;;   Add the following lines to your .emacs file. This allows Emacs
;;;   to load your perlcritic library only when needed.
;;;
;;;     (autoload 'perlcritic        "perlcritic" "" t)
;;;     (autoload 'perlcritic-region "perlcritic" "" t)
;;;     (autoload 'perlcritic-mode   "perlcritic" "" t)
;;;
;;;   Add the following to your .emacs file to get perlcritic-mode to
;;;   run automatically for the `cperl-mode' and `perl-mode'.
;;;
;;;     (eval-after-load "cperl-mode"
;;;      '(add-hook 'cperl-mode-hook 'perlcritic-mode))
;;;     (eval-after-load "perl-mode"
;;;      '(add-hook 'perl-mode-hook 'perlcritic-mode))


;;;   If you think you need perlcritic loaded all the time you can
;;;   make this unconditional by using the following command instead
;;;   of the above autoloading.
;;;
;;;     (require 'perlcritic)
;;;
;;;   Compile the file for extra performance. This is optional. You
;;;   will have to redo this everytime you modify or upgrade your
;;;   perlcritic.el file.
;;;
;;;     M-x byte-compile-file ~/.site-lib/perlcritic.el
;;;
;;;   Additional customization can be found in the Perl::Critic group
;;;   in the Tools section in the Programming section of your Emacs'
;;;   customization menus.


;;;   TODO
;;;
;;;     Find out how to get perlcritic customization stuff into the
;;;     customization menus without having to load perlcritic.el
;;;     first.
;;;
;;;     This needs an installer. Is there anything I can use in
;;;     ExtUtils::MakeMaker, Module::Build, or Module::Install?
;;;     Alien::?
;;;
;;;     Bring in mode-compile so the warnings which read `... in
;;;     <file> on line <line> are links back to the source.
;;;
;;;     XEmacs compatibility. I use GNU Emacs and don't test in
;;;     XEmacs. I'm happy to do what it takes to be compatible but
;;;     someone will have to point things out to me.
;;;


;;; Changes
;;; 0.01
;;;   * It's new. I copied much of this from perl-lint-mode.
;;;
;;; 0.02
;;;   * perlcritic-severity-level added.
;;;   * Touched up the installation documentation.
;;;   * perlcritic-pass-required is now buffer local.
;;;
;;; 0.03
;;;   * compile.el integration. This makes for hotlink happiness.
;;;   * Better sanity when starting the *perlcritic* buffer.
;;; 0.04
;;;   * Removed a roque file-level (setq perlcritic-top 1)
;;;   * Moved cl library to compile-time.
;;; 0.05
;;;   * perlcritic-bin invocation now shown in output.
;;;   * Fixed indentation
;;;   * perlcritic-region is now interactive.

;;; Copyright and license
;;;
;;;   2006 Joshua ben Jore <jjore@cpan.org>
;;;
;;;   This program is free software; you can redistribute it and/or
;;;   modify it under the same terms as Perl itself


(defgroup perlcritic nil "Perl::Critic"
  :prefix "perlcritic-"
  :group 'tools)
(defcustom perlcritic-bin "perlcritic"
  "The perlcritic program used by `perlcritic'."
  :type 'string
  :group 'perlcritic)
(defcustom perlcritic-pass-required nil
  "When `perlcritic-mode' is enabled then this boolean controls
whether your file can be saved when there are perlcritic warnings.

This variable is automatically buffer-local and may be overridden on a
per-file basis with File Variables."
  :type '(radio (const :tag "Require no warnings from perlcritic to save" t)
		(const :tag "Allow warnings from perlcritic when saving" nil))
  :group 'perlcritic)
(make-variable-buffer-local 'perlcritic-pass-required)

(defcustom perlcritic-severity nil
  "Default severity level for `perlcritic'. When this is nil, the
perlcritic program uses whatever it's default is. When this is set it
is a default for everything in Emacs.

This variable is automatically buffer-local and may be overridden on a
per-file basis with File Variables."
  :type '(radio (const :tag "Show only the most severe: 5" 5)
		(const :tag "4" 4)
		(const :tag "3" 3)
		(const :tag "2" 2)
		(const :tag "Show everything including the least severe: 1" 1))
  :group 'perlcritic)
(make-variable-buffer-local 'perlcritic-severity)

(defcustom perlcritic-top nil
  "TODO: Document this.

This variable is automatically buffer-local and may be overridden on a
per-file basis with File Variables."
  :type 'integer
  :group 'perlcritic)
(make-variable-buffer-local 'perlcritic-top)



; The Emacs Lisp manual says to do this with the cl library.
(eval-when-compile (require 'cl))

(defun perlcritic ()
  "Returns a either nil or t depending on whether the current buffer passes perlcritic's check."
  (interactive)
  (save-restriction
    (widen)
    (perlcritic-region (point-min) (point-max))))

(defun perlcritic-region (start end)
  "Returns a either nil or t depending on whether the region passes perlcritic's check."
  
  (interactive "r")

  ; Kill the perlcritic buffer so I can make a new one.
  (let ((buf (get-buffer "*perlcritic*")))
    (if buf (kill-buffer buf)))
  
  (save-excursion
    (let ((src-buf (current-buffer))
	  (err-buf (get-buffer-create "*perlcritic*")))
      
      (set-buffer src-buf)
      (let ((perlcritic-args (loop for p in (list
					     ; !!! Add bin/perlcritic parameters here!
					     (perlcritic-severity)
					     (perlcritic-top))
				   unless (null p)
				   append p)))
        ; Seriously. Is this the nicest way to call
        ; CALL-PROCESS-REGION with variadic arguments? This blows!
        ; (apply FUNCTION (append STATIC-PART DYNAMIC-PART))
	(message "Perl critic...running")
	(let ((rc (apply 'call-process-region
			 (nconc (list start end
				      perlcritic-bin nil
				      (list err-buf t)
				      nil)
				perlcritic-args))))
	  (message "Perl critic...done")
	  
	  (set-buffer err-buf)
	  (if (and (numberp rc) (zerop rc))
	      (delete-matching-lines "source OK$"))
	  (let ((perlcritic-ok (and (numberp rc)
				    (zerop rc)
				    (zerop (buffer-size)))))
	    ; Either clean up or finish setting up my output.
	    (if perlcritic-ok
		(kill-buffer err-buf)
	      
	      ; Set up the output buffer now I know it'll be used.  I
	      ; scooped the guts out of compile-internal. It is
	      ; CRITICAL that the errors start at least two lines from
	      ; the top. compile.el normally assumes the first line is
	      ; an informational `cd somedirectory' command and the
	      ; second line shows the program's invocation.
	      (set-buffer err-buf)
	      (goto-char (point-min))
	      (insert "\n")
	      (insert (reduce (lambda (a b) (concat a " " b))
			      (nconc (list perlcritic-bin)
				     perlcritic-args))
		      "\n")
	      (goto-char (point-min))
	      (compilation-mode "perlcritic")
	      (set (make-local-variable 'perlcritic-buffer) src-buf)
	      (set (make-local-variable 'compilation-error-regexp-alist) perlcritic-compilation-error-regexp-alist)
	      (ad-activate #'compilation-find-file)
	      (display-buffer err-buf))
	    perlcritic-ok))))))

(defun perlcritic-severity ()
  "Returns the appropriate parameters for invoking `perlcritic-bin'
with the current severity"
  (cond ((stringp perlcritic-severity) (list "-severity" perlcritic-severity))
	((numberp perlcritic-severity) (list "-severity" (number-to-string perlcritic-severity)))
	(t nil)))
(defun perlcritic-top ()
  "TODO: document this"
  (cond ((stringp perlcritic-top) (list "-top" perlcritic-top))
	((numberp perlcritic-top) (list "-top" (number-to-string perlcritic-top)))
	(t nil)))



;;; "Blubber at line XY, column XY. Blubber. (Severity XY)"
;;;
;;; compile.el requires that something be the "filename." I've tagged
;;; the severity with that. It happens to make it get highlighted in
;;; red. The following advice on COMPILATION-FIND-FILE makes sure that
;;; the "filename" is getting ignored when perlcritic is using it.
(defvar perlcritic-compilation-error-regexp-alist 
  '(("^[^\n]* at line \\([0-9]+\\), column \\([0-9]+\\).[^\n]*(Severity: \\([0-9]+\\))$" 3 1 2))
  "Alist that specified how to match errors in perlcritic output.")
(defadvice compilation-find-file (around perlcritic-find-file)
  "Lets perlcritic lookup into the buffer we just came from and don't
require that the perl document exist in a file anywhere."
  (let ((debug-buffer (marker-buffer marker)))
    (if (local-variable-p 'perlcritic-buffer debug-buffer)
	(setq ad-return-value perlcritic-buffer)
      ad-do-it)))
    





(defvar perlcritic-mode nil
  "Toggle `perlcritic-mode'")
(make-variable-buffer-local 'perlcritic-mode)

(defun perlcritic-write-hook ()
  "Check perlcritic during `write-file-hooks' for `perlcritic-mode'"
  (if perlcritic-mode
      (save-excursion
	(widen)
	(mark-whole-buffer)
	(if perlcritic-pass-required
	    (not (perlcritic))
	  nil))
    nil))
(defun perlcritic-mode (&optional arg)
  "Perl::Critic checking minor mode."
  (interactive "P")
  (setq perlcritic-mode
	(if (null arg)
	    (not perlcritic-mode)
	  (> (prefix-numeric-value arg) 0)))
  (make-local-hook 'write-file-hooks)
  (if perlcritic-mode
      (add-hook 'write-file-hooks 'perlcritic-write-hook)
    (remove-hook 'write-file-hooks 'perlcritic-write-hook)))
(if (not (assq 'perlcritic-mode minor-mode-alist))
    (setq minor-mode-alist
	  (cons '(perlcritic-mode " Critic")
		minor-mode-alist)))

(provide 'perlcritic)

