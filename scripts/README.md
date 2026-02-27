# Scripts: DTP VLAN Hopping

## 📁 Descripción

Esta carpeta contiene scripts y herramientas para ejecutar el ataque DTP VLAN Hopping de forma automatizada.

## 📋 Archivos Disponibles

### 1. `yersinia_dtp_attack.sh`
**Tipo**: Bash Script
**Propósito**: Automatizar el ataque DTP con Yersinia
**Función**: Negociar puerto de acceso para convertirlo en trunk

```bash
bash yersinia_dtp_attack.sh -i eth0 -t 192.168.1.50 -m desirable
```

---

### 2. `dtp_monitor.sh`
**Tipo**: Bash Script
**Propósito**: Monitorear estado de puertos del switch
**Función**: Verificar cambios de access a trunk

```bash
bash dtp_monitor.sh -s 192.168.1.1 -u admin -p password
```

---

### 3. `port_config_vulnerable.conf`
**Tipo**: Cisco IOS Configuration
**Propósito**: Configuración vulnerable de puerto
**Contenido**: Puerto en modo dynamic auto sin switchport nonegotiate

---

### 4. `port_config_hardened.conf`
**Tipo**: Cisco IOS Configuration
**Propósito**: Configuración segura (mitigada)
**Contenido**: Puerto con switchport nonegotiate y port security

---

### 5. `dtp_negotiation.py`
**Tipo**: Python Script
**Propósito**: Crafting manual de frames DTP
**Función**: Crear solicitudes DTP personalizadas con Scapy

```python
python3 dtp_negotiation.py --mode desirable --interface eth0
```

---

### 6. `vlan_access_test.py`
**Tipo**: Python Script
**Propósito**: Validar acceso multi-VLAN después del ataque
**Función**: Probar conectividad a múltiples VLANs (eth0.20, eth0.30, etc.)

```python
python3 vlan_access_test.py --vlans 10,20,30,40 --target-ips 192.168.20.1,192.168.30.1
```

---

## 🚀 Instalación

```bash
# Clonar scripts
git clone https://github.com/FAVA-007/DTP-VLAN-Hopping.git
cd DTP-VLAN-Hopping/scripts

# Hacer ejecutables
chmod +x *.sh

# Instalar dependencias Python
pip install scapy

# Ejecutar ataque
sudo ./yersinia_dtp_attack.sh
```

---

## ⚠️ Notas de Seguridad

- **Solo en laboratorio**: Red de prueba controlada
- **Autorización explícita**: Obtener permiso escrito
- **Responsabilidad personal**: Usuario es responsable

---

## 📚 Referencias

- Yersinia GitHub: https://github.com/tomac/yersinia
- Cisco DTP Documentation
- Scapy Documentation: https://scapy.readthedocs.io/

---

**Última actualización**: Febrero 2026
