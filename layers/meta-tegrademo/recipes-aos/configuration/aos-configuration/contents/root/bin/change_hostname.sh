#!/bin/bash
# Rename the device at runtime: hostnamectl + /etc/hosts rewrite + avahi restart.
# Restarts avahi because it caches the hostname at startup.
set -xeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <new_hostname>" >&2
  exit 1
fi

# Avoid shadowing bash's built-in ${HOSTNAME} (holds the *current* hostname).
NEW_HOSTNAME="$1"

if [[ ! "${NEW_HOSTNAME}" =~ ^[A-Za-z]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$ ]]; then
  echo "Invalid hostname '${NEW_HOSTNAME}'.  Must be 1-63 chars, [A-Za-z0-9-]," >&2
  echo "start with a letter, end with a letter or digit, hyphens only interior." >&2
  exit 1
fi

echo "Changing hostname to ${NEW_HOSTNAME}"

hostnamectl set-hostname "${NEW_HOSTNAME}"

HOSTS_FILE=/etc/hosts
HOSTS_LINE_PREFIX="127.0.1.1"
HOSTS_LINE_REST="${NEW_HOSTNAME}.local ${NEW_HOSTNAME}"

if [[ ! -f "${HOSTS_FILE}" ]]; then
  echo -e "127.0.0.1\tlocalhost" > "${HOSTS_FILE}"
fi

if grep -q '^127\.0\.1\.1' "${HOSTS_FILE}"; then
  /bin/sed -i "s|^127\.0\.1\.1.*|${HOSTS_LINE_PREFIX}\t${HOSTS_LINE_REST}|" "${HOSTS_FILE}"
else
  echo -e "${HOSTS_LINE_PREFIX}\t${HOSTS_LINE_REST}" >> "${HOSTS_FILE}"
fi

# Ignore failure: image may have been built without 'zeroconf'.
if systemctl restart avahi-daemon 2>/dev/null; then
  echo "avahi-daemon restarted -- ${NEW_HOSTNAME}.local should appear on the network within ~1s"
else
  echo "avahi-daemon not available on this image; ${NEW_HOSTNAME}.local will not be published via mDNS" >&2
fi

echo "Done.  Reach the device at ${NEW_HOSTNAME}.local (mDNS) or ${NEW_HOSTNAME} (local /etc/hosts)."
