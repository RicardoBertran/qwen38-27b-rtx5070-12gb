param(
    [int]$Lineas = 1100,
    [string]$Salida = (Join-Path $PSScriptRoot '..\pruebas\prompt-largo.txt')
)

$inicio = @(
    'Analiza el siguiente archivo sintético completo.'
    'Devuelve únicamente las tres claves SECRET_KEY que aparezcan, una por línea y en orden.'
    'No expliques el procedimiento.'
    ''
)

$lineasCodigo = for ($i = 1; $i -le $Lineas; $i++) {
    if ($i -eq 55) {
        'SECRET_KEY = "RICK-A7F3-291C"'
    }
    elseif ($i -eq [math]::Floor($Lineas / 2)) {
        'SECRET_KEY = "RICK-B4D8-73E1"'
    }
    elseif ($i -eq ($Lineas - 55)) {
        'SECRET_KEY = "RICK-C9A2-5F60"'
    }
    else {
        'registro_{0:D4} = procesar("elemento_{0:D4}", prioridad={1})' -f $i, ($i % 7)
    }
}

$contenido = $inicio + '```python' + $lineasCodigo + '```'
$ruta = [System.IO.Path]::GetFullPath($Salida)
[System.IO.File]::WriteAllLines($ruta, $contenido, [System.Text.UTF8Encoding]::new($false))

Write-Host "Prompt creado: $ruta"
Write-Host "Líneas sintéticas: $Lineas"
Write-Host 'Comprueba el número de tokens en Llama UI: debe superar 6.144 y quedar por debajo de 32.768.'
