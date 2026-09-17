# Protocolo de prueba

## Regla principal

Usa el mismo archivo `prompt-largo.txt`, sin editarlo, primero con `qwen38-27b-code-base` y después con `qwen38-27b-code-novision`.

Genera el archivo desde la raíz del repositorio:

```powershell
.\scripts\generar-prompt-largo.ps1
```

El prompt contiene tres claves repartidas al principio, en el centro y al final. Es una prueba pública equivalente en estructura, no el contenido privado usado en la grabación original. La respuesta correcta debe devolver, en ese orden:

```text
RICK-A7F3-291C
RICK-B4D8-73E1
RICK-C9A2-5F60
```

## Datos que conviene registrar

| Campo | Base | Sin visión |
|---|---|---|
| Perfil | `qwen38-27b-code-base` | `qwen38-27b-code-novision` |
| `ctx-size` | 6144 | 32768 |
| Prompt tokens |  |  |
| Prompt eval (t/s) |  |  |
| Generación (t/s) |  |  |
| VRAM en reposo (MiB) |  |  |
| Pico de VRAM (MiB) |  |  |
| Resultado |  |  |
| Versión `llama.cpp` |  |  |
| Driver NVIDIA |  |  |

No confundas la velocidad de procesamiento del prompt con la velocidad de generación. Si publicas resultados nuevos, identifica ambas.
