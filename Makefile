# Variáveis de Configuração do Projeto

# Nome do projeto
PROJECT_NAME = trabalho_01

# Versão
VERSION = 1.0.0

# Diretório de release
RELEASE_DIR = $(PROJECT_NAME)-$(VERSION)

# Nome do arquivo .tar
TAR_FILE = $(RELEASE_DIR).tar.gz

# Diretório de compilação para arquivos objeto
BUILD_DIR = build

# Diretório do executavel final
BIN_DIR = bin

# Nome do compilador C
CC = gcc

# Flags de compilação:
# -Wall: Habilita a maioria dos avisos comuns
# -std=c11: Usa o padrão C11
# -I./<...>: Inclui o diretório para busca de cabeçalhos
CFLAGS = -Wall -std=c11 -I./src -I./duktape -I./include

# Flags do linker
LDFLAGS = -lm

# Nome do executável final
TARGET = $(BIN_DIR)/executavel_levenshtein # Agora o TARGET aponta para dentro de BIN_DIR

# Arquivos fonte C
SRCS = src/main.c duktape/duktape.c src/levenshtein.c

# Arquivos objeto (gerados automaticamente a partir dos SRCS, e agora no BUILD_DIR)
OBJS = $(patsubst %.c,$(BUILD_DIR)/%.o,$(SRCS))

# Arquivo JavaScript que será executado
JS_SCRIPT = src/script.js

# Regras PHONY (Metas que não representam arquivos reais)
.PHONY: default all run clean release dist

# Regras de Build Principal

# Regra padrão ('make' ou 'make default')
default: $(TARGET)

# Garante que o diretório BUILD_DIR exista antes de qualquer compilação
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Garante que o diretório BIN_DIR exista antes do link
$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

# Regra para criar o executável final
# Depende de todos os arquivos objeto e do diretório BIN_DIR
$(TARGET): $(OBJS) $(BIN_DIR)
	@echo "Linkando $(OBJS) para criar $(TARGET)..."
	$(CC) $(CFLAGS) -o $@ $(OBJS) $(LDFLAGS) # $@ é o TARGET completo (bin/executavel_levenshtein)
	@echo "Executável '$(TARGET)' criado com sucesso."

# Regra genérica para compilar arquivos .c em .o
# Agora, os .o são criados dentro de BUILD_DIR
# Depende do diretório BUILD_DIR existir
$(BUILD_DIR)/%.o: %.c $(BUILD_DIR)
	@mkdir -p $(dir $@)
	@echo "Compilando $< para $@..."
	$(CC) $(CFLAGS) -c $< -o $@

# Alias para 'default'
all: default

# Regras de Execução

# Regra para executar o programa
# Depende do executável e do script JS (para garantir que existam)
run: $(TARGET) $(JS_SCRIPT)
	@echo "Executando $(TARGET) com $(JS_SCRIPT)..."
	./$(TARGET)

# Regras de Limpeza

# Regra para limpar os arquivos gerados pela compilação e pelo release
clean:
	@echo "Limpando arquivos gerados..."
	rm -rf $(BUILD_DIR) # Remove todo o diretório build
	rm -rf $(BIN_DIR) # Remove todo o diretório bin
	rm -rf $(RELEASE_DIR) # Remove o diretório temporário do release
	rm -f $(TAR_FILE) # Remove o arquivo .tar.gz
	@echo "Limpeza concluída."

# Regras de Release / Distribuição

# Alias para a regra 'dist'
release: dist

# Regra para criar um pacote de release (.tar.gz) do projeto
dist: clean $(TARGET)
	@echo "--------------------------------------------------------"
	@echo "Iniciando criação do pacote de release para $(PROJECT_NAME) v$(VERSION)..."
	@echo "--------------------------------------------------------"

	# 1. Criar o diretório temporário para o release
	@echo "Criando diretório temporário: $(RELEASE_DIR)/"
	@mkdir -p $(RELEASE_DIR)
	# Criar subdiretórios essenciais dentro do release
	@mkdir -p $(RELEASE_DIR)/src
	@mkdir -p $(RELEASE_DIR)/duktape
	@mkdir -p $(RELEASE_DIR)/include
	@mkdir -p $(RELEASE_DIR)/$(BIN_DIR) # Copia o binário para dentro de uma pasta 'bin' no tar

	# 2. Copiar os arquivos do projeto para o diretório de release
	@echo "Copiando arquivos do projeto..."
	@cp $(SRCS) $(RELEASE_DIR)/src/ # Copia arquivos .c para o subdiretório 'src'
	@cp duktape/* $(RELEASE_DIR)/duktape/ # Copia arquivos duktape
	@cp include/* $(RELEASE_DIR)/include/ # Copia headers
	@cp Makefile README.md $(JS_SCRIPT) $(RELEASE_DIR)/ # Copia Makefile, README e script JS
	@cp $(TARGET) $(RELEASE_DIR)/$(BIN_DIR)/ # Copia o executável compilado para o subdiretório bin do release

	# 3. Criar o arquivo tar.gz
	@echo "Compactando $(TAR_FILE)..."
	@tar -czvf $(TAR_FILE) $(RELEASE_DIR)/

	# 4. Limpar o diretório temporário de release
	@echo "Limpando diretório temporário de release..."
	@rm -rf $(RELEASE_DIR)

	@echo "--------------------------------------------------------"
	@echo "Pacote de release '$(TAR_FILE)' criado com sucesso!"
	@echo "--------------------------------------------------------"