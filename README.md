# Qwen3.8-27B IQ2_XXS en una RTX 5070 de 12 GB

Prueba local con `llama.cpp` / Llama UI para comparar el mismo modelo y el mismo prompt en dos perfiles:

| Perfil | Visión | Contexto configurado | Offload | Resultado observado |
|---|---:|---:|---:|---|
| `qwen38-27b-code-base` | Sí (`mmproj`) | 6.144 tokens | automático | El prompt largo no cabe y se cancela |
| `qwen38-27b-code-novision` | No | 32.768 tokens | todas las capas | El mismo prompt termina; ~41,3 tokens/s |

Esto representa **5,33 veces más contexto configurado** (`32768 / 6144`) al retirar un componente que no hacía falta para una tarea solo de texto/código. No es una comparación universal ni significa que el rendimiento vaya a ser idéntico en cualquier prompt, versión o equipo.

## Idea de la prueba

El modelo multimodal puede interpretar imágenes mediante un proyector (`mmproj`). Ese componente también consume VRAM. Si una sesión solo necesita texto, código o documentos, puede omitirse el `mmproj` y dedicar ese margen a una ventana de contexto mayor.

La comparación mantiene el mismo GGUF, los mismos parámetros de muestreo, la misma caché KV y el mismo prompt. Solo cambia lo imprescindible:

```diff
- mmproj = <RUTA_AL_MMPROJ>
- ctx-size = 6144
- n-gpu-layers = auto
+ # mmproj omitido: sesión sin visión
+ ctx-size = 32768
+ n-gpu-layers = all
```

## ¿Qué significa IQ2_XXS?

`IQ2_XXS` es una cuantización GGUF de muy pocos bits orientada a reducir mucho el tamaño y la memoria del modelo. Hace posible encajar un modelo de 27B en hardware más limitado, pero existe un intercambio: frente a cuantizaciones de más bits, puede perder precisión o calidad en algunas tareas.

En la prueba se utilizó un GGUF IQ2_XXS de aproximadamente **9,39 GB en disco (8,75 GiB)**. Ese tamaño no equivale al consumo final de VRAM: al cargarlo también intervienen la caché KV, buffers, contexto, el proyector de visión y la versión de `llama.cpp`.

## Contenido del repositorio

```text
configs/
  qwen38-27b-code-base.ini       # visión, contexto 6.144
  qwen38-27b-code-novision.ini   # sin visión, contexto 32.768
  llama-ui-profiles.ini          # los dos perfiles juntos
pruebas/
  README.md                      # protocolo y cómo registrar resultados
scripts/
  generar-prompt-largo.ps1       # prompt reproducible para ambos perfiles
LICENSE
```

No se incluyen modelos, `mmproj`, vídeos ni rutas locales. Sustituye los marcadores `<RUTA_...>` de las configuraciones por tus rutas.

## Reproducción paso a paso

### 1. Requisitos

- Windows y una GPU NVIDIA; la prueba original se hizo con una RTX 5070 de 12 GB.
- Una compilación de `llama.cpp` con CUDA compatible con la GPU.
- Llama UI configurada para leer perfiles INI, o `llama-server` por línea de comandos.
- El GGUF Qwen3.8-27B IQ2_XXS y su `mmproj` compatible.

La versión de `llama.cpp`, los controladores y la compilación CUDA pueden cambiar memoria y velocidad. Registra sus versiones cuando compares resultados.

### 2. Configurar rutas

Edita los dos archivos de `configs/`:

```ini
m = <RUTA_AL_MODELO_GGUF>
mmproj = <RUTA_AL_MMPROJ>
```

`mmproj` aparece únicamente en el perfil base. No lo añadas al perfil `novision`.

Si Llama UI usa un solo fichero de perfiles, copia `configs/llama-ui-profiles.ini` a su ubicación habitual y reemplaza los dos marcadores.

### 3. Crear un prompt largo común

Desde PowerShell, en la raíz del repositorio:

```powershell
.\scripts\generar-prompt-largo.ps1
```

Se creará `pruebas/prompt-largo.txt`. Pega **exactamente el mismo archivo** en los dos perfiles. El generador produce un prompt deliberadamente mayor que 6K y menor que 32K en condiciones normales, con tres claves distribuidas en el texto. Como la tokenización depende del modelo y de la plantilla de chat, comprueba el contador de Llama UI antes de lanzar la prueba.

También puedes sustituirlo por tu propio prompt real; lo importante es no modificarlo entre A y B.

> El prompt de la grabación original rondó los 9.142 tokens, pero su contenido no forma parte de este repositorio. El generador incluido crea un sustituto público para repetir la comparación de capacidad; no pretende reproducir exactamente la cifra de velocidad del prompt privado.

### 4. Ejecutar el perfil base

1. Selecciona `qwen38-27b-code-base`.
2. Confirma en el registro: `ctx-size = 6144` y `mmproj` cargado.
3. Pega `pruebas/prompt-largo.txt` y envíalo.
4. Registra si la interfaz rechaza o cancela la solicitud por superar el contexto.
5. Cierra el servidor antes de cambiar de perfil, para liberar la VRAM.

### 5. Ejecutar el perfil sin visión

1. Selecciona `qwen38-27b-code-novision`.
2. Confirma: no hay `mmproj`, `ctx-size = 32768` y `n-gpu-layers = all`.
3. Pega el mismo `pruebas/prompt-largo.txt`, sin editarlo.
4. Comprueba que recupera las tres claves y termina la respuesta.
5. Anota prompt tokens, tokens generados, VRAM y velocidad de generación.

### 6. Equivalente con `llama-server`

Base, con visión:

```powershell
.\llama-server.exe -m "<RUTA_AL_MODELO_GGUF>" --mmproj "<RUTA_AL_MMPROJ>" --ctx-size 6144 --batch-size 256 --ubatch-size 128 --parallel 1 --flash-attn on --cache-type-k q8_0 --cache-type-v q8_0
```

Sin visión:

```powershell
.\llama-server.exe -m "<RUTA_AL_MODELO_GGUF>" --ctx-size 32768 --n-gpu-layers all --batch-size 256 --ubatch-size 128 --parallel 1 --flash-attn on --cache-type-k q8_0 --cache-type-v q8_0
```

En el segundo comando la visión se desactiva simplemente **omitiendo `--mmproj`**.

## Medir VRAM sin llenar la pantalla

Lectura compacta:

```powershell
$x=nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits;$a=$x-split',';"VRAM: $($a[0].Trim()) / $($a[1].Trim()) MiB"
```

Actualización cada segundo, útil para grabación vertical:

```powershell
while($true){Clear-Host;$x=nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits;$a=$x-split',';"VRAM`n$($a[0].Trim()) / $($a[1].Trim()) MiB";Start-Sleep 1}
```

Detén el bucle con `Ctrl+C`.

## Resultado de referencia

En la ejecución original:

- RTX 5070 con 12 GB de VRAM.
- Mismo Qwen3.8-27B IQ2_XXS y el mismo prompt de ~9.142 tokens en ambas pasadas.
- Con visión y 6.144 de contexto: el prompt no entró y la ejecución se canceló.
- Sin visión, 32.768 de contexto y todas las capas en GPU: el prompt terminó.
- Velocidad observada al generar: **~41,3 tokens/s**.

La cifra es una observación de una ejecución, no una promesa de rendimiento. Para una comparación rigurosa conviene hacer varias pasadas, descartar la primera si hay calentamiento/cachés y publicar versión, prompt tokens y métricas de `prompt eval` y `eval` por separado.

## Limitaciones importantes

- **12 GB no equivalen a 128K de contexto.** La VRAM necesaria crece con el modelo, la caché KV, el número de secuencias, el tipo de caché y la longitud real utilizada.
- **128K son 131.072 tokens** cuando `K = 1024`: `128 × 1024 = 131072`.
- Configurar `ctx-size = 32768` no significa que cada solicitud use 32.768 tokens; solo fija el máximo disponible.
- El prompt y la respuesta deben compartir la ventana de contexto.
- Quitar el `mmproj` elimina la entrada de imágenes. El modelo sigue sirviendo para texto, pero ya no puede analizar imágenes en esa sesión.
- IQ2_XXS prioriza memoria y velocidad de carga; puede degradar calidad frente a cuantizaciones mayores.
- Un contexto más largo puede reducir el rendimiento, especialmente durante el procesamiento del prompt. Los ~41,3 tokens/s corresponden a la generación observada en esta prueba concreta.
- Si realmente necesitas 131.072 tokens con un 27B, una GPU de 12 GB puede no ser la combinación adecuada. Considera un modelo menor, más RAM/VRAM, offload parcial o una caché KV más agresiva, asumiendo sus costes.

## Publicarlo en GitHub

La carpeta entregada ya está inicializada en la rama `main` y los archivos están preparados para el primer commit. Configura tu identidad si Git todavía no la conoce, crea el commit y enlaza un repositorio vacío de GitHub:

```powershell
git config user.name "<TU NOMBRE>"
git config user.email "<TU EMAIL>"
git commit -m "Documenta la prueba Qwen3.8-27B en RTX 5070"
git remote add origin https://github.com/<USUARIO>/<REPO>.git
git push -u origin main
```

## Licencia

El contenido original de este repositorio se distribuye bajo MIT. Los pesos del modelo, el `mmproj`, `llama.cpp`, Llama UI y los controladores conservan sus propias licencias; MIT no las sustituye.
