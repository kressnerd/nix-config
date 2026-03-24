;; -*- no-byte-compile: t; -*-
;;; packages.el

;; Doom Emacs Package Management (via straight.el)
;;
;; This file declares additional Emacs packages to install via straight.el.
;; Following Henrik Lissner's approach: Doom manages ALL Emacs packages,
;; while Nix only provides the Emacs binary and external system tools.
;;
;; After modifying this file, run: doom sync
;; Then restart Emacs for changes to take effect.
;;
;; Note: Most packages are provided by Doom modules in init.el.
;; Only declare packages here that aren't available through Doom modules.

;;; Package Declaration Syntax

;; To install a package from MELPA, ELPA or emacsmirror:
;(package! some-package)

;; To install a package directly from a remote git repo:
;(package! another-package
;  :recipe (:host github :repo "username/repo"))

;; If the package is in a subdirectory:
;(package! this-package
;  :recipe (:host github :repo "username/repo"
;           :files ("some-file.el" "src/lisp/*.el")))

;; To disable a package included with Doom:
;(package! builtin-package :disable t)

;; To override a built-in package recipe:
;(package! builtin-package :recipe (:nonrecursive t))
;(package! builtin-package-2 :recipe (:repo "myfork/package"))

;; To install from a specific branch or tag:
;(package! builtin-package :recipe (:branch "develop"))

;; To pin a package to a specific commit:
;(package! builtin-package :pin "1a2b3c4d5e")

;; To unpin packages (not recommended):
;(unpin! pinned-package)

;;; Actual Package Declarations

;; Nix-specific packages for better NixOS/Nix integration
(package! nixos-options)
(package! company-nixos-options)

;; REST client for API testing (like Postman)
(package! restclient)

;; Enhanced org-mode functionality
(package! org-super-agenda)
(package! org-fancy-priorities)

;; Better large file handling
(package! vlf)

;; Enhanced terminal support
(package! multi-vterm)

;; macOS-specific enhancements
(when IS-MAC
  (package! osx-trash)
  (package! reveal-in-osx-finder))

;;; Development Tools
;; Note: LSP servers and external tools are managed by Nix (not Emacs packages)
;; See home/dan/features/productivity/emacs-doom.nix for system-level tools

;;; Additional Language Support
;; Most language modes come from Doom modules, but you can add extras here
;; Example:
;(package! some-mode)