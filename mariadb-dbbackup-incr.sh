#!/bin/sh

BACKUPDIR="/mnt/innobackup"
DATEDIR=$(date +%F_%H-%M-%S)
BACKUPLIST="${BACKUPDIR}/innobackup.list"
BACKUP_TUNNING=" --compress --parallel=8 --use-memory=2G "
OLDLSN="$(cat ${BACKUPDIR}/last.lsn)"

cd ${BACKUPDIR};

echo "Start backup: $(date '+%F %H:%M:%S')"

if pgrep -f innobackupex >/dev/null; then
  echo "Another innobackupex instance is already running"
  exit 1
fi

BASEBACKUP="$(cat backup.list | grep base 2>/dev/null)"
if [ -z "${BASEBACKUP}" ]; then
  echo "Base backup is not available. Backup failed"
  exit 1
fi

if [ -z "${OLDLSN}" ]; then
  echo "Last backup LSN is missing. Backup failed"
  exit 1
fi

rm -rf ${DATEDIR};
mkdir -p ${DATEDIR};

xtrabackup --backup \
  --databases-file=${BACKUPLIST} \
  --socket=/run/mysql/mysql.sock \
  --rsync \
  --no-timestamp \
  ${BACKUP_TUNNING} \
  --no-version-check \
  --incremental --incremental-lsn=${OLDLSN} \
  --target-dir ${DATEDIR}

sleep 1

LASTLSN="$(cat ${DATEDIR}/xtrabackup_checkpoints | grep to_lsn | awk '{print $3}')"
if [ ! -z "${LASTLSN}" ]; then
  tar cvpjf ${DATEDIR}.tar.bz2 ${DATEDIR}/ && \
  rm -rf ${DATEDIR} && \
  echo "${DATEDIR}.tar.bz2" >>backup.list
  echo "$LASTLSN" >last.lsn
  echo "Last LSN backup: $LASTLSN"
else
  echo "Backup failed!"
  rm -rf ${DATEDIR}
  exit 1
fi

echo "Finish backup: $(date '+%F %H:%M:%S')"
