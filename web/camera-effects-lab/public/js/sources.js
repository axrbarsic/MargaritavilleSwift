// Источники картинки: камера (задняя/передняя), своё фото или видео, демо-сцена.
// Камера останавливается, когда вкладка скрыта, и при смене источника.
import { createDemoScene } from "./demo.js";

export class Sources {
  constructor(onStatus) {
    this.onStatus = onStatus;
    this.video = document.createElement("video");
    this.video.muted = true;
    this.video.playsInline = true;
    this.video.setAttribute("playsinline", "");
    this.demo = createDemoScene();
    this.image = null;
    this.stream = null;
    this.kind = "demo";
    this.facing = "environment";
    document.addEventListener("visibilitychange", () => this.handleVisibility());
  }

  /// Текущий кадр для рендера и нужно ли зеркалить его.
  frame(timeSeconds) {
    if (this.kind === "camera" && this.video.readyState >= 2) {
      return { element: this.video, mirror: this.facing === "user" };
    }
    if (this.kind === "video" && this.video.readyState >= 2) return { element: this.video, mirror: false };
    if (this.kind === "image" && this.image) return { element: this.image, mirror: false };
    this.demo.draw(timeSeconds);
    return { element: this.demo.canvas, mirror: false };
  }

  async startCamera(facing) {
    this.facing = facing;
    this.stopStream();
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.useDemo();
      this.onStatus("Этот браузер не даёт доступ к камере. Показана демо-сцена; можно загрузить фото или видео.", true);
      return false;
    }
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({
        audio: false,
        video: { facingMode: { ideal: facing }, width: { ideal: 1280 }, height: { ideal: 720 } }
      });
      this.video.srcObject = this.stream;
      this.video.removeAttribute("src");
      await this.video.play();
      this.kind = "camera";
      this.onStatus(facing === "user" ? "Передняя камера включена." : "Задняя камера включена.", false);
      return true;
    } catch (error) {
      this.useDemo();
      const denied = error && (error.name === "NotAllowedError" || error.name === "SecurityError");
      this.onStatus(
        denied
          ? "Доступ к камере запрещён. Разрешите камеру для этого сайта в настройках браузера или посмотрите демо-сцену."
          : "Камера не запустилась. Показана демо-сцена; можно загрузить фото или видео.",
        true
      );
      return false;
    }
  }

  async useFile(file) {
    this.stopStream();
    const url = URL.createObjectURL(file);
    if (file.type.startsWith("video/")) {
      this.video.srcObject = null;
      this.video.src = url;
      this.video.loop = true;
      try { await this.video.play(); } catch (_) { /* воспроизведение начнётся после касания */ }
      this.kind = "video";
      this.onStatus("Видео обрабатывается только на этом устройстве.", false);
    } else {
      const image = new Image();
      image.onload = () => { this.image = image; };
      image.src = url;
      this.kind = "image";
      this.onStatus("Фото обрабатывается только на этом устройстве.", false);
    }
  }

  useDemo() {
    this.stopStream();
    this.video.pause();
    this.kind = "demo";
  }

  stopStream() {
    if (this.stream) {
      this.stream.getTracks().forEach((track) => track.stop());
      this.stream = null;
    }
  }

  handleVisibility() {
    if (this.kind !== "camera") return;
    if (document.hidden) {
      this.stopStream();
    } else if (!this.stream) {
      this.startCamera(this.facing);
    }
  }
}
