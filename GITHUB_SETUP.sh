# Instrucciones para Subir a GitHub

## Paso 1: Inicializar el Repositorio Local

```bash
# Navegar a la carpeta del proyecto
cd "c:\Users\FAVA\Desktop\Practica 4 S.R\DTP-VLAN-Hopping"

# Inicializar repositorio git
git init

# Verificar que se creó .git
ls -la
# Deberías ver: drwxr-xr-x  .git
```

## Paso 2: Configurar Git (Primera vez)

```bash
# Configurar nombre de usuario
git config --global user.name "FAVA-007"

# Configurar email
git config --global user.email "tu_email@itla.edu.do"

# Verificar configuración
git config --global --list
```

## Paso 3: Agregar Archivos al Staging

```bash
# Agregar todos los archivos
git add .

# Verificar qué archivos se agregarán
git status
# Deberías ver archivos en verde (staged)
```

## Paso 4: Crear Commit

```bash
# Crear commit inicial
git commit -m "Inicial: Documentación completa del ataque DTP VLAN Hopping

- README.md con descripción del protocolo DTP
- GUIA_DE_USO.md con instrucciones prácticas
- EXPLICACION_TECNICA.md con análisis detallado de negociación
- MITIGACION.md con defensa mediante switchport nonegotiate
- Estructura de carpetas para evidencia fotográfica"
```

## Paso 5: Agregar Repositorio Remoto (GitHub)

```bash
# Agregar remoto (reemplazar URL con tu repositorio real)
git remote add origin https://github.com/FAVA-007/DTP-VLAN-Hopping.git

# Verificar remoto
git remote -v
# Deberías ver:
# origin  https://github.com/FAVA-007/DTP-VLAN-Hopping.git (fetch)
# origin  https://github.com/FAVA-007/DTP-VLAN-Hopping.git (push)
```

## Paso 6: Subir a GitHub

```bash
# Si la rama por defecto es "main"
git push -u origin main

# Si prefieres usar "master"
git branch -M main
git push -u origin main
```

## Paso 7: Agregar Imágenes Posteriormente

Una vez que tomes los screenshots del ataque:

```bash
# 1. Guardar imágenes en carpeta imagenes/
cp /ruta/screenshot_yersinia.png imagenes/image_cd50b7.png
cp /ruta/screenshot_wireshark_dtp.png imagenes/image_dtp_negotiation.png

# 2. Agregar cambios
git add imagenes/

# 3. Commit
git commit -m "Agregar evidencia fotográfica: ejecución DTP hopping

- image_cd50b7.png: Yersinia ejecutando ataque
- image_dtp_negotiation.png: Captura Wireshark de DTP"

# 4. Push
git push origin main
```

## Verificación Final

Visita: https://github.com/FAVA-007/DTP-VLAN-Hopping

Deberías ver:
- ✅ README.md visible en la página principal
- ✅ Carpeta imagenes/ (vacía por ahora)
- ✅ Archivos de guía y documentación
- ✅ Historial de commits

---

**Última actualización**: Febrero 2026
