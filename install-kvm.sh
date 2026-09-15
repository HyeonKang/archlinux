#!/usr/bin/env bash

# 스크립트 실행 중 오류 발생 시 즉시 중단
set -e

echo "=================================================="
echo " Arch Linux QEMU/KVM/Virt-Manager 설치 스크립트"
echo "=================================================="

# 1. 하드웨어 가상화(VT-x/AMD-V) 지원 확인
echo "[1/5] CPU 가상화 지원 여부를 확인합니다..."
if ! lscpu | grep -E -q 'Virtualization:|Hypervisor vendor:'; then
    echo "❌ 에러: CPU가 가상화를 지원하지 않거나 BIOS/UEFI에서 비활성화되어 있습니다."
    exit 1
fi
echo "✅ 가상화 기능이 확인되었습니다."

# 2. 시스템 업데이트 및 필수 패키지 설치
echo "[2/5] 시스템 패키지 저장소를 업데이트하고 QEMU 패키지를 설치합니다..."
sudo pacman -Syu --needed --noconfirm \
    qemu-full \
    virt-manager \
    virt-viewer \
    dnsmasq \
    vde2 \
#   bridge-utils \
    openbsd-netcat \
    iptables-nft \
    dmidecode \
    libguestfs

# 3. Libvirtd 및 개별 가상화 드라이버 서비스 활성화
echo "[3/5] 가상화 시스템 서비스를 등록하고 시작합니다..."
# 최신 Arch 가이드라인에 따라 개별 소켓/서비스 활성화 및 libvirtd 통합 서비스 시작
for drv in qemu interface network nodedev nwfilter secret storage; do
    sudo systemctl enable --now virt${drv}d.service
    sudo systemctl enable --now virt${drv}d{,-ro,-admin}.socket
done
sudo systemctl enable --now libvirtd.service

# 4. 네트워크 설정 (기본 NAT 네트워크 활성화)
echo "[4/5] 기본(Default) 가상 네트워크 구성을 시작합니다..."
sudo virsh net-define /etc/libvirt/qemu/networks/default.xml || true
sudo virsh net-start default || true
sudo virsh net-autostart default || true

# 5. 권한 설정 (일반 사용자 그룹 추가)
echo "[5/5] 현재 사용자를 libvirt 및 kvm 그룹에 등록합니다 (sudo 없이 사용 가능)..."
sudo usermod -aG libvirt,kvm,kvm $USER

echo "=================================================="
echo "🎉 설치가 완료되었습니다!"
echo "⚠️ 권한 변경(그룹 추가)을 적용하려면 시스템을 로그아웃 후 다시 로그인하거나 재부팅해 주세요."
echo "=================================================="
