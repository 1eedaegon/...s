;;; init.el -*- lexical-binding: t; -*-
;; Doom Emacs module selection
;; Move your cursor over a module's name and press 'K' to view its documentation.
;; Press 'gd' to browse its directory (for source code).

(doom! :input

       :completion
       company           ; the ultimate code completion backend
       vertico           ; the search engine of the future

       :ui
       doom              ; what makes DOOM look the way it does
       doom-dashboard    ; a nifty splash screen for Emacs
       hl-todo           ; highlight TODO/FIXME/NOTE/DEPRECATED/HACK/REVIEW
       modeline          ; snazzy, Atom-inspired modeline, plus API
       ophints           ; highlight the region an operation acts on
       (popup +defaults) ; tame sudden yet inevitable temporary windows
       treemacs          ; a project drawer, like neotree but cooler
       vc-gutter         ; vcs diff in the fringe
       vi-tilde-fringe   ; fringe tildes to mark beyond EOB
       workspaces        ; tab emulation, persistence & separate workspaces

       :editor
       (evil +everywhere); come to the dark side, we have cookies
       file-templates    ; auto-snippets for empty files
       fold              ; (nstrstrst) universal code folding
       (format +onsave)  ; automated prettiness
       snippets          ; my elves. They type so I don't have to

       :emacs
       dired             ; making dired pretty [functional]
       electric          ; smarter, keyword-based electric-indent
       undo              ; persistent, smarter undo for your inevitable mistakes
       vc                ; version-control and Emacs, sitting in a tree

       :term
       vterm             ; the best terminal emulation in Emacs

       :checkers
       syntax            ; tasing you for every semicolon you forget

       :tools
       direnv
       (eval +overlay)   ; run code, run (also, determine type information on-the-fly)
       lookup            ; navigate your code and its documentation
       magit             ; a git porcelain for Emacs
       lsp
       tree-sitter

       :os
       (:if (featurep :system 'macos) macos) ; improve compatibility with macOS

       :lang
       emacs-lisp        ; drown in parentheses
       json              ; At least it ain't XML
       markdown          ; writing docs for people to ignore
       nix               ; I hereby declare "everything combinator"
       org               ; organize your plain life in plain text
       (rust +lsp +tree-sitter) ; Fe2O3.unwrap().hierarchical()
       sh                ; she sells {ba,z,fi}sh shells on the C xor
       yaml              ; JSON, but readable
       (web +lsp +tree-sitter) ; the hierarchical hierarchical

       :config
       (default +bindings +smartparens))
