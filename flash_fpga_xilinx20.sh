#!/bin/bash

set -ex

FPGA_BITFILE="Px/p7d_v70824/xilinx_poc1465_snic-sf-iep_201920_70824/hw/xilinx_poc1465_snic-sf-iep_201920_70824.mcs"
FLASH_CONFIG='flash_images/20200928.90d3f/mattituck/p7d/070824_iep/fpga_ef100p0_ef100_2x_vblk.mcs'
FW_ELF='nmc/v0.11.3.0/york/york_p7d_debug/cmc_fw.elf'
# FW_ELF="$(realpath --relative-to /projects/riverhead/Release /home/jp/FWRIVERHD-1372/cmc_fw.elf)"

function update_fpga() {
    local dut=$1
    local partner=$2
    local ret=0

    # /home/jp/src/runbench/riverhead_imager.py -m $dut \
    riverhead_imager -m $dut \
                     --uart-host $partner \
                     --fpga-bitfile ${FPGA_BITFILE} \
                     --smartnic-platform york \
                     --smartnic-flash-config ${FLASH_CONFIG} \
                     -o debian10 -a x86_64 -k 5.7.0-0.bpo.2-amd64 --iommu 0 -f odr

    ret=$?
    return $ret
}


function load_fw() {
    local dut=$1
    local partner=$2
    local ret=0

    riverhead_imager -m $dut \
                     --vivado-path /tools/xilinx/vivado/2019.1/ \
                     --uart-host $partner \
                     --smartnic-platform york \
                     --smartnic-fw-path $FW_ELF \
                     -o debian10 -a x86_64 -k 5.7.0-0.bpo.2-amd64 --iommu 0 -f odr


    # --initial-reboot \
    # --extra-kernel-args 'iommu=on,pt intel_iommu=on pci=realloc default_hugepagesz=1G hugepagesz=1G hugepages=32'

    ret=$?
    return $ret
}

# # ******** Kill MC *********
serverpower reboot xilinx20 --force &
serverpower reboot xilinx-ep20 --force &
wait
sleep 120s

select_os -m xilinx-ep20 -o rhel7 -a x86_64 -k 3.10.0-1062.el7.x86_64 --iommu 0 --no-prompt -f odr &
select_os -m xilinx20 -o debian10 -a x86_64 -k 5.7.0-0.bpo.2-amd64 --iommu 0 --no-prompt -f odr &
wait

update_fpga xilinx20 xilinx-ep20

select_os -m xilinx-ep20 -o rhel7 -a x86_64 -k 3.10.0-1062.el7.x86_64 --iommu 0 --no-prompt -f odr &
select_os -m xilinx20 -o debian10 -a x86_64 -k 5.7.0-0.bpo.2-amd64 --iommu 0 --no-prompt -f odr &
wait


#--ignore-image

load_fw xilinx20 xilinx-ep20

# time /home/jp/start_ovs_functional_tests.sh

exit 0
