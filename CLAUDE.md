# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

macOS dotfiles repository using directory-per-application structure with manual symlinks.

## Structure

Each top-level directory contains configs for one application. Configs requiring home directory placement (yabai, skhd) use symlinks; XDG-compliant configs are organized under `.config/` subdirectories.

## Neovim

Uses lazy.nvim for plugin management. Entry point is `nvim/.config/nvim/init.lua`.
