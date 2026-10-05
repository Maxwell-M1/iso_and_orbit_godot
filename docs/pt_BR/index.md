<!-- translation of docs/en/index.md @ 0499e77e2e07 -->
# Documentação

[English](../en/index.md) · [Español](../es/index.md) · [日本語](../ja/index.md) · **Português (Brasil)** · [Русский](../ru/index.md) · [Türkçe](../tr/index.md) · [简体中文](../zh_CN/index.md)

> Esta é uma tradução do [original em inglês](../en/index.md). Onde houver diferenças, a versão em inglês é a correta.

Um controlador de personagem de clicar para mover e uma câmera orbital para RPGs isométricos e de visão de cima no
Godot 4.7, com dois níveis de demonstração. Comece pelo [README](../../README.pt_BR.md) para uma visão geral.

A documentação em inglês é o original. As traduções a seguem e podem ficar atrasadas; onde houver diferenças, a página
em inglês é a correta.

## Primeira integração funcional

1. [Execute a demo](getting-started.md) para experimentar os controles padrão.
2. [Transfira o herói](integration.md#transferindo-o-herói-da-demo-para-o-seu-projeto) para um nível pequeno do seu
   projeto. Siga a lista de arquivos, o Mapa de Entrada e os passos de navegação antes de alterar o personagem.
3. [Escolha uma configuração](configurations.md): órbita manual, movimento pelo mouse com caminhos ou câmera que
   acompanha a exploração.
4. Consulte [movimento](systems/locomotion.md), [entrada](systems/input.md) e [câmera](systems/camera.md) para
   ajustar propriedades individuais. [Personagens](systems/characters.md) explica como trocar o modelo e animá-lo.

## Menu da documentação

Escolha uma página abaixo. Os guias dos addons vêm após as referências dos sistemas.

### Início

- [Primeiros passos](getting-started.md): requisitos, como abrir o projeto, o que há na demo.
- [Controles](controls.md): todas as entradas, clicar versus segurar, as teclas com o botão direito, a câmera.
- [Configurações](settings.md): todas as opções da janela de configurações, sua chave, seu padrão e o que ela muda.
- [Configurações do herói](configurations.md): origem dos valores, caminhos exatos dos nós, três configurações
  completas e como conferir o resultado.

### Código

- [Arquitetura](architecture.md): a cena principal, como os dados fluem em um tick de física, os componentes e por
  que eles são divididos assim.
- [Usando no seu projeto](integration.md): os addons e do que cada um precisa, a câmera sozinha, clicar para mover,
  seu próprio corpo, NPCs.
- [Configuração do projeto](project-setup.md): camadas de física, ações de entrada, grupos e configurações do projeto
  que os componentes esperam.

### Sistemas

- [Locomoção](systems/locomotion.md): `LocomotionSettings`, `GroundMotion`, `NavigationMover`, `GroundCharacter`,
  o que o personagem informa para animações e a interface, `CharacterMonitor`, degraus e encostas, corrida rápida e
  fôlego, o pulo, a queda (`FallSettings`) e a proteção de bordas.
- [Câmera](systems/camera.md): `OrbitCameraRig` (órbita, curva de zoom, seguir) e `CameraArm` (obstáculos,
  aproximação, esmaecimento).
- [Entrada](systems/input.md): `PointClickMoveInput` (clique, segurar, teclas, o cursor) e `CharacterActionInput`.
- [Personagens](systems/characters.md): modelos e equipamentos, aparências do herói, balanço da mão, flutuação e
  silhueta.
- [Áudio](systems/audio.md): sons do personagem e como eles são sintetizados.
- [UI](systems/ui.md): janelas, o sistema e a janela de configurações, o HUD, o tema, as traduções.
- [Mundo e navegação](systems/world-and-navigation.md): o nível, os locais, as superfícies e as texturas
  pré-calculadas, a montanha, a malha de navegação e como gerá-la de novo.
- [Níveis](systems/levels.md): a cena principal, o host e a tela de carregamento, portais, pontos de entrada,
  herói jogável e a ilha.

### Guias de configuração dos addons

- [Movimento por clique](../../addons/iso_orbit/click_to_move/README.pt_BR.md)
- [Personagem no chão](../../addons/iso_orbit/ground_character/README.pt_BR.md)
- [Câmera orbital](../../addons/iso_orbit/orbit_camera/README.pt_BR.md)
- [Silhueta atrás de obstáculos](../../addons/iso_orbit/occluded_silhouette/README.pt_BR.md)
- [Pontos de interesse](../../addons/iso_orbit/points_of_interest/README.pt_BR.md)
- [Janelas de interface](../../addons/iso_orbit/ui_screens/README.pt_BR.md)
- [Transições entre níveis](../../addons/iso_orbit/levels/README.pt_BR.md)

### Manutenção

- [Testes](testing.md): como rodá-los, o que cada suíte cobre, como escrever uma verificação.
- [Problemas conhecidos](known-issues.md): limitações e peculiaridades da engine, com o que fazer a respeito.
- [Glossário](glossary.md): termos usados no código e na documentação.
- [Roteiro](roadmap.md): trabalho planejado.

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
