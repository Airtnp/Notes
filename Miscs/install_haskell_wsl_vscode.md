# Install OCaml on WSL-Ubuntu with VSCode

## Prerequisite

- WSL-Ubuntu
- VSCode



## Procedure

- WSL-Ubuntu side

  - `curl -sSL https://get.haskellstack.org/ | sh -s - -f`: install  `stack`
  - `stack install ghci hlint`
  - `git clone https://github.com/haskell/haskell-ide-engine --recursive`
  - `cd haskell-ide-engine && stack ./install.sh build-all`

- Windows side

  - install `stack` & `stack install hlint`

  - Solutions for wrapper like OCaml: [link](https://github.com/alanz/vscode-hie-server/issues/99)

    - create `hie.bat`

    - ```bash
      @echo off
      bash -ci "hie-wrapper --lsp"
      ```

- VSCode side

  - install `haskell-linter` extension
  - install `Haskell Syntax Highlighting` extension
  - install `Haskell Language Server` extension
    - change to customized HIE wrapper
    - modify the `extension.js` like the link above

  