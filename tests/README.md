# Testes e robôs de balanceamento

Tudo aqui roda com `-- --sandbox`: o save e as preferências vão para
`user://sandbox/` (no Windows, `%APPDATA%\Godot\app_userdata\Red Shelter\sandbox\`)
e o save de verdade não é tocado. Sem `--sandbox`, o robô se recusa a rodar.

## Campanha (`tests/campaign/`)

Um robô joga uma campanha inteira: expedições (desvia, pula, atira, usa a
arma branca), decisões no abrigo e as defesas. No fim imprime um resumo e
grava o registro da campanha em CSV.

```
godot --headless --path . res://tests/campaign/campaign.tscn -- --sandbox --days=30 --seed=1 --policy=cauteloso
```

| Argumento | Padrão | O que faz |
| --- | --- | --- |
| `--days=N` | 30 | dias da campanha |
| `--seed=N` | 1 | semente (rotas e decisões) |
| `--policy=` | `cauteloso` | `cauteloso` (jogador razoável) ou `atual` (o robô antigo, ganancioso) |

Leva uns 6 minutos para 30 dias. Várias campanhas podem rodar em paralelo.

**CSV:** `user://sandbox/campaign_<política>_<seed>.csv`, separado por `;`.
Uma linha por expedição e por defesa: resultado, loot, gastos do dia
(construções, Oficina, Enfermaria), estoque no fim do dia, moral, moradores,
dias até o ataque e horda prevista.

## Registro da campanha no jogo normal

O mesmo CSV é gravado quando se joga de verdade, em
`user://campaign_log.csv`, e começa de novo a cada jogo novo. Depois de uma
sessão de teste, abra no Excel para ver onde a sucata e a munição foram.
