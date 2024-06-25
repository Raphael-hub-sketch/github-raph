#!/bin/bash
DSCLOUDDIR="${DSCLOUDDIR}"
PROXY_CONF="${AWSCLIProxy}"
if [ ! -z "$PROXY_CONF" ]; then
    export HTTP_PROXY="$PROXY_CONF"
    export HTTPS_PROXY="$PROXY_CONF"
fi
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
INST_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id -H "X-aws-ec2-metadata-token: $TOKEN"`
sendAliveMetric() {
    aws cloudwatch put-metric-data --metric-name "$AliveMetricName" --namespace "$AliveMetricNamespace" --value $1 --dimensions InstanceId="$INST_ID"
}
source $DSCLOUDDIR/vm-creds.sh
STEXT=`service datasunrise status 2> /dev/null`
SSTATUS=$?
if [ $SSTATUS -ne 0 ]; then
    echo $STEXT
    sendAliveMetric 0
    exit $SSTATUS
fi
sendAliveMetric 1