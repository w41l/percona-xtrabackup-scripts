#!/bin/sh

REMOTEMNT="/mnt/dbbak"
BACKUPDIR="/mnt/innobackup"
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

if [ ! -f ${REMOTEMNT}/.locknfs ]; then
  echo "${REMOTEMNT} is not mounted"
  exit 1
fi

if [ -r backup.old ]; then
  for x in $(cat backup.old); do
    YEAR=$(echo $x | sed 's/base-//g' | cut -d - -f 1);
    MONTH=$(echo $x | sed 's/base-//g' | cut -d - -f 2);
    REMOTEDIR="${REMOTEMNT}/backup-${YEAR}/bulan-${MONTH}";
    if [ ! -d "${REMOTEDIR}" ]; then
      mkdir -p ${REMOTEDIR}
    fi
    rsync -vP $x ${REMOTEDIR}/ && rm -rf $x;
  done
fi

echo "Finish backup: $(date '+%F %H:%M:%S')"
