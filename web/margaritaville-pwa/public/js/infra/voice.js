// Голосовая заметка: запись микрофона (MediaRecorder) и расшифровка на русском
// (Web Speech API, если браузер её даёт). Текст выдаётся после остановки записи.
// Источник: Infrastructure/Speech/VoiceTranscriptionService.swift, VoiceNoteViewModel.swift.

const Recognition = window.SpeechRecognition || window.webkitSpeechRecognition;

function pickMimeType() {
  const types = ["audio/mp4", "audio/webm;codecs=opus", "audio/webm"];
  return types.find((t) => window.MediaRecorder?.isTypeSupported?.(t)) ?? "";
}

export class VoiceRecorder {
  constructor({ onStatus, onPhase }) {
    this.onStatus = onStatus;
    this.onPhase = onPhase;
    this.phase = "idle";
    this.reset();
  }

  reset() {
    this.stream = null;
    this.recorder = null;
    this.recognition = null;
    this.chunks = [];
    this.finalText = "";
    this.interimText = "";
  }

  setPhase(phase, status) {
    this.phase = phase;
    if (status) this.onStatus(status);
    this.onPhase(phase);
  }

  get isRecording() { return this.phase === "recording"; }
  get canToggle() { return ["idle", "recording", "failed"].includes(this.phase); }

  async start(onCompletion) {
    if (!navigator.mediaDevices?.getUserMedia || !window.MediaRecorder) {
      this.setPhase("failed", "Запись голоса в этом браузере недоступна");
      return;
    }
    this.onCompletion = onCompletion;
    this.setPhase("requestingPermission", "Проверяю доступ...");
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    } catch {
      this.setPhase("failed", "Нет доступа к микрофону");
      return;
    }
    this.setPhase("starting", "Запускаю микрофон...");
    const mimeType = pickMimeType();
    this.recorder = new MediaRecorder(this.stream, mimeType ? { mimeType } : undefined);
    this.recorder.ondataavailable = (event) => { if (event.data.size) this.chunks.push(event.data); };
    this.recorder.onstop = () => this.finish();
    this.recorder.start();
    this.startRecognition();
    this.setPhase("recording", "Идёт запись...");
  }

  startRecognition() {
    if (!Recognition) return;
    try {
      const recognition = new Recognition();
      recognition.lang = "ru-RU";
      recognition.continuous = true;
      recognition.interimResults = true;
      recognition.onresult = (event) => {
        let interim = "";
        for (let i = event.resultIndex; i < event.results.length; i += 1) {
          const text = event.results[i][0].transcript;
          if (event.results[i].isFinal) this.finalText += text;
          else interim += text;
        }
        this.interimText = interim;
      };
      recognition.onend = () => {
        // Браузер может остановить распознавание по паузе — продолжаем, пока идёт запись.
        if (this.isRecording && this.recognition === recognition) {
          try { recognition.start(); } catch { /* уже запущено */ }
        }
      };
      recognition.onerror = () => {};
      recognition.start();
      this.recognition = recognition;
    } catch {
      this.recognition = null;
    }
  }

  stop() {
    if (!this.isRecording) return;
    this.setPhase("finishing", "Сохраняю запись...");
    const recognition = this.recognition;
    this.recognition = null;
    try { recognition?.stop(); } catch { /* уже остановлено */ }
    // Даём распознаванию дослать последние слова.
    setTimeout(() => this.recorder?.state === "recording" && this.recorder.stop(), recognition ? 600 : 0);
  }

  finish() {
    this.stream?.getTracks().forEach((track) => track.stop());
    const blob = new Blob(this.chunks, { type: this.recorder?.mimeType || "audio/mp4" });
    const transcript = `${this.finalText} ${this.interimText}`.replace(/\s+/g, " ").trim();
    const completion = this.onCompletion;
    this.reset();
    this.setPhase("idle", transcript ? "Готово к записи" : Recognition ? "Голос сохранён без расшифровки" : "Расшифровка в этом браузере недоступна");
    if (blob.size) completion?.({ blob, transcript: transcript || null });
  }

  cancel() {
    const recognition = this.recognition;
    this.recognition = null;
    try { recognition?.abort(); } catch { /* нет распознавания */ }
    if (this.recorder?.state === "recording") {
      this.recorder.onstop = null;
      this.recorder.stop();
    }
    this.stream?.getTracks().forEach((track) => track.stop());
    this.reset();
    this.phase = "idle";
  }
}
