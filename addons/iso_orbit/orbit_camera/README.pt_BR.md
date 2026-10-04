<!-- translation of addons/iso_orbit/orbit_camera/README.md @ 6c214bf8ea42 -->
# Câmera orbital

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · **Português (Brasil)** · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta é uma tradução do [original em inglês](README.md). Onde houver diferenças, a versão em inglês é a correta.

Uma câmera orbital para jogos isométricos e de visão de cima: ela segue um alvo, orbita com o botão direito do mouse,
dá zoom com a roda (distância e inclinação mudam juntas) e pode virar sozinha para trás do alvo em corrida. A câmera
fica na ponta de um braço que para em paredes atrás dela e pode se aproximar quando um obstáculo esconde o alvo.

Parte do Iso & Orbit, um template de câmera e controlador de personagem para Godot 4.7. Licença MIT (veja `LICENSE`).

## Conteúdo

| Arquivo | Classe | Função |
|---|---|---|
| `orbit_camera_rig.gd` | `OrbitCameraRig` (Node3D) | Segue o alvo, órbita, zoom, modo de seguir |
| `camera_arm.gd` | `CameraArm` (Node3D) | Segura a câmera e encurta em obstáculos; esmaece o alvo de perto |

Nenhum outro addon é necessário.

## Configuração

1. Copie esta pasta para `res://addons/iso_orbit/orbit_camera/`.
2. Adicione as ações de entrada (os nomes são propriedades exportadas, então você pode usar os seus): `camera_rotate`
   (botão direito do mouse), `camera_zoom_in` (roda para cima), `camera_zoom_out` (roda para baixo).
3. Monte a câmera ao lado do alvo, não dentro dele:

   ```
   CameraRig    Node3D com orbit_camera_rig.gd, target = seu personagem
   └── CameraArm    Node3D com camera_arm.gd
       └── Camera3D
   ```

4. Camadas de física: o braço para em corpos nas camadas 1 e 3 (`collision_mask`). Coloque a geometria do nível numa
   delas e deixe os personagens fora delas. Corpos no grupo `camera_ignore` (ou sob um nó dele) nunca param o braço.
5. Se o alvo se move em ticks de física, ligue a interpolação de física no projeto: o rig segue a posição interpolada
   do alvo.

Sem braço, um `Camera3D` filho do rig também funciona: ele fica na distância definida pelo zoom e atravessa paredes.

## Documentação

No repositório do template: `docs/pt_BR/systems/camera.md` (todas as propriedades, a curva de zoom, o modo de seguir,
como o braço funciona) e `docs/pt_BR/project-setup.md`.

---

*Esta página corresponde ao Iso & Orbit 1.1.0.*
