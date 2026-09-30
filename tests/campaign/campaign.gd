extends Node

## Cena de entrada dos robôs: põe o robô na raiz da árvore (assim ele
## sobrevive às trocas de cena) e sai do caminho.


func _ready() -> void:
	get_tree().root.add_child.call_deferred(preload("res://tests/campaign/campaign_bot.gd").new())
