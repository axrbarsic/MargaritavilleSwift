import Foundation
import Testing
@testable import MargaritavilleSwift

@Test
func mediaIndicatorUsesSimpleCornerFlagIcons() {
    let now = Date()

    var photoRoom = RoomCell(id: "101", opened: true, completedTasks: [], isVIP: false)
    photoRoom.mediaAttachments = [
        MediaAttachment(id: UUID(), kind: .photo, relativePath: "Media/photo.jpg", createdAt: now)
    ]

    var videoRoom = RoomCell(id: "102", opened: true, completedTasks: [], isVIP: false)
    videoRoom.mediaAttachments = [
        MediaAttachment(id: UUID(), kind: .video, relativePath: "Media/video.mov", createdAt: now)
    ]

    var audioRoom = RoomCell(id: "103", opened: true, completedTasks: [], isVIP: false)
    audioRoom.mediaAttachments = [
        MediaAttachment(id: UUID(), kind: .audio, relativePath: "Media/audio.m4a", createdAt: now)
    ]

    #expect(photoRoom.primaryAttachmentIndicatorIcon == "photo.fill")
    #expect(videoRoom.primaryAttachmentIndicatorIcon == "video.fill")
    #expect(audioRoom.primaryAttachmentIndicatorIcon == "waveform")
}

@Test
func mediaIndicatorPrioritizesAudioWhenRoomHasMultipleAttachments() {
    let now = Date()
    var room = RoomCell(id: "109", opened: true, completedTasks: [], isVIP: false)
    room.mediaAttachments = [
        MediaAttachment(id: UUID(), kind: .video, relativePath: "Media/video.mov", createdAt: now),
        MediaAttachment(id: UUID(), kind: .audio, relativePath: "Media/audio.m4a", createdAt: now),
        MediaAttachment(id: UUID(), kind: .photo, relativePath: "Media/photo.jpg", createdAt: now)
    ]

    #expect(room.primaryAttachmentIndicatorIcon == "waveform")
    #expect(room.attachmentIndicatorCount == 3)
}
