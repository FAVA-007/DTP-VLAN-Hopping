# DTP VLAN Hopping - Explotación de Dynamic Trunking Protocol

## 📋 Descripción General

Este repositorio contiene un análisis exhaustivo y demostraciones prácticas sobre **VLAN Hopping mediante DTP (Dynamic Trunking Protocol)**. Se documenta cómo un atacante puede explotar la negociación automática de puertos troncales para saltarse entre VLANs y acceder a redes aisladas.

## 🔍 Conceptos Técnicos: DTP y VLAN Hopping

### ¿Qué es DTP?

**DTP (Dynamic Trunking Protocol)** es un protocolo patentado de Cisco que negocia automáticamente la configuración de puertos troncales entre switches y dispositivos finales.

**Características de DTP**:
- **Propósito**: Configuración automática de puertos troncales
- **Capa OSI**: 2 (Enlace de datos)
- **Protocolo encapsulado**: ISL o 802.1Q
- **Negociación**: Intercambio de capacidades entre puertos
- **Modos disponibles**:
  - `dynamic desirable` - Propone activamente trunking
  - `dynamic auto` - Acepta trunking si lo proponen
  - `trunk` - Modo fijo (sin DTP)
  - `access` - Modo de acceso (sin trunking)
  - `nonegotiate` - Sin negociación (trunk fijo sin DTP)

### Matriz de Negociación DTP

```
Puerto Remoto:  desirable    auto    trunk    access    nonegotiate
────────────────────────────────────────────────────────────────────
Localmente:
desirable       TRUNK ✓     TRUNK   TRUNK    ACCESS    ACCESS
auto            TRUNK ✓     ACCESS  TRUNK    ACCESS    ACCESS
trunk           TRUNK ✓     TRUNK   TRUNK    ACCESS    ACCESS
access          ACCESS      ACCESS  ACCESS   ACCESS    ACCESS
nonegotiate     ACCESS      ACCESS  TRUNK    ACCESS    ACCESS
────────────────────────────────────────────────────────────────────

✓ = Configuración alcanzada automáticamente sin intervención manual
✗ = Configuración no se alcanza (requiere intervención manual)
```

### Overview: VLAN Hopping Tradicional (Switch Spoofing)

En redes switches mal configuradas, existen dos métodos principales de VLAN Hopping:

#### Método 1: DTP Exploitation (Este Repositorio)
```
Objetivo: Convertir un puerto de acceso en puerto troncal
Mecanismo: Negociación DTP con modo "dynamic desirable"
Resultado: Acceso a múltiples VLANs desde un solo puerto
Riesgo: ALTO - Muy común en redes legadas
Facilidad: ALTA - Automatizado con Yersinia
```

#### Método 2: Double Tagging
```
Objetivo: Saltar VLAN mediante double 802.1Q tagging
Mecanismo: Crafting manual de tramas con etiquetas anidadas
Resultado: Tráfico que evita filtros VLAN
Riesgo: ALTO - Silencioso, difícil de detectar
Facilidad: MEDIA - Requiere Scapy/Yersinia avanzado
```

**Este repositorio se enfoca en el Método 1: DTP Exploitation**

---

## 💡 El Ataque: DTP VLAN Hopping Explicado

### Escenario Vulnerable

```
Red Original (Segura):
┌─────────────────────────────────────┐
│ Switch Cisco (Catalyst 2960)        │
├─────────────────────────────────────┤
│ Puerto 1-24: Modo ACCESS (VLAN 10)  │
│ Puerto 25-26: Modo ACCESS (VLAN 20) │
│ Puerto 47-48: Modo TRUNK (a otros SW)
│                                     │
│ Usuarios normales conexión:         │
│ Laptop → Puerto 10 → VLAN 10 ✓ OK  │
│ El usuario no puede ver VLAN 20     │
└─────────────────────────────────────┘

¿Problema? Puerto 1 está en "dynamic auto"
```

### La Vulnerabilidad: DTP Deshabilitado Selectivamente

```
Configuración Vulnerable:
┌─────────────────────────────────────┐
│ interface Gi0/0/1                   │
│   switchport mode access            │
│   switchport access vlan 10         │
│   ! NO hay "switchport nonegotiate" │ ← VULNERABLE
│                                     │
│ DTP HABILITADO BY DEFAULT           │
│   mode: auto (dinámico en capa 2)   │
└─────────────────────────────────────┘

¿Qué significa? El puerto puede negociar
trunking automáticamente si algo lo solicita.
```

### Flujo del Ataque

```
ANTES DEL ATAQUE:
Atacante PC (en VLAN 10)
└─ Acceso a máquinas en VLAN 10
└─ NO puede ver VLAN 20 (Servidores)
└─ NO puede ver VLAN 30 (Base de datos)

          Yersinia envía DTP desirable
                    ↓
                    
DURANTE EL ATAQUE (Switch recibe DTP desirable):
┌──────────────────────────────────────────────┐
│ DTP Negotiation Process:                     │
├──────────────────────────────────────────────┤
│ 1. Recibe: DTP packet con "desirable mode"  │
│ 2. Lógica: Puerto en "auto" + req "desirable"
│ 3. Decisión: Negociar → TRUNK ✓             │
│ 4. Resultado: Puerto → modo TRUNK           │
│ 5. Activación: 802.1Q tagging habilitado    │
└──────────────────────────────────────────────┘

          Switch reconfigura puerto
                    ↓
                    
DESPUÉS DEL ATAQUE:
Atacante PC (ahora con acceso troncal)
├─ Puede ver VLAN 10 (original)
├─ Puede ver VLAN 20 (Servidores) ✗ HOPPED
├─ Puede ver VLAN 30 (BD Principal) ✗ HOPPED
├─ Puede ver VLAN 40 (Finanzas) ✗ HOPPED
└─ Acceso total a la red

IMPACTO: Escalation from User → Network Administrator
```

---

## 🛠️ Herramienta Utilizada: Yersinia

**Yersinia** es una herramienta profesional de penetration testing específicamente diseñada para probar vulnerabilidades de capa 2.

### Funcionalidad DTP en Yersinia

```
Attacks implemented:
├─ DTP Trunk negotiation (desirable)
├─ DTP Trunk negotiation (auto to trunk)
├─ DTP native VLAN modification
├─ DTP mode negotiation
└─ DTP flooding attacks
```

### Instalación Rápida

```bash
# Debian/Ubuntu
sudo apt-get install yersinia

# Verificar
yersinia --version
# Expected: Yersinia 0.8.x
```

---

## 📊 Variantes del Ataque

### Variante A: DTP Desirable (Fuerza Activa)

```
Atacante → Switch
├─ Envía: DTP packet con "dynamic desirable"
├─ Propósito: Solicitar trunking activamente
├─ Switch responde: Negocia → Puerto se hace TRUNK
└─ Resultado: ✓ Puerto troncal en el primer intento

Ventajas: Rápido, Alta tasa de éxito en "auto" mode
Desventajas: Más ruidoso (paquetes de DTP visibles)
```

### Variante B: DTP Auto-to-Trunk

```
Atacante → Switch
├─ Envía: DTP packet con "dynamic auto"
├─ Espera: Que el switch inicie negociación
├─ Responde: Con "desirable"
└─ Resultado: ✓ Conversión mediante 2-way handshake
```

### Variante C: Native VLAN Manipulation

```
Objetivo: Cambiar la VLAN nativa del puerto
┌─────────────────────────────────┐
│ Original: Native VLAN = 1 (no   │
│ aparece etiquetada)             │
│                                 │
│ Ataque: Enviar DTP con VLAN     │
│ nativa = 20 (Producción)        │
│                                 │
│ Resultado: Tráfico sin etiquetar│
│ (untagged) va a VLAN 20         │
└─────────────────────────────────┘

Impacto: Acceso sin triple-tag awareness
```

---

## 🎯 Impacto Potencial

| Escenario | Severidad | Impacto | Tiempo |
|-----------|-----------|--------|--------|
| Acceso a datos de Producción | 🔴 Crítica | Theft/Modification | Segundos |
| Acceso a red de Finanzas | 🔴 Crítica | Financial Fraud | Segundos |
| Man-in-the-Middle en VLAN BD | 🔴 Crítica | DB Compromise | Inmediato |
| Escalación de privilegios | 🔴 Crítica | Full network control | Minutos |

---

## 🛡️ Mitigación y Defensa

### 1. Deshabilitación de DTP (Fundamental)

```cisco
! En TODOS los puertos de usuario
Switch(config)# interface range Gi0/0/1-24
Switch(config-if-range)# switchport nonegotiate
```

**Efecto**: DTP es completamente deshabilitado. El puerto **NO negociará** trunking aunque reciba solicitudes.

**Validación**:
```cisco
Switch(config-if-range)# exit
Switch# show interface Gi0/0/1 switchport | include Negotiation
Administrative Mode: static access
Negotiation of Trunking: Off
```

### 2. Modo Access Explícito

```cisco
! Forzar modo access en puertos de usuario
Switch(config)# interface range Gi0/0/1-24
Switch(config-if-range)# switchport mode access
Switch(config-if-range)# switchport nonegotiate
```

### 3. BPDU Guard y Root Guard

```cisco
! Protección contra manipulación de Spanning Tree
Switch(config)# interface range Gi0/0/1-24
Switch(config-if-range)# spanning-tree bpduguard enable
Switch(config-if-range)# spanning-tree rootguard enable
```

### 4. Port Security (Defensa Complementaria)

```cisco
Switch(config)# interface range Gi0/0/1-24
Switch(config-if-range)# switchport port-security
Switch(config-if-range)# switchport port-security maximum 1
Switch(config-if-range)# switchport port-security mac-address sticky
```

---

## 📁 Estructura del Repositorio

```
DTP-VLAN-Hopping/
├── README.md                          # Este archivo
├── GUIA_DE_USO.md                    # Instrucciones prácticas del ataque
├── EXPLICACION_TECNICA.md            # Análisis profundo de DTP
├── MITIGACION.md                     # Estrategias de defensa
├── GITHUB_SETUP.sh                   # Script de GitHub
├── imagenes/                         # Evidencia fotográfica
│   ├── image_cd50b7.png             # Ejecución Yersinia
│   ├── image_dtp_negotiation.png    # Captura Wireshark de DTP
│   ├── image_trunk_port_created.png # Puerto se convierte en trunk
│   └── image_vlan_access.png        # Acceso multi-VLAN post-ataque
└── configuraciones/
    ├── switch_vulnerable.conf        # Modo DTP habilitado
    └── switch_seguro.conf            # Switchport nonegotiate
```

## ⚡ Inicio Rápido

1. **Entender DTP**: Lee `EXPLICACION_TECNICA.md`
2. **Preparar lab**: Sigue `GUIA_DE_USO.md`
3. **Ejecutar el ataque**: Con Yersinia
4. **Implementar defensa**: Consulta `MITIGACION.md`
5. **Documentar**: Captura imágenes en `imagenes/`

## 🚀 Requisitos

- **SO**: Linux (Debian/Ubuntu) o VM
- **Herramientas**: Yersinia, Wireshark, GNS3
- **Hardware**: Acceso a switches Cisco o emulación
- **Conocimiento**: Layer 2, 802.1Q, conceptos VLAN, DTP

## ⚠️ Aviso Legal y Ético

**Uso Permitido**:
- ✅ Laboratorios educativos
- ✅ Redes de prueba autorizadas
- ✅ Penetration testing con consentimiento explícito

**Uso Prohibido**:
- ❌ Redes sin autorización
- ❌ Acceso no autorizado a sistemas
- ❌ Actividades maliciosas

**Responsabilidad**: El usuario es responsable de cualquier daño causado.

---

## 👨‍🎓 Contexto Académico

Proyecto de ciberseguridad de ITLA (Instituto Tecnológico Latinoamericano).

**Serie Completa**:
1. 🔗 [VTP Attacks](https://github.com/FAVA-007/VTP-Attacks)
2. 🔄 [DTP VLAN Hopping](https://github.com/FAVA-007/DTP-VLAN-Hopping)
3. 🕵️ [DNS Spoofing/Poisoning](https://github.com/FAVA-007/DNS-Spoofing-DNS-Poisoning)

---

**Última actualización**: Febrero 2026  
**Estado**: Completado ✅
