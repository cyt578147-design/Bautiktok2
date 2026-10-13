# Baú Coletor (v0.1)

App Android que usa um Serviço de Acessibilidade para:
1. Abrir o painel do baú quando o ícone aparece pronto (por texto/descrição ou por imagem).
2. Tocar em "Abrir" quando o botão deixa de ser contagem regressiva.

## Como gerar o APK (sem Android Studio)
1. Crie um repositório no GitHub e envie todo o conteúdo desta pasta (inclusive a pasta `.github`).
2. Vá em **Actions → Build APK → Run workflow** (ou ele roda sozinho a cada push).
3. Ao terminar, baixe o artefato **BauColetor-apk** → `app-debug.apk`.
4. Instale no celular (permita "instalar apps desconhecidos").

## Ativar
1. Abra o app → botão 1 → Acessibilidade → **Baú Coletor** → ativar.
   - Android 13+: se aparecer "configuração restrita", vá em Configurações → Apps → Baú Coletor → ⋮ → **Permitir configurações restritas** e tente de novo.
2. Desative a otimização de bateria do app e deixe o TikTok aberto na live.

## Ajustes
- Botão **Diagnóstico** despeja a árvore de views da tela do TikTok no log: copie e me mande para ajustar os textos/IDs.
- Constantes no topo de `BauService.kt` (`BOTAO_ABRIR`, `PAINEL`, `NCC_MIN`...).
- Template do ícone: `app/src/main/assets/bau_template.png` (recortado do seu print).
