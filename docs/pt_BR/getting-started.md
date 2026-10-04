<!-- translation of docs/en/getting-started.md @ 8829e557c2f0 -->
# Primeiros passos

> Esta é uma tradução do [original em inglês](../en/getting-started.md).
> Onde houver diferenças, a versão em inglês é a correta.

## Requisitos

- Godot 4.7.2, a versão padrão ou a .NET. O projeto ainda não tem código C#, então qualquer uma serve.
- Nada mais para a demo: o Jolt Physics vem embutido na engine, o renderizador é o Forward+ e todos os assets estão no
  repositório.

## Abrir e rodar

1. Clone o repositório.
2. No Gerenciador de Projetos (Project Manager), escolha **Importar** (**Import**) e selecione `project.godot`, depois
   abra o projeto. A primeira importação demora um pouco, pois o cache `.godot/` não está no repositório.
3. Pressione F5. A cena principal é `res://gdscript/main.tscn`.

## O que você vê

O herói está no ponto de spawn, no meio de uma clareira cercada. Os controles estão listados no canto superior
esquerdo, a taxa de quadros no superior direito.

- **Clique esquerdo** no chão: o herói corre até lá contornando obstáculos, e um marcador mostra o ponto.
- **Segure o botão esquerdo**: o herói corre atrás do cursor.
- **Botão direito + mouse**: orbitar a câmera. **Roda**: zoom.
- **Os dois botões**: correr para onde a câmera olha. **Botão direito + WASD**: mover-se em relação à câmera.
- **Shift** ativa a corrida rápida, **Espaço** pula, **F10** abre as configurações.

A lista completa está em [Controles](controls.md).

Locais para visitar:

- **Círculo Antigo**, o anel de colunas a noroeste do spawn. Ande entre as colunas e o herói aparece como silhueta
  atrás delas.
- **Acampamento dos Viajantes** no leste e **Sítio do Poço** no sudoeste, com NPCs.
- **Pico dos Ventos**, a montanha no nordeste: clique no topo e o herói pega a trilha em espiral.
- O labirinto de sebes, a plataforma com sua rampa e a armadilha em forma de U perto do spawn, para testar a busca de
  caminhos.
- As dez aparências do herói em fila junto ao muro sul. Escolha uma em Configurações → Personagem → **Aparência do
  herói**.

## Configurações

F10 abre a janela de configurações e pausa o jogo; Esc ou F10 a fecha. As configurações são salvas em
`user://settings.cfg` e se aplicam na hora. Para ocultar a dica de controles, desligue Configurações → Interface →
**Dica de controles e velocidade**. O idioma da interface é escolhido na mesma aba. Todas as configurações:
[Configurações](settings.md).

## Rodar os testes

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

Aqui `godot` é o seu executável do Godot 4.7.2. No Windows, use a versão `_console.exe` para ver a saída e obter o
código de saída. Num clone novo, importe o projeto uma vez antes, no editor ou com
`godot --headless --path . --import`. Detalhes: [Testes](testing.md).

## Próximos passos

- [Arquitetura](architecture.md): o que cada nó faz e como eles estão ligados.
- [Usando no seu projeto](integration.md): quais arquivos levar e como configurá-los.
- [Configuração do projeto](project-setup.md): camadas de física, ações de entrada e grupos que os componentes
  esperam.

---

*Esta página corresponde ao Iso & Orbit 1.1.0.*
