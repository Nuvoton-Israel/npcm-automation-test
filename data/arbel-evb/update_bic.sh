#!/bin/bash

set -e
log_file="/tmp/log/update_bic_test.log"

FAIL_TO_UPDATE_PLDM_TIME_OUT_ERROR=22
FAIL_TO_UPDATE_PLDM_FAIL_TO_DELETE_SOFTWARE_ID=23
FAIL_TO_UPDATE_PLDM_IMAGE_DOES_NOT_MATCH=24
FAIL_TO_UPDATE_PLDM_MISS_SOFTWARE_ID=25
FAIL_TO_UPDATE_PLDM_PLDM_SOFTWARE_ACTIVATION_STATUS_FAIL=35

pldm_wait_for_update_complete() {
	local counter=0
	while true
	do
		sleep 2
		echo -ne "Waiting for updating... ${counter} sec"\\r >> $log_file

		# Capture the output of busctl command
		local output
		output=$(busctl get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$software_id" xyz.openbmc_project.Software.ActivationProgress Progress)
		if [ $? -ne 0 ]; then
			local status
			status=$(busctl get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$software_id" xyz.openbmc_project.Software.Activation Activation)
			status=$(echo "$status" | cut -d " " -f 2)
			if [ "${status}" == "xyz.openbmc_project.Software.Activation.Activations.Failed" ] || [ "${status}" == "xyz.openbmc_project.Software.Activation.Activations.Invalid" ]; then
				echo -ne \\n"PLDM software activation is ${status}."\\n >> $log_file
				return $FAIL_TO_UPDATE_PLDM_PLDM_SOFTWARE_ACTIVATION_STATUS_FAIL
			fi
		fi

		# Extract progress value from the output
		local progress
		progress=$(echo "$output" | cut -d " " -f 2)

		if [ "${progress}" == 100 ]; then
			echo -ne \\n"Update done."\\n >> $log_file
			return 0
		fi

		counter=$((counter+2))
		# Over 12 seconds is considered timeout
		if [ "${counter}" == 12 ]; then
			echo -ne \\n"Time out. Fail"\\n >> $log_file
			return $FAIL_TO_UPDATE_PLDM_TIME_OUT_ERROR
		fi
	done
}

update_bic() {

	image="${1}"
	bic_netid="${2}"
	bic_eid="${3}"
	cp "${image}" /tmp/images
	sleep 3

	echo "Generating software ID..."
	software_id=$(busctl tree xyz.openbmc_project.PLDM | grep /xyz/openbmc_project/software/ | cut -d "/" -f 5)
	echo "software_id = $software_id"

	if [ "$software_id" != "" ]; then
		activation=$(busctl  get-property xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$software_id" xyz.openbmc_project.Software.Activation Activation | cut -d " " -f 2)
		if [ "${activation}" == "\"xyz.openbmc_project.Software.Activation.Activations.Activating\"" ]; then
			echo "Object /xyz/openbmc_project/software/"$software_id" is stalled in activating"
			echo "Restarting pldmd to recover it."
			killall pldmd
			pldmd -x ${bic_netid} &
			sleep 1
			update_bic ${image} ${bic_netid} ${bic_eid}
		fi

		busctl set-property xyz.openbmc_project.PLDM /xyz/openbmc_project/software/"$software_id" xyz.openbmc_project.Software.Activation RequestedActivation s "xyz.openbmc_project.Software.Activation.RequestedActivations.Active" >& $log_file
		pldm_wait_for_update_complete
		update_status=$?

		if [ $update_status == $FAIL_TO_UPDATE_PLDM_TIME_OUT_ERROR ]; then
			local output
			output=$(pldmtool fw_update GetStatus -m ${bic_eid} -x ${bic_netid})
			bic_current_state=$(echo "$output" | grep -o '"CurrentState": "[^"]*' | cut -d'"' -f4)
			if [ "$bic_current_state" = "DOWNLOAD" ]; then
				pldmtool raw -d 0x80 0x3f 0x1 0x15 0xa0 0x0 0x18 0x03 -m ${bic_eid} -x ${bic_netid}
				sleep 3 # wait for BIC reset
				echo "BMC send DISCOVERY"
				echo 1 > /sys/bus/i3c/devices/i3c-0/discover
			fi
		fi

		return $update_status
	else
		echo "Fail: Miss software id."
		echo "BMC send DISCOVERY"
		echo 1 > /sys/bus/i3c/devices/i3c-0/discover
		sleep 1
		update_bic ${image} ${bic_netid} ${bic_eid}
	fi
}

echo "Start to Update PLDM component" > $log_file

sleep 1
cd /tmp/
update_bic SMCNPCM_signed_with_header.bin 1 10
ret=$?
if [ $ret -ne 0 ]; then
	echo "pldm update failed!!" >> $log_file
else
	echo "pldm update success." >> $log_file
	sleep 3
fi
