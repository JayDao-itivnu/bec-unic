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

# mkdir -p ./user_proj_example/runs/24_10_02_13_13
# rm -rf ./user_proj_example/runs/user_proj_example
# ln -s $(realpath ./user_proj_example/runs/24_10_02_13_13) ./user_proj_example/runs/user_proj_example
# docker run -it -u $(id -u $USER):$(id -g $USER) -v ${PWD}:${PWD} -v ${PDK_ROOT}:${PDK_ROOT} -v ${CARAVEL_ROOT}:${CARAVEL_ROOT} -v /home/userdata/ncs/hiepdm/.ipm:/home/userdata/ncs/hiepdm/.ipm -v ${OPENLANE_ROOT}:/openlane -v ${MCW_ROOT}:${MCW_ROOT} -e PDK_ROOT=${PDK_ROOT} -e PDK=${PDK} -e MISMATCHES_OK=1 -e CARAVEL_ROOT=${CARAVEL_ROOT} -e OPENLANE_RUN_TAG=24_10_02_13_13 -e MCW_ROOT=${MCW_ROOT} efabless/openlane:2023.07.19-1 sh -c "flow.tcl -design $(realpath ./user_proj_example) -save_path $(realpath ..) -save -tag 24_10_02_13_13 -overwrite -ignore_mismatches"
# docker run -it -u $(id -u $USER):$(id -g $USER) -v $(realpath /home/userdata/ncs/hiepdm/bec-unic/..):$(realpath /home/userdata/ncs/hiepdm/bec-unic/..) -v /home/userdata/ncs/hiepdm/bec-unic/dependencies/pdks:/home/userdata/ncs/hiepdm/bec-unic/dependencies/pdks -v /home/userdata/ncs/hiepdm/bec-unic/caravel:/home/userdata/ncs/hiepdm/bec-unic/caravel -v /home/userdata/ncs/hiepdm/.ipm:/home/userdata/ncs/hiepdm/.ipm -v /home/userdata/ncs/hiepdm/bec-unic/dependencies/openlane_src:/openlane -v /home/userdata/ncs/hiepdm/bec-unic/mgmt_core_wrapper:/home/userdata/ncs/hiepdm/bec-unic/mgmt_core_wrapper -e PDK_ROOT=/home/userdata/ncs/hiepdm/bec-unic/dependencies/pdks -e PDK=sky130A -e MISMATCHES_OK=1 -e CARAVEL_ROOT=/home/userdata/ncs/hiepdm/bec-unic/caravel -e OPENLANE_RUN_TAG=24_10_02_13_13 -e MCW_ROOT=/home/userdata/ncs/hiepdm/bec-unic/mgmt_core_wrapper  \
#         efabless/openlane:2023.07.19-1 sh -c "flow.tcl -design $(realpath ./user_proj_example) -save_path $(realpath ..) -save -tag 24_10_02_13_13 -overwrite -ignore_mismatches"
# mkdir -p ./sm_bec_v3/runs/${OPENLANE_RUN_TAG}
# rm -rf ./sm_bec_v3/runs/sm_bec_v3
# ln -s $(realpath ./sm_bec_v3/runs/24_10_02_13_13) ./sm_bec_v3/runs/sm_bec_v3
# docker run -it -u $(id -u $USER):$(id -g $USER) -v $(realpath /home/userdata/ncs/hiepdm/bec-unic/..):$(realpath /home/userdata/ncs/hiepdm/bec-unic/..) -v /home/userdata/ncs/hiepdm/bec-unic/dependencies/pdks:/home/userdata/ncs/hiepdm/bec-unic/dependencies/pdks -v /home/userdata/ncs/hiepdm/bec-unic/caravel:/home/userdata/ncs/hiepdm/bec-unic/caravel -v /home/userdata/ncs/hiepdm/.ipm:/home/userdata/ncs/hiepdm/.ipm -v /home/userdata/ncs/hiepdm/bec-unic/dependencies/openlane_src:/openlane -v /home/userdata/ncs/hiepdm/bec-unic/mgmt_core_wrapper:/home/userdata/ncs/hiepdm/bec-unic/mgmt_core_wrapper -e PDK_ROOT=/home/userdata/ncs/hiepdm/bec-unic/dependencies/pdks -e PDK=sky130A -e MISMATCHES_OK=1 -e CARAVEL_ROOT=/home/userdata/ncs/hiepdm/bec-unic/caravel -e OPENLANE_RUN_TAG=24_10_02_13_13 -e MCW_ROOT=/home/userdata/ncs/hiepdm/bec-unic/mgmt_core_wrapper  \
#         efabless/openlane:2023.07.19-1 []
docker run -it -u $(id -u $USER):$(id -g $USER) -v $(realpath /home/userdata/ncs/hiepdm/bec-unic/..):$(realpath /home/userdata/ncs/hiepdm/bec-unic/..) -v /home/userdata/ncs/hiepdm/bec-unic/dependencies/pdks:/home/userdata/ncs/hiepdm/bec-unic/dependencies/pdks -v /home/userdata/ncs/hiepdm/bec-unic/caravel:/home/userdata/ncs/hiepdm/bec-unic/caravel -v /home/userdata/ncs/hiepdm/.ipm:/home/userdata/ncs/hiepdm/.ipm -v /home/userdata/ncs/hiepdm/bec-unic/dependencies/openlane_src:/openlane -v /home/userdata/ncs/hiepdm/bec-unic/mgmt_core_wrapper:/home/userdata/ncs/hiepdm/bec-unic/mgmt_core_wrapper -e PDK_ROOT=/home/userdata/ncs/hiepdm/bec-unic/dependencies/pdks -e PDK=sky130A -e MISMATCHES_OK=1 -e CARAVEL_ROOT=/home/userdata/ncs/hiepdm/bec-unic/caravel -e OPENLANE_RUN_TAG=24_10_01_15_13 -e MCW_ROOT=/home/userdata/ncs/hiepdm/bec-unic/mgmt_core_wrapper  \
        efabless/openlane:2023.07.19-1 sh -c "flow.tcl -it -design $(realpath ./sm_bec_v3) -save_path $(realpath ..) -save -tag 24_10_01_15_13 -overwrite -ignore_mismatches"