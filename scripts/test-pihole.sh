#!/usr/bin/env sh
set -eu

dns_server="${1:-127.0.0.1}"
allowed_domain="${2:-example.com}"
blocked_domain="${3:-doubleclick.net}"

if ! command -v dig >/dev/null 2>&1; then
  echo "O comando dig não foi encontrado. Instale dnsutils/bind-utils e tente novamente." >&2
  exit 1
fi

echo "Consulta permitida: ${allowed_domain}"
dig @"${dns_server}" "${allowed_domain}" A +short

echo
echo "Consulta que pode ser bloqueada: ${blocked_domain}"
dig @"${dns_server}" "${blocked_domain}" A +short

echo
echo "Veja o Query Log no painel para confirmar a decisão do Pi-hole."
