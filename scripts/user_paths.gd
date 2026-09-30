class_name UserPaths

## Onde ficam os arquivos do jogador em user://. Com `-- --sandbox` na linha
## de comando (testes e robôs em tests/), tudo vai para user://sandbox/ e o
## save e as preferências de verdade não são tocados.

const SANDBOX_FLAG := "--sandbox"


static func is_sandbox() -> bool:
	return SANDBOX_FLAG in OS.get_cmdline_user_args()


static func file(file_name: String) -> String:
	if not is_sandbox():
		return "user://" + file_name
	DirAccess.make_dir_recursive_absolute("user://sandbox")
	return "user://sandbox/" + file_name
