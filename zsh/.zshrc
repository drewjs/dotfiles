# ── Homebrew ──────────────────────────────────────────
eval "$(/opt/homebrew/bin/brew shellenv)"

# ── Environment ───────────────────────────────────────
export EDITOR="nvim"
export GIT_EDITOR="nvim"
export DISABLE_AUTO_TITLE="true"
export PRETTIERD_LOCAL_PRETTIER_ONLY="1"

# ── History ──────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY       # timestamps in history
setopt HIST_EXPIRE_DUPS_FIRST # expire dupes before unique
setopt HIST_IGNORE_DUPS       # don't record consecutive dupes
setopt HIST_IGNORE_SPACE      # skip commands starting with space
setopt HIST_VERIFY            # show expanded command before running
setopt SHARE_HISTORY          # share history across sessions
setopt APPEND_HISTORY         # append rather than overwrite

# ── PATH ──────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# ── Cargo ─────────────────────────────────────────────
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# ── fnm (Node) ────────────────────────────────────────
eval "$(fnm env --use-on-cd)"

# ── fzf ───────────────────────────────────────────────
source <(fzf --zsh)
export FZF_DEFAULT_OPTS="--no-height --no-reverse"
if command -v rg &>/dev/null; then
  export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*"'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# ── Plugins (brew) ────────────────────────────────────
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── Aliases ───────────────────────────────────────────
alias v="nvim"
alias co="code-insiders"
alias lg="lazygit"
alias pn="pnpm"
alias px="pnpm dlx"
alias gc="git branch | fzf | xargs git checkout"
alias gk="git branch | fzf | xargs git kill"
alias cl="$HOME/.claude/local/claude"
alias cld="claude --dangerously-skip-permissions"
alias g="git"

# ── Keybindings ───────────────────────────────────────
bindkey -e
bindkey -s ^f "tmux-sessionizer\n"

# ── Starship ──────────────────────────────────────────
eval "$(starship init zsh)"

# ── Local overrides (secrets, machine-specific) ───────
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# ── Completions ───────────────────────────────────────
autoload -Uz compinit && compinit
# [[ -f "$HOME/.openclaw/completions/openclaw.zsh" ]] && source "$HOME/.openclaw/completions/openclaw.zsh"

# OpenClaw Completion
# source "/Users/drewjs/.openclaw/completions/openclaw.zsh"
unset CLAUDE_CODE_OAUTH_TOKEN
