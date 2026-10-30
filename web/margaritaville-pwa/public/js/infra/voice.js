// Голосовая заметка: запись микрофона (MediaRecorder) и расшифровка на языке интерфейса
// (Web Speech API, если браузер её даёт). Текст выдаётся после остановки записи.
// На части Android микрофон отдаётся только одному потребителю: запись и распознавание
// не работают вместе. Тогда режим запоминается и дальше идёт только расшифровка в текст.
// Источник: Infrastructure/Speech/VoiceTranscriptionService.swift, VoiceNoteViewModel.swift.
import { currentLanguage, tr } from "../i18n/i18n.js";

const Recognition = window.SpeechRecognition || window.webkitSpeechRecognition;
const MODE_KEY = "margaritaville.voiceMode";
const FATAL_ERRORS = new Set(["audio-capture", "not-allowed", "service-not-allowed", "network"]);

function savedMode() {
  try { return localStorage.getItem(MODE_KEY) === "textOnly" && Recognition ? "textOnly" : "both"; } catch { return "both"; }
}

function saveMode(mode) {
  try { localStorage.setItem(MODE_KEY, mode); } catch { /* приватный режим */ }
}

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
    this.recognitionError = null;
  }

  setPhase(phase, status) {
    this.phase = phase;
    if (status) this.onStatus(status);
    this.onPhase(phase);
  }

  get isRecording() { return this.phase === "recording"; }
  get canToggle() { return ["idle", "recording", "failed"].includes(this.phase); }

  async start(onCompletion) {
    this.onCompletion = onCompletion;
    this.mode = savedMode();
    if (this.mode === "textOnly") return this.startTextOnly();
    if (!navigator.mediaDevices?.getUserMedia || !window.MediaRecorder) {
      if (Recognition) return this.startTextOnly();
      this.setPhase("failed", tr("Запись голоса в этом браузере недоступна"));
      return;
    }
    this.setPhase("requestingPermission", tr("Проверяю доступ..."));
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    } catch {
      this.setPhase("failed", tr("Нет доступа к микрофону"));
      return;
    }
    this.setPhase("starting", tr("Запускаю микрофон..."));
    const mimeType = pickMimeType();
    this.recorder = new MediaRecorder(this.stream, mimeType ? { mimeType } : undefined);
    this.recorder.ondataavailable = (event) => { if (event.data.size) this.chunks.push(event.data); };
    this.recorder.onstop = () => this.finish();
    this.recorder.start();
    this.startRecognition(this.stream.getAudioTracks()[0]);
    this.setPhase("recording", tr("Идёт запись..."));
  }

  /// Только расшифровка: микрофон целиком у распознавания, аудиофайл не сохраняется.
  startTextOnly() {
    this.startRecognition(null);
    if (!this.recognition) {
      saveMode("both");
      this.setPhase("failed", tr("Расшифровка в этом браузере недоступна"));
      return;
    }
    this.setPhase("recording", tr("Идёт запись..."));
  }

  /// track — тот же микрофон, что у записи (Chrome умеет делить его через start(track)).
  startRecognition(track) {
    if (!Recognition) return;
    try {
      const recognition = new Recognition();
      recognition.lang = currentLanguage().speech;
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
      recognition.onerror = (event) => { this.recognitionError = event.error; };
      try {
        if (track) recognition.start(track);
        else recognition.start();
      } catch {
        recognition.start();
      }
      this.recognition = recognition;
    } catch {
      this.recognition = null;
    }
  }

  stop() {
    if (!this.isRecording) return;
    this.setPhase("finishing", tr("Сохраняю запись..."));
    const recognition = this.recognition;
    this.recognition = null;
    try { recognition?.stop(); } catch { /* уже остановлено */ }
    // Даём распознаванию дослать последние слова.
    setTimeout(() => {
      if (this.recorder?.state === "recording") this.recorder.stop();
      else if (!this.recorder) this.finish();
    }, recognition ? 600 : 0);
  }

  finish() {
    this.stream?.getTracks().forEach((track) => track.stop());
    const blob = this.recorder ? new Blob(this.chunks, { type: this.recorder.mimeType || "audio/mp4" }) : null;
    const transcript = `${this.finalText} ${this.interimText}`.replace(/\s+/g, " ").trim();
    const completion = this.onCompletion;
    const error = this.recognitionError;
    // Запись шла, а распознавание не получило микрофон — дальше только расшифровка.
    const conflict = this.mode === "both" && !transcript && FATAL_ERRORS.has(error);
    if (conflict) saveMode("textOnly");
    // В режиме «только текст» распознавание тоже не смогло — возвращаем обычную запись.
    if (this.mode === "textOnly" && !transcript && FATAL_ERRORS.has(error)) saveMode("both");
    this.reset();
    this.setPhase("idle", this.statusAfter(transcript, error, conflict));
    if (blob?.size || transcript) completion?.({ blob: blob?.size ? blob : null, transcript: transcript || null });
  }

  statusAfter(transcript, error, conflict) {
    if (transcript) return this.mode === "textOnly" ? tr("Текст добавлен в заметку") : tr("Готово к записи");
    if (!Recognition) return tr("Расшифровка в этом браузере недоступна");
    if (conflict) return tr("Телефон не даёт микрофон записи и расшифровке сразу. Следующие заметки будут только текстом.");
    if (error === "no-speech") return tr("Речь не распознана");
    return error ? tr("Голос сохранён без расшифровки ({error})", { error }) : tr("Голос сохранён без расшифровки");
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
