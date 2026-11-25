import Foundation

/// Lee claves de `MyPet/Secrets.plist`, un archivo local que NO se sube a git (está en `.gitignore`).
/// Copia `Secrets.example.plist` (raíz del repo) a `MyPet/Secrets.plist` y pon ahí tu key.
// ponytail: la key queda dentro del .app y se puede extraer; para publicar, llamar a Gemini desde un servidor propio
enum Secrets {
    static var geminiAPIKey: String? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let values = NSDictionary(contentsOf: url),
              let key = (values["GEMINI_API_KEY"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !key.isEmpty, key != "PEGA_AQUI_TU_API_KEY"
        else { return nil }
        return key
    }
}
