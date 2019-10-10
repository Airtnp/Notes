# Install OCaml on WSL-Ubuntu with VSCode

## Prerequisite

* WSL-Ubuntu
* VSCode
* npm with YARN



## Procedure

* WSL-Ubuntu side

  * delete `~/.opam` if you initialize without `--disable-sandboxing` (`--reinit` will not work)

  * ```bash
    sudo add-apt-repository ppa:avsm/ppa
    sudo apt-get update
    sudo apt-get install -y gcc make m4 build-essential ocaml ocaml-native-compilers camlp4-extra opam nodejs
    opam init --disable-sandboxing
    opam switch create 4.02.3
    opam install merlin ocp-indent
    ```

* VSCode side

  * install `OCaml and Reason IDE` extension. (The for WSL version is broken due to VSCode upgrdation)

* Windows side

  * `npm install -g bs-platform ocaml-reason-wsl`
  * The default user should not be `root`!

  