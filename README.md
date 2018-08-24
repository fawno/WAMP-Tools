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
- [Visual C++ Redistributable for Visual Studio 2017 x64](https://aka.ms/vs/15/release/VC_redist.x64.exe) instalado

# Instalación

#### Notas iniciales:

En la documentación usaré `c:\wamp` como raíz de la istalación, se puede utilar `c:\` sin problemas (yo lo hago así), así como cualquier otra ruta (recomiendo evitar espacios y caractéres especiales).

Las rutas estáns inspiradas en las rutas estándar de GNU/Linux, por lo que si la raíz es `c:\wamp`, todos los binarios y configuración se guardarán en `c:\wamp\usr` y los datos y logs en `c:\wamp\var`

La mayoría de scripts usan comandos que requieren permisos administrativos, por lo que es necesario ejecutarlos como administrador.

### Pasos básicos:

1. Copia la carpeta `usr` del proyecto en la raíz de la instalación: `c:\wamp\usr` (por ejemplo)
2. Ejecuta el script `c:\wamp\usr\wamp-tools\1_php.cmd`
3. Añade al path global de Windows las rutas indicadas por el script `1_php.cmd`:
   - `c:\wamp\usr\bin`
   - `c:\wamp\usr\php`
   - `c:\wamp\usr\php\ext`
4. Añade las variables de entorno globales indicadas por el script `1_php.cmd`:
   - `PHP_INI_SCAN_DIR`=`c:\wamp\usr\etc\php`
   - `PHP_PEAR_SYSCONF_DIR`=`c:\wamp\usr\pear`
   - `MIBDIRS`=`c:\wamp\usr\share\mibs`
5. Ejecuta el script `c:\wamp\usr\wamp-tools\2_apache.cmd`
6. Ejecuta el script `c:\wamp\usr\wamp-tools\apache_set_paths.cmd`
7. Edita la configuración para el certificado en `openssl_conf.php` (opcional):
   - Un nombre para la "organización": `$organizationName = 'Localhost';`
   - El nombre de la máquina WAMP (el nombre del equipo, hostname): `$commonName = 'wamplocal';`
   - El nombre del dominio de la red (hostdomain): `$subjectAltName = [$commonName, 'localhost', '*.example.com'];`
8. Ejecuta el script `c:\wamp\usr\wamp-tools\makecert.cmd`
9. Copia el certificado recien creado en `c:\wamp\usr\httpd\conf\ssl.crt\ca.localhost.crt` a `c:\wamp\usr\httpd\htdocs\ca.localhost.crt`
10. Ejecuta `net start Apache2.4`
11. Ejecuta el script `c:\wamp\usr\wamp-tools\3_mysql.cmd`
12. Ejecuta `net start MySQL`
13. Ejecuta el script `c:\wamp\usr\wamp-tools\mysql_timezone_posix.cmd` (opcional)
14. En los navegadores configura la confianza en el certificado CA generado (`c:\wamp\usr\httpd\conf\ssl.crt\ca.localhost.crt`), puedes hacerlo directamente: [`http://localhost/ca.localhost.crt`](http://localhost/ca.localhost.crt)

### VirtualHosts

1. Edita el archivo `c:\wamp\usr\etc\httpd\vhosts\vhosts.conf`
2. Añade las siguientes líneas para cada VHost adicional al localhost
   ```
   Define VHost "example"
   Define VHostDomain "example.com"
   Define VHostAdmin webmaster@example.com
   Define VHostRoot "/var/www/example"
   Define VHostLog "vhost-${VHost}"
   Include conf/vhosts/_default_.vhost
   ```
3. Añade a `c:\Windows\System32\drivers\etc\hosts` líneas adicionales por host
   ```
   127.0.0.1 example example.example.com
   ```
4. Reinicia el Apache.

### Configurar Firewall para PHP

Para las funciones de FTP de PHP se necesitan crear un par de reglas en el firewall de windows.

Utiliza `c:\wamp\usr\wamp-tools\php_firewall_add.cmd` para crearlas/actualizarlas y `c:\wamp\usr\wamp-tools\php_firewall_add.cmd` para eliminarlas.

#### Nota

La creación, modificación y eliminación de reglas del firewall requiren permisos administrativos, por tanto asegurate de usar los scripts anteriores como administrador.

### Actualizar:

- PHP: `c:\wamp\usr\wamp-tools\1_php.cmd`
- Apache: `c:\wamp\usr\wamp-tools\2_apache.cmd`
- MySQL: `c:\wamp\usr\wamp-tools\3_mysql.cmd`
