# MITIGACIÓN: Defensa contra DTP VLAN Hopping

## 🛡️ Estrategia: Deshabilitación Completa de DTP

DTP es un protocolo sin mecanismos de seguridad reales. La mejor defensa es **eliminar completamente su uso**.

---

## 1️⃣ Solución Principal: Switchport Nonegotiate

### Implementación en Puertos de Usuario

```cisco
! Cambiar TODOS los puertos de usuario a modo fijo
Switch(config)# interface range GigabitEthernet0/0/1-24
Switch(config-if-range)# switchport mode access
Switch(config-if-range)# switchport access vlan 10
Switch(config-if-range)# switchport nonegotiate
Switch(config-if-range)# exit

! Verificar aplicación
Switch# show interface GigabitEthernet0/0/1 switchport
Name: Gi0/0/1
Switchport: Enabled
Administrative Mode: static access
Negotiation of Trunking: Off ← DTP DESHABILITADO
```

### Efecto de la Configuración

```
ANTES (Vulnerable):
┌─────────────────────────────────────┐
│ Port: access                        │
│ Negotiation: On (DTP enabled)       │
├─────────────────────────────────────┤
│ Si le llega DTP desirable:          │
│ → Se convierte en TRUNK ✗           │
│ → Acceso multi-VLAN ✗              │
└─────────────────────────────────────┘

DESPUÉS (Protegido):
┌─────────────────────────────────────┐
│ Port: access                        │
│ Negotiation: Off (DTP disabled)     │
├─────────────────────────────────────┤
│ Si le llega DTP desirable:          │
│ → Ignora completamente ✓            │
│ → Se mantiene como access ✓        │
│ → Sin conversión a trunk ✓         │
└─────────────────────────────────────┘
```

---

## 2️⃣ Configuración de Puertos Troncales

### Entre Switches (Trunk Fijo)

```cisco
! Puertos entre switches: SIEMPRE modo fijo
Switch(config)# interface GigabitEthernet0/0/47-48
Switch(config-if-range)# switchport mode trunk
Switch(config-if-range)# switchport trunk encapsulation dot1q
Switch(config-if-range)# switchport trunk allowed vlan 1,10,20,30
Switch(config-if-range)# switchport nonegotiate
Switch(config-if-range)# exit

! Verificar
Switch# show interface GigabitEthernet0/0/47 switchport
Administrative Mode: static trunk
Operational Mode: static trunk
Negotiation of Trunking: Off
Allowed VLANs: 1,10,20,30
```

### Beneficios

✅ **Control explícito**: Qué VLANs se permiten en cada trunk
✅ **Sin sorpresas**: No hay negociación automática
✅ **Seguridad por defecto**: DTP completamente deshabilitado
✅ **Documentación clara**: Configuración en CLI = intención clara

---

## 3️⃣ BPDU Guard y Port Security

### BPDU Guard (Spanning Tree Protection)

```cisco
! En TODOS los puertos de acceso de usuario
Switch(config)# interface range Gi0/0/1-24
Switch(config-if-range)# spanning-tree bpduguard enable
Switch(config-if-range)# exit

! Configurar acción cuando se detecta BPDU
Switch(config)# spanning-tree portfast bpduguard default

! Verificar
Switch# show spanning-tree interface Gi0/0/1 detail
Port 23 (GigabitEthernet0/0/1)
 BPDU Guard is enabled
 BPDU: sent 0, received 0
```

**¿Por qué?** BPDU Guard bloquea puertos que reciben BPDU (incluyendo DTP que usa mecanismo similar)

### Port Security

```cisco
! Asegurar que solo MACs autorizadas comunican
Switch(config)# interface range Gi0/0/1-24
Switch(config-if-range)# switchport port-security
Switch(config-if-range)# switchport port-security maximum 1
Switch(config-if-range)# switchport port-security mac-address sticky
Switch(config-if-range)# switchport port-security violation shutdown
Switch(config-if-range)# exit

! Verificar
Switch# show port-security interface Gi0/0/1
Port Security: Enabled
Port Status: Secure-up
Violation Mode: Shutdown
Maximum MAC Addresses: 1
Total MAC Addresses: 1
Configured MAC Addresses: 0
Sticky MAC Addresses: 1
Last Source Address: 0016.4668.2a01 ← MAC aprendida
```

**Beneficio**: Si se conecta un nuevo dispositivo (atacante), el puerto se deshabilita

---

## 4️⃣ Protocolos Seguros Alternativos

### Reemplazo por Protocolo Automatizado SEGURO

Si necesitas **automatización** de provisioning de VLAN sin DTP:

#### Opción 1: NETCONF/YANG

```python
# Script Python usando NETCONF
from ncclient import manager

with manager.connect(host="switch.local", 
                     username="admin", 
                     password="Secure@2024") as m:
    
    # Crear VLAN automáticamente (sin DTP)
    vlan_config = """
    <config>
      <native xmlns="http://cisco.com/ns/yang/Cisco-IOS-XE">
        <vlan>
          <vlan-list>
            <vlan-id>50</vlan-id>
            <name>NewDepartment</name>
          </vlan-list>
        </vlan>
      </native>
    </config>
    """
    
    m.edit_config(target='candidate', config=vlan_config)
    m.commit()
```

#### Opción 2: Ansible + SSH

```yaml
---
- name: Configure VLAN without DTP
  hosts: switches
  gather_facts: no
  
  tasks:
    - name: Create VLAN
      ios_vlan:
        vlan_id: 50
        name: NewDepartment
        state: present
      
    - name: Assign to interface
      ios_config:
        lines:
          - switchport access vlan 50
          - switchport mode access
          - switchport nonegotiate
        parents: interface GigabitEthernet0/0/5
```

**Ventaja**: Automatización segura, con autenticación y cifrado

---

## 5️⃣ Configuración de Seguridad Completa por Interfaz

### Plantilla de Configuración Segura

```cisco
! ==================== PUERTOS DE USUARIO ====================

Switch(config)# interface GigabitEthernet0/0/1
Switch(config-if)# switchport mode access
Switch(config-if)# switchport access vlan 10
Switch(config-if)#
Switch(config-if)# ! Deshabilitar DTP completamente
Switch(config-if)# switchport nonegotiate
Switch(config-if)#
Switch(config-if)# ! Port Security
Switch(config-if)# switchport port-security
Switch(config-if)# switchport port-security maximum 1
Switch(config-if)# switchport port-security mac-address sticky
Switch(config-if)# switchport port-security violation shutdown
Switch(config-if)#
Switch(config-if)# ! Spanning Tree Security
Switch(config-if)# spanning-tree portfast
Switch(config-if)# spanning-tree bpduguard enable
Switch(config-if)#
Switch(config-if)# ! Otras configuraciones
Switch(config-if)# no cdp run
Switch(config-if)# no shutdown
Switch(config-if)# exit

! ==================== PUERTOS TRONCALES ====================

Switch(config)# interface GigabitEthernet0/0/47
Switch(config-if)# switchport mode trunk
Switch(config-if)# switchport trunk encapsulation dot1q
Switch(config-if)# switchport trunk allowed vlan 1,10,20,30,50
Switch(config-if)#
Switch(config-if)# ! Deshabilitar DTP en puertos troncales
Switch(config-if)# switchport nonegotiate
Switch(config-if)#
Switch(config-if)# ! NO usar BPDU Guard en trunks
Switch(config-if)# ! (bloquearía switches legítimos)
Switch(config-if)#
Switch(config-if)# no shutdown
Switch(config-if)# exit
```

---

## 6️⃣ Script de Hardening Masivo

```cisco
! Hardening script: Aplicar seguridad a todos los puertos

! Primero: Usar configuración en modo en batch
Switch(config)# template USER_PORT_SECURE
Switch(config-template)# switchport mode access
Switch(config-template)# switchport nonegotiate
Switch(config-template)# switchport port-security
Switch(config-template)# switchport port-security maximum 1
Switch(config-template)# switchport port-security mac-address sticky
Switch(config-template)# switchport port-security violation shutdown
Switch(config-template)# spanning-tree portfast
Switch(config-template)# spanning-tree bpduguard enable
Switch(config-template)# exit

! Luego: Aplicar a todos los puertos de usuario
Switch(config)# interface range GigabitEthernet0/0/1-24
Switch(config-if-range)# access-template USER_PORT_SECURE
Switch(config-if-range)# exit

! Verificar (muestra resumen)
Switch# show access-template USER_PORT_SECURE
Switch# show running-config interface Gi0/0/1
```

---

## 7️⃣ Monitoreo y Alerting

### Detección de Intentos de DTP

```bash
#!/bin/bash
# monitor_dtp.sh - Alerta si hay DTP inesperado

SWITCH_IP="192.168.1.1"
ADMIN_USER="admin"
ALERT_EMAIL="security@company.com"

while true; do
    # Ejecutar comando en switch
    STATUS=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no \
             $ADMIN_USER@$SWITCH_IP \
             "show interface GigabitEthernet0/0/1 switchport | grep Negotiation")
    
    # Verificar si DTP está accidentalmente habilitado
    if echo "$STATUS" | grep -q "On"; then
        echo "⚠️ ALERTA: DTP DETECTADO HABILITADO EN GI0/0/1" | \
            mail -s "SEGURIDAD: DTP Habilitado (NO ESPERADO)" $ALERT_EMAIL
            
        # Remediar automáticamente
        sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no \
            $ADMIN_USER@$SWITCH_IP << EOF
configure terminal
interface GigabitEthernet0/0/1
switchport nonegotiate
exit
exit
EOF
        
        echo "DTP deshabilitado automáticamente"
    fi
    
    sleep 300  # Verificar cada 5 minutos
done
```

### Alertas en Wireshark

```
Crear regla de alerta:

Analyze → Display Filters
Filter: dtp

Si hay tráfico DTP en puertos que NO deberían tenerlo:
⚠️ Alerta inmediata
```

---

## 📋 Checklist de Implementación

```
[ ] 1. Inventariar configuración actual de todos los switches
       └─ Nota qué puertos tienen "switchport nonegotiate"

[ ] 2. Auditar puertos vulnerables (sin nonegotiate)
       ├─ Puertos de usuario en "dynamic auto"
       └─ Puertos en "dynamic desirable"

[ ] 3. Crear plan de actualización
       ├─ Cronograma de cambios por switch
       ├─ Ventanas de mantenimiento
       └─ Rollback plan

[ ] 4. Implementar en fases
       ├─ Fase 1: Puertos de usuario acceso
       ├─ Fase 2: Puertos de usuario guest
       ├─ Fase 3: Puertos troncales

[ ] 5. Configurar protecciones adicionales
       ├─ BPDU Guard en user ports
       ├─ Port Security sticky learning
       └─ Spanning Tree Portfast

[ ] 6. Implementar monitoreo
       ├─ Script de verificación periódica
       ├─ SIEM alerts
       └─ Reportes semanales

[ ] 7. Capacitación de personal
       ├─ Explicar por qué DTP es inseguro
       ├─ Nueva procedimiento de configuración manual
       └─ Troubleshooting sin DTP

[ ] 8. Documentación
       ├─ Actualizar diagrama de redl
       ├─ Documentar VLAN assignments
       └─ Crear baseline de seguridad
```

---

## 🎯 Comparativa: Antes vs Después

| Aspecto | Sin Protección | Con Nonegotiate |
|---------|---|---|
| Riesgo de DTP Hopping | 🔴 Crítico | 🟢 Eliminado |
| Automatización | ✅ Automática | ❌ Manual |
| Complejidad operacional | Baja | Media |
| Seguridad | Baja | Alta |
| Tasa de fallos | Baja (auto) | Baja (manual) |

---

## 🔐 Configuración Segura en Producción

### Caso Real: Network Finance Company

```cisco
! Switch-Finance (Serv financiero crítico)

! Puertos de usuario: Acceso departamento Finanzas
interface range Gigabit0/0/1-8
  switchport mode access
  switchport access vlan 30  ! Finanzas
  switchport nonegotiate      ! SIN DTP
  switchport port-security
  spanning-tree bpduguard enable
  no shutdown
exit

! Puertos de usuario: Acceso departamento RH
interface range Gigabit0/0/9-16  
  switchport mode access
  switchport access vlan 40  ! Recursos Humanos
  switchport nonegotiate      ! SIN DTP
  switchport port-security
  spanning-tree bpduguard enable
  no shutdown
exit

! Puertos troncales (a otros switches)
interface Gigabit0/0/47-48
  switchport mode trunk
  switchport trunk encapsulation dot1q
  switchport trunk allowed vlan 1,30,40,99
  switchport nonegotiate      ! SIN DTP
  no shutdown
exit

! Verificación
show interface status | include connected
show vlan brief
show running-config | include nonegotiate
```

**Resultado**: Red segura, con aislamiento efectivo, sin riesgo de VLAN hopping

---

## 🚨 Incident Response si Hopping Detectado

```
1. AISLAMIENTO (Inmediato)
   ├─ Shutdown del puerto identificado
   ├─ Isolate en VLAN de cuarentena
   └─ Capturar puerto para forensia

2. INVESTIGACIÓN (Primeros minutos)
   ├─ Revisar logs del switch
   ├─ Analizar PCAP del período de ataque
   ├─ Identificar MAC del atacante
   └─ Revisar acceso posterior del atacante

3. REMEDIACIÓN (Siguientes horas)
   ├─ Confirmar nonegotiate en TODOS los puertos
   ├─ Cambiar credenciales de acceso de red
   ├─ Auditar cambios de VLAN
   └─ Implementar protecciones adicionales

4. POST-INCIDENT (Próximas semanas)
   ├─ Análisis completo de tráfico capturado
   ├─ Detectar si hubo MITM/exfiltración
   ├─ Notificar stakeholders
   └─ Actualizar políticas de seguridad
```

---

**Última actualización**: Febrero 2026  
**Recomendación Final**: Deshabilitar completamente DTP. Ningún beneficio compensa el riesgo de seguridad.
