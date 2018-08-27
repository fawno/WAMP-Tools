# WAMP-Tools
Utilidades para la instalación y actualización de un WAMP:

- Windows
- Apache
- Mysql
- PHP

Este proyecto se basa en la instalación manual de cada componente, automatizando y proveyendo de scripts de ayuda para la mayoría de tareas.

He usado [XAMPP](https://www.apachefriends.org) durante mas de 10 años, pero al final reemplazaba el Apache, MySQL y PHP que traía de serie con mis propias configuraciones. Esta es la instalación con la que he terminado, basada en las rutas estandar GNU/Linux.

#### Instalar y mantener un WAMP de esta manera requiere ciertos conocimientos, para usuarios nóveles recomiendo los proyectos [XAMPP](https://www.apachefriends.org) o [WAMP](http://www.wampserver.com/en/).

# Requisitos

- Windows 7 (x64) o superior (7, 8, 8.1, Server 2008R2, Server 2012, Server 2016)
- [PowerShell 5.1](https://www.microsoft.com/en-us/download/details.aspx?id=54616)
- [Visual C++ Redistributable for Visual Studio 2017 x64](https://aka.ms/vs/15/release/VC_redist.x64.exe) instalado

# Instalación

#### Notas iniciales:

En la documentación usaré `c:\wamp` como raíz de la istalación, se puede utilar `c:\` sin problemas (yo lo hago así), así como cualquier otra ruta (recomiendo evitar espacios y caractéres especiales).

Las rutas estáns inspiradas en las rutas estándar de GNU/Linux, por lo que si la raíz es `c:\wamp`, todos los binarios y configuración se guardarán en `c:\wamp\usr` y los datos y logs en `c:\wamp\var`

**Es necesario ejecutar los scripts como administrador**

### Ayuda instalación:
- PHP: `Install-PHP.cmd -h`

### Pasos básicos:

1. Copia la carpeta `usr` del proyecto en la raíz de la instalación: `c:\wamp\usr` (por ejemplo)
2. Ejecuta el script `c:\wamp\usr\wamp-tools\Install-PHP.cmd`

### Actualizacion:
- PHP: `Install-PHP.cmd`
