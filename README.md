# Barz Kiosk Mode

Demonstração Flutter/Android de um quiosque leve para dispositivos dedicados: seleciona um aplicativo permitido, inicia a experiência após o boot e tenta recuperar o foco quando o usuário sai do fluxo esperado.

> Edição independente de portfólio. Não contém configuração, infraestrutura, credencial ou dado de produção.

## Problema

Tablets e terminais de autoatendimento precisam voltar rapidamente ao aplicativo correto, inclusive após reinicializações ou falhas. Sem provisionamento administrativo do Android, porém, um aplicativo comum não consegue oferecer o mesmo bloqueio de um equipamento gerenciado.

## Solução implementada

Esta edição implementa somente o modo leve. A camada Flutter cuida da configuração, do estado e da interface; a camada Kotlin integra launcher, boot, monitoramento do aplicativo em primeiro plano, watchdog e permissões concedidas pelo usuário.

O método nativo informa `isDeviceOwner = false`. Device Owner aparece apenas como contexto técnico e não é uma funcionalidade disponível neste snapshot.

## Tecnologias

- Flutter e Dart para interface, estado e regras de configuração;
- Kotlin e Android SDK para boot, launcher, serviços e permissões;
- Method Channel para comunicação tipada entre Flutter e Android;
- testes Flutter e testes do exportador fail-closed.

## Funcionalidades demonstradas

- catálogo e seleção de aplicativos instalados;
- validação do pacote escolhido;
- inicialização após o boot;
- launcher dedicado e recuperação de foco em modo leve;
- watchdog, diagnóstico de permissões e modo seguro para falhas nativas;
- PIN local armazenado com salt e hash, sem texto puro;
- interface de configuração e troca de PIN.

## Arquitetura e decisões

- **Flutter/Dart:** mantém o estado observável e apresenta falhas nativas de forma explícita.
- **Method Channel:** limita a fronteira entre interface e recursos Android.
- **Kotlin/Android:** executa integrações que não existem diretamente no Flutter.
- **Identidade de portfólio:** o APK usa `dev.juniorbarz.portfolio.kiosk` como ID de instalação, evitando colisão com aplicativos privados.

Serviços que não precisam receber chamadas externas permanecem com `exported="false"`. O overlay é obrigatório para iniciar o modo leve e viabilizar o gesto secreto de desbloqueio; acessibilidade é opcional. Ambas as permissões dependem de consentimento explícito no dispositivo.

## Como executar

Pré-requisitos: Flutter compatível com o SDK declarado, Android SDK e dispositivo ou emulador Android.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Para gerar um APK demonstrativo:

```bash
flutter build apk --debug
```

A configuração de release também usa a chave de debug exclusivamente para avaliação local; ela não serve para distribuição. A permissão `INTERNET` presente nos manifests de debug/profile pertence ao tooling Flutter e não representa um cliente de rede implementado pelo aplicativo.

## Testes e validação

Os testes cobrem transições de estado, validação de pacote, integração do canal nativo, PIN e widgets. O pipeline de portfólio exporta somente caminhos permitidos, valida hashes, rejeita arquivos inesperados e executa verificações de segredos antes da publicação controlada.

## Limitações e segurança

- O modo leve não impede de forma absoluta o acesso ao sistema; a solução não substitui Device Owner nem um MDM.
- Permissões especiais precisam ser concedidas manualmente e fabricantes podem alterar o comportamento de energia, launcher e serviços.
- O armazenamento nativo atual persiste somente hash, salt e versão do PIN. Ao carregar esse registro, `failedAttempts` volta a zero; como a interface o recarrega antes de cada envio, tentativas inválidas não se acumulam e o bloqueio por limite não é alcançado pelo fluxo normal.
- Existe uma espera curta após cada entrada inválida, mas ela não constitui limitação de tentativas persistente. Reabrir ou reiniciar o aplicativo também restaura o estado.
- A derivação do PIN usa uma rotina demonstrativa baseada em SHA-256 repetido. Ela não foi projetada nem auditada como armazenamento de credenciais para produção.
- Não existe backend, telemetria, suporte remoto ou configuração empresarial nesta edição.

Essas limitações são mantidas de forma explícita porque o objetivo deste repositório é demonstrar arquitetura Flutter/Android, tratamento de estados e integração nativa — não apresentar um controle de segurança pronto para implantação real.

## Autoria e direitos

Projeto, arquitetura, implementação Flutter/Kotlin, testes e documentação: Junior Barz. Consulte [PORTFOLIO_NOTICE.md](PORTFOLIO_NOTICE.md).

O repositório é apresentado somente para leitura e avaliação profissional. Não recebe Issues, Pull Requests ou suporte externo.
