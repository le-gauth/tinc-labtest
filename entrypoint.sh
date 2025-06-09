#!/bin/sh
set -e

NETNAME="netlabssir"
CONF_DIR="/etc/tinc/$NETNAME"
SHARED_DIR="/shared"
HOSTNAME="${NODE_NAME:-$(hostname)}"

# Création du répertoire hosts s'il n'existe pas
mkdir -p "$CONF_DIR/hosts"

# Création du fichier tinc.conf s'il n'existe pas
if [ ! -f "$CONF_DIR/tinc.conf" ]; then
  echo "Name = $HOSTNAME" > "$CONF_DIR/tinc.conf"
fi

# Génération des clés si elles n'existent pas
if [ ! -f "$CONF_DIR/rsa_key.priv" ]; then
  echo "Génération des clés pour $HOSTNAME..."
  echo | tincd -n "$NETNAME" -K4096
fi

# Copie des clés public dans le répertoire partagé
cp "$CONF_DIR/hosts/$HOSTNAME" "$SHARED_DIR/$HOSTNAME"

# Import des clés des autres pairs depuis le répertoire partagé
for file in "$SHARED_DIR"/*; do
  peer=$(basename "$file")
  if [ "$peer" != "$HOSTNAME" ] && [ ! -f "$CONF_DIR/hosts/$peer" ]; then
    echo "Import de la clé de $peer"
    cp "$file" "$CONF_DIR/hosts/$peer"

    # Si c'est le fichier server_01, ajoute Address et Port au début
    if [ "$peer" = "server_01" ]; then
      # Crée un fichier temporaire avec les deux lignes
      echo "Address = 192.168.175.10" > "$CONF_DIR/hosts/server_01.tmp"
      echo "Port = 655" >> "$CONF_DIR/hosts/server_01.tmp"
      # Ajoute le contenu original
      cat "$CONF_DIR/hosts/server_01" >> "$CONF_DIR/hosts/server_01.tmp"
      # Remplace l'original par le fichier corrigé
      mv "$CONF_DIR/hosts/server_01.tmp" "$CONF_DIR/hosts/server_01"
    fi
  fi
done

# Si le fichier server_01 n'existe pas, on attend qu'il soit créé
# Copie de la clé du serveur sur les clients
if [ "$HOSTNAME" != "server_01" ]; then
  echo "En attente de la clé du serveur..."
  while [ ! -f "$CONF_DIR/hosts/server_01" ]; do
    if [ -f "$SHARED_DIR/server_01" ]; then
      cp "$SHARED_DIR/server_01" "$CONF_DIR/hosts/server_01"
      # Ajoute Address et Port au début du fichier server_01
      echo "Address = 192.168.175.10" > "$CONF_DIR/hosts/server_01.tmp"
      echo "Port = 655" >> "$CONF_DIR/hosts/server_01.tmp"
      cat "$CONF_DIR/hosts/server_01" >> "$CONF_DIR/hosts/server_01.tmp"
      mv "$CONF_DIR/hosts/server_01.tmp" "$CONF_DIR/hosts/server_01"
      break
    fi
    sleep 1
  done
fi

# Ajustement de l'adresse IP du serveur pour le client_02
if [ "$HOSTNAME" = "client_02" ]; then
  sed -i 's/192.168.175.10/10.13.37.5/g' "$CONF_DIR/hosts/server_01"
fi

# Rendre exécutable les scripts tinc-up et tinc-down
chmod +x "$CONF_DIR/tinc-up" "$CONF_DIR/tinc-down"

# Lancement de tincd en mode démon débug 3
exec tincd -n "$NETNAME" -D -d3
