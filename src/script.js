// script.js

// Função JavaScript que usa a função C exposta
function getAndPrintLevenshteinDistance(str1, str2) {
    try {
        // Chama a função C que foi registrada no main.c
        var distance = calculateLevenshteinInC(str1, str2);
        
        // A função C retorna o valor para esta variável 'distance'
        printResult(str1, str2, distance);

    } catch (e) {
        print("Error calling C function or processing result: " + e);
    }
}

// Função JS para imprimir o resultado
function printResult(s1, s2, dist) {
    // Duktape por padrão não tem um 'console.log'.
    if (typeof print === 'function') {
        print("Levenshtein distance between '" + s1 + "' and '" + s2 + "' is: " + dist);
    } else if (typeof Duktape !== 'undefined' && typeof Duktape.Logger === 'function') {
        var logger = new Duktape.Logger();
        logger.info("Levenshtein distance between '" + s1 + "' and '" + s2 + "' is: " + dist);
    } else {
        // Fallback se nenhuma função de print for encontrada.
        console.log("JS: Levenshtein distance between '" + s1 + "' and '" + s2 + "' is: " + dist);
    }
}

// Demonstração com quatro pares de strings
print("--- JavaScript Levenshtein Demo ---");

getAndPrintLevenshteinDistance("kitten", "sitting");
getAndPrintLevenshteinDistance("saturday", "sunday");
getAndPrintLevenshteinDistance("rosettacode", "raisethysword");
getAndPrintLevenshteinDistance("test", "test");
getAndPrintLevenshteinDistance("apple", "apply");

print("--- End of JavaScript Demo ---");