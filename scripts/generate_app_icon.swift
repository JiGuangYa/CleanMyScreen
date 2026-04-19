import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: swift generate_app_icon.swift <output-png-path>\n", stderr)
    exit(EXIT_FAILURE)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let canvasSize = CGSize(width: 1024, height: 1024)
let fullRect = NSRect(origin: .zero, size: canvasSize)
let pixelsWide = Int(canvasSize.width)
let pixelsHigh = Int(canvasSize.height)

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixelsWide,
    pixelsHigh: pixelsHigh,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Failed to create bitmap context\n", stderr)
    exit(EXIT_FAILURE)
}

bitmap.size = canvasSize

NSGraphicsContext.saveGraphicsState()
guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("Failed to create graphics context\n", stderr)
    exit(EXIT_FAILURE)
}

NSGraphicsContext.current = context

NSColor.clear.setFill()
fullRect.fill()

let baseRect = fullRect.insetBy(dx: 72, dy: 72)
let basePath = NSBezierPath(roundedRect: baseRect, xRadius: 230, yRadius: 230)
let baseGradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.98, alpha: 1.0),
    NSColor(calibratedRed: 0.83, green: 0.85, blue: 0.88, alpha: 1.0)
])!
baseGradient.draw(in: basePath, angle: -90)

NSGraphicsContext.saveGraphicsState()
let outerShadow = NSShadow()
outerShadow.shadowColor = NSColor(calibratedWhite: 0.0, alpha: 0.18)
outerShadow.shadowBlurRadius = 30
outerShadow.shadowOffset = NSSize(width: 0, height: -10)
outerShadow.set()
basePath.fill()
NSGraphicsContext.restoreGraphicsState()

let screenFrame = NSRect(x: 180, y: 250, width: 664, height: 430)
let bezelPath = NSBezierPath(roundedRect: screenFrame, xRadius: 92, yRadius: 92)
NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.14, alpha: 1.0).setFill()
bezelPath.fill()

let screenRect = screenFrame.insetBy(dx: 28, dy: 28)
let screenPath = NSBezierPath(roundedRect: screenRect, xRadius: 68, yRadius: 68)
NSColor.black.setFill()
screenPath.fill()

NSGraphicsContext.saveGraphicsState()
screenPath.addClip()

let reflection = NSBezierPath()
reflection.move(to: CGPoint(x: screenRect.minX - 40, y: screenRect.minY + 170))
reflection.line(to: CGPoint(x: screenRect.minX + 130, y: screenRect.minY - 20))
reflection.line(to: CGPoint(x: screenRect.maxX + 40, y: screenRect.maxY - 110))
reflection.line(to: CGPoint(x: screenRect.maxX - 130, y: screenRect.maxY + 20))
reflection.close()

NSColor.white.withAlphaComponent(0.10).setFill()
reflection.fill()

let highlightRect = NSRect(x: screenRect.minX + 60, y: screenRect.maxY - 150, width: screenRect.width * 0.45, height: 52)
let highlightPath = NSBezierPath(roundedRect: highlightRect, xRadius: 26, yRadius: 26)
NSColor.white.withAlphaComponent(0.14).setFill()
highlightPath.fill()

NSGraphicsContext.restoreGraphicsState()

let standNeck = NSBezierPath(roundedRect: NSRect(x: 452, y: 168, width: 120, height: 110), xRadius: 36, yRadius: 36)
NSColor(calibratedRed: 0.78, green: 0.81, blue: 0.85, alpha: 1.0).setFill()
standNeck.fill()

let standBase = NSBezierPath(roundedRect: NSRect(x: 350, y: 118, width: 324, height: 54), xRadius: 27, yRadius: 27)
NSColor(calibratedRed: 0.69, green: 0.72, blue: 0.77, alpha: 1.0).setFill()
standBase.fill()

func drawSparkle(center: CGPoint, scale: CGFloat) {
    let path = NSBezierPath()
    path.lineWidth = 18 * scale
    path.lineCapStyle = .round

    path.move(to: CGPoint(x: center.x, y: center.y + 46 * scale))
    path.line(to: CGPoint(x: center.x, y: center.y - 46 * scale))

    path.move(to: CGPoint(x: center.x - 46 * scale, y: center.y))
    path.line(to: CGPoint(x: center.x + 46 * scale, y: center.y))

    path.move(to: CGPoint(x: center.x - 28 * scale, y: center.y - 28 * scale))
    path.line(to: CGPoint(x: center.x + 28 * scale, y: center.y + 28 * scale))

    path.move(to: CGPoint(x: center.x - 28 * scale, y: center.y + 28 * scale))
    path.line(to: CGPoint(x: center.x + 28 * scale, y: center.y - 28 * scale))

    NSColor.white.withAlphaComponent(0.96).setStroke()
    path.stroke()
}

drawSparkle(center: CGPoint(x: 760, y: 640), scale: 1.0)
drawSparkle(center: CGPoint(x: 285, y: 355), scale: 0.52)
NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Failed to render icon PNG\n", stderr)
    exit(EXIT_FAILURE)
}

try pngData.write(to: outputURL)
