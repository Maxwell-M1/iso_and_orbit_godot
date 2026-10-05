<!-- translation of docs/en/getting-started.md @ a68235d39cbc -->
# Primeiros passos

[← Índice da documentação](index.md)

> Esta é uma tradução do [original em inglês](../en/getting-started.md).
> Onde houver diferenças, a versão em inglês é a correta.

## Requisitos

- Godot 4.7.2. A versão padrão basta: o projeto usa GDScript e dispensa o SDK .NET.
- Nada mais para a demo: o Jolt Physics vem embutido na engine, o renderizador é o Forward+ e todos os assets estão no
  repositório.

## Abrir e rodar

1. Clone o repositório.
2. No Gerenciador de Projetos (Project Manager), escolha **Importar** (**Import**) e selecione `project.godot`, depois
   abra o projeto. A primeira importação demora um pouco, pois o cache `.godot/` não está no repositório.
3. Pressione F5. A cena principal é `res://gdscript/main.tscn`.

A demo carrega suas configurações salvas anteriormente. Use **F10 → Redefinir tudo** para os padrões descritos aqui.
Num clone novo, espere a importação terminar antes de abrir scripts ou executar testes. Não copie o cache `.godot/`
de outro projeto.

## O que você vê

O herói está no ponto de spawn, no meio de uma clareira cercada. Os controles estão listados no canto superior
esquerdo, a taxa de quadros no superior direito.

- **Clique esquerdo** no chão: o herói corre até lá contornando obstáculos, e um marcador mostra o ponto.
- **Segure o botão esquerdo**: o herói corre atrás do cursor.
- **Botão direito + mouse**: orbitar a câmera. **Roda**: zoom.
- **Botão direito, depois esquerdo**: correr para onde a câmera olha. **Esquerdo segurado, depois direito**: olhar
  em volta durante a corrida. **Botão direito + WASD**: mover-se em relação à câmera.
- **Shift** ativa a corrida rápida, **Espaço** pula, **F10** abre as configurações.

A lista completa está em [Controles](controls.md).

Locais para visitar:

- **Círculo Antigo**, o anel de colunas a noroeste do spawn. Ande entre as colunas e o herói aparece como silhueta
  atrás delas.
- **Acampamento dos Viajantes** no leste e **Sítio do Poço** no sudoeste, com NPCs.
- **Pico dos Ventos**, a montanha no nordeste: clique no topo e o herói pega a trilha em espiral.
- O labirinto de sebes, a plataforma com sua rampa e sua escada e a armadilha em forma de U perto do spawn, para
  testar a busca de caminhos.
- As dez aparências do herói em fila junto ao muro sul. Escolha uma em Configurações → Personagem → **Aparência do
  herói**.
- **A plataforma de teleporte** junto do Círculo Antigo, com um cristal giratório: suba nela e aperte E ou clique
  na oferta para viajar à **Ilha Solitária** e ao **Acampamento do Eremita**. Uma plataforma na ilha
  (“Teletransporte: Vale Verde”) traz você de volta.

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

- [Transfira o herói pronto](integration.md#transferindo-o-herói-da-demo-para-o-seu-projeto): arquivos exatos, um
  nível de teste e verificações para uma integração funcional.
- [Configurações](configurations.md): padrão fornecido e duas variantes úteis de movimento e câmera.
- [Arquitetura](architecture.md): o que cada nó faz e como eles se conectam.
- [Configuração do projeto](project-setup.md): camadas de física, ações de entrada e dependências opcionais da demo.

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
