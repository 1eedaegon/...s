;;; init.el -*- lexical-binding: t; -*-

(doom! :input

       :completion
       (corfu +orderless)
       vertico

       :ui
       doom
       doom-dashboard
       hl-todo
       modeline
       (popup +defaults)
       vc-gutter

       :editor
       (evil +everywhere)
       fold
       (format +onsave)

       :emacs
       dired
       electric
       undo
       vc

       :term
       vterm

       :checkers
       syntax

       :tools
       biblio            ; citar for Zotero BibTeX
       direnv
       (eval +overlay)
       lookup
       magit
       lsp
       pdf               ; PDF viewing + org-noter
       tree-sitter

       :os
       (:if (featurep :system 'macos) macos)

       :lang
       emacs-lisp
       json
       markdown
       nix
       (org +roam2       ; org-roam Zettelkasten
            +journal     ; daily journal (PE writing practice)
            +noter       ; PDF annotation
            +pretty)     ; pretty rendering
       (rust +lsp +tree-sitter)
       sh
       yaml
       (web +lsp +tree-sitter)

       :config
       (default +bindings +smartparens))
