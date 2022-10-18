## Como crear un Box de Vagrant para VirtualBox con Packer

En este tutorial vamos a ver como podemos crear una imagen (Box) de Vagrant para usar con el proveedor VirtualBox, para ello usaremos la herramienta de HashiCorp Packer:

https://www.packer.io/

https://github.com/jpaybar/Packer/tree/main/Introduccion_a_Packer

## ¿Por qué usar Packer?

Construir imágenes es un proceso manual por lo tanto es propenso a errores. Packer puede automatizar la creación de imágenes e integrarse con herramientas de gestión como Ansible.

Para ver como sería el proceso de construcción de una imagen (Box) de Vagrant para VirtualBox de forma manual puedes consultar este post:

[Vagrant/How_to_create_a_Vagrant_Box_from_scratch_(VirtualBox) at main · jpaybar/Vagrant · GitHub](https://github.com/jpaybar/Vagrant/tree/main/How_to_create_a_Vagrant_Box_from_scratch_(VirtualBox))

Una vez leas el tutorial en el que explico como hacer el Box de forma manual, entenderás porque es fundamental el uso de Packer para estos menesteres.

## Requisitos:

- Host Microsoft Windows 10 Pro Versión 20H2.

- Vagrant Versión 2.2.19

- VirtualBox Versión 6.1.28

- Packer Versión 1.8.3

## Estructura del directorio de trabajo:

```bash
vagrant@masterVM:~$ tree 
├── http
│   ├── meta-data
│   └── user-data
├── iso
│   └── ubuntu-20.04.5-live-server-amd64.iso
├── output
├── README.md
├── scripts
│   ├── cleanup.sh
│   ├── motd.sh
│   ├── sudoers.sh
│   ├── update.sh
│   ├── vagrant.sh
│   └── virtualbox.sh
└── ubuntu2004_vagrant_box.json
```

- `http`: Contiene los ficheros de respuesta para instalar el sistema de forma desatendida (explicaremos más adelante los detalles).

- `iso`: Contiene la imagen iso del disco de instalación (en este caso Ubuntu 20.04 LTS).

- `output`: Será el directorio que contenga el Box de Vagrant resultante.

- `scripts`: Contiene los scripts de shell que usaramos como `providers` para modificar nuestra imagen.

- `ubuntu2004_vagrant_box.json`: Fichero `json` que leerá Packer para crear nuestra imagen (explicaremos más adelante los detalles).

- `README.md`: Este mismo fichero que lees.

## http

Este directorio contendrá los ficheros de respuesta para la instalación desatendida. Ubuntu Server en su versión 18.04 LTS y anteriores utiliza el instalador de debian (d-i) para dicho proceso. Esto incluye soporte para los ficheros de respuesta `preseeding` para crear instalaciones desatendidas (automatizadas).

[DebianInstaller/Preseed - Debian Wiki](https://wiki.debian.org/DebianInstaller/Preseed)

Con la introducción de Ubuntu Server 20.04 'Focal Fossa' LTS, en abril de 2020, Canonical decidió que el nuevo instalador `subiquity` estaba listo para ocupar su lugar.

Hay una diferencia conceptual entre el nuevo instalador `subiquity` y el `preseeding`. Un archivo `preseed` debe responder a todas las preguntas que el instalador necesita y cambiará al modo interactivo si no se responde alguna pregunta, interrumpiendo el proceso de instalación desatendida.

El nuevo instalador `Subiquity` tiene valores predeterminados para todos los pasos de instalación, esto significa que se puede automatizar completamente el proceso de instalación con solo unas pocas líneas de YAML. No se necesita una respuesta para cada paso.

Podemos encontrar información más detallada en el siguiente enlace:

[Automated Server Installs | Ubuntu](https://ubuntu.com/server/docs/install/autoinstall)

Para que nuestro instalador `subiquity` funcione necesitaremos 2 archivos principalmente (`meta-data` y `user-data`):

`meta-data`: Será un archivo vacío en nuestro caso, pero puede contener información específica del proveedor cuando se inicie en algún servicio en la nube (EC2 por ejemplo).

`user-data`: Este es el archivo YAML que contendrá las directivas de instalación automática.

`vendor-data`: Opcionalmente, también podemos proporcionar un archivo de datos de proveedor.

Nuestro archivo `user-data` tendrá el siguiente aspecto:

```yaml
#cloud-config
autoinstall:
  version: 1
  early-commands:
  - systemctl stop ssh # We prevent Packer from trying to connect and exceeding the maximum number of attempts.
  locale: en_US
  keyboard:
    layout: en
  identity:
    hostname: ubuntu
    password: '$6$xzsJvkg10l$/MR33d6N0hKXj23Mlb7xustF5i2TzA1iQt9gErJysQxnANBHUyeUdyc.paED1gB0tIx5XPG2Zic4BLygr1Z2a/'
    username: vagrant
    realname: "Juan M. Payan"
  ssh:
    install-server: yes
    allow-pw: yes
  storage:
    layout:
      name: lvm
  proxy: http://10.40.50.60:8080 # In the case of being behind a proxy, but it will only work with apt, necessary ("http_proxy": "{{env `http_proxy`}}") to declare the ENV VAR in the json file, for a environment proxy.
```

Se puede facilmente intuir que hace cada entrada, para información más detalla puedes visitar la documentación oficial:

[Automated server install reference | Ubuntu](https://ubuntu.com/server/docs/install/autoinstall-reference)

##### **<u>NOTA:</u>**

La entrada `proxy` permitirá al instalador actualizar y hacer descargas de repositorios `apt` pero en caso de necesitar descargas desde otras fuentes, debermos configurar nuestro `proxy` en las variables de entorno de nuestro fichero `JSON` de `Packer` (Se explicará con más detalle posteriormente).

## iso

Como hemos dicho anteriormente, contendrá la imagen ISO del CD de instalación de Ubuntu 20.04 LTS, que podremos descargar desde aqui:

https://releases.ubuntu.com/focal/ubuntu-20.04.5-live-server-amd64.iso

```bash
wget https://releases.ubuntu.com/focal/ubuntu-20.04.5-live-server-amd64.iso
```

## output

Contendrá la imagen resultante de nuestro sistema preempaquetado, en este caso nuestro fichero Box de Vagrant.

```bash
output/ubuntu-20.04-virtualbox.box
```

## scripts

Este directorio tiene los scripts que pasaremos a la sección `providers` con los cuales personalizaremos la imagen, instalar software, configuraciones, etc...

```bash
vagrant@masterVM:/scripts$ tree
.
├── cleanup.sh
├── motd.sh
├── sudoers.sh
├── update.sh
├── vagrant.sh
└── virtualbox.sh
```

## ubuntu2004_vagrant_box.json

Será nuestro fichero `json` en el que configuraremos todo lo necesario para que Packer pueda crear nuestra imagen.

La instalación de Packer en `Windows / Linux` la puedes ver aquí:

[Packer/Introduccion_a_Packer at main · jpaybar/Packer · GitHub](https://github.com/jpaybar/Packer/tree/main/Introduccion_a_Packer)

Packer usa una plantilla en formato `JSON` para definir una imagen, aunque como dice la pagina oficial a partir de la versión 1.7.0 es preferible usar HCL2 (HashiCorp Configuration Language).

También nos da la posibilidad de usar el comando `hcl2_upgrade` para convertir nuestras plantillas `JSON` a `HCL`.

```bash
packer hcl2_upgrade -with-annotations docker-ubuntu.json
Successfully created docker-ubuntu.json.pkr.hcl
```

Ejecutando el siguiente comando, vemos todas las opciones:

```bash
vagrant@masterVM:$ packer help
```

```bash
Usage: packer [--version] [--help] <command> [<args>]

Available commands are:
    build           build image(s) from template
    console         creates a console for testing variable interpolation
    fix             fixes templates from old versions of packer
    fmt             Rewrites HCL2 config files to canonical format
    hcl2_upgrade    transform a JSON template into an HCL2 configuration
    init            Install missing plugins or upgrade plugins
    inspect         see components of a template
    plugins         Interact with Packer plugins and catalog
    validate        check that a template is valid
    version         Prints the Packer version
```

## Secciones dentro del fichero JSON

Dentro de nuestro fichero de plantilla `JSON` hay tres secciones principales:

`builders`, `provisioners`, `post-processors` y una opcional, `variables`.

### builders

Los `builders` crean máquinas y generan imágenes a partir de esas máquinas para varias plataformas. Por ejemplo, hay constructores separados para EC2, VMware, VirtualBox, etc.

Por lo tanto la sección `builders` define las características de la VM que se instala para
construir la imagen. Esto puede estar definido en la sección `variables`.

Podemos consultar todas las opciones de los `builders` en la pagina oficial, en el siguiente enlace (en este caso para VirtualBox):

[VirtualBox ISO - Builders | Packer by HashiCorp](https://www.packer.io/plugins/builders/virtualbox/iso)

Vamos a analizar algunos apartados de la sección `builders`:

```json
"builders": [
    {	
		"boot_wait": "5s",
		"boot_command": [
        "<enter><enter><f6><esc><wait> ",
        "autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
        "<enter>"
        ],
		"disk_size": "{{ user `virtualbox_disk_size` }}",
		"format": "ova",
		"guest_additions_mode": "upload",
		"guest_additions_path": "VBoxGuestAdditions_{{.Version}}.iso",
		"guest_os_type": "Ubuntu_64",
		"hard_drive_interface": "sata",
		"headless": "{{ user `headless` }}",
		"http_directory": "http",
		"iso_checksum": "{{ user `iso_checksum` }}",
		"iso_url": "iso/{{user `iso_name`}}",
		"shutdown_command": "echo 'vagrant'|sudo -S shutdown -P now",
		"ssh_handshake_attempts": "50",
		"ssh_password": "vagrant",
		"ssh_port": 22,
		"ssh_timeout": "10000s",
		"ssh_username": "vagrant",
        "type": "virtualbox-iso",
        "vboxmanage": [
            [ "modifyvm", "{{.Name}}", "--memory", "{{ user `ram` }}" ],
            [ "modifyvm", "{{.Name}}", "--vram", "16" ],
            [ "modifyvm", "{{.Name}}", "--cpus", "{{ user `cpus` }}" ]
        ],
        "vm_name": "ubuntu2004"
    }
    ]
```

##### `"boot_command":`

Especifica la combinación de teclas que se deben pulsar cuando la máquina virtual se inicia por primera vez para que comience el instalador del sistema operativo. Este comando se escribe después de `"boot_wait":`, lo que le da a la máquina virtual algo de tiempo para cargar.

La secuencia y la combinación de teclas variará según el sistema operativo, hay multiples plantillas aqui:

[Download Packer Community Projects](https://www.packer.io/community-tools#templates)

{{ .HTTPIP }} {{ .HTTPPort }}: la dirección IP y el puerto, respectivamente, del servidor HTTP que servirá el directorio que contiene el fichero de respuesta para la instalación desatendida (`user-data` para el instalador `subiquity` y `preseed` para `d-i`), éste se especifica por el parámetro de configuración `http_directory`. En nuestro caso es `"http_directory": "http"`

Donde `"http"` es el directorio donde tenemos nuestro fichero de respuesta dentro de la carpeta de trabajo como hemos detallado más arriba.

##### `"disk_size":`

Tiene asignado el valor de la variable "{{ user \`virtualbox_disk_size\` }}" que será el tamaño de disco que tendrá la imagen resultante. La palabra clave `user` nos dice que dicha variable ha sido definida por el usuario, en este caso \`virtualbox_disk_size\`. Estas variables de definen en la sección `variables` de nuestro fichero `JSON`.

##### `"format":`

Ya sea `ovf` u `ova`, esto especifica el formato de salida de la máquina virtual exportada. Por defecto es `ovf`.

#### `"guest_additions_mode":`

El método por el cual las `guest additions` se ponen a disposición del `guest` para su instalación. Las opciones válidas son `upload`, `attach`, o `disable`. Si el modo es `attach`, las `guest additions` se adjuntarán como un dispositivo de CD a la máquina virtual. Si el modo es `upload`, las `guest additions` se cargarán en la ruta especificada por `guest_additions_path`. El valor predeterminado es `upload`. Si se usa `disable`, las `guest additions` no se descargarán.

##### `"guest_additions_path":`

La ruta en la máquina virtual donde se cargará el ISO con las `guest additions` de `VirtualBox`. De forma predeterminada, esta es`VBoxGuestAdditions_{{.Version}}.iso`, que debería cargarse en el directorio de inicio de sesión del usuario. La variable `Version` se reemplaza con la versión de `VirtualBox`.

##### `"guest_os_type":`

El tipo de sistema operativo invitado que se está instalando (para nuestro ejemplo `Ubuntu_64`). De forma predeterminada, este es `other`, pero se pueden obtener mejoras considerables en el rendimiento configurando esto en el valor adecuado. Para ver todos los valores disponibles podemos ejecutar el siguiente comando:

```bash
VBoxManage list ostypes
```

Establecer el valor correcto sugiere a `VirtualBox` cómo optimizar el hardware virtual para que funcione mejor con ese sistema operativo.

##### `"hard_drive_interface":`

El tipo de controlador al que está conectado el disco duro principal, por defecto es `ide`. Cuando se establece en `sata`, la unidad se conecta a un controlador `AHCI SATA`.

##### `"headless":`

Por defecto, `Packer` construye máquinas virtuales de `VirtualBox` iniciando una GUI que muestra la consola de la máquina que se está ejecutando. Cuando este valor se establece en `true`, la máquina se iniciará sin una consola.

##### `"http_directory":`

Donde `"http"` es el directorio donde tenemos nuestro fichero de respuesta dentro de la carpeta de trabajo como hemos detallado más arriba.

##### `"iso_url":`

La suma de comprobación del archivo ISO o del disco duro virtual.

##### `"shutdown_command":`

El comando que se usará para apagar correctamente la máquina una vez que se haya realizado todo el aprovisionamiento. De forma predeterminada, esta es una cadena vacía, que le dice a `Packer` que simplemente apague la máquina a la fuerza, a menos que se ejecute un comando de apagado dentro de alguno de los scripts de aprovisionamiento, por lo que se puede omitir de manera segura. Si uno o más scripts requieren un reinicio, se sugiere dejar este espacio en blanco ya que los reinicios pueden fallar y especificar el comando de apagado final en el último script.

##### `"ssh_handshake_attempts":`

El número de `handshakes` con SSH una vez que se pueda conectar. Esto por defecto es 10.

##### `"ssh_password":`

La contraseña en texto plano que se usará para autenticarse con SSH.

##### `"ssh_port":`

Número de puerto para la conexión SSH.

##### `"ssh_timeout":`

El tiempo de espera hasta que SSH esté disponible. `Packer` usa esto para determinar cuándo se ha iniciado la máquina, por lo que suele ser bastante largo.

##### `"ssh_username":`

El nombre de usuario que se usará para autenticarse con SSH.

##### `"type":`

El `builder` VirtualBox puede crear máquinas virtuales y exportarlas en formato OVF u OVA, a partir de una imagen ISO, OVF o VM (en nuestro caso desde una ISO del CD de instalación).

El `builder` construye una máquina virtual a partir de otra desde cero, iniciándola, instalando el sistema operativo, aprovisionando software dentro del sistema operativo y luego apagándola. El resultado del `builder` de VirtualBox es un directorio que contiene todos los archivos necesarios para ejecutar la máquina virtual de forma portátil.

##### `"vboxmanage":`

Comandos de `VBoxManage` con el fin de personalizar aún más la máquina virtual que se está creando.

Opciones en la documentación oficial:

https://www.virtualbox.org/manual/ch08.html

La variable `"{{.Name}}"`, se reemplaza con el nombre único de la VM, el cual es necesario para muchas llamadas que realiza `VBoxManage`.

"{{ user \`ram\` }}" como hemos indicado antes la palabra reservada `user` indica que la variable `ram` ha sido definida por el usuario en la sección `variables`.

##### `"vm_name":`

El nombre del archivo OVF para la nueva máquina virtual, sin la extensión. De forma predeterminada, es packer-BUILDNAME, donde "BUILDNAME" es el nombre de la compilación.



### provisioners

`Provisioners` sería la siguiente sección de un archivo JSON de Packer. Una vez instalado el sistema operativo, se invoca a los `provisioners` para configurar el
sistema.

Lo normal es que sean scripts o comandos en linea de SHELL o PowerShell, dependiendo el sistema para formar la imagen.

Podemos consultar la documentación oficial en :

https://www.packer.io/docs/provisioners

Vamos a analizar algunos apartados de la sección `provisioners`:

##### `"environment_vars":`

Un Array de pares clave/valor para inyectar antes del apartado `"execute_command":`. El formato debe ser clave=valor. Packer inyecta algunas variables de entorno de forma predeterminada, como por ejemplo `http_proxy` o `http_proxy` si nos encontramos detrás de una red corporativa.

Para ello, dependiendo del sistema operativo de nuestro Host donde tenemos instalado `Packer` deberemos setear las variables de entorno:

###### **Windows**

```powershell
$ENV:http_proxy="http://10.40.50.60:8080"
$ENV:https_proxy="http://10.40.50.60:8080"
```

###### **Linux**

```bash
export http_proxy="http://10.40.50.60:8080"
export https_proxy="http://10.40.56.3:8080"
```

En la sección `providers` definimos "http_proxy={{user \`http_proxy\`}}" de esta forma si la variable `http_proxy` la tenemos a su vez en la sección `variables` como "{{env \`http_proxy\`}}" donde la palabra reservada `env` indica que la variable es de entorno y la variable de entorno está configurada en nuestro Host, la variable de tipo `user` de la sección `providers` tomará dicho valor y podremos realizar conexiones a través de nuestro proxy corporativo.

##### `"execute_command":`

El comando a usar para ejecutar el/los script de la sección `providers`. Por defecto es `chmod +x {{ .Path }}; {{ .Vars }} {{ .Path }}`, a menos que el usuario haya configurado `"use_env_var_file": true` -- en ese caso, el comando de ejecución predeterminado es `chmod +x {{.Path}}; . {{.EnvVarFile}} && {{.Path}}`

Las variables de `template` son variables especiales que `Packer` establece automáticamente en el momento de la compilación. Algunos `builders`, `providers` y otros componentes tienen variables de `template` que están disponibles solo para ese componente. Las variables de `template` son reconocibles porque tienen el prefijo de un punto, como {{ .Name }}.

[Template Engine - Templates | Packer by HashiCorp](https://www.packer.io/docs/templates/legacy_json_templates/engine#template-variables)

##### `"expect_disconnect":`

El valor predeterminado es `false`. Cuando es `true`, permite que el servidor se desconecte de `Packer` sin generar un error. Puede ocurrir una desconexión si reinicia el servidor SSH o reinicia el host.

##### `"scripts":`

Un Array de scripts para ejecutar. Los scripts se cargarán y ejecutarán en el orden especificado. Cada secuencia de comandos se ejecuta de forma aislada, por lo que el estado, como las variables de una secuencia de comandos, no continuará con la siguiente. 

Es decir, el orden de ejecución será en este caso ("scripts/update.sh", "scripts/sudoers.sh", "scripts/virtualbox.sh", "scripts/vagrant.sh", "scripts/cleanup.sh", "scripts/motd.sh") y las variables definidas en cada script serán independientes del siguiente.

Otras posibles opciones son `inline` y `script`, podemos ver una definición más detallada en la documentación oficial:

https://www.packer.io/docs/provisioners/shell#configuration-reference

##### `"type":`

El `providers` Shell de Packer aprovisiona máquinas creadas mediante scripts de shell. El aprovisionamiento mediante scripts de Shell es la forma más fácil de instalar y configurar software en una máquina.

En el caso de que la máquina a provisionar para crear nuestra imagen sea Windows, deberemos hacerlo mediante `PowerShell`:

[PowerShell - Provisioners | Packer by HashiCorp](https://www.packer.io/docs/provisioners/powershell)



### variables

Esta sección define variables que se usan en algunos parametros antes descritos de nuestro fichero o `template` `JSON`. Esta sección es definida por el usuario.

```json
"variables": {
		"cpus": "1",
        "headless": "false",
		"http_proxy": "{{env `http_proxy`}}",
		"https_proxy": "{{env `https_proxy`}}",
        "iso_checksum": "5035be37a7e9abbdc09f0d257f3e33416c1a0fb322ba860d42d74aa75c3468d4",
		"iso_name": "ubuntu-20.04.5-live-server-amd64.iso",
		"no_proxy": "{{env `no_proxy`}}",
		"ram": "1024",
        "version": "0",
        "virtualbox_disk_size": "102400"
    }
```

### post-processors

La última sección de nuestro `template` son los `post-processors`. Este apartado es opcional, pero es necesario para crear Boxes de Vagrant. Estas se generan tomando una imagen genérica en formato OVF y empaquetándola como una imagen 
de Vagrant.



## Creando la imagen

Antes de crear nuestro Box de Vagrant, podemos ejecutar el siguiente comando para comprobar que nuestro fichero `JSON` o `template` es correcto:

```bash
vagrant@masterVM:$ packer validate ubuntu2004_vagrant_box.json
The configuration is valid.
```

otro comando útil para ver información sobre las diferentes secciones es:

```bash
vagrant@masterVM:$ packer inspect ubuntu2004_vagrant_box.json
Packer Inspect: JSON mode
Optional variables and their defaults:

  cpus                 = 1
  headless             = false
  http_proxy           = {{env `http_proxy`}}
  https_proxy          = {{env `https_proxy`}}
  iso_checksum         = 5035be37a7e9abbdc09f0d257f3e33416c1a0fb322ba860d42d74aa75c3468d4
  iso_name             = ubuntu-20.04.5-live-server-amd64.iso
  no_proxy             = {{env `no_proxy`}}
  ram                  = 1024
  version              = 0
  virtualbox_disk_size = 102400

Builders:

  virtualbox-iso

Provisioners:

  shell

Note: If your build names contain user variables or template
functions such as 'timestamp', these are processed at build time,
and therefore only show in their raw form here.
```

Ahora podemos construir nuestra imagen:

```powershell
PS C:> packer build .\ubuntu2004_vagrant_box.json
```

Y el resultado será algo similar a lo siguiente:

```bash
Build 'virtualbox-iso' finished after 19 minutes 7 seconds.

==> Wait completed after 19 minutes 7 seconds

==> Builds finished. The artifacts of successful builds are:
--> virtualbox-iso: 'virtualbox' provider box: output/ubuntu-20.04-virtualbox.box
```

## Comprobando el Box de Vagrant recien creado

Para ello agregamos nuestro Box:

```powershell
PS C:> vagrant box add --name my_ubuntu output/ubuntu-20.04-virtualbox.box
```

Generamos nuestro Vagrantfile:

```powershell
vagrant init -m my_ubuntu
```

```powershell
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "my_ubuntu"
end
```

Iniciamos nuestro Box y nos conectamos via SSH:

```powershell
PS C:> vagrant up; vagrant ssh;
```

Y estaremos logados en nuestro Box de Vagrant:

![box_logon.PNG](https://github.com/jpaybar/Packer/blob/main/Como_crear_un_Box_de_Vagrant_para_VirtualBox_con_Packer/box_logon.PNG)



## Author Information

Juan Manuel Payán Barea    (IT Technician)    [st4rt.fr0m.scr4tch@gmail.com](mailto:st4rt.fr0m.scr4tch@gmail.com) [jpaybar (Juan M. Payán Barea) · GitHub](https://github.com/jpaybar) https://es.linkedin.com/in/juanmanuelpayan
