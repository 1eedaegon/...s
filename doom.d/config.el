;;; config.el -*- lexical-binding: t; -*-
;; Place your private configuration here.
;; Note: user-full-name and user-mail-address are injected by Nix (see home/home.nix)

;; Theme
(setq doom-theme 'doom-one)

;; Line numbers
(setq display-line-numbers-type 'relative)

;; Font
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 14)
      doom-variable-pitch-font (font-spec :family "FiraCode Nerd Font" :size 14))

;; Org directory
(setq org-directory "~/org/")
