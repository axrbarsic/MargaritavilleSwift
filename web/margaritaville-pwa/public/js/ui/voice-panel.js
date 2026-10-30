// Панель записи голоса и пузыри голосовых заметок.
// Источник: Features/Notes/VoiceTranscriptionPanel.swift, VoiceNoteBubble.swift.
import { h, formatTime } from "./dom.js";
import { icon } from "./icons.js";
import { VoiceRecorder } from "../infra/voice.js";
import { attachmentURL } from "../infra/media-files.js";
import { tr } from "../i18n/i18n.js";

/// Возвращает { element, cancel }. onCompletion({ blob, transcript }) — после остановки.
export function voicePanel(title, feedback, onCompletion) {
  const iconBox = h("span", { class: "voice-icon" });
  const label = h("div", { class: "voice-title" });
  const status = h("div", { class: "voice-status" }, tr("Готово к записи"));
  const hint = h("p", { class: "voice-hint" }, tr("Говори на языке интерфейса. Текст появится после остановки записи."));
  const button = h("button", { class: "voice-button" }, iconBox, h("div", {}, label, status));
  const recorder = new VoiceRecorder({
    onStatus: (text) => { status.textContent = text; },
    onPhase: () => render()
  });
  const render = () => {
    const recording = recorder.isRecording;
    iconBox.replaceChildren(icon(recording ? "stop" : "mic", 30, 2.6));
    button.classList.toggle("recording", recording);
    button.disabled = !recorder.canToggle;
    label.textContent = recording ? tr("Остановить") : title;
    hint.hidden = !recording;
  };
  button.addEventListener("click", () => {
    if (recorder.isRecording) {
      feedback.tap();
      recorder.stop();
    } else {
      feedback.holdStart();
      recorder.start(onCompletion);
    }
  });
  render();
  return { element: h("div", { class: "voice-panel" }, button, hint), cancel: () => recorder.cancel() };
}

export function voiceBubble(attachment, onDelete) {
  let audio = null;
  const playIcon = h("span", {}, icon("play", 18, 3));
  const error = h("div", { class: "voice-error", hidden: true });
  const play = h("button", {
    class: "voice-play",
    "aria-label": tr("Воспроизвести"),
    onclick: async () => {
      if (audio && !audio.paused) {
        audio.pause();
        return;
      }
      const url = await attachmentURL(attachment);
      if (!url) {
        error.hidden = false;
        error.textContent = tr("Не удалось воспроизвести голос");
        return;
      }
      audio ??= new Audio(url);
      audio.onplay = () => playIcon.replaceChildren(icon("pause", 18, 3));
      audio.onpause = audio.onended = () => playIcon.replaceChildren(icon("play", 18, 3));
      audio.play().catch(() => { error.hidden = false; error.textContent = tr("Не удалось воспроизвести голос"); });
    }
  }, playIcon);
  return h("div", { class: "voice-bubble" },
    play,
    h("div", { class: "voice-bubble-body" },
      h("div", { class: "voice-bubble-head" },
        h("span", {}, formatTime(attachment.createdAt)),
        h("span", { class: "voice-bubble-tools" },
          icon("waveform", 14, 2.6),
          onDelete ? h("button", { class: "voice-delete", "aria-label": tr("Удалить голосовую заметку"), onclick: onDelete }, icon("trash", 13, 2.8)) : null)
      ),
      h("div", { class: "voice-bubble-text" }, attachment.transcript || tr("Голос сохранён без расшифровки")),
      error
    )
  );
}
