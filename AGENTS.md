# MyPet: contexto para agentes de IA

App iOS para dueños y paseadores de mascotas: registro e inicio de sesión locales, perfil, mascotas (perros y gatos) con foto, nivel y experiencia, logros, paseos con GPS, recorridos personalizados, recordatorios de paseo, QR imprimible y pedido de placa.

## Entorno
- El código se edita en Linux/WSL **sin Xcode ni Swift**: aquí no se puede compilar ni probar. Se compila en otra Mac con **Xcode 16 o superior**.
- Abrir `MyPet.xcodeproj`. El proyecto usa una **carpeta sincronizada** (`PBXFileSystemSynchronizedRootGroup`): cualquier archivo dentro de `MyPet/` entra solo al target. **No edites `project.pbxproj` para agregar archivos.**
- Info.plist generado: los textos de permisos van en `project.pbxproj` como `INFOPLIST_KEY_*` (ya está `NSLocationWhenInUseUsageDescription`).
- Destino mínimo: iOS 17. Swift 6 (concurrencia estricta). Sin dependencias de terceros: pregunta antes de agregar una.

## Arquitectura (MVVM + SwiftData)
```
MyPet/
├── App/        MyPetApp (ModelContainer), RootView (Login → Setup → Home)
├── Models/     @Model de SwiftData + enums (Species, UserRole, AchievementCode)
├── Services/   AuthService, SessionStore, AchievementService, ReminderScheduler, PasswordHasher, Keychain
├── Shared/     Vistas y utilidades reutilizables (FormField, PawBackground, PetPhoto, UserPhoto, ImageDownscaler, QRCode, PDFRenderer, Format, AddressLookup, PlaceSearch)
└── Features/   Una carpeta por funcionalidad: View + ViewModel
```
- ViewModels: `@MainActor @Observable final class`, guardados en la vista con `@State`. Reciben `ModelContext` o un servicio como parámetro del método; no lo guardan.
- Los servicios son `@MainActor struct` que envuelven un `ModelContext`.
- Sesión: `SessionStore` en el `environment`; el nombre de usuario se guarda en Keychain.
- Contraseñas: PBKDF2-SHA256 con salt (CommonCrypto). Nunca se guardan en texto plano.
- La navegación del Home es `NavigationStack(path: $user.navigationPath)`: la ruta se guarda por usuario en SwiftData como JSON (`navigationPathData`). Las mascotas y recorridos se identifican en la ruta por `Pet.uuid` / `Route.uuid`.
- El botón de perfil (arriba a la derecha) abre `ProfileView`, donde está Cerrar sesión; la esquina izquierda queda para la flecha atrás nativa.
- MapKit/CoreLocation todavía no marcan `MKRoute`, `MKMapItem` ni `CLPlacemark` como `Sendable`: los archivos que los reciben de llamadas `async` usan `@preconcurrency import`.

## Convenciones
- Un tipo por archivo. Código en inglés; textos de la interfaz en español (`String(localized:)`, `LocalizedStringResource`).
- APIs modernas de SwiftUI: `foregroundStyle`, `clipShape(.rect(cornerRadius:))`, `Button("Título", systemImage:)`, `ContentUnavailableView`.
- Accesibilidad: elementos decorativos con `accessibilityHidden`; botones con etiqueta de texto aunque solo muestren un ícono.
- Simplificaciones intencionales marcadas con `// ponytail:`, que indican el límite y cuándo mejorarlas.
- Valores derivados como propiedades calculadas, no guardadas (`Pet.level`, `Walk.duration`).

## Reglas de negocio
- **Experiencia (XP)**: la tiene la mascota. `Pet.level = experience / 50 + 1`.
- **Logros** (`AchievementCode`): "Mi primer amigo" da 50 XP y "Familia completa" (perro + gato) da 100 XP. La XP va a la mascota que desbloqueó el logro. Para agregar un logro: nuevo `case` + su regla en `AchievementService.evaluate`. El catálogo se precarga al iniciar.
- **Paseos** (`Walk`, tabla `Paseo`): uno o varios perros/gatos (muchos a muchos `Walk.pets` ↔ `Pet.walks`). Cada mascota gana 10 XP por cada 100 m completos (`Walk.complete(distance:)`, que no duplica XP). Guarda fechas, coordenadas y direcciones de inicio/fin (`AddressLookup`, geocodificación inversa), distancia GPS, trazo real (`trackLatitudes`/`trackLongitudes`) y el recorrido personalizado usado (`route`, opcional). Borrar una mascota o un recorrido **no** borra sus paseos.
- **Calorías** (`Walk.calories(walking:weight:)`): estimación con el costo de transporte de Taylor et al. (1982), `10.7 · peso^0.684 · metros / 4184` kcal (perro de 10 kg, 1 km ≈ 12 kcal). Sin peso registrado no se calcula. Usa el peso actual de la mascota.
- **Mis paseos** (`WalksListView`, `WalkCard`): cada card muestra un resumen (mascotas, fecha y hora, distancia, duración). Al tocarla se despliega un mapa pequeño con el trazo (naranja), el recorrido (azul) e inicio/final, y el detalle: fecha, horas, ubicaciones, calorías, XP y recorrido ("No se usó una ruta personalizada" si no hubo). El mapa solo se crea al desplegar. Se ordena por fecha ascendente/descendente. El + abre "Iniciar un nuevo paseo".
- **Iniciar un nuevo paseo** (`NewWalkView` + `WalkSessionViewModel`): casillas de mascotas y ruta: "Calculada por el sistema" o un recorrido personalizado. La calculada se elige en `RoutePlannerView`, tipo Uber/DiDi: campos de inicio (vacío = mi ubicación) y destino con autocompletado (`PlaceSearch`), o tocando el mapa. Al escoger el inicio se acepta solo, el campo conserva el nombre y el foco pasa al destino; al escoger el destino se dibuja la ruta. `MKDirections` `.walking` con alternativas: se elige la de menor `expectedTravelTime` y, si empatan, la más corta. El formulario muestra un mapa pequeño de la ruta, la distancia y el tiempo. El recorrido personalizado solo se puede iniciar a ≤ 50 m de su inicio. Se descartó Openrouteservice: pide API key, que quedaría expuesta en la app, y tiene cuota diaria.
- **Paseo en curso** (`WalkInProgressView`, `fullScreenCover`): mapa en vivo con la ruta planeada y lo recorrido, hora de inicio, cronómetro, llegada estimada (MapKit, o distancia del recorrido / 1.4 m/s), distancia y calorías por mascota. GPS con `CLLocationUpdate.liveUpdates(.fitness)` (descarta precisión > 25 m y saltos < 5 m). "Finalizar viaje" crea el `Walk` (no antes, para no dejar paseos abiertos si se cierra la app); "Descartar" lo cancela.
- **Mis recorridos** (`RoutesListView`, `RouteEditorView`; `Route` = tabla `Ruta`): rutas personalizadas del usuario. Se trazan tocando el mapa (primer punto = inicio, último = final; Deshacer/Borrar), con nombre; al guardar se buscan las direcciones de inicio y final. Distancia = suma de tramos rectos. Menú ⋯ o deslizar para editar o eliminar.
- **Perfil** (`ProfileView`): foto, nombre, km recorridos (`User.walkedDistance`, suma de sus paseos), Editar perfil, Recompensas (todos los logros como cards) y Cerrar sesión. **Editar perfil** (`EditProfileView`, `AuthService.updateProfile`): foto, nombre de usuario (único) y cambio de contraseña con actual/nueva/confirmar; si la nueva queda vacía no se cambia. Tras guardar se actualiza el nombre en Keychain.
- **Tipo de usuario**: Dueño o Paseador; es lo único que pide la configuración inicial.
- **Recordatorios**: un `Reminder` por mascota, creado al agregar la mascota: cada N días (`everyDays`, contando desde `startDate`), paseos al día = `times.count`, `times` en minutos desde las 00:00. Los formularios editan un `ReminderDraft`. `ReminderScheduler`: si es diario usa notificaciones repetidas; si es cada N días programa las próximas 10 fechas y las renueva al abrir la app.
- **Carrusel** (`PetCarousel`): circular; después de la última mascota vuelve a la primera y viceversa.
- **Card de mascota** (`PetDetailView`): se abre al tocar la mascota en el carrusel. Muestra foto, nivel, barra de XP, especie, raza, peso, recordatorio, QR y placa. El menú "Opciones" (arriba a la derecha) permite **editar** (`PetFormView` con `pet`, sin la sección de recordatorio) y **eliminar** (con confirmación; borra su recordatorio y cancela sus notificaciones; sus paseos y los logros del usuario se conservan). Al eliminar, primero se sale de la card y luego se borra: los destinos del Home buscan la mascota por UUID en cada render y así nunca leen un objeto borrado.
- **Alta y edición**: `PetFormView`/`PetFormViewModel` sirven para las dos cosas. Al guardar se reevalúan los logros (cambiar la especie puede desbloquear "Familia completa") y se reprograma el recordatorio (la notificación lleva el nombre).
- **Especies y razas**: solo perro y gato. `Species.breeds` tiene "Mestizo" + las 15 razas más comunes en México de cada uno. `Pet.breed` guarda el texto. Al quitar ave y tortuga, las mascotas guardadas con esas especies ya no se pueden leer.
- **Cambios de esquema en desarrollo**: tras cambios incompatibles (quitar especies, `Walk.pet` → `Walk.pets`, `Route` como recorrido) **hay que borrar la app del simulador/iPhone de pruebas**. Antes de publicar, usar `VersionedSchema` + `SchemaMigrationPlan`.
- **QR** (`PetQRView`, `PetQRSheet`): pide dirección y teléfono (10 dígitos) del dueño, guardados en `User.address`/`User.phone` y reutilizados en todas sus mascotas y en la placa. El QR es texto plano (cualquier cámara lo lee sin internet): nombre, especie, raza, peso, dueño, teléfono y dirección. La hoja carta (612 × 792 pt) se convierte en PDF con `ImageRenderer` y se abre el diálogo de impresión de iOS, que también deja guardarlo o compartirlo.
- **Placa personalizada** (`PlateOrderView`): forma (círculo, corazón, escudo), color, texto grabado (≤ 40 caracteres, por defecto nombre + teléfono) y dirección de envío. Cuesta $100 MXN con **pago simulado** (espera 2 s, no pide tarjeta ni cobra). Solo se guarda `Pet.plateOrderDate`.
- **Card de logro** (`AchievementCard`): al tocar una medalla del Home se abre una hoja con el título, cómo se obtiene, la XP y si ya está conseguido.
- **Fotos**: se eligen con `PhotosPicker` y se reducen a ≤ 800 px JPEG (`@Attribute(.externalStorage)`).

## Relación con el diagrama original
`Usuario`→`User`, `Mascota`→`Pet`, `Paseo`→`Walk`, `Ruta`→`Route`, `Logro`→`Achievement`, `Enfermedad`→`Disease`. Las tablas intermedias `logro_usuario` y `Mascota_enfermedad` son relaciones muchos a muchos; `Paseo`↔`Mascota` también (un paseo puede ser de varias mascotas). `Ruta` es el recorrido personalizado: muchos paseos pueden usar la misma. `Paseo_Usuario` se omitió porque duplicaba `Paseo.usuario`.

## Pendiente
- Paseo: seguir el GPS en segundo plano (`UIBackgroundModes` location + `CLBackgroundActivitySession`), terminar solo al llegar al destino, avisar si te sales del recorrido personalizado, y pantalla para cuando se niega el permiso de ubicación (hoy solo no aparece la posición).
- Target de pruebas.
- Placa: pago real (backend + pasarela como Stripe o Mercado Pago), historial de pedidos (modelo `PlateOrder` en vez de solo la fecha) y forma de hueso (SF Symbols no la tiene; requiere un `Shape` propio).
- QR: si se quiere que al escanearlo se abra una página con los datos actualizados, hace falta un servidor; hoy los datos van fijos dentro del QR y hay que reimprimir si cambian.
- Recorridos: trazar con calles reales (hoy son tramos rectos entre los puntos tocados) o grabarlos caminando.
