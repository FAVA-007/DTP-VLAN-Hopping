# Scripts: DTP VLAN Hopping

## 📁 Descripción

Esta carpeta contiene scripts y herramientas para ejecutar el ataque DTP VLAN Hopping de forma automatizada.

## 📋 Archivos Disponibles

### 1. `vlan_hopping.py`
**Tipo**: Python Script
**Propósito**: Negociación DTP automática con Scapy
**Función**: Enviar frames DTP "Dynamic Desirable" para obtener acceso multi-VLAN

```python
python3 vlan_hopping.py
```

---

### 2. `port_config_vulnerable.conf`
**Tipo**: Cisco IOS Configuration
**Propósito**: Configuración vulnerable de puerto
**Contenido**: Puerto en modo dynamic auto sin switchport nonegotiate

---

### 3. `port_config_hardened.conf`
**Tipo**: Cisco IOS Configuration
**Propósito**: Configuración segura (mitigada)
**Contenido**: Puerto con switchport nonegotiate y port security

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
