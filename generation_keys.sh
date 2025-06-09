#!/bin/bash
# Génération des clés Tinc et synchronisation des fichiers hosts entre server, client_01 et client_02

set -e

NODES=(server client_01 client_02)
NETNAME="netlabssir"
BASE_DIR=$(pwd)

# Création des clés et du fichier hosts pour chaque noeud
for NODE in "${NODES[@]}"; do

  echo "\n Génération des clés pour $NODE :"
  cd "$BASE_DIR/$NODE"

  # Génération de la clé si elle n'existe pas
  if [ ! -f rsa_key.priv ]; then
    tincd -n "$NETNAME" -K4096 <<<""
    echo "\n La clé a été générée pour $NODE"
  else
    echo "\n La clé est déjà existante pour $NODE"
  fi

done

# Copie croisée des fichiers hosts
for SRC in "${NODES[@]}"; do
  for DST in "${NODES[@]}"; do
    if [ "$SRC" != "$DST" ]; then
      echo "\n Copie de $SRC/hosts/$SRC dans $DST/hosts/$SRC"
      cp "$BASE_DIR/$SRC/hosts/$SRC" "$BASE_DIR/$DST/hosts/$SRC"
    fi
  done

done

echo "\n Toutes les clés ont été générées et les fichiers hosts synchronisés"
echo "\n Le lab est maintenant prêt à être lancé : docker compose up -d"