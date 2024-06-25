#!/bin/bash
DSCLOUDDIR=$2
PROXY_CONF=$4
if [ ! -z "$PROXY_CONF" ]; then
    export HTTP_PROXY="$PROXY_CONF"
    export HTTPS_PROXY="$PROXY_CONF"
fi
BACKUP_TMPDIR=$3
BACKUP_BUCKET=$1
if [ -z "$BACKUP_BUCKET" ]; then
    exit 1
fi
source $DSCLOUDDIR/vm-creds.sh
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
INST_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id -H "X-aws-ec2-metadata-token: $TOKEN"`
uploadBackup() {
    echo -ne "Upload '$1'...\\n"
    aws s3 $S3_CMDARGS cp $1 $BACKUP_BUCKET/Backup/$INST_ID/
    uplrv=$?
    if [ $uplrv -eq 0 ]; then
        rm -f $1
    fi
}
goThrough() {
    for fent in $1/*
    do
        if [ -d "${fent}" ]; then
            goThrough $fent
        else
            if [ -f "${fent}" ]; then
                uploadBackup $fent
            fi
        fi
    done
}
goThrough $BACKUP_TMPDIR
