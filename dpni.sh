#! /bin/bash




DPMAC=$1

echo "Setting up DPAA2 environment on $DPMAC for 16T16R configuration"




export MAX_QUEUES=16

export FS_ENTRIES=16

export MAX_TCS=16

export DPBP_COUNT=40





#check if required parametrs are given or not

if [ -z "$DPMAC" ]

then

    printf "Dpmac ID not given, exiting...\n"

    return

fi




ADDNI_OUTPUT=$(ls-addni $DPMAC)

x=$?;




if [ "$x" = 0 ]

then

    LINUX_IF=$(echo $ADDNI_OUTPUT | grep "Created interface" | grep -o eth[0-9]*)

    LINUX_DPNI=$(echo $ADDNI_OUTPUT | grep "Created interface" | grep -o dpni.[0-9]*)




elif grep -q "already linked" <<< "$ADDNI_OUTPUT"

then

    LINUX_DPNI=$(echo $ADDNI_OUTPUT | grep -o dpni.[0-9]*)

    LINUX_IF=$(ls-listni | grep "end point: $DPMAC" | grep -o eth[0-9]*)

    LINUX_DPRC=$(ls-listni | grep $LINUX_DPNI | grep -o dprc.[0-9]* | head -1)




    echo "using existing $LINUX_DPNI under $LINUX_DPRC for non-ecpri traffic"




    restool dprc disconnect $LINUX_DPRC --endpoint=$LINUX_DPNI

else

    echo "Failed to run ls-addni, exiting...!!"

    return

fi




source /usr/local/dpdk/dpaa2/dynamic_dpl.sh $DPMAC dpni

sleep 1

echo "Created $DPRC"




echo $DPRC > /sys/bus/fsl-mc/drivers/vfio-fsl-mc/unbind

sleep 1




restool dprc disconnect $DPRC --endpoint=$DPNI1

sleep 1




restool dpdmux create --num-ifs=3 --method DPDMUX_METHOD_CUSTOM --manip=DPDMUX_MANIP_NONE --option=DPDMUX_OPT_CLS_MASK_SUPPORT,DPDMUX_OPT_AUTO_MAX_FRAME_LEN --container=dprc.1 --default-if=1 --mem-size=1024 --max-dmat-entries=16

sleep 1




restool dprc connect dprc.1 --endpoint1=dpdmux.0.0 --endpoint2=$DPMAC

restool dprc connect dprc.1 --endpoint1=dpdmux.0.1 --endpoint2=$LINUX_DPNI

restool dprc connect dprc.1 --endpoint1=dpdmux.0.2 --endpoint2=$DPNI1

restool dprc connect dprc.1 --endpoint1=dpdmux.0.3 --endpoint2=$DPNI2

sleep 1




restool dprc assign dprc.1 --object=dpdmux.0 --child=$DPRC --plugged=1

sleep 1




echo $DPRC > /sys/bus/fsl-mc/drivers/vfio-fsl-mc/bind

sleep 1




restool dpdmux info dpdmux.0




echo "Configuration done..!!"

echo "$DPNI1 and $DPNI2 are created for ecpri data"

echo "Interface $LINUX_IF is created on $LINUX_DPNI for all other data"




export DPAA2_FLOW_CONTROL_MISS_FLOW=0