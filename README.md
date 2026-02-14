# dotfiles

Personal Linux dotfiles managed with `GNU Stow`.

## Packages

- `config` -> `~/.config/*`
- `shell` -> `~/.zshrc`, `~/.bashrc`
- `git` -> `~/.gitconfig`
- `scripts` -> `~/.scripts/*`

## Screenshots

## Setup

1. Install prerequisites:
   - `git`
   - `stow`
2. Clone this repo:

```bash
git clone https://github.com/structnull/dotfiles ~/.dotfiles
cd ~/.dotfiles
```

3. Preview symlinks (dry run):

```bash
stow -nv -t "$HOME" config shell git scripts
```

4. Apply symlinks:

```bash
stow -t "$HOME" config shell git scripts
```

## Maintenance

- Restow after changes: `stow -R -t "$HOME" config shell git scripts`
- Remove a package: `stow -D -t "$HOME" shell`
