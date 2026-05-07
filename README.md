# Configuração MikroTik RB760iGS para Academia

## 📋 Visão Geral

Configuração profissional para academia com:
- Isolamento completo entre rede administrativa e rede de clientes
- Limitação de banda por PCQ (divisão justa entre clientes ativos)
- Prioridade automática para TikTok, Instagram Reels e WhatsApp
- FastTrack para máxima performance
- **Conexão WAN via PPPoE** (provedor de internet)

## 🏗️ Arquitetura da Rede

| Rede | Faixa IP | Interface | Uso |
|:---|:---|:---|:---|
| **Administrativa** | 10.8.0.0/23 | ether5-rede adm | Computadores, caixa, UniFi Controller |
| **Clientes** | 10.7.0.0/23 | ether4 rede clientes | WiFi da academia (AP UniFi) |
| **WAN** | PPPoE | ether1-Link | Internet do provedor (usuário/senha) |

## 📊 Limites de Banda

| Direção | Limite Total | Divisão |
|:---|:---|:---|
| Download | 300 Mbps | PCQ - igual entre clientes ativos |
| Upload | 40 Mbps | PCQ - igual entre clientes ativos |

> ⚠️ Ajuste os valores de `max-limit` no script conforme seu link de internet.

## 🎯 Prioridades

| Tipo de Tráfego | Prioridade |
|:---|:---|
| Pacotes pequenos (1-128 bytes) - TikTok, WhatsApp | 🚀 Máxima |
| Conexões estabelecidas | ✅ Alta |
| Navegação geral | ✅ Normal |
| Downloads pesados | ⚠️ Limitada (para não atrapalhar) |

## 🔒 Firewall

### Chain INPUT (protege o roteador)
1. ACCEPT established/related
2. ACCEPT REDE SUPORTE (10.8.0.0/23)
3. ACCEPT ICMP (limitado a 50 pacotes)
4. DROP GERAL

### Chain FORWARD
1. BLOQUEIA CLIENTE → ADMIN (drop)
2. PERMITE ADMIN → CLIENTE (accept)
3. ACCEPT established/related
4. FASTTRACK (aceleração)
5. ACEITAR INTERNET (accept)

## 🚀 Como Instalar

### 1. Fazer backup da configuração atual
/system backup save name=backup-original

2. Antes de executar o script
Configure os dados do seu provedor PPPoE no script:

Linha: add name=pppoe-out1 user="SEU_USUARIO" password="SUA_SENHA" interface=ether1-Link

Substitua SEU_USUARIO e SUA_SENHA pelos dados fornecidos pelo provedor

3. Enviar o script para a MikroTik
No Winbox, vá em Files e clique em Upload. Selecione o arquivo config-academia.rsc

4. Executar o script
/import config-academia.rsc

6. Ajustar valores do link de internet
/queue simple set [find name="clientes-academia"] max-limit=40M/300M

🧪 Testes de Validação
Teste	Comando/Procedimento	Resultado Esperado
PPPoE conectado	/interface pppoe-client print	status=running
Isolamento	Ping de 10.7.x.x para 10.8.0.1	❌ Timeout
Admin → Cliente	Ping de 10.8.x.x para 10.7.0.1	✅ Responde
Internet clientes	Conectar um celular na rede clientes	✅ Navega normal
Limite de banda	Speedtest na rede clientes	≤ 300M download / ≤ 40M upload
Prioridade TikTok	Scroll no TikTok com download pesado	✅ Fluido

📝 Ajustes Personalizáveis
Alterar limite de banda total
/queue simple set [find name="clientes-academia"] max-limit=<UPLOAD>/<DOWNLOAD>

Exemplo: link de 100 Mbps para clientes
/queue simple set [find name="clientes-academia"] max-limit=40M/100M

Verificar status da conexão PPPoE
/interface pppoe-client monitor pppoe-out1

Reconectar PPPoE (se necessário)
/interface pppoe-client disable pppoe-out1
/interface pppoe-client enable pppoe-out1

🔧 Serviços
Serviço	Porta	Status
Winbox	1530	✅ Habilitado
Telnet	23	❌ Desabilitado
SSH	22	❌ Desabilitado
FTP	21	❌ Desabilitado
WWW	80	❌ Desabilitado

📦 Backup da Configuração Final
routeros
/export compact file=config-academia-final
/system backup save name=backup-academia-final password=sua_senha

📞 Suporte
Em caso de problemas, conecte via MAC Winbox (independente de configurações IP) e execute:
routeros
/ip firewall filter disable [find action=drop]

📄 Licença
Configuração livre para uso e modificação.
