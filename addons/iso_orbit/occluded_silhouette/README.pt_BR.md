<!-- translation of addons/iso_orbit/occluded_silhouette/README.md @ ed5707ab8355 -->
# Silhueta atrás de obstáculos

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · **Português (Brasil)** · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta é uma tradução do [original em inglês](README.md). Onde houver diferenças, a versão em inglês é a correta.

Mostra um personagem através do que quer que o esconda: o corpo como uma única forma plana, os itens nas mãos
contornados por cima e uma borda em volta de tudo. Onde o personagem está visível, nada é desenhado. Os materiais do
próprio modelo ficam intactos, então o mesmo modelo em outro lugar não tem silhueta.

Parte do Iso & Orbit, um template de câmera e controlador de personagem para Godot 4.7. Licença MIT (veja `LICENSE`).

## Conteúdo

| Arquivo | Função |
|---|---|
| `occluded_silhouette.gd` | `OccludedSilhouette` (Node): coloca os passes em todas as malhas do modelo como `material_overlay`, inclusive malhas adicionadas depois |
| `silhouette_mask.gdshader`, `.tres` | Marca onde o personagem está visível por si mesmo |
| `silhouette_body.gdshader`, `.tres` | O preenchimento plano do corpo |
| `silhouette_gear.gdshader`, `.tres` | O preenchimento mais claro dos itens na mão |
| `silhouette_outline.gdshader`, `.tres` | A borda em volta da forma inteira |
| `silhouette_common.gdshaderinc` | Código compartilhado: profundidade em metros, a disposição do stencil |

Nenhum outro addon é necessário.

## Configuração

1. Copie esta pasta para `res://addons/iso_orbit/occluded_silhouette/`; os materiais se referem aos shaders por esse
   caminho.
2. Adicione um `Node` com `occluded_silhouette.gd` ao personagem. Defina `target` como o nó que contém o modelo e
   atribua `silhouette_mask.tres`, `silhouette_body.tres`, `silhouette_gear.tres` e `silhouette_outline.tres` a
   `mask`, `body_fill`, `gear_fill` e `outline`.
3. Malhas sob nós listados em `gear_nodes` (`RightHand`, `LeftHand`) contam como itens na mão.

As cores são os parâmetros `color` dos materiais, a largura da borda é `width` em `silhouette_outline.tres`, e
`outline_enabled` desliga a borda. A silhueta precisa de um obstáculo pelo menos 30 cm à frente do personagem
(`min_gap`).

Usa o stencil buffer, que é experimental no Godot 4.5+. Testado com o renderizador Forward+.

## Documentação

No repositório do template: `docs/pt_BR/systems/characters.md`.

---

*Esta página corresponde ao Iso & Orbit 1.1.0.*
