#!/bin/sh

REMOTEMNT="/some/remote/path maybe NFS mount?"
BACKUPDIR="/some/local/backup/path"
BACKUPLIST="${BACKUPDIR}/innobackup.list"
BACKUP_TUNNING=" --compress --parallel=8 --use-memory=2G "
DATEDIR="$(date +%Y-%m-%d_%H-%M-%S)"

echo "Start backup: $(date '+%F %H:%M:%S')"

cd ${BACKUPDIR};
rm -rf base-${DATEDIR};
mkdir -p base-${DATEDIR};

xtrabackup --backup \
    --databases-file=${BACKUPLIST} \
    --socket=/run/mysql/mysql.sock \
    --rsync \
    --no-timestamp \
    ${BACKUP_TUNNING} \
    --no-version-check \
    --target-dir base-${DATEDIR}

sleep 1

LASTLSN=$(cat base-${DATEDIR}/xtrabackup_checkpoints | grep to_lsn | awk '{print $3}')
if [ -z "${LASTLSN}" ]; then
  echo "Backup failed!"
  rm -rf base-${DATEDIR}
  exit 1
fi

if [ -f backup.list ]; then
  mv backup.list backup.old
fi

echo "base-${DATEDIR}.tar.bz2" >backup.list
echo "$LASTLSN" >last.lsn
echo "Last LSN backup: $LASTLSN"

tar cpjf base-${DATEDIR}.tar.bz2 base-${DATEDIR}/;
rm -rf base-${DATEDIR};

# If you are on real machine or qemu/vbox,
# and can perform an nfs mount, then
#if ! df $REMOTEMNT | grep "${REMOTEMNT}" | grep -q nfs 2>/dev/null; then
#  echo "${REMOTEMNT} is not mounted"
#  exit 1
#fi

# Small hack to get nfs mount status if you are on
# lxc container and cannot mount nfs directly.
# You can do this on lxc host before starting container:
#   mount -t nfs some-remote:/path /some/mount/path
#   touch /some/mount/path/.locknfs
# Don't forget to add mount bind /some/mount/path to your container
if [ ! -f ${REMOTEMNT}/.locknfs ]; then
  echo "${REMOTEMNT} is not mounted"
  exit 1
fi

if [ -r backup.old ]; then
  for x in $(cat backup.old); do
    YEAR=$(echo $x | sed 's/base-//g' | cut -d - -f 1);
    MONTH=$(echo $x | sed 's/base-//g' | cut -d - -f 2);
    REMOTEDIR="${REMOTEMNT}/backup-${YEAR}/${MONTH}";
    if [ ! -d "${REMOTEDIR}" ]; then
      mkdir -p ${REMOTEDIR}
    fi
    rsync -vP $x ${REMOTEDIR}/ && rm -rf $x;
  done
fi

echo "Finish backup: $(date '+%F %H:%M:%S')"
