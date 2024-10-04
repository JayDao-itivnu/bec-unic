export PWD=`pwd`
export PROJECT_ROOT=${PWD}/..
export PDK=sky130A
export PDK_ROOT=${PROJECT_ROOT}/dependencies/pdks
export OPENLANE_ROOT=${PROJECT_ROOT}/dependencies/openlane_src
export CARAVEL_ROOT=${PROJECT_ROOT}/caravel
export PRECHECK_ROOT=${PROJECT_ROOT}/mpw_precheck
export MCW_ROOT=${PROJECT_ROOT}/mgmt_core_wrapper

export SKYWATER_COMMIT=f70d8ca46961ff92719d8870a18a076370b85f6c
export OPEN_PDKS_COMMIT_LVS=6d4d11780c40b20ee63cc98e645307a9bf2b2ab8
export OPEN_PDKS_COMMIT=78b7bc32ddb4b6f14f76883c2e2dc5b5de9d1cbc
export OPENLANE_RUN_TAG=$(date '+%y_%m_%d_%H_%M')

#export CMD_OPENLANE="flow.tcl -it" 
#export CMD_OPENLANE+="-design $(realpath ./sm_bec_v3) -save_path $(realpath ..) -save -tag 24_10_01_15_13 -overwrite -ignore_mismatches"
#alias openlane="docker run -it -u $(id -u $USER):$(id -g $USER) -v $(realpath ${PROJECT_ROOT}/..):$(realpath ${PROJECT_ROOT}/..) -v ${PDK_ROOT}:${PDK_ROOT} -v ${CARAVEL_ROOT}:${CARAVEL_ROOT} -v ${PROJECT_ROOT}/dependencies/openlane_src:/openlane -v ${MCW_ROOT}:${MCW_ROOT} -e PDK_ROOT=${PDK_ROOT} -e PDK=sky130A -e MISMATCHES_OK=1 -e CARAVEL_ROOT=${CARAVEL_ROOT} -e OPENLANE_RUN_TAG=24_10_01_15_13 -e MCW_ROOT=${MCW_ROOT} \
#        efabless/openlane:2023.07.19-1 sh -c ${CMD_OPENLANE}"
alias openlane='docker run -it -u $(id -u $USER):$(id -g $USER) -v $(realpath ${PROJECT_ROOT}/..):$(realpath ${PROJECT_ROOT}/..) -v ${PDK_ROOT}:${PDK_ROOT} -v ${CARAVEL_ROOT}:${CARAVEL_ROOT} -v ${PROJECT_ROOT}/dependencies/openlane_src:/openlane -v ${MCW_ROOT}:${MCW_ROOT} -e PDK_ROOT=${PDK_ROOT} -e PDK=sky130A -e MISMATCHES_OK=1 -e CARAVEL_ROOT=${CARAVEL_ROOT} -e OPENLANE_RUN_TAG=24_10_01_15_13 -e MCW_ROOT=${MCW_ROOT} efabless/openlane:2023.07.19-1 sh -c "flow.tcl -it -design $(realpath ./sm_bec_v3) -save_path $(realpath ..) -save -tag 24_10_01_15_13 -overwrite -ignore_mismatches"'
alias openroad='docker run -it -u $(id -u $USER):$(id -g $USER) -v $(realpath ${PROJECT_ROOT}/..):$(realpath ${PROJECT_ROOT}/..) -v ${PDK_ROOT}:${PDK_ROOT} -v ${CARAVEL_ROOT}:${CARAVEL_ROOT} -v ${PROJECT_ROOT}/dependencies/openlane_src:/openlane -v ${MCW_ROOT}:${MCW_ROOT} -e PDK_ROOT=${PDK_ROOT} -e PDK=sky130A -e MISMATCHES_OK=1 -e CARAVEL_ROOT=${CARAVEL_ROOT} -e OPENLANE_RUN_TAG=24_10_01_15_13 -e MCW_ROOT=${MCW_ROOT} -e DISPLAY=$DISPLAY -v /Applications/Utilities/XQuartz.app:/Applications/Utilities/XQuartz.app efabless/openlane:2023.07.19-1 sh -c "openroad"'

