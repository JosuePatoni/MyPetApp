import SwiftUI

enum PDFRenderer {
    /// Una página PDF del tamaño de `view` (dale un `frame` fijo, p. ej. carta 612 × 792 pt).
    @MainActor
    static func data(for view: some View) -> Data {
        let data = NSMutableData()
        ImageRenderer(content: view).render { size, render in
            var box = CGRect(origin: .zero, size: size)
            guard let consumer = CGDataConsumer(data: data as CFMutableData),
                  let pdf = CGContext(consumer: consumer, mediaBox: &box, nil)
            else { return }
            pdf.beginPDFPage(nil)
            render(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }
        return data as Data
    }
}
