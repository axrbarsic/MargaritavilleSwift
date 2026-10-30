// Медиа: кнопки съёмки, сетка миниатюр, полноэкранный просмотр с листанием.
// Источник: Features/Media/MediaAttachmentGrid.swift, MediaThumbnailView.swift,
// MediaViewerScreen.swift.
import { h, formatTime } from "./dom.js";
import { icon } from "./icons.js";
import { pushScreen } from "./screen-stack.js";
import { attachmentURL, captureWithCamera, saveAttachment } from "../infra/media-files.js";

const KIND_ICON = { photo: "photo", video: "video", audio: "waveform" };

/// Кнопки «Фото» и «Видео»: открывают системную камеру и сохраняют снимок локально.
export function mediaActions(feedback, onSaved, onError) {
  const action = (kind, iconName, title) => h("button", {
    class: "media-action",
    onclick: async () => {
      feedback.tap();
      const file = await captureWithCamera(kind);
      if (!file) return;
      try {
        onSaved(await saveAttachment(kind, file));
      } catch (error) {
        onError(error?.message || "Не удалось сохранить медиа");
      }
    }
  }, icon(iconName, 28, 2.6), h("span", {}, title));
  return h("div", { class: "media-actions" }, action("photo", "camera", "Фото"), action("video", "video", "Видео"));
}

function thumbnail(attachment) {
  const box = h("div", { class: "media-thumb" }, h("div", { class: "media-thumb-loading" }));
  attachmentURL(attachment).then((url) => {
    if (!url) return;
    const view = attachment.kind === "video"
      ? h("video", { src: url, muted: true, loop: true, autoplay: true, playsinline: true })
      : h("img", { src: url, alt: "" });
    if (view.tagName === "VIDEO") view.muted = true;
    box.querySelector(".media-thumb-loading")?.replaceWith(view);
  });
  box.append(badge(attachment));
  return box;
}

const badge = (attachment) => h("span", { class: "media-badge" }, icon(KIND_ICON[attachment.kind], 11, 3), formatTime(attachment.createdAt));

export function mediaGrid(attachments, { onOpen, onDelete }) {
  return h("div", { class: "media-grid" }, attachments.map((attachment) => h("div", { class: "media-card" },
    h("button", { class: "media-open", "aria-label": "Открыть медиа", onclick: () => onOpen(attachment) }, thumbnail(attachment)),
    h("button", { class: "media-delete", "aria-label": "Удалить медиа", onclick: () => onDelete(attachment) }, icon("trash", 13, 2.8))
  )));
}

/// Полноэкранный просмотр: листание вбок, счётчик «2 / 5», время съёмки.
export function openMediaViewer(attachments, initial) {
  pushScreen((close) => {
    let index = Math.max(0, attachments.findIndex((a) => a.id === initial.id));
    const counter = h("div", { class: "viewer-counter" });
    const time = h("div", { class: "viewer-time" });
    const track = h("div", { class: "viewer-track" }, attachments.map((attachment) => {
      const page = h("div", { class: "viewer-page" });
      attachmentURL(attachment).then((url) => {
        if (!url) return;
        page.append(attachment.kind === "video"
          ? h("video", { src: url, controls: true, playsinline: true })
          : h("img", { src: url, alt: "" }));
      });
      return page;
    }));
    const update = () => {
      counter.textContent = `${index + 1} / ${attachments.length}`;
      time.textContent = new Date(attachments[index].createdAt).toLocaleString("en-US", { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" });
      track.querySelectorAll("video").forEach((v, i) => { if (i !== index) v.pause(); });
    };
    track.addEventListener("scroll", () => {
      const next = Math.round(track.scrollLeft / Math.max(track.clientWidth, 1));
      if (next !== index && next >= 0 && next < attachments.length) { index = next; update(); }
    }, { passive: true });
    requestAnimationFrame(() => { track.scrollLeft = index * track.clientWidth; update(); });
    update();
    return h("div", { class: "viewer" }, track,
      h("div", { class: "viewer-bar" },
        h("button", { class: "viewer-close", "aria-label": "Закрыть", onclick: close }, icon("close", 18, 3)),
        h("div", {}, counter, time)
      ));
  }, { className: "black" });
}
