#!/bin/bash
set -e

NETNAME="netlabssir"
CONTAINERS=(server client_01 client_02)
TMP_DIR="/tmp/tinc-hosts-sync"

mkdir -p "$TMP_DIR"

# Copie des fichiers hosts de chaque conteneur vers le répertoire temporaire
for C in "${CONTAINERS[@]}"; do
  docker cp "$C:/etc/tinc/$NETNAME/hosts/$C" "$TMP_DIR/$C"
done

# Synchronisation des fichiers hosts entre les conteneurs
for DST in "${CONTAINERS[@]}"; do
  for SRC in "${CONTAINERS[@]}"; do
    if [ "$SRC" != "$DST" ]; then
      docker cp "$TMP_DIR/$SRC" "$DST:/etc/tinc/$NETNAME/hosts/$SRC"
    fi
  done
done

rm -rf "$TMP_DIR"
echo "\n Les fichiers hosts ont été synchronisés entre les conteneurs"
echo "Le labtest est prêt à être utilisé"

