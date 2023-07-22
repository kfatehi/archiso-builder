#!/bin/bash
HERE=$(dirname `readlink -f "${BASH_SOURCE:-$0}"`)
BUILDER_TAG=archiso-builder:latest

function print_help {
  echo "Usage: $(basename $0) [command] [name]"
  echo " e.g.: $(basename $0) build [name]"
  echo " e.g.: $(basename $0) new [name]"
}

function process_command {
  local command=$1
  local name=$2

  case $command in
    build)
      if [ -z "$name" ]; then
        echo "Error: No profile name provided for build command"
        print_help
        exit 1
      fi
      if [[ ! -f ./configs/$name/profiledef.sh ]]; then
        echo "Error: Profile $name not found. Can be created with new command"
        exit 1
      fi

      echo "Building profile $name..."
      docker compose build
      mnt=/tmp/archiso-$name
      mkdir -p $mnt/work $mnt/out
      pushd $HERE
      docker compose run --rm -v $HERE/custompkgs:/root/custompkgs -v $HERE/custompkgs:/root/archlive/airootfs/root/custompkgs -v $HERE/configs/$name:/root/archlive -v /tmp:/tmp -w /root/archlive builder mkarchiso -v -w $mnt/work -o $mnt/out /root/archlive/
      popd
      ls -lah $mnt/out/*.iso
      ;;
    new)
      if [ -z "$name" ]; then
        echo "Error: No profile name provided for new command"
        print_help
        exit 1
      fi
      if [[ -d ./configs/$name ]]; then
        echo "Error: Directory configs/$name already exists. Cannot continue..."
        exit 1
      fi

      echo "Creating new profile $name in ./configs by copying default releng config"
      mkdir -p configs
      pushd $HERE
      docker compose build builder
      container_id=$(docker-compose run --no-deps --rm --name temp_builder -d builder sleep infinity)
      docker cp temp_builder:/usr/share/archiso/configs/releng ./configs/$name
      docker stop temp_builder > /dev/null
      popd
      ;;
    custompkgs)
      if [[ ! -f $HERE/custompkgs/pkglist.txt ]]; then
        echo "Error: $HERE/custompkgs/pkglist.txt not found. Cannot continue..."
        exit 1
      fi
      pushd $HERE
      docker compose run --rm -v $HERE/custompkgs:/root/custompkgs --name custompkgs -w /root/custompkgs builder /root/custompkgs/create.sh
      popd
      ;;
    *)
      print_help
      ;;
  esac
}

if [ $# -lt 1 ]; then
  print_help
  exit 1
fi

process_command $@
