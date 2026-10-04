<!-- translation of docs/en/index.md @ b40c280f0207 -->
# Documentação

[English](../en/index.md) · [Español](../es/index.md) · [日本語](../ja/index.md) · **Português (Brasil)** · [Русский](../ru/index.md) · [Türkçe](../tr/index.md) · [简体中文](../zh_CN/index.md)

> Esta é uma tradução do [original em inglês](../en/index.md). Onde houver diferenças, a versão em inglês é a correta.

Um controlador de personagem de clicar para mover e uma câmera orbital para RPGs isométricos e de visão de cima no
Godot 4.7, com um nível de demonstração. Comece pelo [README](../../README.pt_BR.md) para uma visão geral.

A documentação em inglês é o original. As traduções a seguem e podem ficar atrasadas; onde houver diferenças, a página
em inglês é a correta.

## Início

- [Primeiros passos](getting-started.md): requisitos, como abrir o projeto, o que há na demo.
- [Controles](controls.md): todas as entradas, clicar versus segurar, as teclas com o botão direito, a câmera.
- [Configurações](settings.md): todas as opções da janela de configurações, sua chave, seu padrão e o que ela muda.

## Código

- [Arquitetura](architecture.md): a cena principal, como os dados fluem em um tick de física, os componentes e por
  que eles são divididos assim.
- [Usando no seu projeto](integration.md): os addons e do que cada um precisa, a câmera sozinha, clicar para mover,
  seu próprio corpo, NPCs.
- [Configuração do projeto](project-setup.md): camadas de física, ações de entrada, grupos e configurações do projeto
  que os componentes esperam.

## Sistemas

- [Locomoção](systems/locomotion.md): `LocomotionSettings`, `GroundMotion`, `NavigationMover`, `GroundCharacter`,
  corrida rápida e fôlego, o pulo, a proteção de bordas.
- [Câmera](systems/camera.md): `OrbitCameraRig` (órbita, curva de zoom, seguir) e `CameraArm` (obstáculos,
  aproximação, esmaecimento).
- [Entrada](systems/input.md): `PointClickMoveInput` (clique, segurar, teclas, o cursor) e `CharacterActionInput`.
- [Personagens](systems/characters.md): modelos e equipamentos, aparências do herói, o balanço da mão, a silhueta.
- [Áudio](systems/audio.md): sons do personagem e como eles são sintetizados.
- [UI](systems/ui.md): janelas, o sistema e a janela de configurações, o HUD, o tema, as traduções.
- [Mundo e navegação](systems/world-and-navigation.md): o nível, os locais, as superfícies e as texturas
  pré-calculadas, a montanha, a malha de navegação e como gerá-la de novo.

## Manutenção

- [Testes](testing.md): como rodá-los, o que cada suíte cobre, como escrever uma verificação.
- [Problemas conhecidos](known-issues.md): limitações e peculiaridades da engine, com o que fazer a respeito.
- [Glossário](glossary.md): termos usados no código e na documentação.
- [Roteiro](roadmap.md): trabalho planejado.

---

*Esta página corresponde ao Iso & Orbit 1.1.0.*
