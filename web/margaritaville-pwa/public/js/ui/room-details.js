// Экран комнаты: «Заметки» (текст), «Голос/медиа» (голос + фото/видео) или «Медиа».
// Изменения сохраняются сразу. Источник: Features/RoomDetails/RoomDetailsScreen.swift.
import { h } from "./dom.js";
import { backButton, pushScreen, updatedLabel } from "./screen-stack.js";
import { mediaActions, mediaGrid, openMediaViewer } from "./media-views.js";
import { voiceBubble, voicePanel } from "./voice-panel.js";
import { deleteAttachment, saveAttachment } from "../infra/media-files.js";

const TITLES = { text: "Заметки", voice: "Голос/медиа", media: "Медиа" };

export function openRoomDetails(app, roomID, mode, onMutation = () => {}) {
  const { store, feedback } = app;
  return pushScreen((close, setRefresh) => {
    const room = () => store.room(roomID);
    const stamp = h("div", { class: "detail-stamp" });
    const error = h("div", { class: "detail-error", hidden: true });
    const voiceList = h("div", { class: "voice-list" });
    const mediaBox = h("div", { class: "media-box" });
    const showError = (message) => { error.hidden = !message; error.textContent = message ?? ""; };

    const attachments = () => room()?.mediaAttachments ?? [];
    const visual = () => attachments().filter((a) => a.kind === "photo" || a.kind === "video");
    const voices = () => attachments().filter((a) => a.kind === "audio");

    const remove = async (attachment) => {
      await deleteAttachment(attachment);
      store.removeRoomMedia(roomID, attachment);
      onMutation();
    };

    const refresh = () => {
      const r = room();
      if (!r) return close();
      const date = mode === "text" ? r.textNoteUpdatedAt
        : mode === "voice" ? voices()[0]?.createdAt ?? r.voiceTranscriptUpdatedAt
          : visual()[0]?.createdAt;
      stamp.hidden = date == null;
      stamp.textContent = date == null ? "" : `Обновлено: ${updatedLabel(date)}`;
      voiceList.replaceChildren(...(voices().length
        ? voices().map((a) => voiceBubble(a, () => remove(a)))
        : [h("p", { class: "detail-hint dim" }, "Голосовые заметки появятся здесь пузырями после записи.")]));
      mediaBox.replaceChildren(visual().length
        ? mediaGrid(visual(), { onOpen: (a) => openMediaViewer(visual(), a), onDelete: remove })
        : h("p", { class: "detail-hint" }, "Фото и видео сохраняются локально и не синхронизируются."));
    };
    setRefresh(refresh);

    const mediaSection = () => h("div", { class: "detail-stack" },
      mediaActions(feedback, (attachment) => { store.addRoomMedia(roomID, attachment); showError(null); onMutation(); }, showError),
      error,
      mediaBox
    );

    let body;
    let voice = null;
    if (mode === "text") {
      const area = h("textarea", { class: "detail-editor", placeholder: "Текстовая заметка", rows: 8 });
      area.value = room()?.textNote ?? "";
      let timer = null;
      area.addEventListener("input", () => {
        clearTimeout(timer);
        timer = setTimeout(() => {
          if (area.value === (room()?.textNote ?? "")) return;
          store.updateTextNote(roomID, area.value);
          onMutation();
        }, 250);
      });
      area.addEventListener("blur", () => {
        clearTimeout(timer);
        if (area.value !== (room()?.textNote ?? "")) { store.updateTextNote(roomID, area.value); onMutation(); }
      });
      setTimeout(() => area.focus(), 260);
      body = area;
    } else {
      voice = mode === "voice" ? voicePanel("Новая голосовая заметка", feedback, async ({ blob, transcript }) => {
        try {
          const attachment = await saveAttachment("audio", blob, transcript);
          store.addRoomMedia(roomID, attachment);
          if (transcript) store.updateVoiceTranscript(roomID, transcript);
          showError(null);
          onMutation();
        } catch (e) {
          showError(e?.message || "Не удалось сохранить голос");
        }
      }) : null;
      body = mode === "voice"
        ? h("div", { class: "detail-stack" }, voice.element, voiceList, h("hr", { class: "detail-divider" }), mediaSection())
        : mediaSection();
    }
    refresh();

    return h("main", { class: "detail-screen" },
      h("header", { class: "detail-header" },
        backButton(() => { voice?.cancel(); close(); }),
        h("div", { class: "detail-room-number" }, roomID)
      ),
      h("div", { class: "detail-scroll" },
        h("section", { class: "detail-card" },
          h("h1", { class: "detail-title" }, TITLES[mode]),
          stamp,
          body
        )
      )
    );
  });
}
