#!/bin/bash
HERE=$(dirname `readlink -f "${BASH_SOURCE:-$0}"`)
BUILDER_TAG=archiso-builder:latest

function print_help {
  echo "Usage: $(basename $0) [command] [name]"
  echo " Copy Releng: $(basename $0) new [name]"
  echo " Build ISO: $(basename $0) build [config_dir] [custompkgs_dir]"
  echo " Make Packages: $(basename $0) custompkgs [custompkgs_dir]"
}

function process_command {
  local command=$1
  local name=$2

  case $command in
    build)
      pushd $HERE
      if [ -z "$name" ]; then
        echo "Error: No profile name provided for build command"
        print_help
        exit 1
      fi
      
      if [[ -f ./configs/$name/profiledef.sh ]]; then
        releng=`readlink -f ./configs/$name`
      elif [[ -f $name/profiledef.sh ]]; then
        releng=`readlink -f $name`
      else
        echo "Error: Profile $name not found. Can be created with new command"
        exit 1
      fi

      if [[ -n $3 ]]; then
        custompkgs_dir=`readlink -f "$3"`
        if [[ ! -d $custompkgs_dir ]]; then
          echo "Error: Directory $custompkgs_dir not found. Cannot continue..."
          exit 1
        fi
      fi

      echo "Building profile $name..."
      docker compose build
      work_dir=${ARCHISO_WORK_DIR:-/tmp/archiso-$name/work}
      out_dir=${ARCHISO_OUT_DIR:-/tmp/archiso-$name/out}
      
      echo "Work dir: $work_dir"
      echo "Out dir: $out_dir"
      echo "Custompkgs dir: $custompkgs_dir"
      mkdir -p $work_dir $out_dir
      if [[ -n $custompkgs_dir ]]; then
        docker compose run --rm \
          -v $custompkgs_dir:/root/custompkgs \
          -v $custompkgs_dir:/root/archlive/airootfs/root/custompkgs \
          -v $releng:/root/archlive -v $out_dir:$out_dir -v $work_dir:$work_dir -w /root/archlive builder mkarchiso -v -w $work_dir -o $out_dir /root/archlive/
      else
        docker compose run --rm \
          -v $releng:/root/archlive -v $out_dir:$out_dir -v $work_dir:$work_dir -w /root/archlive builder mkarchiso -v -w $work_dir -o $out_dir /root/archlive/
      fi
      if [[ $? -ne 0 ]]; then
        echo "Error: Build failed"
        exit 1
      fi
      # Fix the permissions after we're done
      docker compose run --rm --no-deps \
        -v $out_dir:$out_dir -v $work_dir:$work_dir \
        builder chown -R $(id -u):$(id -g) $out_dir $work_dir
      ls -lah $out_dir/*.iso
      ln -sfn "$(ls -t $out_dir/*.iso | head -n 1)" "$out_dir/latest.iso"
      docker compose down
      popd
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
      docker compose build --pull builder
      container_id=$(docker-compose run --no-deps --rm --name temp_builder -d builder sleep infinity)
      docker cp temp_builder:/usr/share/archiso/configs/releng ./configs/$name
      docker stop temp_builder > /dev/null
      popd
      ;;
    custompkgs)
      if [[ -z $2 ]]; then
        echo "Error: No custompkgs directory provided"
        print_help
        exit 1
      fi
      custompkgs_dir=`readlink -f "$2"`
      if [[ ! -d $custompkgs_dir ]]; then
        echo "Error: Directory $custompkgs_dir not found. Cannot continue..."
        exit 1
      fi
      if [[ ! -f $custompkgs_dir/create.sh ]]; then
        echo "Error: $custompkgs_dir/create.sh not found. Cannot continue..."
        exit 1
      fi
      if [[ ! -f $custompkgs_dir/pkglist.txt ]]; then
        echo "Error: $custompkgs_dir/pkglist.txt not found. Cannot continue..."
        exit 1
      fi
      pushd $HERE
      docker compose build
      docker compose run --rm \
        -v $custompkgs_dir:/root/custompkgs \
        --name custompkgs -w /root/custompkgs builder /root/custompkgs/create.sh
      
      # Fix the permissions after we're done
      docker compose run --rm --no-deps \
        -v $custompkgs_dir:/root/custompkgs \
        builder chown -R $(id -u):$(id -g) /root/custompkgs
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
