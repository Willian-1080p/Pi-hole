[CmdletBinding()]
param(
    [string]$DnsServer = "127.0.0.1",
    [string]$AllowedDomain = "example.com",
    [string]$BlockedDomain = "doubleclick.net"
)

$ErrorActionPreference = "Stop"

function Test-DnsQuery {
    param(
        [Parameter(Mandatory)]
        [string]$Domain
    )

    try {
        $answers = Resolve-DnsName -Name $Domain -Server $DnsServer -DnsOnly
        $addresses = @(
            $answers |
                Where-Object { $_.Type -in @("A", "AAAA") } |
                ForEach-Object { $_.IPAddress }
        )

        [PSCustomObject]@{
            Dominio  = $Domain
            Servidor = $DnsServer
            Resultado = if ($addresses.Count -gt 0) { $addresses -join ", " } else { "Sem endereço A/AAAA" }
            Consulta = "OK"
        }
    }
    catch {
        [PSCustomObject]@{
            Dominio  = $Domain
            Servidor = $DnsServer
            Resultado = $_.Exception.Message
            Consulta = "Bloqueado ou falhou"
        }
    }
}

Write-Host "Verificando a porta DNS em $DnsServer..." -ForegroundColor Cyan
$portTest = Test-NetConnection -ComputerName $DnsServer -Port 53 -WarningAction SilentlyContinue

[PSCustomObject]@{
    Servidor = $DnsServer
    PortaTCP53 = $portTest.TcpTestSucceeded
} | Format-Table -AutoSize

Write-Host "Executando consultas DNS..." -ForegroundColor Cyan
@(
    Test-DnsQuery -Domain $AllowedDomain
    Test-DnsQuery -Domain $BlockedDomain
) | Format-Table -AutoSize -Wrap

Write-Host ""
Write-Host "Observação: o domínio de teste pode retornar 0.0.0.0, :: ou erro/NXDOMAIN quando estiver bloqueado." -ForegroundColor Yellow
