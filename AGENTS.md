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
├── Shared/     Vistas y utilidades reutilizables (FormField, PawBackground, PetPhoto, UserPhoto, ImageDownscaler, QRCode, PDFRenderer, Format, AddressLookup, PlaceSearch, SuggestedPath, RouteThumbnail)
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
- Colores: solo los de `MyPetPalette` (paleta del reto, documentada en `README.md`). Texto negro sobre mint, yellow, apricot y turquoise.
- Un tipo por archivo. Código en inglés; textos de la interfaz en español (`String(localized:)`, `LocalizedStringResource`).
- APIs modernas de SwiftUI: `foregroundStyle`, `clipShape(.rect(cornerRadius:))`, `Button("Título", systemImage:)`, `ContentUnavailableView`.
- Accesibilidad: elementos decorativos con `accessibilityHidden`; botones con etiqueta de texto aunque solo muestren un ícono.
- Simplificaciones intencionales marcadas con `// ponytail:`, que indican el límite y cuándo mejorarlas.
- Valores derivados como propiedades calculadas, no guardadas (`Pet.level`, `Walk.duration`).

## Reglas de negocio
- **Experiencia (XP)**: la tiene la mascota. `Pet.level = experience / 50 + 1`.
- **Logros** (`AchievementCode`, 12 en total): cada `case` tiene nombre, cómo se obtiene, XP y su regla `isMet(by:)`; `AchievementService.evaluate(for:rewarding:)` entrega los que se cumplan y da la XP completa a cada mascota de `rewarding` (la que se agregó/editó, o las del paseo). Se evalúan al guardar una mascota y al terminar un paseo. El catálogo se precarga al iniciar (los nuevos se agregan solos). Para agregar uno: nuevo `case` con sus textos, XP y regla.
  - Mascotas: "Mi primer amigo" (primera mascota, 50 XP), "Familia completa" (perro + gato, 100 XP).
  - Distancia acumulada: "Primeros pasos" 1 km (20), "Caminante" 10 km (50), "Explorador" 50 km (100), "Maratonista" 100 km (200).
  - Paradas pet friendly: "Parada amigable" 1 (20), "Vecino pet friendly" 10 (60), "Guía de la ciudad" 25 (120).
  - Rendimiento: "Paseo largo" un paseo ≥ 5 km (60), "Paso veloz" un paseo ≥ 1 km con promedio ≥ 5 km/h (40), "En forma" una mascota llega a nivel 5 (80).
- **Paseos** (`Walk`, tabla `Paseo`): uno o varios perros/gatos (muchos a muchos `Walk.pets` ↔ `Pet.walks`). Cada mascota gana 10 XP por cada 100 m completos (`Walk.complete(distance:)`, que no duplica XP). Guarda fechas, coordenadas y direcciones de inicio/fin (`AddressLookup`, geocodificación inversa), distancia GPS, trazo real (`trackLatitudes`/`trackLongitudes`), el camino sugerido tal como era al iniciar (`plannedLatitudes`/`plannedLongitudes`: ruta calculada o recorrido) y el recorrido personalizado usado (`route`, opcional). Borrar una mascota o un recorrido **no** borra sus paseos.
- **Calorías** (`Walk.calories(walking:weight:)`): estimación con el costo de transporte de Taylor et al. (1982), `10.7 · peso^0.684 · metros / 4184` kcal (perro de 10 kg, 1 km ≈ 12 kcal). Sin peso registrado no se calcula. Usa el peso actual de la mascota.
- **Estilo de rutas en mapas**: el camino sugerido es una línea azul con borde blanco (`SuggestedPath`, como Apple Maps) y lo caminado va encima en naranja. Se usa en elegir ruta, formulario, paseo en curso e historial.
- **Mis paseos** (`WalksListView`, `WalkCard`): cada card muestra un resumen con una captura pequeña del recorrido (`RouteThumbnail`, imagen de `MKMapSnapshotter` con el camino sugerido y lo caminado dibujados encima), mascotas, fecha y hora, distancia y duración. Al tocarla se despliega un mapa pequeño con el camino sugerido, lo caminado e inicio/final, y el detalle: fecha, horas, ubicaciones, calorías, XP y recorrido ("No se usó una ruta personalizada" si no hubo). El mapa solo se crea al desplegar. Se ordena por fecha ascendente/descendente. El + abre "Iniciar un nuevo paseo".
- **Iniciar un nuevo paseo** (`NewWalkView` + `WalkSessionViewModel`): casillas de mascotas y ruta: "Calculada por el sistema" o un recorrido personalizado. La calculada se elige en `RoutePlannerView`, tipo Uber/DiDi: campos de inicio (vacío = mi ubicación) y destino con autocompletado (`PlaceSearch`), o tocando el mapa. Al escoger el inicio se acepta solo, el campo conserva el nombre y el foco pasa al destino; al escoger el destino se dibuja la ruta. `MKDirections` `.walking` con alternativas: se elige la de menor `expectedTravelTime` y, si empatan, la más corta. El formulario muestra un mapa pequeño de la ruta, la distancia y el tiempo. El recorrido personalizado solo se puede iniciar a ≤ 50 m de su inicio. El botón dice "Iniciar paseo". Se descartó Openrouteservice: pide API key, que quedaría expuesta en la app, y tiene cuota diaria.
- **Paseo en curso** (`WalkInProgressView`, `fullScreenCover`): mapa en vivo con la ruta planeada y lo recorrido, hora de inicio, cronómetro, llegada estimada (MapKit, o distancia del recorrido / 1.4 m/s), distancia y calorías por mascota. GPS con `CLLocationUpdate.liveUpdates(.fitness)` (descarta precisión > 25 m y saltos < 5 m). "Finalizar paseo" crea el `Walk` (no antes, para no dejar paseos abiertos si se cierra la app); "Descartar" lo cancela. "Registrar parada pet friendly" busca con MapKit un parque (`MKLocalPointsOfInterestRequest`; en iOS 18 también `.animalService`) o una veterinaria/tienda de mascotas (búsqueda por texto) a ≤ 100 m y guarda su nombre en `Walk.petFriendlyStops` (sin repetir lugar en el mismo paseo); si no hay, avisa. Las paradas se ven en el detalle del paseo.
- **Mis recorridos** (`RoutesListView`, `RouteEditorView`; `Route` = tabla `Ruta`): rutas personalizadas del usuario. Se trazan tocando el mapa (primer punto = inicio, último = final; Deshacer/Borrar), con nombre; al guardar se buscan las direcciones de inicio y final. Distancia = suma de tramos rectos. Menú ⋯ o deslizar para editar o eliminar.
- **Perfil** (`ProfileView`): foto, nombre, km recorridos (`User.walkedDistance`, suma de sus paseos), Editar perfil, Recompensas y Cerrar sesión. **Editar perfil** (`EditProfileView`, `AuthService.updateProfile`): foto, nombre de usuario (único) y cambio de contraseña con actual/nueva/confirmar; si la nueva queda vacía no se cambia. Tras guardar se actualiza el nombre en Keychain.
- **Tipo de usuario** (`UserRole`): Dueño o Paseador; es lo único que pide la configuración inicial (`SetupView`), con una card por rol (ícono, descripción, color de la paleta). El perfil muestra el rol como etiqueta.
- **Interfaz del paseador**: igual que la del dueño, pero sin emisión de placas (no ve "Solicitar placa" y la ruta `.petPlate` muestra un aviso). En el Home la sección dice "Mascotas que paseo" en lugar de "Mis mascotas". Su QR pide solo su teléfono: la hoja y el QR dicen "Paseador" y no incluyen dirección.
- **Loki** (`Features/Loki`): chatbot de cuidado de perros y gatos con Gemini (`gemini-3.1-flash-lite`, REST `generateContent`, `Services/GeminiClient.swift`, sin dependencias). Es un gato: solo sabe de perros y gatos y declina otros animales y temas.
  - Se abre desde el Home ("Habla con Loki", se elige la mascota arriba) o desde la card de la mascota ("Preguntar a Loki", mascota fija). Ruta `HomeDestination.loki(UUID?)`.
  - Prompt en `LokiPrompt.swift`: personalidad, primer mensaje ("mreow ola soy loki en que puedo ayudarte {usuario}" + lo que puede hacer), alcance, paseos para bajar de peso, alimentación, seguridad y formato. Al final van los datos en `<datos_app>`.
  - Datos enviados (`LokiContext`, JSON regenerado en cada mensaje): usuario (nombre, rol, km), mascota (nombre, especie, raza, edad, peso, nivel, XP, recordatorio) y sus 10 paseos más recientes (fecha, km, minutos, kcal, paradas). **No** se envían dirección, teléfono, correo ni coordenadas.
  - Historial guardado por mascota (`ChatMessage`, se borra con la mascota o con "Borrar conversación"). Se mandan los últimos 40 mensajes; el primer turno siempre es `[INICIO_DE_CONVERSACION]` (Gemini exige empezar con "user") y en un chat vacío hace que Loki salude.
  - API key: `MyPet/Secrets.plist` (clave `GEMINI_API_KEY`), ignorado por git; plantilla en `Secrets.example.plist`. Lo lee `Secrets.geminiAPIKey`; sin key el chat muestra "Loki está dormido". La key va dentro del .app: para publicar, mover la llamada a un servidor.
- **Paseadores y calificaciones** (`Features/Walkers`):
  - El dueño, desde su perfil, abre "Seleccionar paseador" (`WalkerPickerView`): cards con nombre, XP, cantidad de paseos y estrellas, ordenadas por calificación. Tocar una la guarda como `User.selectedWalker` ("Mi paseador", visible en el perfil; "Quitar" la borra). Solo se marca: no se comparten mascotas entre cuentas.
  - La lista sale de las cuentas con rol Paseador de este dispositivo y de 4 paseadores de ejemplo (`DemoWalkerSeeder`, `User.isDemo`, etiqueta "Ejemplo"; su contraseña es un hash aleatorio y no pueden iniciar sesión).
  - Al iniciar un paseo, si el dueño tiene paseador, el interruptor "Lo pasea {nombre}" (activado por defecto) guarda `Walk.walker`.
  - XP del paseador: 10 XP por cada 100 m, igual que las mascotas, en `User.walkerExperience`, y `walkerWalkCount` +1. Lo suma `Walk.complete` al paseador asignado o, si quien registra el paseo es un paseador, a él mismo.
  - Calificación: en la card del paseo (Mis paseos) el dueño da de 1 a 5 estrellas y un comentario (`WalkRatingSection` → `Walk.rate`, que reemplaza la calificación anterior). El promedio es `User.averageRating` (`ratingSum` / `ratingCount`).
  - El perfil del paseador muestra su calificación, XP, paseos y los comentarios recibidos (`WalkerStatsView`).
  - Los totales del paseador se guardan en lugar de calcularse porque los de ejemplo no tienen paseos reales.
- **Recordatorios**: un `Reminder` por mascota, creado al agregar la mascota: cada N días (`everyDays`, contando desde `startDate`), paseos al día = `times.count`, `times` en minutos desde las 00:00. Los formularios editan un `ReminderDraft`. `ReminderScheduler`: si es diario usa notificaciones repetidas; si es cada N días programa las próximas 10 fechas y las renueva al abrir la app.
- **Carrusel** (`PetCarousel`): circular; después de la última mascota vuelve a la primera y viceversa.
- **Card de mascota** (`PetDetailView`): se abre al tocar la mascota en el carrusel. Muestra foto, nivel, barra de XP, especie, raza, peso, recordatorio, QR y placa. El menú "Opciones" (arriba a la derecha) permite **editar** (`PetFormView` con `pet`, sin la sección de recordatorio) y **eliminar** (con confirmación; borra su recordatorio y cancela sus notificaciones; sus paseos y los logros del usuario se conservan). Al eliminar, primero se sale de la card y luego se borra: los destinos del Home buscan la mascota por UUID en cada render y así nunca leen un objeto borrado.
- **Alta y edición**: `PetFormView`/`PetFormViewModel` sirven para las dos cosas. Al guardar se reevalúan los logros (cambiar la especie puede desbloquear "Familia completa") y se reprograma el recordatorio (la notificación lleva el nombre).
- **Especies y razas**: solo perro y gato. `Species.breeds` tiene "Mestizo" + las 15 razas más comunes en México de cada uno. `Pet.breed` guarda el texto. Al quitar ave y tortuga, las mascotas guardadas con esas especies ya no se pueden leer.
- **Cambios de esquema en desarrollo**: tras cambios incompatibles (quitar especies, `Walk.pet` → `Walk.pets`, `Route` como recorrido) **hay que borrar la app del simulador/iPhone de pruebas**. Antes de publicar, usar `VersionedSchema` + `SchemaMigrationPlan`.
- **QR** (`PetQRView`, `PetQRSheet`): pide dirección y teléfono (10 dígitos) del dueño, guardados en `User.address`/`User.phone` y reutilizados en todas sus mascotas y en la placa. El QR es texto plano (cualquier cámara lo lee sin internet): nombre, especie, raza, peso, dueño, teléfono y dirección. La hoja carta (612 × 792 pt) se convierte en PDF con `ImageRenderer` y se abre el diálogo de impresión de iOS, que también deja guardarlo o compartirlo.
- **Placa personalizada** (`PlateOrderView`): forma (círculo, corazón, escudo), color, texto grabado (≤ 40 caracteres, por defecto nombre + teléfono) y dirección de envío. Cuesta $100 MXN con **pago simulado** (espera 2 s, no pide tarjeta ni cobra). Solo se guarda `Pet.plateOrderDate`.
- **Recompensas** (`Features/Rewards`, wireframes 14–16): cupones de descuento y promociones de marcas aliadas que se desbloquean por distancia y uso de la app.
  - Entidades: `Brand` (tabla `Marca`: nombre, ícono, sitio web y teléfono para canjear; se precarga desde `BrandCode`) y `Reward` (tabla `Recompensa`: cupón de un usuario con código único, textos copiados del catálogo, fecha de desbloqueo y vencimiento; usuario 1→N recompensas, marca 1→N recompensas).
  - Catálogo en `RewardCode` (marca, descuento, categoría, meta `RewardRequirement` y si es Pro). Metas: km caminados, paseos terminados o días distintos con paseo. Para agregar uno: nuevo `case`. Vigencia: 3 meses.
  - `RewardService.evaluate` entrega los cupones al terminar un paseo y al abrir Recompensas (para paseos anteriores). Código de canje = prefijo de la marca + 6 caracteres aleatorios (`HUELLAS20-7K3QX9`); sin servidor la marca no puede validarlo.
  - Plan Básico/Pro (`User.isPro`): la etiqueta junto al título abre `ProPlanView` ($49 MXN/mes, **pago simulado**, se puede volver a Básico). Con Básico los cupones Pro se ganan pero quedan bloqueados y el filtro de marcas está desactivado (se ven todas). Con Pro se abren todos y las casillas ocultan marcas (`User.hiddenBrandCodes`).
  - Al tocar un cupón se abre `CouponDetailView`: descuento, código para copiar, vigencia y enlaces a la tienda y teléfono de la marca. "Próxima recompensa" muestra la meta pendiente con más avance y su barra.
- **Home**: el botón "Agregar mascota" es de texto (junto a "Mis mascotas" cuando ya hay mascotas; sin mascotas lo muestra el carrusel).
- **Card de logro** (`AchievementCard`): al tocar una medalla del Home se abre una hoja con el título, cómo se obtiene, la XP y si ya está conseguido.
- **Fotos**: se eligen con `PhotosPicker` y se reducen a ≤ 800 px JPEG (`@Attribute(.externalStorage)`).

## Relación con el diagrama original
`Usuario`→`User`, `Mascota`→`Pet`, `Paseo`→`Walk`, `Ruta`→`Route`, `Logro`→`Achievement`, `Enfermedad`→`Disease`. Las tablas intermedias `logro_usuario` y `Mascota_enfermedad` son relaciones muchos a muchos; `Paseo`↔`Mascota` también (un paseo puede ser de varias mascotas). `Ruta` es el recorrido personalizado: muchos paseos pueden usar la misma. `Paseo_Usuario` se omitió porque duplicaba `Paseo.usuario`. Tablas nuevas: `Marca`→`Brand` y `Recompensa`→`Reward` (Usuario 1→N Recompensa, Marca 1→N Recompensa).

## Pendiente
- Paseo: seguir el GPS en segundo plano (`UIBackgroundModes` location + `CLBackgroundActivitySession`), terminar solo al llegar al destino, avisar si te sales del recorrido personalizado, y pantalla para cuando se niega el permiso de ubicación (hoy solo no aparece la posición).
- Target de pruebas.
- Placa: pago real (backend + pasarela como Stripe o Mercado Pago), historial de pedidos (modelo `PlateOrder` en vez de solo la fecha) y forma de hueso (SF Symbols no la tiene; requiere un `Shape` propio).
- QR: si se quiere que al escanearlo se abra una página con los datos actualizados, hace falta un servidor; hoy los datos van fijos dentro del QR y hay que reimprimir si cambian.
- Recorridos: trazar con calles reales (hoy son tramos rectos entre los puntos tocados) o grabarlos caminando.
- Recompensas: catálogo de marcas y cupones desde un backend con convenios reales, validación del código por la marca, marcar cupón como canjeado, y suscripción Pro real con StoreKit 2.
- Paseadores: con servidor, lista real de paseadores (quitar los de ejemplo), compartir las mascotas del dueño con su paseador y calcular XP/calificación desde los paseos.
- Loki: llamar a Gemini desde un servidor propio (la key no debe ir en la app publicada) y mostrar la respuesta mientras se genera (streaming).
