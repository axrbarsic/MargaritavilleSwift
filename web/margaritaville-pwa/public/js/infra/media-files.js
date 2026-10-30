// Локальные файлы медиа: сохранение снимков, видео и голоса в IndexedDB и ссылки
// для показа. Источник: Data/LocalMediaFileStore.swift (медиа только на устройстве).
import { deleteMedia, loadMedia, saveMedia } from "../store/db.js";

const urls = new Map();
const EXT = { photo: "jpg", video: "mp4", audio: "m4a" };

export async function saveAttachment(kind, blob, transcript = null) {
  const id = crypto.randomUUID();
  const relativePath = `media/${id}.${EXT[kind] ?? "bin"}`;
  await saveMedia(relativePath, blob);
  return { id, kind, relativePath, createdAt: Date.now(), transcript: transcript?.trim() ? transcript : null, completedAt: null };
}

export async function deleteAttachment(attachment) {
  const url = urls.get(attachment.relativePath);
  if (url) URL.revokeObjectURL(url);
  urls.delete(attachment.relativePath);
  await deleteMedia(attachment.relativePath).catch(() => {});
}

/// Ссылка на файл вложения (кэшируется, пока вложение существует).
export async function attachmentURL(attachment) {
  if (urls.has(attachment.relativePath)) return urls.get(attachment.relativePath);
  const blob = await loadMedia(attachment.relativePath);
  if (!blob) return null;
  const url = URL.createObjectURL(blob);
  urls.set(attachment.relativePath, url);
  return url;
}

/// Системная камера для фото или видео (CameraCaptureView). Возвращает файл или null.
export function captureWithCamera(kind) {
  return new Promise((resolve) => {
    const input = document.createElement("input");
    input.type = "file";
    input.accept = kind === "video" ? "video/*" : "image/*";
    input.setAttribute("capture", "environment");
    input.style.display = "none";
    let settled = false;
    const done = (file) => { if (settled) return; settled = true; input.remove(); resolve(file); };
    input.addEventListener("change", () => done(input.files?.[0] ?? null));
    input.addEventListener("cancel", () => done(null));
    document.body.append(input);
    input.click();
  });
}
