;;; perlcritic.el --- minor mode for Perl::Critic integration

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;      $URL$
;;;     $Date$
;;;   $Author$
;;; $Revision$
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
;; 0.10
;;   * Synched up regexp alist with Perl::Critic::Utils and accounted for all
;;     past patterns too.
;; 0.09
;;   * Added documentation for perlcritic-top, perlcritic-include,
;;     perlcritic-exclude, perlcritic-force, perlcritic-verbose.
;;   * Added emacs/vim editor hints to the bottom.
;;   * Corrected indentation.
;; 0.08
;;   * Fixed perlcritic-compilation-error-regexp-alist for all
;;     severity levels.
;;   * Added documentation strings for functions.
;; 0.07
;;   * Moved perlcritic-compilation-error-regexp-alist so it is in the
;;     source before it's used. This only seems to matter when
;;     perlcritic.el is compiled to bytecode.
;;   * Added perlcritic-exclude, perlcritic-include

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

;;; Customization and variables.
(defgroup perlcritic nil "Perl::Critic"
  :prefix "perlcritic-"
  :group 'tools)

(defcustom perlcritic-bin "perlcritic"
  "The perlcritic program used by `perlcritic'."
  :type 'string
  :group 'perlcritic)

(defcustom perlcritic-pass-required nil
  "When \\[perlcritic-mode] is enabled then this boolean controls
whether your file can be saved when there are perlcritic warnings.

This variable is automatically buffer-local and may be overridden on a
per-file basis with File Variables."
  :type '(radio
	  (const :tag "Require no warnings from perlcritic to save" t)
	  (const :tag "Allow warnings from perlcritic when saving" nil))
  :group 'perlcritic)
(make-variable-buffer-local 'perlcritic-pass-required)

(defcustom perlcritic-profile nil
  "Specify an alternate .perlcriticrc file. This is only used if
non-nil."
  :type '(string)
  :group 'perlcritic)
(make-variable-buffer-local 'perlcritic-profile)

(defcustom perlcritic-noprofile nil
  "Disables the use of any .perlcriticrc file."
  :type '(boolean)
  :group 'perlcritic)
(make-variable-buffer-local 'perlcritic-noprofile)

(defcustom perlcritic-severity nil
  "Directs perlcritic to only report violations of Policies with a
severity greater than N. Severity values are integers ranging from
1 (least severe) to 5 (most severe). The default is 5. For a given
-profile, decreasing the -severity will usually produce more
violations.  Users can redefine the severity for any Policy in their
.perlcriticrc file.

This variable is automatically buffer-local and may be overridden on a
per-file basis with File Variables."
  :type '(radio
	  (const :tag "Show only the most severe: 5" 5)
	  (const :tag "4" 4)
	  (const :tag "3" 3)
	  (const :tag "2" 2)
	  (const :tag "Show everything including the least severe: 1" 1)
	  (const :tag "Default from .perlcriticrc" nil))
  :group 'perlcritic)
(make-variable-buffer-local 'perlcritic-severity)

(defcustom perlcritic-top nil
  "Directs \"perlcritic\" to report only the top N Policy violations in
each file, ranked by their severity. If the -severity option is not
explicitly given, the -top option implies that the minimum severity
level is 1. Users can redefine the severity for any Policy in their
.perlcriticrc file.

This variable is automatically buffer-local and may be overridden on a
per-file basis with File Variables."
  :type '(integer)
  :group 'perlcritic)
(make-variable-buffer-local 'perlcritic-top)

(defcustom perlcritic-include nil
  "Directs \"perlcritic\" to apply additional Policies that match the regex \"/PATTERN/imx\".
Use this option to override your profile and/or the severity settings.

For example:

  layout

This would cause \"perlcritic\" to apply all the \"CodeLayout::*\" policies
even if they have a severity level that is less than the default level of 5,
or have been disabled in your .perlcriticrc file.  You can specify multiple
`perlcritic-include' options and you can use it in conjunction with the
`perlcritic-exclude' option.  Note that `perlcritic-exclude' takes precedence
over `perlcritic-include' when a Policy matches both patterns.  You can set
the default value for this option in your .perlcriticrc file."
  :type '(string)
  :group 'perlcritic)
(make-variable-buffer-local 'perlcritic-include)

(defcustom perlcritic-exclude nil
  "Directs \"perlcritic\" to not apply any Policy that matches the regex
\"/PATTERN/imx\".  Use this option to temporarily override your profile and/or
the severity settings at the command-line.  For example:

  strict

This would cause \"perlcritic\" to not apply the \"RequireUseStrict\" and
\"ProhibitNoStrict\" Policies even though they have the highest severity
level.  You can specify multiple `perlcritic-exclude' options and you can use
it in conjunction with the `perlcritic-include' option.  Note that
`perlcritic-exclude' takes precedence over `perlcritic-include' when a Policy
matches both patterns.  You can set the default value for this option in your
.perlcriticrc file."
  :type '(string)
  :group 'perlcritic)
(make-variable-buffer-local 'perlcritic-exclude)


(defcustom perlcritic-force nil
  "Directs \"perlcritic\" to ignore the magical \"## no critic\"
pseudo-pragmas in the source code. You can set the default value for this
option in your .perlcriticrc file."
  :type '(boolean)
  :group 'perlcritic)
(make-variable-buffer-local 'perlcritic-force)

(defcustom perlcritic-verbose nil
  "Sets the numeric verbosity level or format for reporting violations. If
given a number (\"N\"), \"perlcritic\" reports violations using one of the
predefined formats described below. If the `perlcritic-verbose' option is not
specified, it defaults to either 4 or 5, depending on whether multiple files
were given as arguments to \"perlcritic\".  You can set the default value for
this option in your .perlcriticrc file.

Verbosity     Format Specification
-----------   -------------------------------------------------------------
 1            \"%f:%l:%c:%m\n\",
 2            \"%f: (%l:%c) %m\n\",
 3            \"%m at %f line %l\n\",
 4            \"%m at line %l, column %c.  %e.  (Severity: %s)\n\",
 5            \"%f: %m at line %l, column %c.  %e.  (Severity: %s)\n\",
 6            \"%m at line %l, near ’%r’.  (Severity: %s)\n\",
 7            \"%f: %m at line %l near ’%r’.  (Severity: %s)\n\",
 8            \"[%p] %m at line %l, column %c.  (Severity: %s)\n\",
 9            \"[%p] %m at line %l, near ’%r’.  (Severity: %s)\n\",
10            \"%m at line %l, column %c.\n  %p (Severity: %s)\n%d\n\",
11            \"%m at line %l, near ’%r’.\n  %p (Severity: %s)\n%d\n\"

Formats are a combination of literal and escape characters similar to the way
\"sprintf\" works.  See String::Format for a full explanation of the
formatting capabilities.  Valid escape characters are:

Escape    Meaning
-------   ----------------------------------------------------------------
%c        Column number where the violation occurred
%d        Full diagnostic discussion of the violation
%e        Explanation of violation or page numbers in PBP
%F        Just the name of the file where the violation occurred.
%f        Path to the file where the violation occurred.
%l        Line number where the violation occurred
%m        Brief description of the violation
%P        Full name of the Policy module that created the violation
%p        Name of the Policy without the Perl::Critic::Policy:: prefix
%r        The string of source code that caused the violation
%s        The severity level of the violation

The purpose of these formats is to provide some compatibility with text
editors that have an interface for parsing certain kinds of input.


This variable is automatically buffer-local and may be overridden on a
per-file basis with File Variables."
  :type '(integer)
  :group 'perlcritic)
(make-variable-buffer-local 'perlcritic-verbose)

;; TODO: Enable strings in perlcritic-verbose.
;; (defcustom perlcritic-verbose-regexp nil
;;   "An optional  regexp to match the warning output.
;;
;; This is used when `perlcritic-verbose' has a regexp instead of one of
;; the standard verbose levels.")
;; (make-local-variable 'perlcritic-verbose-regexp)


;; compile.el requires that something be the "filename." I've tagged
;; the severity with that. It happens to make it get highlighted in
;; red. The following advice on COMPILATION-FIND-FILE makes sure that
;; the "filename" is getting ignored when perlcritic is using it.

;; These patterns are defined in Perl::Critic::Utils

(defvar perlcritic-error-error-regexp-alist nil
  "Alist that specified how to match errors in perlcritic output.")
(setq perlcritic-error-error-regexp-alist
      '(;; Verbose level 1
        ;;  "%f:%l:%c:%m\n"
        ("^\\([^\n]+\\):\\([0-9]+\\):\\([0-9]+\\)" 1 2 3 1)

        ;; Verbose level 2
        ;;  "%f: (%l:%c) %m\n"
        ("^\\([^\n]+\\): (\\([0-9]+\\):\\([0-9]+\\))" 1 2 3 1)

        ;; Verbose level 3
        ;;   "%m at %f line %l\n"
        ("^[^\n]+ at \\([^\n]+\\) line \\([0-9]+\\)" 1 2 nil 1)
        ;;   "%m at line %l, column %c.  %e.  (Severity: %s)\n"
        ("^[^\n]+ at line\\( \\)\\([0-9]+\\), column \\([0-9]+\\)." nil 2 3 1)

        ;; Verbose level 4
        ;;   "%m at line %l, column %c.  %e.  (Severity: %s)\n"
        ("^[^\n]+\\( \\)at line \\([0-9]+\\), column \\([0-9]+\\)" nil 2 3)
        ;;   "%f: %m at line %l, column %c.  %e.  (Severity: %s)\n"
        ("^\\([^\n]+\\): [^\n]+ at line \\([0-9]+\\), column \\([0-9]+\\)" 1 2 3)

        ;; Verbose level 5
        ;;    "%m at line %l, near '%r'.  (Severity: %s)\n"
        ("^[^\n]+ at line\\( \\)\\([0-9]+\\)," nil 2)
        ;;    "%f: %m at line %l, column %c.  %e.  (Severity: %s)\n"
        ("^\\([^\n]+\\): [^\n]+ at line \\([0-9]+\\), column \\([0-9]+\\)" 1 2 3)

        ;; Verbose level 6
        ;;    "%m at line %l, near '%r'.  (Severity: %s)\\n"
        ("^[^\n]+ at line\\( \\)\\([0-9]+\\)" nil 2)
        ;;    "%f: %m at line %l near '%r'.  (Severity: %s)\n"
        ("^\\([^\n]+\\): [^\n]+ at line \\([0-9]+\\)" 1 2)

        ;; Verbose level 7
        ;;    "%f: %m at line %l near '%r'.  (Severity: %s)\n"
        ("^\\([^\n]+\\): [^\n]+ at line \\([0-9]+\\)" 1 2)
        ;;    "[%p] %m at line %l, column %c.  (Severity: %s)\n"
        ("^\\[[^\n]+\\] [^\n]+ at line\\( \\)\\([0-9]+\\), column \\([0-9]+\\)" nil 2 3)

        ;; Verbose level 8
        ;;    "[%p] %m at line %l, column %c.  (Severity: %s)\n"
        ("^\\[[^\n]+\\] [^\n]+ at line\\( \\)\\([0-9]+\\), column \\([0-9]+\\)" nil 2 3)
        ;;    "[%p] %m at line %l, near '%r'.  (Severity: %s)\n"
        ("^\\[[^\n]+\\] [^\n]+ at line\\( \\)\\([0-9]+\\)" nil 2)

        ;; Verbose level 9
        ;;    "%m at line %l, column %c.\n  %p (Severity: %s)\n%d\n"
        ("^[^\n]+ at line\\( \\)\\([0-9]+\\), column \\([0-9]+\\)" nil 2 3)
        ;;    "[%p] %m at line %l, near '%r'.  (Severity: %s)\n"
        ("^\\[[^\n]+\\] [^\n]+ at line\\( \\)\\([0-9]+\\)" nil 2)

        ;; Verbose level 10
        ;;    "%m at line %l, near '%r'.\n  %p (Severity: %s)\n%d\n"
        ("^[^\n]+ at line\\( \\)\\([0-9]+\\)" nil 2)
        ;;    "%m at line %l, column %c.\n  %p (Severity: %s)\n%d\n"
        ("^[^\n]+ at line\\( \\)\\([0-9]+\\), column \\([0-9]+\\)" nil 2 3)

        ;; Verbose level 11
        ;;    "%m at line %l, near '%r'.\n  %p (Severity: %s)\n%d\n"
        ("^[^\n]+ at line\\( \\)\\([0-9]+\\)" nil 2)
        ))



;; The Emacs Lisp manual says to do this with the cl library.
(eval-when-compile (require 'cl))

(define-compilation-mode perlcritic-error-mode "perlcritic-error"
  "..."
  (set (make-local-variable 'perlcritic-buffer) src-buf)
  (ad-activate #'compilation-find-file))

;;;###autoload
(defun perlcritic ()
  "\\[perlcritic]] returns a either nil or t depending on whether the
current buffer passes perlcritic's check. If there are any warnings
those are displayed in a separate buffer."
  (interactive)
  (save-restriction
    (widen)
    (perlcritic-region (point-min) (point-max))))

;;;###autoload
(defun perlcritic-region (start end)
  "\\[perlcritic-region] returns a either nil or t depending on
whether the region passes perlcritic's check. If there are any
warnings those are displayed in a separate buffer."

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
					     (perlcritic--param-profile)
					     (perlcritic--param-noprofile)
                                             (perlcritic--param-severity)
                                             (perlcritic--param-top)
					     (perlcritic--param-include)
					     (perlcritic--param-exclude)
					     (perlcritic--param-force)
                                             (perlcritic--param-verbose))
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
				      (goto-char (point-min))
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
              (perlcritic-error-mode)
              ;; (ad-deactivate #'compilation-find-file)
              (display-buffer err-buf))

	    ;; Return our success or failure.
            perlcritic-ok))))))




;;; Parameters for use by perlcritic-region.
(defun perlcritic--param-profile ()
  "A private method that supplies the -profile FILENAME parameter for
\\[perlcritic-region]"
  (if perlcritic-profile (list "-profile" perlcritic-profile)))

(defun perlcritic--param-noprofile ()
  "A private method that supplies the -noprofile parameter for
\\[perlcritic-region]"
  (if perlcritic-noprofile (list "-noprofile")))

(defun perlcritic--param-force ()
  "A private method that supplies the -force parameter for
\\[perlcritic-region]"
  (if perlcritic-force (list "-force")))

(defun perlcritic--param-severity ()
  "A private method that supplies the -severity NUMBER parameter for
\\[perlcritic-region]"
  (cond ((stringp perlcritic-severity)
	 (list "-severity" perlcritic-severity))
        ((numberp perlcritic-severity)
	 (list "-severity" (number-to-string perlcritic-severity)))
        (t nil)))

(defun perlcritic--param-top ()
  "A private method that supplies the -top NUMBER parameter for
\\[perlcritic-region]"
  (cond ((stringp perlcritic-top)
	 (list "-top" perlcritic-top))
        ((numberp perlcritic-top)
	 (list "-top" (number-to-string perlcritic-top)))
        (t nil)))

(defun perlcritic--param-include ()
  "A private method that supplies the -include REGEXP parameter for
\\[perlcritic-region]"
  (if perlcritic-include
      (list "-include" perlcritic-include)
    nil))

(defun perlcritic--param-exclude ()
  "A private method that supplies the -exclude REGEXP parameter for
\\[perlcritic-region]"
  (if perlcritic-exclude
      (list "-exclude" perlcritic-exclude)
    nil))

(defun perlcritic--param-verbose ()
  "A private method that supplies the -verbose NUMBER parameter for
\\[perlcritic-region]"
  (cond ((stringp perlcritic-verbose)
	 (list "-verbose" perlcritic-verbose))
        ((numberp perlcritic-verbose)
	 (list "-verbose" (number-to-string perlcritic-verbose)))
        (t nil)))


;; Interactive functions for use by the user to modify parameters on
;; an adhoc basis. I'm sure there's room for significant niceness
;; here. Suggest something. Please.
(defun perlcritic-profile (profile)
  "Sets perlcritic's -profile FILENAME parameter."
  (interactive "sperlcritic -profile: ")
  (setq perlcritic-profile (if (string= profile "") nil profile)))

(defun perlcritic-noprofile (noprofile)
  "Toggles perlcritic's -noprofile parameter."
  (interactive (list (yes-or-no-p "Enable perlcritic -noprofile? ")))
  (setq perlcritic-noprofile noprofile))

(defun perlcritic-force (force)
  "Toggles perlcritic's -force parameter."
  (interactive (list (yes-or-no-p "Enable perlcritic -force? ")))
  (setq perlcritic-force force))

(defun perlcritic-severity (severity)
  "Sets perlcritic's -severity NUMBER parameter."
  (interactive "nperlcritic -severity: ")
  (setq perlcritic-severity severity))

(defun perlcritic-top (top)
  "Sets perlcritic's -top NUMBER parameter."
  (interactive "nperlcritic -top: ")
  (setq perlcritic-top top))

(defun perlcritic-include (include)
  "Sets perlcritic's -include REGEXP parameter."
  (interactive "sperlcritic -include: ")
  (setq perlcritic-include include))

(defun perlcritic-exclude (exclude)
  "Sets perlcritic's -exclude REGEXP parameter."
  (interactive "sperlcritic -exclude: ")
  (setq perlcritic-exclude exclude))

(defun perlcritic-verbose (verbose)
  "Sets perlcritic's -verbose NUMBER parameter."
  (interactive "nperlcritic -verbose: ")
  (setq perlcritic-verbose verbose))





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

;; Local Variables:
;; mode: emacs-lisp
;; tab-width: 8
;; fill-column: 78
;; indent-tabs-mode: nil
;; End:
;; ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :

;;; perlcritic.el ends here
