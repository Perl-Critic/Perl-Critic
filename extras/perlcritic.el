;;; perlcritic.el --- minor mode for Perl::Critic integration

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;     $URL$
;;;    $Date$
;;;  $Author$
;;; $Revison: $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;; Readme
;;
;; This is a minor mode for emacs intended to allow you to
;; automatically incorporate perlcritic into your daily code
;; writing. When enabled it can optionally prevent you from saving
;; code that doesn't pass your enabled perlcritic policies.
;;
;; Even if you don't enable the automatic code checking you can still
;; use the automatic checking or the `perlcritic' function.


;;; Installation instructions:
;;
;;   Copy perlcritic.el to your ~/.site-lib directory. If you don't
;;   have a .site-lib directory create it and add the following line
;;   to your .emacs file. This location isn't special, you could use
;;   a different location if you wished.
;;
;;     (add-to-list 'load-path "/home/your-name/.site-lisp")
;;
;;   Add the following lines to your .emacs file. This allows Emacs
;;   to load your perlcritic library only when needed.
;;
;;     (autoload 'perlcritic        "perlcritic" "" t)
;;     (autoload 'perlcritic-region "perlcritic" "" t)
;;     (autoload 'perlcritic-mode   "perlcritic" "" t)
;;
;;   Add the following to your .emacs file to get perlcritic-mode to
;;   run automatically for the `cperl-mode' and `perl-mode'.
;;
;;     (eval-after-load "cperl-mode"
;;      '(add-hook 'cperl-mode-hook 'perlcritic-mode))
;;     (eval-after-load "perl-mode"
;;      '(add-hook 'perl-mode-hook 'perlcritic-mode))
;;
;;
;;   If you think you need perlcritic loaded all the time you can
;;   make this unconditional by using the following command instead
;;   of the above autoloading.
;;
;;     (require 'perlcritic)
;;
;;   Compile the file for extra performance. This is optional. You
;;   will have to redo this everytime you modify or upgrade your
;;   perlcritic.el file.
;;
;;     M-x byte-compile-file ~/.site-lib/perlcritic.el
;;
;;   Additional customization can be found in the Perl::Critic group
;;   in the Tools section in the Programming section of your Emacs'
;;   customization menus.


;;;   TODO
;;
;;     Find out how to get perlcritic customization stuff into the
;;     customization menus without having to load perlcritic.el
;;     first.
;;
;;     This needs an installer. Is there anything I can use in
;;     ExtUtils::MakeMaker, Module::Build, or Module::Install?
;;     Alien::?
;;
;;     XEmacs compatibility. I use GNU Emacs and don't test in
;;     XEmacs. I'm happy to do what it takes to be compatible but
;;     someone will have to point things out to me.
;;
;;     Make all documentation strings start with a sentence that fits
;;     on one line. See "Tips for Documentation Strings" in the Emacs
;;     Lisp manual.
;;
;;     Any FIXME, TODO, or XXX tags below.


;;; Change Log:
;; 0.06
;;   * Code cleanliness.
;;   * Comment cleanliness.
;;   * Nice error message when perlcritic warns.
;;   * Documented perlcritic-top, perlcritic-verbose.
;;   * Regular expressions for the other standard -verbose levels.
;;   * Reversed Changes list so the most recent is first.
;;   * Standard emacs library declarations.
;;   * Added autoloading metadata.
;; 0.05
;;   * perlcritic-bin invocation now shown in output.
;;   * Fixed indentation.
;;   * perlcritic-region is now interactive.
;; 0.04
;;   * Removed a roque file-level (setq perlcritic-top 1)
;;   * Moved cl library to compile-time.
;; 0.03
;;   * compile.el integration. This makes for hotlink happiness.
;;   * Better sanity when starting the *perlcritic* buffer.
;; 0.02
;;   * perlcritic-severity-level added.
;;   * Touched up the installation documentation.
;;   * perlcritic-pass-required is now buffer local.
;; 0.01
;;   * It's new. I copied much of this from perl-lint-mode.

;;; Copyright and license
;;
;;   2006 Joshua ben Jore <jjore@cpan.org>
;;
;;   This program is free software; you can redistribute it and/or
;;   modify it under the same terms as Perl itself


;;; Code:
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
  :type '(radio
	  (const :tag "Require no warnings from perlcritic to save" t)
	  (const :tag "Allow warnings from perlcritic when saving" nil))
  :group 'perlcritic)
(make-variable-buffer-local 'perlcritic-pass-required)

;; TODO: perlcritic-profile

;; TODO: perlcritic-noprofile


(defcustom perlcritic-severity nil
  "Directs perlcritic to only report violations of Policies with a
severity greater than N. Severity values are integers ranging from
1 (least severe) to 5 (most severe). The default is 5. For a given
-profile, decreasing the -severity will usually produce more
violations.  Users can redefine the severity for any Policy in their
.perlcriticrc file.

This variable is automatically buffer-local and may be overridden on a
per-file basis with File Variables."
  ;; FIXME: My GNU Emacs doesn't show a radio widget or a menu here.
  :type '(radio
	  (const :tag "Show only the most severe: 5" 5)
	  (const :tag "4" 4)
	  (const :tag "3" 3)
	  (const :tag "2" 2)
	  (const :tag "Show everything including the least severe: 1" 1))
  :group 'perlcritic)
(make-variable-buffer-local 'perlcritic-severity)

(defcustom perlcritic-top nil
  "Directs perlcritic to report only the top N Policy violations in
each file, ranked by their severity. If the -severity option is not
explicitly given, the -top option implies that the minimum severity
level is 1. Users can redefine the severity for any Policy in their
.perlcriticrc file.

This variable is automatically buffer-local and may be overridden on a
per-file basis with File Variables."
  :type 'integer
  :group 'perlcritic)
(make-variable-buffer-local 'perlcritic-top)

;; TODO: perlcritic-include

;; TODO: perlcritic-exclude

;; TODO: perlcritic-force

(defcustom perlcritic-verbose nil
  "TODO: Document this.

This variable is automatically buffer-local and may be overridden on a
per-file basis with File Variables."
  :type 'integer
  :group 'perlcritic)
(make-variable-buffer-local 'perlcritic-verbose)

;; TODO: perlcritic-verbose-regexp. perlcritic supports custom
;; formats.



;; The Emacs Lisp manual says to do this with the cl library.
(eval-when-compile (require 'cl))

;;;###autoload
(defun perlcritic ()
  "Returns a either nil or t depending on whether the current buffer
passes perlcritic's check."
  (interactive)
  (save-restriction
    (widen)
    (perlcritic-region (point-min) (point-max))))

;;;###autoload
(defun perlcritic-region (start end)
  "Returns a either nil or t depending on whether the region passes
perlcritic's check."

  (interactive "r")

  ;; Kill the perlcritic buffer so I can make a new one.
  (if (get-buffer "*perlcritic*")
      (kill-buffer "*perlcritic*"))

  ;; In the following lines I'll be switching between buffers
  ;; freely. This upper save-excursion will keep things sane.
  (save-excursion
    (let ((src-buf (current-buffer))
          (err-buf (get-buffer-create "*perlcritic*")))

      (set-buffer src-buf)
      (let ((perlcritic-args (loop for p in (list
                                             ;; Add new bin/perlcritic
                                             ;; parameters here!
                                             (perlcritic-severity)
                                             (perlcritic-top)
                                             (perlcritic-verbose))
                                   unless (null p)
                                   append p)))
                                        ;
        (message "Perl critic...running")
        ;; Seriously. Is this the nicest way to call
        ;; CALL-PROCESS-REGION with variadic arguments? This blows!
        ;; (apply FUNCTION (append STATIC-PART DYNAMIC-PART))
        (let ((rc (apply 'call-process-region
                         (nconc (list start end 
                                      perlcritic-bin nil
                                      (list err-buf t)
                                      nil)
                                perlcritic-args))))

          ;; Figure out whether we're ok or not. perlcritic has to
          ;; return zero and the output buffer has to be empty except
          ;; for that "... source OK" line. Different versions of the
          ;; perlcritic script will print different things when
          ;; they're ok. I expect to see things like "some-file source
          ;; OK", "SCALAR=(0x123457) source OK", "STDIN source OK",
          ;; and "source OK".
          (let ((perlcritic-ok (and (numberp rc)
                                    (zerop rc)
                                    (progn
				      (set-buffer err-buf)
				      (delete-matching-lines "source OK$")
				      (zerop (buffer-size))))))
            ;; Either clean up or finish setting up my output.
            (if perlcritic-ok
		;; Ok!
                (progn
                  (kill-buffer err-buf)
                  (message "Perl critic...ok"))


	      ;; Not ok!
	      (message "Perl critic...not ok")

              ;; Set up the output buffer now I know it'll be used.  I
              ;; scooped the guts out of compile-internal. It is
              ;; CRITICAL that the errors start at least two lines
              ;; from the top. compile.el normally assumes the first
              ;; line is an informational `cd somedirectory' command
              ;; and the second line shows the program's invocation.
	      ;;
	      ;; Since I have the space available I've put the
	      ;; program's invocation here. Maybe it'd make sense to
	      ;; put the buffer's directory here somewhere too.
              (set-buffer err-buf)
              (goto-char (point-min))
              (insert (reduce (lambda (a b) (concat a " " b))
                              (nconc (list perlcritic-bin)
                                     perlcritic-args))
                      "\n"
		      ;; TODO: instead of a blank line, print the
		      ;; buffer's directory+file.
		      "\n")
              (goto-char (point-min))
	      ;; TODO: get `recompile' to work.
	      
	      ;; just an fyi. compilation-mode will delete my local
	      ;; variables so be sure to call it *first*.
              (compilation-mode "perlcritic")
              (set (make-local-variable 'perlcritic-buffer) src-buf)
              (set (make-local-variable 'compilation-error-regexp-alist)
		   perlcritic-compilation-error-regexp-alist)
              (ad-activate #'compilation-find-file)
	      ; (ad-deactivate #'compilation-find-file)
              (display-buffer err-buf))
	    
	    ;; Return our success or failure.
            perlcritic-ok))))))

(defun perlcritic-severity ()
  "Returns the appropriate parameters for invoking `perlcritic-bin'
with the current severity"
  (cond ((stringp perlcritic-severity)
	 (list "-severity" perlcritic-severity))
        ((numberp perlcritic-severity)
	 (list "-severity" (number-to-string perlcritic-severity)))
        (t nil)))

(defun perlcritic-top ()
  "Returns the appropriate parameters for invoking `perlcritic-bin'
with -top"
  (cond ((stringp perlcritic-top)
	 (list "-top" perlcritic-top))
        ((numberp perlcritic-top)
	 (list "-top" (number-to-string perlcritic-top)))
        (t nil)))

(defun perlcritic-verbose ()
  "Returns the appropriate parameters for invoking `perlcritic-bin'
with -verbose"
  (cond ((stringp perlcritic-verbose)
	 (list "-verbose" perlcritic-verbose))
        ((numberp perlcritic-verbose)
	 (list "-verbose" (number-to-string perlcritic-verbose)))
        (t nil)))



;; compile.el requires that something be the "filename." I've tagged
;; the severity with that. It happens to make it get highlighted in
;; red. The following advice on COMPILATION-FIND-FILE makes sure that
;; the "filename" is getting ignored when perlcritic is using it.

;; Verbosity     Format Specification
;; -----------   --------------------------------------------------------------------
;; 1             "%f:%l:%c:%m\n"
;; 2             "%m at line %l, column %c.  %e. (Severity: %s)\n"
;; 3             "%f: %m at line %l, column %c.  %e. (Severity: %s)\n"
;; 4             "%m near '%r'. (Severity: %s)\n"
;; 5             "%f: %m near '%r'. (Severity: %s)\n"
;; 6             "%m at line %l, column %c near '%r'.  %e. (Severity: %s)\n"
;; 7             "%f: %m at line %l, column %c near '%r'.  %e. (Severity: %s)\n"
;; 8             "[%p] %m at line %l, column %c near '%r'.  %e. (Severity: %s)\n"
;; 9             "[%p] %m at line %l, column %c near '%r'.  %e. (Severity: %s)\n%d\n"
(defvar perlcritic-compilation-error-regexp-alist
  '(("^\\([^\n]+\\):\\([0-9]+\\):\\([0-9]+\\):[^\n]+$" 1 2 3)
    ("^[^\n]+ at line \\([0-9]+\\), column \\([0-9]+\\).  [^\n]+. (Severity: \\([0-9]+\\))$" 3 1 2)
    ("^\\([^\n]+\\): [^\n]+ at line \\([0-9]+\\), column \\([0-9]+\\).  [^\n]+. (Severity: [0-9]+)$" 1 2 3)
    ("^[^\n]+ near '[^\n]+'. (Severity: [0-9]+)$" 1)
    ("^\\([^\n]+\\): [^\n]+ near '[^\n]+'. (Severity: [0-9]+)$" 1)
    ("^[^\n]+ at line \\([0-9]+\\), column \\([0-9]+\\) near '[^\n]+'.  [^\n]+. (Severity: [0-9]+)" 3 1 2)
    ("^\\([^\n]+\\): [^\n]+ at line \\([0-9]+\\), column \\([0-9]+\\) near '[^\n]+'.  [^\n]+. (Severity: [^\n]+)$" 1 2 3)
    ("\\[[^\n]+\\] [^\n]+ at line \\([0-9]+\\), column \\([0-9]+\\) near '[0-9]+;.  [^\n]+. (Severity: [^\n]+)$" 3 1 2)
    ("\\[[^\n]+\\] [^\n]+ at line \\([0-9]+\\), column \\([0-9]+\\) near '[^\n]+'.  [^\n]+. (Severity: \\([^\n]+\\))" 3 1 2))
  "Alist that specified how to match errors in perlcritic output.")


;; Hooks compile.el's compilation-find-file to enable our file-less
;; operation. We feed `perlcritic-bin' from STDIN, not from a file.
(defadvice compilation-find-file (around perlcritic-find-file)
  "Lets perlcritic lookup into the buffer we just came from and don't
require that the perl document exist in a file anywhere."
  (let ((debug-buffer (marker-buffer marker)))
    (if (local-variable-p 'perlcritic-buffer debug-buffer)
        (setq ad-return-value perlcritic-buffer)
      ad-do-it)))





;; All the scaffolding of having a minor mode.
(defvar perlcritic-mode nil
  "Toggle `perlcritic-mode'")
(make-variable-buffer-local 'perlcritic-mode)

(defun perlcritic-write-hook ()
  "Check perlcritic during `write-file-hooks' for `perlcritic-mode'"
  (if perlcritic-mode
      (save-excursion
        (widen)
        (mark-whole-buffer)
        (let ((perlcritic-ok (perlcritic)))
          (if perlcritic-pass-required
	      ;; Impede saving if we're not ok.
              (not perlcritic-ok)
	    ;; Don't impede saving. We might not be ok but that
	    ;; doesn't matter now.
            nil)))
    ;; Don't impede saving. We're not in perlcritic-mode.
    nil))

;;;###autoload
(defun perlcritic-mode (&optional arg)
  "Perl::Critic checking minor mode."
  (interactive "P")
  
  ;; Enable/disable perlcritic-mode
  (setq perlcritic-mode (if (null arg)
			    ;; Nothing! Just toggle it.
			    (not perlcritic-mode)
			  ;; Set it.
			  (> (prefix-numeric-value arg) 0)))
  
  (make-local-hook 'write-file-hooks)
  (if perlcritic-mode
      (add-hook 'write-file-hooks 'perlcritic-write-hook)
    (remove-hook 'write-file-hooks 'perlcritic-write-hook)))

;; Make a nice name for perl critic mode. This string will appear at
;; the bottom of the screen.
(if (not (assq 'perlcritic-mode minor-mode-alist))
    (setq minor-mode-alist
          (cons '(perlcritic-mode " Critic")
                minor-mode-alist)))

(provide 'perlcritic)

;;; perlcritic.el ends here
