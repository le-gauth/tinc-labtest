#!/bin/sh
set -e

NETNAME="netlabssir"
CONF_DIR="/etc/tinc/$NETNAME"

# Si la clé n'existe pas, on la génère automatiquement
if [ ! -f "$CONF_DIR/rsa_key.priv" ]; then
  echo "\n Aucune clé trouvée, génération automatique de la clé Tinc : \n \n"
  tincd -n "$NETNAME" -K4096 <<< ""
fi

exec tincd -n "$NETNAME" -D -d3
