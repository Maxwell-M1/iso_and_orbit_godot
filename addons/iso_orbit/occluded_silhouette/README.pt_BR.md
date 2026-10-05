<!-- translation of addons/iso_orbit/occluded_silhouette/README.md @ af038a43f7c2 -->
# Silhueta atrás de obstáculos

[← Índice da documentação (repositório do template)](../../../docs/pt_BR/index.md)

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
2. Adicione um `Node` com `occluded_silhouette.gd` ao personagem. Defina `target` como o nó que contém o modelo
   (o herói fornecido usa `Character/Visual`) e
   atribua `silhouette_mask.tres`, `silhouette_body.tres`, `silhouette_gear.tres` e `silhouette_outline.tres` a
   `mask`, `body_fill`, `gear_fill` e `outline`.
3. Malhas sob nós listados em `gear_nodes` (`RightHand`, `LeftHand`) contam como itens na mão. Sem esses nós, todas
   as malhas recebem o preenchimento do corpo; altere os nomes se o equipamento tiver outra hierarquia.

As cores são os parâmetros `color` dos materiais, a largura da borda é `width` em `silhouette_outline.tres`, e
`outline_enabled` desliga a borda. A silhueta precisa de um obstáculo pelo menos 30 cm à frente do personagem
(`min_gap`, parâmetro dos materiais de corpo, equipamento e contorno, vindo de `silhouette_common.gdshaderinc`:
altere-o nos três).

O componente define `material_overlay` de cada malha, inclusive as adicionadas depois da troca de aparência. Se
o modelo já usa essa propriedade para outro efeito, escolha qual overlay deve controlá-la. Os materiais são
copiados para cadeias de passes quando o componente fica pronto: defina cores e `min_gap` antes de executar a cena;
`outline_enabled` pode mudar durante o jogo.

Usa o stencil buffer, que é experimental no Godot 4.5+. Testado com o renderizador Forward+.

## Documentação

No repositório do modelo: `docs/pt_BR/systems/characters.md` (inclusive troca de modelo) e
`docs/pt_BR/integration.md` (cópia do herói jogável).

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
