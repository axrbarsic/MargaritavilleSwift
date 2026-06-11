import Foundation

extension BuildChangelog {
    static let midEntries = [
        BuildChangelogEntry(
            version: "0.2.0 (94)",
            date: "2026-06-09",
            changes: [
                "Restored a visible animated VIP jelly mask over the whole composited cell so VIP rooms no longer stay plain rectangles.",
                "Kept the Metal layer effect for content deformation while the shared jelly mask guarantees the cell contour visibly moves.",
                "Migrated existing installs to enable VIP jelly once by default so old saved experiment flags cannot hide the effect."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (93)",
            date: "2026-06-09",
            changes: [
                "Replaced the invisible VIP jelly distortion with a SwiftUI layerEffect shader that samples the full composited cell layer.",
                "Moved the VIP jelly silhouette into the Metal shader alpha mask so the cell contour and its contents deform through the same field.",
                "Removed the pre-warp static clipping for VIP jelly cells so the animated contour is visible again."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (92)",
            date: "2026-06-09",
            changes: [
                "VIP-желе переведено на один источник деформации: ячейка растеризуется целиком (заливка, номер, S/L/B, бейджи) и гнётся одним Metal-полем — контур и содержимое теперь один материал.",
                "Удалена CPU-клякса формы и повторная маска после warp, которые двигались по другой математике и создавали ощущение отдельных слоёв.",
                "Удалён эксперимент VIP depth/объём; тень ячейки теперь следует за деформированным силуэтом, бейджи времени и медиа гнутся вместе с ячейкой."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (91)",
            date: "2026-06-09",
            changes: [
                "Fixed VIP jelly content warp so the room number and S/L/B layer uses repeating local shader coordinates instead of collapsing to a nearly static edge sample.",
                "Moved VIP jelly deformation onto the composited cell layer so the status fill, room number, and S/L/B controls warp as one material.",
                "Increased the Metal warp amplitude and sample offset so content deformation is visibly tied to the moving jelly cell."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (90)",
            date: "2026-06-09",
            changes: [
                "Hid and force-disabled the unfinished VIP jelly depth experiment so it cannot remain active from saved settings.",
                "Started the performance audit by collapsing VIP jelly animation work to one frame clock per VIP cell instead of separate clocks for background, mask, and each label.",
                "Replaced per-label fake motion with a single Metal distortion pass that warps the rendered room number and S/L/B layer together."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (89)",
            date: "2026-06-09",
            changes: [
                "Added a Developer toggle for VIP jelly depth so the raised blob look can be compared on and off.",
                "Strengthened the VIP jelly depth lighting with a clear specular highlight, darker lower edge, and deeper status-colored body shadow.",
                "Made the room number and S/L/B controls move subtly with VIP jelly so the content follows the blob instead of staying rigid."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (88)",
            date: "2026-06-09",
            changes: [
                "Added native bevel depth to VIP jelly cells using inner highlights, inner shadows, and soft edge lighting.",
                "Kept depth, flicker, and shadow effects clipped to the same live jelly shape so the blob reads as the cell itself, not an overlay."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (87)",
            date: "2026-06-09",
            changes: [
                "Added selectable Broken TV background variants: Analog, Fine, Tear, Green, and Hard.",
                "Persisted the selected TV-static variant and included it in the background renderer configuration.",
                "Moved VIP flicker into the jelly cell renderer when VIP jelly is active, so flashes follow the blob shape instead of the old rectangle."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (86)",
            date: "2026-06-09",
            changes: [
                "Smoothed VIP jelly edges with cubic curves so the cell no longer catches angular polygon corners while wobbling.",
                "Clipped VIP flicker through the same jelly cell mask and replaced the diagonal light gradient with a uniform natural flash."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (85)",
            date: "2026-06-09",
            changes: [
                "Removed the VIP breathing experiment from active settings and replaced it with VIP jelly.",
                "Made VIP jelly deform the actual cell shape and mask instead of drawing a moving line inside a stable rectangle.",
                "Added per-room seeded multi-wave motion so VIP jelly cells do not move in the same short visible loop."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (84)",
            date: "2026-06-09",
            changes: [
                "Strengthened the VIP jelly effect so enabled VIP cells visibly pulse vertically and warp through the real cell size.",
                "Added animated jelly edge highlights to make the effect easier to see without bringing back the removed zebra or TV-static VIP modes."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (83)",
            date: "2026-06-09",
            changes: [
                "Removed the old VIP TV-static and VIP zebra experiments from active settings and room rendering.",
                "Reworked VIP breathing into a GPU distortion shader so VIP cells can jelly-warp instead of only stretching horizontally.",
                "Simplified Broken TV background controls to brightness and green tint, with stronger visible response."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (82)",
            date: "2026-06-09",
            changes: [
                "Added live controls for the Broken TV background: noise speed, grain size, brightness, and green tint.",
                "Added experimental VIP flicker and VIP breathing controls so VIP cells can pulse without using the coarse TV-static cell effect."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (81)",
            date: "2026-06-09",
            changes: [
                "Rebuilt the VIP TV-noise cell effect on the same Core Image random-noise renderer used by the full-screen TV background.",
                "Replaced the coarse Canvas block pattern with finer status-tinted static grain and matching scanlines inside VIP cells."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (80)",
            date: "2026-06-08",
            changes: [
                "Removed the TV-noise cell toggle from the Background settings so it can no longer read as a global all-cells mode.",
                "Kept TV noise only as a VIP experimental effect: regular cells never create the overlay."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (79)",
            date: "2026-06-08",
            changes: [
                "Changed the broken-TV cell effect into a VIP-only mode instead of applying it to every room cell.",
                "When the VIP TV mode is enabled, VIP cells use status-tinted TV static and the regular VIP zebra is suppressed to avoid stacked animated overlays."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (78)",
            date: "2026-06-08",
            changes: [
                "Optimized the broken-TV cell overlay after device testing showed heat and scrolling jank.",
                "Kept the cell TV static visually obvious while replacing per-pixel drawing with a bounded low-cost noise grid."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (77)",
            date: "2026-06-08",
            changes: [
                "Made the broken-TV cell overlay much more visible with high-contrast black, white, and status-tinted static.",
                "Raised the cell TV static cadence to 60 Hz and added stronger scanline/glitch bands so the effect reads like the full-screen TV background."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (76)",
            date: "2026-06-08",
            changes: [
                "Made the cell broken-TV experiment easier to find by showing it in Background settings as well as Developer experiments.",
                "Renamed the toggle to 'Сломанный ТВ в ячейках' so it clearly describes the visible cell effect."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (75)",
            date: "2026-06-08",
            changes: [
                "Added a Developer experiment that applies broken-TV static inside room cells instead of only as a full-screen background.",
                "Tinted the cell TV static from each room's current status color so yellow, red, green, blue, and scheduled cells keep their meaning.",
                "Kept the effect as a lightweight visible-cell overlay with deterministic per-room noise instead of creating a SpriteKit scene per cell."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (74)",
            date: "2026-06-08",
            changes: [
                "Replaced the black SpriteKit GLSL TV Static path with a native Core Image CIRandomGenerator background so the TV mode renders visibly on the iPhone.",
                "Kept TV Static as a regular background mode next to Off, Matrix, and Video, with scanline overlay for an analog television feel.",
                "Removed the unused SpriteKit TV shader scene from the active code path."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (73)",
            date: "2026-06-08",
            changes: [
                "Moved the broken-TV effect out of the Developer preview and into the regular background mode picker next to Off, Matrix, and Video.",
                "Made TV Static render as a full-screen SpriteKit background and write opaque shader fragments directly so it cannot appear as a black preview panel.",
                "Added persistence coverage for the TV Static background mode."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (72)",
            date: "2026-06-08",
            changes: [
                "Fixed the temporary broken-TV preview visibility by adapting ShaderKit's Dynamic Gray Noise output alpha to OceanKey's direct SKSpriteNode shader wrapper.",
                "Kept the ShaderKit noise algorithm intact while removing the dependency on ShaderKit's color-mix helper state.",
                "Restored video wallpaper matte blur as a real variable UIBlurEffect instead of the coarse gray material-step overlay."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (71)",
            date: "2026-06-08",
            changes: [
                "Added a temporary experimental Settings block for the first broken-TV visual candidate.",
                "Integrated ShaderKit's MIT Dynamic Gray Noise shader as a SpriteKit GPU preview instead of hand-rolling the TV static effect.",
                "Persisted the temporary TV noise toggle so the preview can be switched on and off while testing."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (70)",
            date: "2026-06-08",
            changes: [
                "Rebuilt the top setup-unlock puzzle swipe as one measured GeometryReader track so the dragged piece lands exactly in the settings-button socket.",
                "Fixed the room-cell puzzle swipe math so the piece center and socket center match exactly at commit instead of landing a few points off."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (69)",
            date: "2026-06-08",
            changes: [
                "Rebuilt video wallpaper playback around a stable AVPlayerLayer path so the main screen no longer starts black until Settings forces a redraw.",
                "Moved blur, green tint, brightness, and grid to lightweight overlay layers instead of per-frame Core Image video composition.",
                "Added tap-to-close behavior: when a room action menu is open, tapping the room cell closes it."
            ]
        ),
    ]
}
