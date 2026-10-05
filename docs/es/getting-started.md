<!-- translation of docs/en/getting-started.md @ a68235d39cbc -->
# Primeros pasos

[← Índice de documentación](index.md)

> Esta es una traducción del [original en inglés](../en/getting-started.md).
> Si hay diferencias, la versión en inglés es la correcta.

## Requisitos

- Godot 4.7.2. Basta la versión estándar: el proyecto usa GDScript y no requiere el SDK de .NET.
- Nada más para la demo: Jolt Physics viene integrado en el motor, el renderizador es Forward+ y todos los assets
  están en el repositorio.

## Abrir y ejecutar

1. Clona el repositorio.
2. En el Administrador de Proyectos (Project Manager), elige **Importar** (Import) y selecciona `project.godot`;
   luego abre el proyecto. La primera importación tarda un poco, ya que la caché `.godot/` no está en el repositorio.
3. Presiona F5. La escena principal es `res://gdscript/main.tscn`.

La demo carga tus ajustes anteriores. Usa **F10 → Restablecer todo** para obtener los valores descritos aquí.
En un clon nuevo, espera a que terminen las importaciones antes de abrir scripts o ejecutar pruebas. No copies
la caché `.godot/` de otro proyecto.

## Qué ves

El héroe está en el punto de aparición, en medio de un claro cercado. Los controles aparecen en la esquina superior
izquierda y la tasa de fotogramas en la superior derecha.

- **Clic izquierdo** en el suelo: el héroe corre hasta allí rodeando los obstáculos, y un marcador indica el punto.
- **Mantener el botón izquierdo**: el héroe corre tras el cursor.
- **Botón derecho + mouse**: orbitar la cámara. **Rueda**: zoom.
- **Botón derecho y luego izquierdo**: correr hacia donde mira la cámara. **Izquierdo mantenido y luego derecho**:
  mirar alrededor durante la carrera. **Botón derecho + WASD**: moverse según la cámara.
- **Shift** activa el sprint, **Espacio** salta, **F10** abre la configuración.

La lista completa está en [Controles](controls.md).

Lugares a los que ir:

- **Círculo Antiguo**, el anillo de columnas al noroeste del punto de aparición. Camina entre las columnas y el héroe
  se verá como una silueta detrás de ellas.
- **Campamento de Viajeros** al este y **Granja del Pozo** al suroeste, con NPC.
- **Cumbre de los Vientos**, la montaña del noreste: haz clic en la cima y el héroe toma el sendero en espiral.
- El laberinto de setos, la plataforma con su rampa y su escalera, y la trampa en forma de U cerca del punto de
  aparición, para probar la búsqueda de rutas.
- Los diez aspectos del héroe en fila junto al muro sur. Elige uno en Configuración → Personaje → **Aspecto del
  héroe**.
- **La plataforma de teletransporte** junto al Círculo Antiguo, con un cristal giratorio: súbete y pulsa E o haz
  clic en la invitación para ir a **Isla Solitaria** y su **Campamento del Ermitaño**. Otra plataforma de la isla
  («Teletransporte: Valle Verde») te devuelve.

## Configuración

F10 abre la ventana de configuración y pausa el juego; Esc o F10 la cierra. La configuración se guarda en
`user://settings.cfg` y se aplica al instante. Para ocultar la ayuda de controles, desactiva Configuración → Interfaz
→ **Ayuda de controles y velocidad**. El idioma de la interfaz se elige en la misma pestaña. Todas las opciones:
[Configuración](settings.md).

## Ejecutar las pruebas

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

Aquí `godot` es tu ejecutable de Godot 4.7.2. En Windows usa la compilación `_console.exe` para ver la salida y
obtener el código de salida. En un clon nuevo, importa primero el proyecto una vez, en el editor o con
`godot --headless --path . --import`. Detalles: [Pruebas](testing.md).

## Siguientes pasos

- [Transferir el héroe preparado](integration.md#transferir-el-héroe-de-la-demo-a-tu-proyecto): archivos exactos,
  nivel de prueba y comprobaciones para una integración funcional.
- [Configuraciones](configurations.md): opción predeterminada y dos variantes útiles de movimiento y cámara.
- [Arquitectura](architecture.md): qué hace cada nodo y cómo se conectan.
- [Preparación del proyecto](project-setup.md): capas de física, acciones de entrada y ajustes opcionales.

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
