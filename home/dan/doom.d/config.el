;;; config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;; Early directories (must precede org/org-roam load to override defaults)
(setq org-directory "~/dev/PRIVATE/breq/")
(setq org-roam-directory (file-truename "~/dev/PRIVATE/breq/")
            org-roam-dailies-directory "journals"
            org-roam-dailies-capture-templates
            '(("d" "default" entry
                  "* %?" :target
                  (file+head "%<%Y-%m-%d>.org"
                                      "#+title: %<%a, %d.%m.%Y>\n* Aufgaben\n** \n* Tagesplan\n** \n* Log\n** "))) 
            org-roam-capture-templates
            '(("d" "default" plain
                  "%?" :target
                  (file+head "pages/${slug}.org" "#+title: ${title}\n")
                  :unnarrowed t)))

;; Larger initial GUI window (only when a graphical display is used)
(when (display-graphic-p)
  (setq frame-resize-pixelwise t)
  ;; Append preferred size; Doom may set its own later, so we prepend ours
  (setq initial-frame-alist (append '((width . 180) (height . 55)) initial-frame-alist)
        default-frame-alist (append '((width . 180) (height . 55)) default-frame-alist)))

;;; Personal Information
(setq user-full-name "Daniel Kressner"
      user-mail-address "daniel.kressner@example.com") ; Update with actual email

;;; UI Configuration
;; Font configuration for macOS - using available Nix fonts
;; Using JetBrains Mono as primary font (installed via nix packages)
(setq doom-font (font-spec :family "JetBrains Mono" :size 14 :weight 'medium)
      doom-variable-pitch-font (font-spec :family "Helvetica" :size 16)
      doom-unicode-font (font-spec :family "Menlo" :size 14)
      doom-big-font (font-spec :family "JetBrains Mono" :size 20 :weight 'medium))

;; Fallback font configuration if JetBrains Mono is not available
(when (not (find-font doom-font))
  (setq doom-font (font-spec :family "Monaco" :size 14 :weight 'medium)
        doom-variable-pitch-font (font-spec :family "Arial" :size 16)
        doom-unicode-font (font-spec :family "Monaco" :size 14)
        doom-big-font (font-spec :family "Monaco" :size 20 :weight 'medium)))

;; Theme configuration - keeping doom-one from original
(setq doom-theme 'doom-one)

;; Modeline configuration
(setq doom-modeline-height 32
      doom-modeline-bar-width 3
      doom-modeline-icon t
      doom-modeline-major-mode-icon t
      doom-modeline-buffer-file-name-style 'truncate-upto-project)

;; Dashboard configuration
(setq doom-dashboard-name "Welcome to Doom Emacs"
      +doom-dashboard-menu-sections
      '(("Recently opened files" :icon (nerd-icons-faicon "nf-fa-file_text_o" :face 'doom-dashboard-menu-title) :action recentf-open-files)
        ("Open project" :icon (nerd-icons-codicon "nf-cod-briefcase" :face 'doom-dashboard-menu-title) :action projectile-switch-project)
        ("Jump to bookmark" :icon (nerd-icons-faicon "nf-fa-bookmark" :face 'doom-dashboard-menu-title) :action bookmark-jump)
        ("Open private configuration" :icon (nerd-icons-mdicon "nf-md-wrench" :face 'doom-dashboard-menu-title) :action doom/open-private-config)
        ("Open documentation" :icon (nerd-icons-faicon "nf-fa-book" :face 'doom-dashboard-menu-title) :action doom/help)))

;;; macOS specific configuration
(when IS-MAC
  ;; macOS modifier keys - enable umlauts with left Option key
  (setq mac-option-modifier 'none
        mac-command-modifier 'super
        mac-right-option-modifier 'meta
        ns-use-native-fullscreen nil
        ns-use-fullscreen-animation nil)

  ;; Better scrolling on macOS - from original config
  (setq mouse-wheel-scroll-amount '(1 ((shift) . 1))
        mouse-wheel-progressive-speed nil
        mouse-wheel-follow-mouse t
        scroll-step 1
        scroll-conservatively 10000)

  ;; macOS specific keybindings - from original config
  (global-set-key (kbd "s-=") 'text-scale-increase)
  (global-set-key (kbd "s--") 'text-scale-decrease)
  (global-set-key (kbd "s-0") 'text-scale-adjust)

  ;; PATH integration not needed; Doom env handles shell PATH.
  )

;;; Editor Configuration
;; Line numbers - Doom enables this by default, but ensure it's configured properly
(setq display-line-numbers-type 'relative) ; Use relative line numbers for vim-style navigation

;; Disable line numbers in certain modes where they're not useful
(dolist (mode '(org-mode-hook
                term-mode-hook
                shell-mode-hook
                treemacs-mode-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode -1))))

;; Better defaults matching original configuration
(setq-default
 delete-by-moving-to-trash t                      ; Delete files to trash
 window-combination-resize t                      ; Take new window space from all other windows
 x-stretch-cursor t)                             ; Stretch cursor to the glyph width

(setq undo-limit 80000000                         ; Raise undo-limit to 80Mb
      evil-want-fine-undo t                       ; By default while in insert all changes are one big blob
      auto-save-default t                         ; Nobody likes to lose work
      truncate-string-ellipsis "…"                ; Unicode ellipses are nicer
      scroll-margin 2)                            ; It's nice to maintain a little margin

;;; Org Mode Configuration
(use-package! org
  :init
  ;; Defaults (directory set early above)
  (setq org-agenda-files (list org-directory)
        org-ellipsis " ▾ "
        org-hide-emphasis-markers t
        org-log-done 'time
        org-startup-folded 'overview
        org-startup-with-inline-images t))

(use-package! org-roam
  :after org
  :defer t
  :hook (org-mode . org-roam-db-autosync-enable)
  :init
  (setq org-roam-completion-everywhere t)
  :config
  (setq org-roam-file-exclude-regexp "\\.git/.*\\|logseq/.*$"))
;;; Development Configuration
;; LSP configuration - enhanced from original
(use-package! lsp-mode
  :commands lsp
  ;; Use deferred startup for better responsiveness in large projects
  :hook (nix-mode . lsp-deferred)
  :init
  (setq lsp-keymap-prefix "C-c l")
  :config
  (setq lsp-enable-symbol-highlighting t
        lsp-signature-render-documentation t
        lsp-completion-provider :company-capf
        lsp-log-io nil
        lsp-idle-delay 0.500
        lsp-prefer-flymake nil))

(use-package! lsp-ui
  :after lsp-mode
  :init
  (setq lsp-ui-doc-enable t
        lsp-ui-doc-show-with-cursor nil
        lsp-ui-doc-show-with-mouse t))
 
(use-package! lsp-ivy
  :after lsp-mode
  :defer t)

;; Treemacs integration for LSP (outline, errors, symbols)
(use-package! lsp-treemacs
  :after (lsp-mode treemacs)
  :defer t)

;; Company configuration - use-package style
(use-package! company
  :defer t
  :init
  (setq company-idle-delay 0.2
        company-minimum-prefix-length 2
        company-tooltip-limit 20
        company-tooltip-align-annotations t
        company-require-match 'never
        company-global-modes '(not erc-mode message-mode help-mode gud-mode eshell-mode shell-mode)
        company-auto-complete nil
        company-auto-complete-chars nil
        company-dabbrev-downcase nil
        company-dabbrev-ignore-case nil))
 
(use-package! yasnippet
  :defer t
  :init
  (setq yas-triggers-in-field t
        yas-snippet-dirs (list (concat doom-private-dir "snippets")))
  :config
  (yas-global-mode 1))

;; Projectile configuration
(use-package! projectile
  :defer t
  :init
  (setq projectile-completion-system 'ivy
        projectile-enable-caching t
        projectile-indexing-method 'hybrid))

;;; Nix Integration
(use-package! nix-mode
  :mode ("\\.nix\\'" . nix-mode)
  :init
  (setq nix-indent-function 'nix-indent-line)
  :config
  (set-company-backend! 'nix-mode 'company-capf 'company-nixos-options)
  (map! :localleader
        :map nix-mode-map
        "f" #'nix-format-buffer
        "r" #'nix-repl-show
        "s" #'nix-shell
        "b" #'nix-build
        "u" #'nix-unpack))

;; Removed separate company-nixos-options after! block (merged into nix-mode use-package)

;;; Git Integration
(use-package! magit
  :commands (magit-status magit-branch-checkout)
  :init
  (setq magit-repository-directories '(("~/dev" . 2))
        magit-save-repository-buffers nil
        magit-inhibit-save-previous-winconf 'user)
  :config
  (setq magit-diff-refine-hunk t
        magit-revision-show-gravatars '("^Author:     " . "^Commit:     ")))

;;; Terminal Integration
(use-package! vterm
  :commands (vterm multi-vterm)
  :init
  (setq vterm-max-scrollback 10000
        vterm-buffer-name-string "vterm %s"
        vterm-kill-buffer-on-exit t)
  :config
  (map! :map vterm-mode-map
        "C-c C-t" #'multi-vterm
        "C-c C-n" #'multi-vterm-next
        "C-c C-p" #'multi-vterm-prev))

;;; File Management
(use-package! dired
  :commands (dired dired-jump)
  :init
  (setq dired-dwim-target t
        dired-recursive-copies 'always
        dired-recursive-deletes 'top
        delete-by-moving-to-trash t)
  :config
  (when IS-MAC
    (setq dired-use-ls-dired nil
          insert-directory-program "/usr/bin/ls")))

;;; Custom Keybindings
;; Global keybindings from original configuration
(global-set-key (kbd "C-x C-b") 'ibuffer)
(global-set-key (kbd "C-c r") 'revert-buffer)

;; Additional Doom-specific keybindings
(map! :leader
      ;; File operations
      "f r" #'recentf-open-files
      "f R" #'rename-file-and-buffer
       
      ;; Buffer operations
      "b r" #'revert-buffer
      "b R" #'rename-buffer
       
      ;; Project operations
      "p t" #'multi-vterm-project
       
      ;; Window operations
      "w =" #'balance-windows
       
      ;; Git operations
      "g s" #'magit-status
      "g b" #'magit-branch-checkout
      "g l" #'magit-log-oneline
       
      ;; Search operations
      "s p" #'projectile-ag
      "s d" #'ag-dired)

(map! :leader
      ;; Org-roam dailies
      "n r j" #'org-roam-dailies-goto-today
      "n r n" #'org-roam-dailies-capture-today)

;;; Package-specific configurations
;; REST client configuration
(use-package! restclient
  :mode ("\\.http\\'" . restclient-mode))

;; Treemacs configuration
(use-package! treemacs
  :commands (treemacs treemacs-select-window)
  :init
  (setq treemacs-width 32)
  :config
  (treemacs-follow-mode 1)
  (treemacs-filewatch-mode 1)
  (treemacs-fringe-indicator-mode 1)
  (treemacs-git-mode 'extended))

;; Ivy configuration enhancements
(use-package! ivy
  :after counsel
  :init
  (setq ivy-use-virtual-buffers t
        ivy-count-format "(%d/%d) "
        ivy-display-style 'fancy
        ivy-initial-inputs-alist nil)) ; Don't start searches with ^

;; Which-key configuration
(use-package! which-key
  :defer 1
  :init
  (setq which-key-idle-delay 0.5
        which-key-popup-type 'side-window
        which-key-side-window-location 'bottom
        which-key-side-window-max-width 0.33
        which-key-side-window-max-height 0.25))

;;; Performance optimizations
(use-package! vlf
  :defer t
  :config
  (setq vlf-application 'dont-ask))

;; Garbage collection optimization
(setq gc-cons-threshold 100000000
      read-process-output-max (* 1024 1024))

;;; Spell Checking Configuration
;; Configure ispell to use Hunspell with English and German dictionaries simultaneously
(use-package! ispell
  :init
  ;; On macOS, add user Nix profile to exec-path for GUI Emacs
  (when (and IS-MAC (display-graphic-p))
    (let ((user-bin (expand-file-name "~/.nix-profile/bin")))
      (when (file-directory-p user-bin)
        (add-to-list 'exec-path user-bin)))
    (let ((user-bin "/etc/profiles/per-user/daniel.kressner/bin"))
      (when (file-directory-p user-bin)
        (add-to-list 'exec-path user-bin))))
  
  (setq ispell-program-name "hunspell"
        ispell-dictionary "en_US,de_DE")
  :config
  ;; Configure Hunspell to use multiple dictionaries
  (ispell-set-spellchecker-params)
  (ispell-hunspell-add-multi-dic "en_US,de_DE"))

;; Flyspell configuration for on-the-fly spell checking
(use-package! flyspell
  :hook ((text-mode . flyspell-mode)
         (prog-mode . flyspell-prog-mode))
  :init
  (setq flyspell-issue-message-flag nil
        flyspell-issue-welcome-flag nil))

;;; Load local configuration if it exists
;; This allows for machine-specific configuration without modifying this file
(when (file-exists-p (concat doom-user-dir "local.el"))
  (load! "local"))

;; Load custom file if it exists (for customize interface)
(setq custom-file (expand-file-name "custom.el" doom-user-dir))
(when (file-exists-p custom-file)
  (load custom-file))