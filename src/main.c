#include <stdio.h>
#include <string.h>
#include "duktape.h"     // Duktape
#include "../include/levenshtein.h" // Biblioteca Levenshtein

// Função "ponte" que será chamada pelo JavaScript
static duk_ret_t native_levenshtein(duk_context *ctx) {
    const char *str1;
    const char *str2;
    int distance;

    // 1. Pegar os argumentos da stack do Duktape
    // Verifica se temos dois argumentos e se são strings
    if (duk_get_top(ctx) != 2) { // Espera exatamente 2 argumentos
        duk_error(ctx, DUK_ERR_TYPE_ERROR, "Expected 2 string arguments");
        return DUK_EXEC_ERROR; // Indica um erro
    }
    if (!duk_is_string(ctx, 0) || !duk_is_string(ctx, 1)) {
        duk_error(ctx, DUK_ERR_TYPE_ERROR, "Arguments must be strings");
        return DUK_EXEC_ERROR;
    }

    str1 = duk_require_string(ctx, 0); // Pega o primeiro argumento (índice 0)
    str2 = duk_require_string(ctx, 1); // Pega o segundo argumento (índice 1)

    size_t levenshtein_result;
    // 2. Chamar a função da biblioteca externa de Levenshtein
    levenshtein_result = levenshtein(str1, str2);

    // 3. Empurrar o resultado de volta para a stack do Duktape
    duk_push_uint(ctx, (duk_uint_t)levenshtein_result); // Empurra como um inteiro sem sinal

    // 4. Indicar que estamos retornando 1 valor
    return 1;
}

// Função para carregar e executar um arquivo JavaScript
static int execute_javascript_file(duk_context *ctx, const char *filename) {
    FILE *f;
    long len;
    char *buf;
    int success = 0;

    f = fopen(filename, "rb");
    if (!f) {
        perror(filename);
        return 0;
    }

    fseek(f, 0, SEEK_END);
    len = ftell(f);
    fseek(f, 0, SEEK_SET);

    buf = (char *) malloc(len + 1);
    if (!buf) {
        fprintf(stderr, "Failed to allocate memory to read %s\n", filename);
        fclose(f);
        return 0;
    }

    if (fread(buf, 1, len, f) != (size_t)len) {
        fprintf(stderr, "Failed to read content of %s\n", filename);
        free(buf);
        fclose(f);
        return 0;
    }
    buf[len] = '\0';
    fclose(f);

    if (duk_peval_string(ctx, buf) != 0) {
        fprintf(stderr, "Error executing JavaScript from %s: %s\n", filename, duk_safe_to_string(ctx, -1));
        duk_pop(ctx); // Remove a mensagem de erro da stack
    } else {
        // Se a execução do script JS retornar um valor, ele estará no topo da stack.
        // Não esperamos um valor de retorno do script.
        duk_pop(ctx); // Remove o valor de retorno indefinido
        success = 1;
    }

    free(buf);
    return success;
}

// Função C para ser chamada pelo JavaScript para imprimir no terminal
static duk_ret_t native_print(duk_context *ctx) {
    // Pega o primeiro argumento, formata como string e imprime
    // Permite múltiplos argumentos para print, como console.log
    duk_idx_t i, n;
    n = duk_get_top(ctx); // Número de argumentos
    for (i = 0; i < n; i++) {
        if (i > 0) {
            printf(" "); // Espaço entre argumentos
        }
        // duk_safe_to_string para converter qualquer tipo para string de forma segura
        printf("%s", duk_safe_to_string(ctx, i));
    }
    printf("\n");
    fflush(stdout); // Garante que a saída seja exibida imediatamente
    return 0; // Não retorna nenhum valor para o JavaScript
}


int main(int argc, char *argv[]) {
    duk_context *ctx = NULL;

    // 1. Criar o contexto Duktape
    ctx = duk_create_heap_default();
    if (!ctx) {
        printf("Failed to create a Duktape heap.\n");
        return 1;
    }

    // 2. Registrar a função C "native_levenshtein" para que o JavaScript possa chamá-la
    // O JavaScript a chamará como "calculateLevenshteinInC"
    duk_push_c_function(ctx, native_levenshtein, 2 /*número de argumentos esperados*/);
    duk_put_global_string(ctx, "calculateLevenshteinInC");

    // 3. Registrar a função native_print como 'print' global para o JavaScript
    duk_push_c_function(ctx, native_print, DUK_VARARGS /*aceita número variável de args*/);
    duk_put_global_string(ctx, "print"); // O JS poderá chamar print(...)

    // 4. Carregar e executar o arquivo JavaScript ("script.js")
    // O arquivo "script.js" deve estar no mesmo diretório do executável.
    printf("Demonstrating Levenshtein distance via JavaScript (using C binding):\n");
    if (!execute_javascript_file(ctx, "./src/script.js")) {
        fprintf(stderr, "Failed to run script.js\n");
        duk_destroy_heap(ctx);
        return 1;
    }

    // 4. Limpar e destruir o contexto Duktape
    duk_destroy_heap(ctx);

    return 0;
}