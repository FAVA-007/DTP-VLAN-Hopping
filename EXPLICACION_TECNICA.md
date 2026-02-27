# EXPLICACIÓN TÉCNICA: DTP VLAN Hopping Profundo

## 🔬 Desglose Detallado de DTP y VLAN Hopping

### Estructura del Protocolo DTP

DTP es un protocolo propietario de Cisco de capa 2 que automatiza la negociación de configuraciones de puertos troncales.

#### Campos de DTP Header

```
Trama Ethernet DTP:
┌──────────────────────────────────────────┐
│ MAC Destino: 01:00:0c:cc:cc:cd           │
│ MAC Origen: <MAC del switch/atacante>    │
│ Tipo: 0x00b6 (DTP)                      │
│ VLAN: 1 (Management VLAN)                │
└──────────────────────────────────────────┘
                    ↓
┌──────────────────── DTP TLV ───────────────────┐
│ Type:                   0x01 (Management)      │
│ Length:                 1 (un word)            │
│ Value:                  Capabilities bitfield  │
│                                                │
│ Type:                   0x02 (Port Identity)   │
│ Length:                 2 (dos words)          │
│ Value:                  Port info               │
│                                                │
│ Type:                   0x03 (System Name)     │
│ Length:                 variable                │
│ Value:                  Device name            │
│                                                │
│ Type:                   0x04 (Model Number)    │
│ Length:                 variable                │
│ Value:                  Cisco model             │
│                                                │
│ Type:                   0x05 (Native VLAN)     │
│ Length:                 1 (un word)             │
│ Value:                  VLAN ID (default: 1)   │
│                                                │
│ Type:                   0x06 (Duplex)          │
│ Length:                 1 (un word)            │
│ Value:                  Full/Half              │
└────────────────────────────────────────────────┘
```

#### Campo Crítico: Capabilities

```
DTP Capabilities Bitmap (2 bytes):
┌────────────────────────────────────────┐
│ Bit 0: Support ISL encapsulation       │
│ Bit 1: Support 802.1Q encapsulation    │
│ Bit 2: Support DTP negotiation         │
│ ...                                    │
│                                        │
│ Ejemplo de valor: 0xA0                 │
│ Binario: 1010 0000                     │
│         ↓  ↓                            │
│    802.1Q ISL ← Soporte para ambos     │
└────────────────────────────────────────┘
```

---

## 💥 Mecanismo de Negociación DTP

### El Protocolo de Negociación en Detalle

```
NEGOCIACIÓN NORMAL (Sin ataque):

Momento T=0: Switch A y B inicializan
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Switch A (Gi0/0/47):          Switch B (Gi0/0/48):
Mode: dynamic desirable        Mode: dynamic auto
      ↓ envía DTP             ↑ recibe
┌─────────────────────┐
│ DTP Message:        │
│ Mode: desirable ───→│→ recibe "desirable"
│ Capabilities:       │       ├─ Lógica:
│  ├─ 802.1Q         │       │  auto + desirable
│  └─ ISL            │       │    = TRUNK
│                    │       │
└─────────────────────┘ ←────┼─ responde con
                              │  sus capabilities

              Resultado: AMBOS en modo TRUNK
                        Encapsulación: 802.1Q

                              ✓
                        Negociación exitosa
```

### Tabla de Negociación Detallada

```
La regla de oro de DTP:

┌────────────────────────────────────────────────────────┐
│                                                        │
│  COMBINATION: Si hay un "desirable" ACTIVO...        │
│  ├─ desirable + desirable   → TRUNK                  │
│  ├─ desirable + auto        → TRUNK ✓ Explotable    │
│  ├─ desirable + trunk       → TRUNK                  │
│  ├─ desirable + access      → ACCESS (blocked)       │
│  └─ desirable + nonegotiate → ACCESS (blocked)       │
│                                                        │
│  Nota: "auto" solo negocia si el otro es desirable   │
│                                                        │
└────────────────────────────────────────────────────────┘

Implementación en switch (pseudocódigo):

if (remote_mode == "desirable" OR local_mode == "desirable") AND
   (remote_mode != "access" AND local_mode != "access") AND
   (local_mode != "nonegotiate") THEN
    → puerto_pasa_a_TRUNK
    → habilitar_802.1Q_tagging
END IF
```

---

## 🎯 Cómo Funciona el Ataque: Paso a Paso

### Fase 1: Reconocimiento (Información Gathering)

```
Atacante conectado en Puerto Gi0/0/1 (Access)
┌──────────────────────────────────────────┐
│ Escucha pasiva:                          │
│ ├─ Captura DTP advertisements del switch │
│ ├─ Observa: capabilities, native VLAN    │
│ ├─ Nota: Puerto está en "dynamic auto"   │
│ └─ Decisión: Enviar "desirable"          │
└──────────────────────────────────────────┘

tcpdump output:
IP 192.168.1.1.unknown > ff:ff.unknown.unknown: UDP (Frag)
[DTP]
    Mode: dynamic auto ← Puerto vulnerable
    Capabilities: 802.1Q, ISL ← Soporta encapsulación
    Native VLAN: 1
```

### Fase 2: Inyección de DTP Desirable

```
Yersinia crafteando paquete DTP malicioso:

┌──────────────────────────────────────────┐
│ DTP Packet Crafting:                     │
├──────────────────────────────────────────┤
│ MAC Src:     aa:bb:cc:dd:ee:ff           │
│              (MAC del atacante)           │
│ MAC Dst:     01:00:0c:cc:cc:cd           │
│              (Multicast DTP estándar)    │
│ 802.1P:      7 (Highest priority)        │
│ 802.1Q VLAN: 1 (Management)              │
│                                          │
│ DTP Payload:                             │
│ ├─ Version: 2                            │
│ ├─ TLV[1] (Mgmt):                        │
│ │   ├─ Bit 0 (ISL): 1                    │
│ │   └─ Bit 1 (802.1Q): 1                 │
│ │                                        │
│ ├─ TLV[2] (Port Type):                   │
│ │   └─ Mode: DESIRABLE ← ¡EL ATAQUE!    │
│ │                                        │
│ └─ TLV[5] (Native VLAN):                 │
│     └─ VLAN: 1                           │
│                                          │
└──────────────────────────────────────────┘
```

### Fase 3: Envío e Inyección

```
Yersinia envía el frame a nivel 2:

Atacante                Switch Vulnerable
   │                           │
   ├─ sudo yersinia dtp -a 1  │
   │   [Craft DTP packet]      │
   │                           │
   ├──────────[DTP]───────────→│
   │                           │ Recibe DTP con "desirable"
   │                           │ ├─ Compara modos:
   │                           │ │  auto (local) + 
   │                           │ │  desirable (remoto)
   │                           │ │
   │                           │ ├─ Resultado: TRUNK ✓
   │                           │
   │                           ├─ Reconfig inmediata:
   │                           │  ├─ Puerto Gi0/0/1
   │                           │  ├─ Mode: trunk
   │                           │  ├─ Encapsulation: 802.1Q
   │                           │  └─ Allowed VLANs: 1-4094
   │                           │
   │ ←──────[Cambio OK]───────┤
   │                           │
   └─ Yersinia: [+] Success    │
```

### Fase 4: Explotación

```
Ahora el puerto es un TRUNK completamente funcional:

Atacante en Gi0/0/1 (ahora trunk):

ANTES (Access mode):
┌────────────────────────┐
│ Tráfico VLAN 10 aquí   │
│ (sin etiqueta)         │
├────────────────────────┤
│ MAC: aa:bb:cc:dd:ee:ff │
│ DEST: 192.168.10.50    │ → Usuario normal
│ SRC:  192.168.10.100   │   (misma VLAN)
└────────────────────────┘

DESPUÉS (Trunk mode):
┌────────────────────────────────────────┐
│ Tráfico de TODAS las VLANs             │
│ (con etiquetas 802.1Q)                 │
├────────────────────────────────────────┤
│ Subinterfaz eth0.10:                   │
│   MAC: aa:bb:cc:dd:ee:ff               │
│   DEST: 192.168.10.50  (VLAN 10)       │
│                                        │
│ Subinterfaz eth0.20:                   │
│   MAC: aa:bb:cc:dd:ee:ff               │
│   DEST: 192.168.20.100 (VLAN 20) ✗     │
│   → Acceso a Production servers        │
│                                        │
│ Subinterfaz eth0.30:                   │
│   MAC: aa:bb:cc:dd:ee:ff               │
│   DEST: 192.168.30.50  (VLAN 30) ✗     │
│   → Acceso a Finance servers           │
└────────────────────────────────────────┘

IMPACTO: Escalation from isolated user
         to network-wide privilege
```

---

## 🔐 Análisis de Por Qué Funciona el Ataque

### 1. Confianza Implícita en Modos

```
Lógica vulnerable del switch:

┌─────────────────────────────┐
│ IF dtp_mode == "auto" THEN  │
│   IF remote_advertise ==    │
│      "desirable" THEN       │
│     ├─ aceptar()            │
│     ├─ cambiar_a_trunk()    │
│     └─ habilitar_tagging()  │
│   END IF                    │
│ END IF                      │
│                             │
│ ¿Validación de origen?      │
│ → NO existe ✗               │
│                             │
│ ¿Autenticación MAC?         │
│ → NO existe ✗               │
└─────────────────────────────┘

DTP asume: "Si me dicen que confíe, confío"
```

### 2. Falta de Autenticación de Origen

```
DTP NOT checking:
✗ ¿Es este DTP de un switch legítimo?
✗ ¿Viene de una MAC conocida?
✗ ¿Hay una firma digital?

Lo que DTP SÍ hace:
✓ Lee: "El remoto dice que es modo desirable"
✓ Compara: Con su propio modo
✓ Aplica: Regla de negociación
✓ Configura: Trunk automáticamente

Conclusión: Diseño sin verificación de identidad
```

### 3. Encapsulación 802.1Q

```
Lo que hace 802.1Q después del "trunk":

┌─────────────────────────────────────────┐
│ Original (Access mode):                 │
│ ┌──────────────────────────┐            │
│ │ Payload (sin etiquetar) │            │
│ └──────────────────────────┘            │
│ $ tcpdump: IP packet directo           │
│                                        │
│ Después del Trunk (Con 802.1Q):        │
│ ┌────┬─────────┬──────────────────┐   │
│ │Prio│  VLAN   │    Payload       │   │
│ └────┴─────────┴──────────────────┘   │
│ $ tcpdump:                             │
│   VLAN 20, IP 192.168.20.100          │
│   (Acceso directo a otra VLAN)        │
│                                        │
│ Permite crear subinterfaces:          │
│ $ vconfig add eth0 20                 │
│ $ ip addr add 192.168.20.1/24 ...     │
│                                        │
│ Ahora puede acceder a VLAN 20 ✓       │
└─────────────────────────────────────────┘
```

---

## 📊 Variantes Técnicas del Ataque

### Variante 1: DTP Desirable (Classic)

```
Atacante envía:
Mode: desirable

Switch (en auto) responde:
auto + desirable = TRUNK

Resultado: Conversión en ~1-2 segundos
Tasa de éxito: ~95% en switches legacy
Detección: Relativamente fácil (paquetes DTP visibles)
```

### Variante 2: DTP Native VLAN Modification

```
Cambiar la VLAN nativa del puerto:

Antes:
─────
Untagged traffic → VLAN 1

Ataque:
──────
Enviar DTP con Native VLAN = 20

Después:
───────
Untagged traffic → VLAN 20 ✗
Tagged 802.1Q → Según etiqueta

Impacto: Tráfico sin etiquetar va a VLAN maliciosa
```

### Variante 3: Double DTP Attack

```
Ejecutar múltiples veces:

Intento 1: Enviar desirable
Intento 2: Enviar desirable con native VLAN 20
Intento 3: Enviar desirable nuevamente

Efecto: Aumentar probabilidad de éxito
        Saturar buffer de negociación
        Forzar reconexión del puerto
```

---

## 🛡️ Controles de Detección

### Indicadores de Ataque en Progreso

```
1. Paquetes DTP Anómalos
   tcpdump filter: 'dtp'
   Buscar: MACs desconocidas enviando DTP
   
2. Cambio de Puerto Inesperado
   show interface GigabitEthernet0/0/1 switchport
   Buscar: Cambio de "access" a "trunk" sin comando

3. Negociación DTP Sin Autorización
   En Wireshark: Filtrar por 'dtp'
   Ver cuáles hosts envían DTP
   
4. VLAN Subinterfaces Creadas
   En Atacante: ip link | grep vlan
   Buscar: eth0.20, eth0.30, etc.
```

### Log Analysis

```cisco
Switch# show logging | include DTP
! Buscar: 
! "DTP negotiation initiated"
! "Port changed to trunk mode"
! "Encapsulation changed to dot1q"
```

---

## 🔍 Capas de Seguridad Derrotadas

```
Capa 1: Acceso Físico
├─ Atacante: Conectado al puerto ✓

Capa 2: VLAN (Aislamiento)
├─ Intención: Aislar al usuario en VLAN 10
├─ Ataque: DTP convierte puerto en trunk
├─ Derrota: ✗ Bypass de aislamiento

Capa 3: Routing
├─ Intención: Route-based access control
├─ Ataque: Ahora está en misma capa 2 que servidores
├─ Derrota: ✗ La segregación L3 se vuelve inútil

Capa 4-7: ACLs, Firewalls
├─ Intención: Control de tráfico
├─ Problema: Si el atacante está en misma red L2,
│   puede hacer ARP spoofing, MITM, etc.
└─ Derrota: ✗ ACLs de red no protegen L2

CONCLUSIÓN: Defensa en capas no importa si L2 es inseguro
```

---

## 📈 Escala de Impacto

```
Sin VLAN Hopping:
- Atacante puede: Sniff tráfico VLAN 10
- Ataque: ARP spoofing local, DHCP exhaustion
- Alcance: VLAN 10 solamente
- Riesgo: 🟡 Medio

Con VLAN Hopping:
- Atacante puede: Acceso directo a todas las VLANs
- Ataque: MITM en servidores de Producción/Finanzas
- Alcance: TODA la red de switches
- Riesgo: 🔴 Crítico

Multiplicador: 50x más impacto (10 VLANs × 5 servicios by VLAN)
```

---

## 🎓 Conclusiones Técnicas

1. **DTP es inseguro por diseño**: No tiene autenticación
2. **Negociación automática es problemática**: Confía en el remoto
3. **Falta de validación de origen**: Cualquier dispositivo puede negociar
4. **Encapsulación 802.1Q lo permite**: Una vez trunk, puede acceder a cualquier VLAN
5. **Defensa simple**: Deshabilitar completamente DTP con `switchport nonegotiate`

---

**Última actualización**: Febrero 2026
