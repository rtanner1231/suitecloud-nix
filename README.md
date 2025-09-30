# suitecloud-nix

Nix flake for using Netsuite's [Suitecloud CLI](https://www.npmjs.com/package/@oracle/suitecloud-cli?activeTab=versions).  Adds the suitecloud command to your environment.

This flake only installs the CLI, it does not install any of the dependencies to make it work (Java JDK, Gnome Keyring, etc.)

This project is in no way affiliated with Oracle or Netsuite.

## Usage

Use like any other flake.

Example:
This will install create a temporary shell with the suitecloud command available.
```sh
nix shell github:rtanner1231/suitecloud-nix
```

Alternatively, you can add this to your system flake.nix file and install it globally.

