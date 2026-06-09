import SpriteKit
import UIKit

@MainActor
final class TVStaticNoiseSpriteScene: SKScene, ResizableSpriteScene {
    private var noiseNode: SKSpriteNode?
    private var scanlineNode: SKSpriteNode?

    override init(size: CGSize) {
        super.init(size: size)
        configureScene()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureScene()
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        resize(to: size)
        isPaused = false
    }

    func resize(to size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        removeAllChildren()
        backgroundColor = .black

        let texture = Self.makeOpaqueTexture(size: CGSize(width: 8, height: 8))
        let node = SKSpriteNode(texture: texture)
        node.position = CGPoint(x: size.width / 2, y: size.height / 2)
        node.size = size
        node.zPosition = 0
        node.color = .white
        node.colorBlendFactor = 1
        node.alpha = 1
        node.shader = SKShader(source: Self.dynamicGrayNoiseShaderSource)
        addChild(node)
        noiseNode = node

        let scanlines = SKSpriteNode(texture: Self.makeScanlineTexture())
        scanlines.position = CGPoint(x: size.width / 2, y: size.height / 2)
        scanlines.size = size
        scanlines.zPosition = 2
        scanlines.blendMode = .multiply
        scanlines.alpha = 0.22
        addChild(scanlines)
        scanlineNode = scanlines
    }

    private func configureScene() {
        scaleMode = .resizeFill
        anchorPoint = .zero
        backgroundColor = .black
    }

    private static func makeOpaqueTexture(size: CGSize) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return SKTexture(image: image)
    }

    private static func makeScanlineTexture() -> SKTexture {
        let size = CGSize(width: 2, height: 6)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor.black.withAlphaComponent(0.54).setFill()
            context.fill(CGRect(x: 0, y: 0, width: size.width, height: 1))
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }

    // Source: ShaderKit SHKDynamicGrayNoise.fsh by Paul Hudson / twostraws.
    // MIT License: https://github.com/twostraws/ShaderKit
    // Adapted only as a local SpriteKit shader string for OceanKey's direct SKSpriteNode wrapper.
    // The original multiplies by v_color_mix.a; our node does not rely on ShaderKit's helper setup,
    // so the background variant writes an opaque fragment directly.
    private static let dynamicGrayNoiseShaderSource = """
    float random(float offset, vec2 tex_coord, float time) {
        vec2 non_repeating = vec2(12.9898 * time, 78.233 * time);
        float sum = dot(tex_coord, non_repeating);
        float sine = sin(sum);
        float huge_number = sine * 43758.5453 * offset;
        float fraction = fract(huge_number);
        return fraction;
    }

    void main() {
        float noise = random(1.0, v_tex_coord, u_time + 0.371);
        gl_FragColor = vec4(vec3(noise), 1.0);
    }
    """
}
