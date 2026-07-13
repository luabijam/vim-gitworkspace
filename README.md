# vim-gitworkspace

Multi-repo git status explorer for Vim/Neovim, powered by [gita](https://github.com/nosarthur/gita) and inspired by [vim-fugitive](https://github.com/tpope/vim-fugitive).

## Features

- **Multi-repo overview** — shows all gita-tracked repos in one window
- **Staged / Unstaged grouping** — files grouped by repo and staging status
- **Syntax highlighting** — aligned with fugitive's color scheme
- **In-place refresh** — no flicker on toggle/stage/unstage
- **Fugitive-style keymaps** — familiar shortcuts if you know fugitive

## Requirements

- [gita](https://github.com/nosarthur/gita) (`pip install gita`)
- [vim-fugitive](https://github.com/tpope/vim-fugitive) (for `Gdiffsplit`)

## Installation

With vim-plug:

```vim
Plug '~/.local/share/nvim/plugged/vim-gitworkspace'
```

Or place the plugin directory anywhere on your `&runtimepath`.

## Usage

| Command / Key | Description |
|---|---|
| `:GitWorkspace` | Open the multi-repo status window |
| `<leader>ga` | Toggle the window open/close |

### Keymaps (inside GitWorkspace window)

| Key | Action |
|---|---|
| `<CR>` / `o` | Open file in previous window |
| `-` | Toggle stage / unstage |
| `s` | Stage file (`git add`) |
| `u` | Unstage file (`git reset`) |
| `U` | Unstage all in current repo (`git reset -q`) |
| `dd` | Diff (`Gdiffsplit`) |
| `dv` | Vertical diff (`Gvdiffsplit`) |
| `dh` | Horizontal diff (`Ghdiffsplit`) |
| `X` | Discard changes (`git checkout` / `rm`) |
| `gI` | Append to `.gitignore` |
| `R` | Refresh (in-place, no flicker) |
| `q` | Close window |
| `g?` | Show help |

## Screenshot

```
▶ tool  [master]
▶ risk-proto  [master]
▼ gm-default-api  [feature/story]
  ▼ Staged (3)
    M app/common/common.go
    M app/gateway/mux.go
    M main.go
▶ go-config-test  [master]
▼ gm-chat-logic  [feature/story]
  ▼ Unstaged (17)
     M biz/chat_biz_model.go
     M biz/chat_biz_msg.go
    ?? biz/chat_biz_continue.go
  ▼ Staged (1)
    A biz/new_file.go
```

## License

MIT
