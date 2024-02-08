This repository serves as a dummy for reproducible data analysis environments, utilizing Nix and direnv with a flake for managing dependencies and ensuring reproducibility. The main technologies employed in this repository are Python and PostgreSQL.

## Using Nix Flakes and Direnv
Direnv provides a reproducible way to manage and build development environments. The flake.nix file defines the project's dependencies and environment. Additionally, Direnv is used to automatically load the project's environment when entering the project directory.

## Managing Python Dependencies
Python dependencies are managed using Nix expressions within the flake.nix file. This approach ensures that all dependencies are managed and built within the Nix ecosystem, eliminating the need for tools like pip or virtualenv.
