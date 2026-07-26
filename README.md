# Pi-hole com Docker Compose

Laboratório pessoal para aprender, testar e evoluir o Pi-hole sem alterar toda a
rede logo no primeiro teste.

O Pi-hole recebe consultas DNS dos seus dispositivos e compara os domínios com
listas de bloqueio. Consultas permitidas seguem para um servidor DNS externo;
domínios conhecidos por anúncios, rastreamento ou telemetria podem ser bloqueados.
O painel mostra consultas, clientes, bloqueios e listas.

> Este projeto não bloqueia anúncios dentro do YouTube e de outros serviços que
> entregam anúncios pelo mesmo domínio do conteúdo. Ele atua na camada DNS.

## O que este laboratório cria

| Recurso | Endereço/porta |
|---|---|
| Painel do Pi-hole | `http://localhost:8080/admin` |
| DNS TCP | `127.0.0.1:53` |
| DNS UDP | `127.0.0.1:53` |
| Dados persistentes | `./data/etc-pihole` |

O Compose usa a imagem oficial `pihole/pihole:2026.05.0`. A versão está fixada
para o laboratório continuar reproduzível; a atualização deve ser feita de forma
intencional.

## Pré-requisitos

- Docker Desktop com contêineres Linux no Windows, ou Docker Engine no Linux;
- portas TCP e UDP `53` disponíveis;
- porta TCP `8080` disponível;
- PowerShell 5.1 ou superior para o teste no Windows.

## 1. Verificar se as portas estão livres no Windows

Abra o PowerShell como administrador:

```powershell
Get-NetTCPConnection -LocalPort 53,8080 -ErrorAction SilentlyContinue
Get-NetUDPEndpoint -LocalPort 53 -ErrorAction SilentlyContinue
```

Se aparecer um processo usando a porta 53, identifique-o antes de iniciar:

```powershell
Get-Process -Id (Get-NetUDPEndpoint -LocalPort 53).OwningProcess
```

Não encerre serviços de DNS da empresa ou do Windows sem validar a função deles.

## 2. Configurar a senha

No PowerShell, dentro da pasta do projeto:

```powershell
Copy-Item .env.example .env
notepad .env
```

Troque `PIHOLE_PASSWORD` por uma senha forte. O `.env` está ignorado pelo Git e
não deve ser enviado nem compartilhado.

## 3. Validar e iniciar

```powershell
docker compose config
docker compose pull
docker compose up -d
docker compose ps
docker compose logs --tail 100 pihole
```

Quando o contêiner estiver em execução, abra:

`http://localhost:8080/admin`

## 4. Testar sem mudar o DNS do computador

Primeiro confirme uma resolução normal:

```powershell
Resolve-DnsName example.com -Server 127.0.0.1 -DnsOnly
```

Depois consulte um domínio que costuma constar nas listas:

```powershell
Resolve-DnsName doubleclick.net -Server 127.0.0.1 -DnsOnly
```

O bloqueio pode aparecer como `0.0.0.0`, `::`, ausência de endereço ou
`NXDOMAIN`, conforme a configuração. A confirmação definitiva fica no
**Query Log** do painel.

Também há um teste pronto:

```powershell
.\scripts\Test-Pihole.ps1
```

No Linux:

```bash
chmod +x scripts/test-pihole.sh
./scripts/test-pihole.sh
```

## 5. Testar em somente um dispositivo

Depois dos testes locais, descubra o IPv4 da máquina que executa o Docker:

```powershell
ipconfig
```

No adaptador de rede de apenas um computador de teste, configure esse IPv4 como
DNS. Não use `127.0.0.1` em outro equipamento: esse endereço sempre aponta para
o próprio equipamento.

Valide:

```powershell
ipconfig /flushdns
nslookup example.com IP_DO_HOST_DOCKER
nslookup doubleclick.net IP_DO_HOST_DOCKER
```

Só altere o DNS distribuído pelo roteador/DHCP depois de confirmar estabilidade,
listas e exceções. Em uma rede de empresa, faça isso apenas com autorização e
janela de mudança.

## Operação diária

```powershell
# Ver estado
docker compose ps

# Acompanhar logs
docker compose logs -f pihole

# Reiniciar
docker compose restart pihole

# Parar sem apagar dados
docker compose down

# Atualizar para a versão definida no .env
docker compose pull
docker compose up -d
```

## Reversão

Se você alterou o DNS de um único Windows, volte o adaptador para DNS automático
ou restaure os endereços anteriores e execute:

```powershell
ipconfig /flushdns
docker compose down
```

O diretório `data` permanece no computador. Para recomeçar do zero, faça backup
e remova esse diretório somente com o contêiner parado.

## Problemas comuns

### `bind: address already in use` na porta 53

Outro serviço DNS já usa a porta. Localize o processo com os comandos da etapa 1.
Em Linux, `systemd-resolved` pode ocupar a porta; em Windows, VPN, DNS proxy,
Internet Connection Sharing ou outro contêiner também podem causar conflito.

### Painel abre, mas os clientes não usam o Pi-hole

Confirme se o DNS do cliente aponta para o IPv4 do host Docker, se a porta 53 está
liberada no Firewall do Windows para a rede privada e se o host mantém IP fixo ou
reserva DHCP.

### A internet para ao desligar o host

Isso ocorre quando o Pi-hole é o único DNS anunciado. Para uso permanente, planeje
alta disponibilidade ou um segundo DNS filtrante. Um DNS público como secundário
pode evitar indisponibilidade, mas também permite que clientes contornem o filtro.

## Próximas evoluções

- exportar métricas para Prometheus e Grafana;
- monitorar DNS e painel com Uptime Kuma;
- backup versionado das configurações;
- listas por grupo de dispositivos;
- segundo Pi-hole para redundância;
- documentação da integração futura com o projeto de disponibilidade e verificação.

## Referências oficiais

- [Imagem Docker oficial do Pi-hole](https://github.com/pi-hole/docker-pi-hole)
- [Documentação do Pi-hole](https://docs.pi-hole.net/)
