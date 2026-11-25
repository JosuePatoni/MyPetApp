# MyPet

App iOS (SwiftUI + SwiftData, iOS 17+) para dueños y paseadores de mascotas: mascotas con nivel y experiencia, paseos con GPS, recorridos personalizados, recordatorios, QR imprimible, placa personalizada y recompensas de marcas aliadas.

Abrir `MyPet.xcodeproj` con Xcode 16 o superior. Las reglas de arquitectura y de negocio están en [`AGENTS.md`](AGENTS.md).

## Paleta de colores

Paleta del reto del proyecto. Está definida en código en `MyPet/Shared/MyPetPalette.swift` (`MyPetPalette.teal`, etc.); usa siempre esas constantes en lugar de escribir colores a mano.

| Nombre | Hex | RGB | Uso en la app |
|---|---|---|---|
| `teal` | `#008080` | 0, 128, 128 | Color principal: botones principales, bordes, íconos y flechas. Es el color de acento en modo claro. |
| `turquoise` | `#38D1B4` | 56, 209, 180 | Estados seleccionados, barras de progreso y rol **Paseador**. Es el color de acento en modo oscuro. |
| `mint` | `#CCFFFF` | 204, 255, 255 | Fondos de cards, cupones y del código de canje. |
| `yellow` | `#FFEA80` | 255, 234, 128 | Etiquetas de sección, insignia del plan (Básico/Pro) y rol **Dueño**. |
| `apricot` | `#FFCB80` | 255, 203, 128 | Etiquetas secundarias (p. ej. "Ubicación inicial") y huellas decorativas. |

### Reglas de uso

- **Texto sobre `mint`, `yellow`, `apricot` y `turquoise`:** siempre negro (`.foregroundStyle(.black)`). Son colores claros y el blanco no se lee.
- **`teal`** sirve para texto e íconos sobre fondo blanco y como fondo de botones con texto blanco.
- **Color de acento:** `AccentColor` (en `Assets.xcassets`) es `teal` en modo claro y `turquoise` en modo oscuro. `.tint` y los controles nativos lo usan solos.
- **Cards que se repiten** (paseos, cupones): alternan `mint` y `yellow`.
- **Bordes:** `teal`, de 1.5 pt (2–3 pt para resaltar lo seleccionado).
