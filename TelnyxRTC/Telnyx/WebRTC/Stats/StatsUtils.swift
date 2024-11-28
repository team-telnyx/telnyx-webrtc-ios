class StatsUtils {
    
    static func extractUfrag(from input: String) -> String? {
        // Expresión regular para capturar el valor de ufrag
        let pattern = "ufrag\\s+(\\w+)"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: input.utf16.count)
            
            // Buscar el patrón en el string
            if let match = regex.firstMatch(in: input, options: [], range: range) {
                // Obtener el valor del ufrag que está en el primer grupo de captura (el valor después de "ufrag")
                if let ufragRange = Range(match.range(at: 1), in: input) {
                    return String(input[ufragRange])
                }
            }
        } catch {
            print("Error al crear la expresión regular: \(error)")
        }
        
        return nil
    }
    
}
