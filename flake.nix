{
  description = "A Nix-flake-based Python development environment";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f rec{
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
      });
    in
    {
      devShells =
        forEachSupportedSystem ({ pkgs, lib }:
          let
            psql_setup_file = pkgs.writeText "setup.sql" ''
              DO
              $do$
              BEGIN
                IF NOT EXISTS ( SELECT FROM pg_catalog.pg_roles WHERE rolname = 'leviathan') THEN
                  CREATE ROLE leviathan CREATEDB LOGIN;
                END IF;
              END
              $do$
            '';
            postgres_setup = ''
              export PGDATA=$PWD/postgres_data
              export PGHOST=$PWD/postgres
              export LOG_PATH=$PWD/postgres/LOG
              export PGDATABASE=postgres
              # export DATABASE_CLEANER_ALLOW_REMOTE_DATABASE_URL=true
              if [ ! -d $PGHOST ]; then
                mkdir -p $PGHOST
              fi
              if [ ! -d $PGDATA ]; then
                echo 'Initializing postgresql database...'
                LC_ALL=C.utf8 initdb $PGDATA --auth=trust >/dev/null
              fi
            '';
            start_postgres = pkgs.writeShellScriptBin "start_postgres" ''
              pg_ctl start -l $LOG_PATH -o "-c listen_addresses= -c unix_socket_directories=$PGHOST"
              psql -f ${psql_setup_file} > /dev/null
            '';
            stop_postgres = pkgs.writeShellScriptBin "stop_postgres" ''
              pg_ctl -D $PGDATA stop
            '';
          in
          {
            services = {
              postgresql = {
                enable = true;
                settings = {
                  log_connections = true;
                  log_statement = "all";
                  logging_collector = true;
                  log_disconnections = true;
                  log_destination = lib.mkForce "syslog";
                };
              };
            };
            default = pkgs.mkShell {
              name = "leviathan";
              packages = with pkgs; [
                start_postgres
                stop_postgres
                postgresql
                python311
                virtualenv
              ] ++ (with pkgs.python311Packages; [
                scrapy
                pip
              ]);
              shellHook = ''
                ${pkgs.python311}/bin/python --version
                ${pkgs.postgresql}/bin/postgres --version
                ${postgres_setup}
              '';
            };
          });
    };
}
