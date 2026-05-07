
---

## 📄 config-academia.rsc (com PPPoE)

```routeros
# ============================================
# Script de Configuração - Academia
# MikroTik RB760iGS (hEX S)
# RouterOS 6.49+
# Conexão WAN via PPPoE
# ============================================

# ============================================
# 1. LIMPEZA INICIAL (mantém interfaces e DHCP)
# ============================================
/ip firewall filter remove [find]
/ip firewall nat remove [find]
/ip firewall mangle remove [find]
/queue simple remove [find]
/queue tree remove [find]
/queue type remove [find where name~"pcq-"]
/ip firewall address-list remove [find]
/interface pppoe-client remove [find]

# ============================================
# 2. INTERFACES (renomeação)
# ============================================
/interface ethernet
set [find default-name=ether1] name=ether1-Link
set [find default-name=ether4] name="ether4 rede clientes"
set [find default-name=ether5] name="ether5-rede adm"

# ============================================
# 3. PPPoE CLIENT (WAN)
# ============================================
# ⚠️ ATENÇÃO: Substitua SEU_USUARIO e SUA_SENHA pelos dados do seu provedor!
/interface pppoe-client
add name=pppoe-out1 user="SEU_USUARIO" password="SUA_SENHA" interface=ether1-Link \
    add-default-route=yes use-peer-dns=yes disabled=no

# ============================================
# 4. ENDEREÇOS IP (REDES INTERNAS)
# ============================================
/ip address
add address=10.8.0.1/23 interface="ether5-rede adm"
add address=10.7.0.1/23 interface="ether4 rede clientes"

# ============================================
# 5. DHCP SERVER (REDES INTERNAS)
# ============================================
/ip pool
add name=dhcp_pool_admin ranges=10.8.0.10-10.8.1.254
add name=dhcp_pool_clientes ranges=10.7.0.10-10.7.1.254

/ip dhcp-server
add address-pool=dhcp_pool_admin disabled=no interface="ether5-rede adm" lease-time=30m name=dhcp-admin
add address-pool=dhcp_pool_clientes disabled=no interface="ether4 rede clientes" lease-time=30m name=dhcp-clientes

/ip dhcp-server network
add address=10.8.0.0/23 gateway=10.8.0.1
add address=10.7.0.0/23 gateway=10.7.0.1

# ============================================
# 6. DNS (via PPPoE - use-peer-dns)
# ============================================
/ip dns
set allow-remote-requests=yes

# ============================================
# 7. ADDRESS LISTS
# ============================================
/ip firewall address-list
add address=10.8.0.0/23 list="REDE SUPORTE"
# Descomente abaixo e adicione o IP do AP UniFi (se necessário)
# add address=10.7.1.254 list="AP-UNIFI"

# ============================================
# 8. FIREWALL - INPUT
# ============================================
/ip firewall filter
add chain=input action=accept connection-state=established,related comment="ACEITA CONEXOES ESTABELECIDAS OU RELACIONADAS"
add chain=input action=accept src-address-list="REDE SUPORTE" comment="ACEITA REDE SUPORTE"
add chain=input action=accept protocol=icmp limit=50,5:packet comment="ACEITA ICMP"
add chain=input action=drop comment="DROP GERAL"

# ============================================
# 9. FIREWALL - FORWARD
# ============================================
# Bloquear cliente -> admin
/ip firewall filter add chain=forward action=drop src-address=10.7.0.0/23 dst-address=10.8.0.0/23 comment="BLOQUEIA CLIENTE -> ADMIN"

# Permitir admin -> cliente
/ip firewall filter add chain=forward action=accept src-address=10.8.0.0/23 dst-address=10.7.0.0/23 comment="PERMITE ADMIN -> CLIENTE"

# Aceitar conexões estabelecidas
/ip firewall filter add chain=forward action=accept connection-state=established,related comment="FORWARD - CONEXOES ESTABELECIDAS"

# FastTrack (performance)
/ip firewall filter add chain=forward action=fasttrack-connection connection-state=established,related comment="FASTTRACK"

# Aceitar internet (regra geral)
/ip firewall filter add chain=forward action=accept comment="FORWARD - ACEITAR INTERNET"

# Descomente abaixo se tiver AP UniFi (substitua o IP)
# /ip firewall filter add chain=forward action=accept src-address-list="AP-UNIFI" dst-address=10.8.0.0/23 comment="LIBERA AP UNIFI -> CONTROLLER"
# /ip firewall filter add chain=forward action=accept protocol=tcp src-address-list="AP-UNIFI" dst-address=10.8.0.0/23 dst-port=8080,8443,8880,10001 comment="UNIFI PORTAS"

# ============================================
# 10. NAT (usando interface PPPoE)
# ============================================
/ip firewall nat
add action=masquerade chain=srcnat out-interface=pppoe-out1 comment="NAT - PPPoE"

# ============================================
# 11. PCQ - LIMITAÇÃO DE BANDA
# ============================================
/queue type
add kind=pcq name=pcq-up-clientes pcq-classifier=src-address
add kind=pcq name=pcq-down-clientes pcq-classifier=dst-address

/queue simple
add name="clientes-academia" target=10.7.0.0/23 queue=pcq-up-clientes/pcq-down-clientes max-limit=40M/300M comment="PCQ CLIENTES - AJUSTE AQUI OS VALORES DO SEU LINK"

# ============================================
# 12. MANGLE (Marcar pacotes pequenos)
# ============================================
/ip firewall mangle
add chain=prerouting action=mark-connection new-connection-mark=small-pkt-conn passthrough=yes protocol=tcp src-address=10.7.0.0/23
add chain=prerouting action=mark-packet new-packet-mark=small-packets packet-size=1-128 passthrough=no protocol=tcp src-address=10.7.0.0/23
add chain=prerouting action=mark-packet new-packet-mark=small-packets packet-size=1-128 passthrough=no protocol=udp src-address=10.7.0.0/23

# ============================================
# 13. QUEUE TREE (Prioridade para pacotes pequenos)
# ============================================
/queue type
add kind=pcq name=pcq-small-up pcq-classifier=src-address
add kind=pcq name=pcq-small-down pcq-classifier=dst-address

/queue tree
add name=upload-prioritario parent=pppoe-out1 packet-mark=small-packets priority=1 queue=pcq-small-up
add name=download-prioritario parent="ether4 rede clientes" packet-mark=small-packets priority=1 queue=pcq-small-down

# ============================================
# 14. SERVIÇOS (Segurança)
# ============================================
/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set ssh disabled=yes
set api disabled=yes
set api-ssl disabled=yes
set winbox port=[Escolha sua porta]

# ============================================
# 15. AJUSTES FINAIS
# ============================================
/system clock set time-zone-name=America/Sao_Paulo
/system identity set name="NOME-DA-SUA-RB"
/system package update set channel=long-term

# ============================================
# 16. MENSAGEM FINAL
# ============================================
:put "========================================="
:put "Configuracao concluida com sucesso!"
:put "========================================="
:put "REDE ADMIN: 10.8.0.1/23 (DHCP ativo)"
:put "REDE CLIENTES: 10.7.0.1/23 (DHCP ativo)"
:put "WINBOX PORTA: [Porta Escolhida]"
:put "PPPoE: configurado na interface pppoe-out1"
:put "========================================="
:put "ANTES DE USAR:"
:put "1. Verifique se o PPPoE conectou:"
:put "   /interface pppoe-client monitor pppoe-out1"
:put "========================================="
:put "2. Ajuste o limite de banda conforme seu link:"
:put "   /queue simple set [find name=clientes-academia] max-limit=UPLOAD/DOWNLOAD"
:put "========================================="
