# dgm-navbar

Componente web polymer para definir el navbar utilizado en sitios relativos a `datos.gob.mx`

## Uso

Para usar el componente en cualquier aplicación es necesario instalarlo en el sitio, la manera más fácil es a través de `bower`.

En el archivo de configuración de la aplicación, normalmente `bower.json` incluye el componente como dependencía.

```
{
  "dependencies"  : {
    "dgm-navbar"  : "mxabierto/dgm-navbar#latest"
  }
}
```

Una vez listados los componentes a utilizar instalalos con:

```
bower install
```

## Dependencias

Para utilizar los componentes web en cualquier aplicación es necesario utilizar `Polymer`.

`Polymer` requiere el componente HTML `polymer` y la librería `webcomponents.js` ambos son instalados como dependecias utilizando bower.

## Instalación

Una vez instalado el componente utilizando `bower` se creará una estructura como la siguiente:

```
- bower_components
  - dgm-navbar
  - polymer
  - webcomponentsjs
```

Para utilizar los componentes es necesario incluir `webcomponents.js`, incluye el siguiente script antes de la etiqueta de cierre `</body>`.

```
<script src="bower_components/webcomponentsjs/webcomponents-lite.min.js"></script>
```

Y en la etiqueta `<head>` del documento.

```
<link rel="import" href="bower_components/polymer/polymer.html">
<link rel="import" href="bower_components/dgm-navbar/dgm-navbar.html">
```

No olvides reemplazar el path a `bower_components` que corresponda a tu instalación.

Ya que hayas incluido el componente y las dependencias necesarias, basta con agregar el tag HTML en el sitio donde deba colocarse el componente.

```
<dgm-navbar></dgm-navbar>
```
