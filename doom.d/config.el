;;; config.el -*- lexical-binding: t; -*-
;; Note: user-full-name and user-mail-address are injected by Nix from userRegistry.

;; ── Knowledge base path (CHANGE THIS to your location) ──
(defvar knowledge-base (expand-file-name "~/research-git")
  "Root directory for org-roam, papers, journal, and agenda files.")

;; Theme
(setq doom-theme 'doom-one)

;; Line numbers
(setq display-line-numbers-type 'relative)

;; Font
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 14)
      doom-variable-pitch-font (font-spec :family "FiraCode Nerd Font" :size 14))

;; ── Paths derived from vault ──
(setq org-directory knowledge-base)
(setq org-roam-directory knowledge-base)
(setq org-roam-db-location (expand-file-name ".org-roam.db" knowledge-base))
(setq citar-bibliography (list (expand-file-name "references.bib" knowledge-base)))
(setq citar-notes-paths (list (expand-file-name "papers/reading" knowledge-base)))
(setq org-agenda-files (list (expand-file-name "shutdown.org" knowledge-base)
                             (expand-file-name "weekly/" knowledge-base)))
(setq org-journal-dir (expand-file-name "pe/mock-answers/" knowledge-base))
(setq org-journal-file-format "%Y-%m-%d.org")
(setq org-journal-date-format "#+title: %Y-%m-%d PE Writing\n")

;; ── org-roam capture templates ──
(after! org-roam
  (setq org-roam-capture-templates
        '(("p" "paper" plain
           "\n* Summary\n\n* System Model\n\n* Key Idea\n\n* Proof / Experiment\n\n* Open Questions\n\n* Links\n"
           :target (file+head "papers/reading/${slug}.org"
                    "#+title: ${title}\n#+filetags: :paper:\n#+date: %<%Y-%m-%d>\n")
           :unnarrowed t)

          ("c" "concept" plain
           "\n* Definition\n\n* Why it matters\n\n* System connection\n\n* Links\n"
           :target (file+head "concepts/${slug}.org"
                    "#+title: ${title}\n#+filetags: :concept:\n#+date: %<%Y-%m-%d>\n")
           :unnarrowed t)

          ("e" "pe topic" plain
           "\n* Overview\n\n* Components\n| Item | Description |\n|------+-------------|\n\n* How it works\n\n* Pros / Cons\n\n* Exam points\n\n* Keywords\n"
           :target (file+head "pe/topics/${slug}.org"
                    "#+title: ${title}\n#+filetags: :pe:\n#+date: %<%Y-%m-%d>\n")
           :unnarrowed t)

          ("r" "review" plain
           "\n* Structure check\n\n* Good parts\n\n* Needs fix\n| Location | Issue | Suggestion |\n|----------+-------+------------|\n\n* Technical review\n\n* Next version TODO\n"
           :target (file+head "review/${slug}.org"
                    "#+title: ${title}\n#+filetags: :review:\n#+date: %<%Y-%m-%d>\n")
           :unnarrowed t))))
