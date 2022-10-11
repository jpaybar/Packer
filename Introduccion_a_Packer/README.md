## ¿Qué es Packer?

Packer es una herramienta de creación de imágenes de código abierto, 
escrita en Go. Nos permite crear imágenes para múltiples plataformas de destino, desde una única fuente de configuración. [Packer](https://www.packer.io/) corre bajo plataforma Linux, Windows y Mac OS X.

Una imagen es una unidad estática que contiene un sistema operativo preconfigurado. Podemos usar imágenes para crear nuevos hosts. Las imágenes ayudan a acelerar el 
proceso de construcción y despliegue de una infraestructura y pueden tener diversos formatos para distintas plataformas y entornos de implementación.

Packer tiene soporte para crear imágenes de Amazon EC2, CloudStack, DigitalOcean, Docker, Google Compute Engine, Microsoft Azure, QEMU, VirtualBox, VMware entre otros.

## ¿Por qué usar Packer?

Construir imágenes es un proceso manual por lo tanto es propenso a errores. Packer puede automatizar la creación de imágenes e integrarse con herramientas de gestión  como Ansible.

## Infraestructura mutable vs Infraestructura inmutable

La infraestructura mutable se puede cambiar cuando sea necesario . Los servidores tradicionales o mutables son servidores que se actualizan y modifican continuamente.

Estos servidores requieren docenas de inicios de sesión y cuentas, pueden estar en cualquier estado de reparación o mal estado, y administran software con actualizaciones que pueden tener éxito o fallar.

Hay muchos problemas con este enfoque. Estos cambios continuos significan que es casi imposible tener servidores idénticos en un entorno. Además, no hay formas rápidas y efectivas de reemplazar un servidor existente con otro idéntico en caso de problemas.

Para resolver los problemas de la infraestructura mutable, se crearon herramientas de infraestructura como código para actualizar los servidores rápidamente.

Recientemente, la aparición de servicios en la nube ha dado lugar a una infraestructura inmutable. La infraestructura inmutable se refiere a servidores (o máquinas virtuales) que nunca se modifican después de la implementación.

Cuando necesitamos actualizar un servidor, lo reemplazaremos con una nueva versión. Para cualquier actualización, corrección o modificación se deberá:

- Crear un servidor a partir de una imagen común, con cambios, paquetes y servicios adecuados.
- Aprovisionar el nuevo servidor para reemplazarlo.
- Validar el servidor.
- Retirar el servidor anterior.

## Instalación de Packer

Accedemos a la pagina de descargas:

https://www.packer.io/downloads

## Windows

Descargaremos la versión para Windows:

```powershell
Invoke-WebRequest https://releases.hashicorp.com/packer/1.8.3/packer_1.8.3_windows_amd64.zip -OutFile packer_1.8.3_windows_amd64.zip
```

Extraemos el zip:

```powershell
Expand-Archive .\packer_1.8.3_windows_amd64.zip .\packer_1.8.3_windows_amd64
```

Creamos el directorio que tendrá el ejecutable:

```powershell
mkdir c:\packer
```

y lo copiamos:

```powershell
cp .\packer_1.8.3_windows_amd64\packer.exe C:\packer\
```

Agregamos al PATH del usuario el directorio que contiene el ejecutable:

```powershell
setx PATH "C:\packer;%PATH%"
```

O al PATH del sistema si agregamos el parametro /m:

```powershell
setx /m PATH "C:\packer;%PATH%"
```

Cerramos la ventana de PowerShell o CMD y abrimos una nueva para comprobar que Packer se ejecuta correctamente:

```powershell
packer version
```

Deberiamos obtener una salida similar a la siguiente:

```powershell
Packer v1.8.3
```

## Linux

Vemos el contenido de la variable de sistema `PATH`:

```bash
echo $PATH
```

```bash
/home/vagrant/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
```

Descargamos el fichero `zip` que contiene el binario:

```bash
wget https://releases.hashicorp.com/packer/1.8.3/packer_1.8.3_linux_amd64.zip
```

Descomprimimos el fichero `zip`:

```bash
unzip packer_1.8.3_linux_amd64.zip -d packer
```

Copiamos el binario a `/usr/local/bin` y borramos la descarga:

```bash
sudo mv ~/packer/packer /usr/local/bin; rm -rf ~/packer*; ls -l
```

Comprobamos que Packer se ejecuta correctamente:

```bash
packer version
```

```bash
Packer v1.8.3
```

## ¿Como trabaja Packer?

Packer usa una plantilla en formato `JSON` para definir una imagen, aunque como dice la pagina oficial a partir de la versión 1.7.0 es preferible usar HCL2 (HashiCorp Configuration Language). 

"As of version 1.7.0, HCL2 is the preferred way to write Packer templates. You can use the `hcl2_upgrade` command to transition your existing Packer JSON template to HCL2. This enables you to preserve your existing workflows while leveraging HCL2’s advanced features like variable interpolation and configuration composability."

También nos da la posibilidad de usar el comando `hcl2_upgrade` para convertir nuestras plantillas `JSON` a `HCL`.

```bash
packer hcl2_upgrade -with-annotations docker-ubuntu.json
Successfully created docker-ubuntu.json.pkr.hcl
```

Nos centraremos en el formato de plantilla `JSON` más conocido en general.

Dentro de nuestro fichero de plantilla `JSON` hay tres secciones principales: 

`builders`, `provisioners`, `post-processors` y una opcional, `variables`.

##### builders

Los `builders` crean máquinas y generan imágenes a partir de esas máquinas para varias plataformas. Por ejemplo, hay constructores separados para EC2, VMware, VirtualBox, etc.

Por lo tanto la sección `builders` define las características de la VM que se instala para
 construir la imagen. Esto puede estar definido en la sección `variables`.

Podemos consultar todas las opciones de los `builders` en la pagina oficial, en el siguiente enlace (por ejemplo para Openstack):

[OpenStack - Builders | Packer by HashiCorp](https://www.packer.io/plugins/builders/openstack)

##### provisioners

`Provisioners` sería la siguiente sección de un archivo JSON de Packer. Una vez instalado el sistema operativo, se invoca a los `provisioners` para configurar el 
sistema.

Lo normal es que sean scripts o comandos en linea de SHELL o PowerShell, dependiendo el sistema para formar la imagen.

Podemos consultar la documentación oficial en :

https://www.packer.io/docs/provisioners

##### variables

Esta sección define variables que se usan en algunos parametros antes descritos del template, como la parte de `builders` donde definimos las caracteristicas de la máquina o la URL si necesitamos descargar una ISO de instalación, etc...

##### post-processors

El `post-processors` se ejecutan después de los `builders`y `provisioners`, son opcionales y se pueden usar para cargar artefactos, volver a empaquetar archivos, etc...

Estos pueden ser la propia SHELL de comandos, Vagrant, VMware vSphere, Google Cloud Platform, DigitalOcean, etc...

En el siguiente link se detalla el post-processors para DigitalOcean:

[DigitalOcean Import - Post-Processors | Packer by HashiCorp](https://www.packer.io/plugins/post-processors/digitalocean)

## Author Information

Juan Manuel Payán Barea    (IT Technician)    [st4rt.fr0m.scr4tch@gmail.com](mailto:st4rt.fr0m.scr4tch@gmail.com) [jpaybar (Juan M. Payán Barea) · GitHub](https://github.com/jpaybar) https://es.linkedin.com/in/juanmanuelpayan
