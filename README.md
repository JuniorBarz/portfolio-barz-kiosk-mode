# Barz Kiosk Mode

Aplicação Flutter/Android para transformar dispositivos dedicados em uma experiência de quiosque leve, com inicialização automática, seleção do aplicativo permitido e recuperação do estado de execução.

> Edição independente para avaliação de portfólio. Não contém configuração, infraestrutura ou dados de produção.

## Problema

Dispositivos dedicados precisam iniciar sempre no aplicativo correto, reduzir saídas acidentais e continuar utilizáveis quando permissões especiais não estão disponíveis. O desafio é combinar uma interface simples em Flutter com recursos nativos do Android sem prometer o mesmo nível de bloqueio de um equipamento provisionado como Device Owner.

## Solução

O projeto oferece dois níveis de operação:

- modo leve, baseado em launcher, monitoramento e recuperação;
- integração opcional com recursos administrativos quando o dispositivo foi provisionado adequadamente.

O aplicativo valida o pacote escolhido, acompanha permissões necessárias, inicia o alvo configurado e entra em modo seguro quando uma etapa nativa falha.

## Principais funcionalidades

- catálogo de aplicativos instalados;
- seleção e validação do aplicativo permitido;
- inicialização após o boot;
- launcher dedicado;
- watchdog e recuperação de foco;
- PIN local armazenado com salt e hash;
- bloqueio progressivo após tentativas inválidas;
- tela de diagnóstico de permissões;
- modo seguro para falhas nativas.

## Arquitetura

- **Flutter/Dart:** estado, regras de configuração, PIN e interface.
- **Method Channel:** contrato explícito entre Flutter e Android.
- **Kotlin/Android:** launcher, receiver de boot, watchdog, overlay opcional e integração com permissões especiais.
- **Testes:** regras de estado, PIN, transições, validação de pacote e widgets.

O código nativo retorna resultados estruturados ao Flutter. A camada Dart transforma falhas de plataforma em estados visíveis, evitando deixar o dispositivo preso em uma transição indefinida.

## Permissões Android

Este tipo de aplicativo exige permissões amplas e deve ser instalado somente em dispositivos dedicados e administrados:

- `QUERY_ALL_PACKAGES` permite apresentar a lista de aplicativos instalados;
- `RECEIVE_BOOT_COMPLETED` permite restaurar o launcher após a inicialização;
- acesso ao uso de aplicativos auxilia o monitoramento em modo leve;
- overlay e acessibilidade são opcionais e dependem de consentimento explícito no dispositivo;
- serviços internos que não precisam receber chamadas externas permanecem com `exported="false"`.

Essas permissões devem ser reavaliadas para qualquer distribuição em loja. A versão de portfólio não coleta telemetria e não realiza chamadas de rede.

## Como executar

Pré-requisitos:

- Flutter estável compatível com o SDK declarado;
- Android SDK;
- dispositivo ou emulador Android.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Para gerar uma demonstração Android local:

```bash
flutter build apk --debug
```

A configuração de release do projeto usa assinatura de debug apenas para facilitar avaliação local. Ela não é uma assinatura de distribuição.

## Limitações

- Sem Device Owner, o Android não oferece bloqueio absoluto.
- Permissões especiais precisam ser concedidas manualmente.
- Fabricantes podem impor comportamentos diferentes de gerenciamento de energia e launcher.
- O projeto não substitui uma solução MDM.
- A edição pública não inclui suporte, backend ou configuração de ambiente real.

## Decisões e desafios técnicos

- separar falhas nativas de regras de interface;
- manter um fallback leve quando Device Owner não existe;
- proteger o PIN sem armazenar texto puro;
- evitar loops de recuperação que prejudiquem o usuário;
- tornar permissões e limitações visíveis em vez de ocultá-las.

## Minha participação

Projeto, arquitetura, implementação Flutter e Kotlin, testes automatizados, tratamento de estados de falha e documentação técnica.

## Direitos e contribuições

Consulte [PORTFOLIO_NOTICE.md](PORTFOLIO_NOTICE.md). Este repositório é apresentado para avaliação profissional e não recebe Issues, Pull Requests ou suporte externo.
