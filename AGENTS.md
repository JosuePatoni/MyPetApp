# MyPet: contexto para agentes de IA

App iOS para dueños y paseadores de mascotas: registro e inicio de sesión locales, mascotas con foto, nivel y experiencia, logros, paseos y recordatorios de paseo.

## Entorno
- El código se edita en Linux/WSL **sin Xcode ni Swift**: aquí no se puede compilar ni probar. Se compila en otra Mac con **Xcode 16 o superior**.
- Abrir `MyPet.xcodeproj`. El proyecto usa una **carpeta sincronizada** (`PBXFileSystemSynchronizedRootGroup`): cualquier archivo dentro de `MyPet/` entra solo al target. **No edites `project.pbxproj` para agregar archivos.**
- Destino mínimo: iOS 17. Swift 6 (concurrencia estricta). Sin dependencias de terceros: pregunta antes de agregar una.

## Arquitectura (MVVM + SwiftData)
```
MyPet/
├── App/        MyPetApp (ModelContainer), RootView (Login → Setup → Home)
├── Models/     @Model de SwiftData + enums (Species, UserRole, AchievementCode)
├── Services/   AuthService, SessionStore, AchievementService, ReminderScheduler, PasswordHasher, Keychain
├── Shared/     Vistas y utilidades reutilizables (FormField, PawBackground, PetPhoto, ImageDownscaler)
└── Features/   Una carpeta por funcionalidad: View + ViewModel
```
- ViewModels: `@MainActor @Observable final class`, guardados en la vista con `@State`. Reciben `ModelContext` o un servicio como parámetro del método; no lo guardan.
- Los servicios son `@MainActor struct` que envuelven un `ModelContext`.
- Sesión: `SessionStore` en el `environment`; el nombre de usuario se guarda en Keychain.
- Contraseñas: PBKDF2-SHA256 con salt (CommonCrypto). Nunca se guardan en texto plano.
- La navegación del Home es `NavigationStack(path: $user.navigationPath)`: la ruta se guarda por usuario en SwiftData.

## Convenciones
- Un tipo por archivo. Código en inglés; textos de la interfaz en español (`String(localized:)`, `LocalizedStringResource`).
- APIs modernas de SwiftUI: `foregroundStyle`, `clipShape(.rect(cornerRadius:))`, `Button("Título", systemImage:)`, `ContentUnavailableView`.
- Accesibilidad: elementos decorativos con `accessibilityHidden`; botones con etiqueta de texto aunque solo muestren un ícono.
- Simplificaciones intencionales marcadas con `// ponytail:`, que indican el límite y cuándo mejorarlas.
- Valores derivados como propiedades calculadas, no guardadas (`Pet.level`, `Walk.duration`).

## Reglas de negocio
- **Experiencia (XP)**: la tiene la mascota. `Pet.level = experience / 50 + 1`.
- **Logros** (`AchievementCode`): "Mi primer amigo" da 50 XP y "Familia completa" (perro + gato) da 100 XP. La XP va a la mascota que desbloqueó el logro. Para agregar un logro: nuevo `case` + su regla en `AchievementService.evaluate`. El catálogo se precarga al iniciar.
- **Paseos**: 10 XP por cada 100 m completos (`Walk.complete(distance:)`, que no duplica XP).
- **Tipo de usuario**: Dueño o Paseador; se elige en la configuración inicial.
- **Recordatorios**: un `Reminder` por usuario, creado en la configuración inicial (cada N horas desde una hora de inicio). `ReminderScheduler` programa notificaciones locales diarias.
- **Especies y razas**: el catálogo está en `Species.breeds` (perro, gato, ave, tortuga). `Pet.breed` guarda el texto.
- **Fotos**: se eligen con `PhotosPicker` y se reducen a ≤ 800 px JPEG (`@Attribute(.externalStorage)`).

## Relación con el diagrama original
`Usuario`→`User`, `Mascota`→`Pet`, `Paseo`→`Walk`, `Ruta`→`Route`, `Logro`→`Achievement`, `Enfermedad`→`Disease`. Las tablas intermedias `logro_usuario` y `Mascota_enfermedad` son relaciones muchos a muchos. `Paseo_Usuario` se omitió porque duplicaba `Paseo.usuario`.

## Pendiente
- Pantallas "Mis paseos" y "Recorridos" (GPS con MapKit y CoreLocation, guardando la ruta en `Route`).
- Target de pruebas.
